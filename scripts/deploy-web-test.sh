#!/bin/bash
set -Eeuo pipefail
echo "Deploy web-test and run health check"

terminate() {
  local id="${1:-}"
  if [[ -n "${id}" ]]; then
    echo "Terminating instance ${id}..."
    aws ec2 terminate-instances --instance-ids "${id}" >/dev/null
  fi
}

cleanup() {
  rm -f ~/.ssh/web-key.pem || true
}
trap 'cleanup' EXIT

# 1) 인스턴스 생성
instance_id=$(aws ec2 run-instances \
  --launch-template LaunchTemplateName="web-test-lt" \
  --query 'Instances[0].InstanceId' --output text)
echo "Web-test instance id: ${instance_id}"

# 문제가 생겨도 반드시 종료
trap 'terminate "${instance_id}"; cleanup' ERR INT

# 2) running 상태까지만 대기
aws ec2 wait instance-running --instance-ids "${instance_id}"
echo "Instance state: running"

# 3) 프라이빗 IP 조회
private_ip=$(aws ec2 describe-instances --instance-ids "${instance_id}" \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
echo "Web-test private ip: ${private_ip}"

# 4) SSH 가능해질 때까지 초단위 폴링(최대 90초)
echo "Waiting for SSH to be ready..."
deadline=$((SECONDS + 90))
while (( SECONDS < deadline )); do
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -i "~/.ssh/web-key.pem" \
       -q ubuntu@"${private_ip}" "exit 0"; then
    echo "SSH ready."
    break
  fi
  sleep 3
done
if (( SECONDS >= deadline )); then
  echo "SSH not ready in time ❌"
  terminate "${instance_id}"
  exit 1
fi

# 5) /health 초단위 헬스 체크(3초 간격, 최대 360초)
echo "Probing app health..."
deadline=$((SECONDS + 360))
while (( SECONDS < deadline )); do
  code=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -i "~/.ssh/web-key.pem" \
    ubuntu@"${private_ip}" \
    "curl -s -o /dev/null -w '%{http_code}' --connect-timeout 1 --max-time 2 http://localhost/health" \
    || echo "000")
  echo "Health: ${code}"
  if [[ "${code}" == "200" ]]; then
    echo "Health check passed ✅"
    terminate "${instance_id}"
    rm -f ~/.ssh/web-key.pem
    exit 0
  fi
  sleep 3
done

echo "Health check failed ❌"
terminate "${instance_id}"
rm -f ~/.ssh/web-key.pem
exit 1