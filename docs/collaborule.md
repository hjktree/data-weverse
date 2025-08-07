# 협업 규칙

## 브랜치 전략
- `main`: 배포용
- `feature/이름`: 각자 개발 작업용 (예: `feature/jihyun`)

## 커밋 메시지 규칙
- 형식: `타입: 설명`
- 예시:
  - `feat: Flask 앱 초기 구성`
  - `docs: 협업 규칙 작성`
  - `fix: EC2 설정 오류 수정`

## PR(Pull Request) 규칙
- 제목: `작업 요약 (이름)`
- 리뷰 후 `main` 브랜치로 merge
- 팀원 최소 1인 이상 리뷰 후 merge

## 기타
- 평소 작업한 내용은 각자 노션 혹은 슬랙 등에 보관 
- 매주 월요일까지 `docs/weekN-역할명.md`에 실습 결과 캡처 및 설명 정리

# 🚨 GitHub 협업 시 절대 공유하거나 업로드해서는 안 되는 정보들 (AWS 실습 기준)

팀 프로젝트 중 실수로 민감한 정보가 GitHub에 업로드되면 **AWS 요금 폭탄**, **계정 해킹**, **데이터 유출** 등의 심각한 사고로 이어질 수 있습니다.

아래 항목은 모두 **절대 GitHub에 공유하거나 커밋/푸시해서는 안 되는 민감정보** 목록입니다.

---

## 📛 1. 절대 올리면 안 되는 민감 정보 목록

| 항목 | 설명 | 사고 사례 및 영향 |

| ✅ AWS Access Key / Secret Key | IAM 사용자 생성 시 발급되는 키 쌍 | 💸 키 유출 → 타인이 AWS 리소스 생성 → 수십~수백만 원 과금 발생 사례 다수 |

| ✅ `.pem` 키 파일 | EC2 인스턴스 접속용 SSH 키 | 🔓 키 노출 시 EC2에 누구나 접속 가능 |

| ✅ GitHub Personal Access Token | GitHub 자동화 설정 시 발급 | 🧬 노출되면 리포지토리 전체 권한 탈취 가능 |

| ✅ GitHub Actions Secrets | 자동 배포 시 저장한 민감 정보 | 🔐 Secrets는 코드에서 직접 사용하지 말 것 (출력 금지) |

| ✅ 환경 변수 (.env 파일) | DB 비밀번호, API 키 등 보관 | ⚠️ 커밋 실수 많음, 반드시 `.gitignore` 필요 |

| ✅ RDS, DB, Redis 접속 주소 및 포트 | 내외부 접근 가능한 IP, 포트 포함 | 🔗 외부 침입/디도스 위협 증가 |

| ✅ 인증 토큰, API Key | 외부 서비스(GCP, OpenAI, Slack 등) API 키 | 🎯 대부분의 API 사용량에 따라 요금 발생 |

| ✅ CloudFormation, Terraform 상태 파일 (`.tfstate`) | 암호화되지 않은 상태에서 키 포함될 수 있음 | 🧨 비밀번호, 키 등 포함된 경우 다수 |

---

## ⚠️ 2. 실수로 업로드 시 대처 방법

| 상황 | 조치 방법 |

| ✅실수로 키를 커밋/푸시함 | 즉시 해당 키를 AWS 콘솔에서 삭제 또는 비활성화 |

| ✅`.pem` 파일 업로드됨 | 키 폐기 → 새 키페어 생성 후 다시 설정 |

| ✅GitHub에 Token 노출됨 | GitHub > Developer Settings > Token 삭제 |

| ✅민감 정보 포함된 커밋이 push됨 | 커밋 내역을 `git filter-repo` 등으로 **완전히 제거**하고 새 리포지토리 생성 고려 |

| ✅노출된 리포지토리가 public인 경우 | 즉시 private 전환 후 GitHub에 보안 사고 신고 (https://github.com/contact) |

---

## 🛡️ 3. 예방을 위한 GitHub 보안 규칙

| 수칙 | 설명 |

| 📌 `.gitignore`에 민감 파일 등록 | 예: `.env`, `team-key.pem`, `*.pem`, `secrets.json` 등 |

| 📌 민감정보는 GitHub Actions Secrets에만 저장 | Secrets은 GitHub Settings > Secrets 에서 설정 |

| 📌 `output` 명령어로 Secrets 출력 금지 | 로그에 노출되면 의미 없음 |

| 📌 코드에 하드코딩된 키 금지 | `accessKey = "AKIA..."` 이런 형태는 즉시 탐지됨 |

| 📌 자동 커밋 전 `git status`, `git diff` 반드시 확인 | 실수 방지용 습관화 필요 |

| 📌 GitGuardian 등 민감정보 탐지 툴 사용 권장 | GitHub 연동으로 키 유출 실시간 탐지 가능 |

---

## 🧠 4. 보안 실수 예방 체크리스트

- 1.`.gitignore`에 `*.pem`, `.env`, `*.tfstate` 포함했는가?

- 2. AWS Key 또는 Token을 코드에 절대 하드코딩하지 않았는가?

- 3. GitHub Actions Secrets를 통해 민감정보를 안전하게 주입했는가?

- 4. 커밋 전 `git diff`, `git status`로 파일 확인을 했는가?

- 5. GitHub에 올린 리포지토리는 기본 `private`으로 설정했는가?


---

## 📌 팀 규칙 요약

> 팀원은 아래 내용을 반드시 준수해야 하며, 위반 시 프로젝트 리소스 손실 및 금전적 피해가 발생할 수 있습니다.

- `.env`, `.pem`, AWS Key, Token 등 민감정보는 GitHub에 절대 업로드 금지
- 민감정보는 반드시 `.gitignore`에 등록하고, 공유는 Slack/Notion 등 외부에서만
- GitHub Actions 활용 시 Secrets 설정 필수, 로그에 민감정보 노출 주의
- 민감정보 포함된 커밋은 즉시 알리고 조치할 것
- 모든 리포지토리는 **private** 상태 유지

---

🔐 **보안을 지키는 것이 곧 팀원 전체의 책임입니다.**  
💣 작은 실수 하나가 팀 전체 프로젝트를 무너뜨릴 수 있습니다.


