# ☁️ Auto Scaling 기반 AWS 클라우드 인프라 프로젝트

> 트래픽 급증에도 유연하게 대응하는 클라우드 인프라를 구축하고,  
DevOps 자동화와 실시간 모니터링까지 구현하는 6주 완성형 실습 프로젝트

---

## 📌 프로젝트 개요

이 프로젝트는 이벤트 기간 동안 반복적으로 발생하는 서버 다운 현상을  
해결하기 위한 **Auto Scaling 인프라 + 실시간 모니터링 + 자동 배포 시스템**을 구축하는 팀 기반 실습입니다.

---

## ⚙️ 기술 스택

| 분야 | 기술 |
|------|------|
| 클라우드 | AWS EC2, ALB, Auto Scaling, AMI, CloudWatch |
| 백엔드 | Python Flask |
| 배포 & 자동화 | GitHub Actions, Docker|
| 보안 | UFW, Security Groups |
| 협업 | Git, GitHub, Branch 전략, PR 리뷰 |

---

## ✨ 주요 기능

- EC2 기반 웹서버 구축 및 수동 배포 실습
- Python Flask 웹 애플리케이션 개발
- AMI 기반 Auto Scaling Group 구성
- ab 테스트로 인한 트래픽 자동 확장 확인
- CloudWatch 로그 수집 및 CPU 부하 경보
- GitHub Actions 기반 CI/CD 자동화 배포 파이프라인 구성
- 장애 시나리오 테스트 및 자동 복구

---

## 🗂️ 디렉토리 구조

```bash
auto-scaling-project/
├── flask-app/              # Flask 앱 코드
│   └── app.py
├── scripts/                # EC2 초기 셋업 스크립트
│   └── setup.sh
├── monitoring/             # CloudWatch 설정
│   └── config.json
├── auto-scaling/           # AMI, ASG, LT 설정
│   └── auto-scaling-notes.md
├── docs/                   # 발표자료 및 협업 문서
│   ├── 협업규칙.md
│   ├── week1-ec2-nginx.png
│   ├── architecture.png
│   ├── week3-auto-scaling-flow.png
│   ├── aws 과금 방지 규칙.md
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions 배포 설정
├── .gitignore
└── README.md


## 📍 최종 목표

- Auto Scaling 기반 안정적 서비스 인프라 구현  
- 실시간 모니터링 및 자동 복구 구조 실현  
- 자동화된 간단 CI/CD 파이프라인으로 운영 효율화  
- 장애 시나리오 실험을 통한 안정성 테스트  

---

## ✍️ 작성자 및 팀 정보

| 이름 | 역할 |
|------|------|
| 유민선 | 모니터링 & 경보 담당 |
| 김동욱 | Devops 자동화 담당 |
| 김성희 | 인프라/네트워크 구성 |
| 최재원 | 보안 및 서버 운영 담당 |
| 김현지 | 장애 실험 및 문서화 담당 |
