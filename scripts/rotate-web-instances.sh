#!/bin/bash
set -Eeuo pipefail
echo "Rolling update ASG"
ASG_NAME="asg-test-k"
ORIGIN_MIN=0
ORIGIN_MAX=0
ORIGIN_DESIRED=0

# 배치·버퍼 파라미터(환경변수로 덮어쓰기 가능
BATCH_SIZE=${BATCH_SIZE:-2}           # 한 번에 종료/교체할 인스턴스 수
BUFFER=${BUFFER:-$BATCH_SIZE}         # 여유 용량(원래 Desired + BUFFER 만큼 확보)
TERMINATE_TIMEOUT=${TERMINATE_TIMEOUT:-300}  # [초] 배치 terminating 대기 타임아웃
HEALTHY_TIMEOUT=${HEALTHY_TIMEOUT:-600}      # [초] 배치 healthy 대기 타임아웃
SLEEP_SEC=${SLEEP_SEC:-6}                    # 폴링 주기


# 인스턴스 상태 출력 함수
print_instance_states() {
  echo "현재 인스턴스 상태:"
  aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$ASG_NAME" \
    --query 'AutoScalingGroups[0].Instances[*].[InstanceId, LifecycleState, HealthStatus]' \
    --output text
}

# 기존 용량 복구 함수
restore_capacity() {
  aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name "$ASG_NAME" \
    --min-size "$ORIGIN_MIN" \
    --max-size "$ORIGIN_MAX" \
    --desired-capacity "$ORIGIN_DESIRED"
  echo "용량 복원 완료: $ORIGIN_MIN(Min), $ORIGIN_MAX(Max), $ORIGIN_DESIRED(Desired)"
}

# [추가] ALB 타깃 그룹 Healthy 수 조회 헬퍼
healthy_targets() {
  aws elbv2 describe-target-health \
    --target-group-arn "$TG_ARN" \
    --region ap-northeast-1 \
    --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" \
    --output text
}

# 1. 기존 용량 설정 백업
ORIGIN_MIN=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$ASG_NAME" \
  --query 'AutoScalingGroups[0].MinSize' --output text)
ORIGIN_MAX=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$ASG_NAME" \
  --query 'AutoScalingGroups[0].MaxSize' --output text)
ORIGIN_DESIRED=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$ASG_NAME" \
  --query 'AutoScalingGroups[0].DesiredCapacity' --output text)
echo "기존 용량: $ORIGIN_MIN(Min), $ORIGIN_MAX(Max), $ORIGIN_DESIRED(Desired)"

# 2. 교체 대상 인스턴스 파악
instances=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$ASG_NAME" \
  --query 'AutoScalingGroups[0].Instances[?!starts_with(LifecycleState, `Terminating`)].InstanceId' \
  --output text)
read -ra instance_array <<< "$instances"
replace_count=${#instance_array[@]}
echo "교체 대상 인스턴스 ($replace_count개): ${instance_array[*]}"
print_instance_states

# 3. 용량 설정 변경 ( ORIGIN_DESIRED + BUFFER )
new_capacity=$((ORIGIN_DESIRED + BUFFER ))
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name "$ASG_NAME" \
  --min-size "$new_capacity" \
  --max-size "$new_capacity" \
  --desired-capacity "$new_capacity"
echo "용량 설정 변경: Desired ${ORIGIN_DESIRED} → ${new_capacity} (Min=Max=Desired)"

# ASG에 연결된 첫 번째 Target Group ARN 확보
TG_ARN=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$ASG_NAME" \
  --query 'AutoScalingGroups[0].TargetGroupARNs[0]' \
  --output text)
echo "사용할 Target Group: $TG_ARN"


# 4. 확장된 용량이 ALB(Target Group) Healthy 될 때까지 대기  [변경]
for i in $(seq $(( HEALTHY_TIMEOUT / SLEEP_SEC ))); do
  echo "새 인스턴스 Healthy 대기: $i"
  tg_healthy=$(healthy_targets)
  echo "TargetGroup Healthy: ${tg_healthy}/${new_capacity}"
  if (( tg_healthy >= new_capacity )); then
    echo "✅ 초기 확장 Target Group Healthy 확인 완료"
    print_instance_states
    break
  fi
  if (( i == HEALTHY_TIMEOUT / SLEEP_SEC )); then
    echo "❌ 초기 Target Group Healthy 확인 실패"
    print_instance_states
    restore_capacity
    exit 1
  fi
  sleep "$SLEEP_SEC"
done

# [변경] 기준 Healthy 수를 'ALB 타깃 그룹' 기준으로 기록
baseline_healthy=$(healthy_targets)
echo "baseline_healthy(TG): $baseline_healthy"

# 5. 대상 인스턴스들을 하나씩 교체
echo "인스턴스 롤링 교체 시작..."
replaced_total=0
total=${#instance_array[@]}

for ((start=0; start<total; start+=BATCH_SIZE)); do
  end=$(( start + BATCH_SIZE - 1 ))
  (( end >= total )) && end=$(( total - 1 ))
  batch_size=$(( end - start + 1 ))

  echo "---------------------------------------------"
  echo "배치 종료 요청: index ${start} ~ ${end} (배치 크기: ${batch_size})"

  # 5.1 배치 동시 종료 요청(병렬)
  pids=()
  for ((i=start; i<=end; i++)); do
    id="${instance_array[$i]}"
    echo "종료 요청 → $id"
    aws autoscaling terminate-instance-in-auto-scaling-group \
      --instance-id "$id" \
      --no-should-decrement-desired-capacity & pids+=($!)
  done
  # 모든 종료 API 호출 완료 대기
  for pid in "${pids[@]}"; do wait "$pid"; done

  # 5.2 배치 전체가 Terminating(or 목록에서 사라짐) 될 때까지 대기
  deadline=$(( SECONDS + TERMINATE_TIMEOUT ))
  while : ; do
    all_terminating=true
    for ((i=start; i<=end; i++)); do
      id="${instance_array[$i]}"
      lifecycle=$(aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names "$ASG_NAME" \
        --query "AutoScalingGroups[0].Instances[?InstanceId=='$id'].LifecycleState" \
        --output text)
      if [[ -n "$lifecycle" && "$lifecycle" != Terminating* ]]; then
        all_terminating=false
        echo "$id 상태: $lifecycle (terminating 대기 중)"
      fi
    done
    $all_terminating && { echo "✅ 배치 terminating 확인 완료"; print_instance_states; break; }
    (( SECONDS >= deadline )) && {
      echo "❌ 배치 terminating 확인 타임아웃"
      print_instance_states
      restore_capacity
      exit 1
    }
    sleep "$SLEEP_SEC"
 done
done

# 6. 기존 용량 설정 복구
echo "롤링 업데이트 완료"
restore_capacity