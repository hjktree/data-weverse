1. EC2 인스턴스 생성 및 퍼블릭 IP 테스트

    1) AWS 콘솔 접속
        https://aws.amazon.com/ 에 접속 후 로그인하세요.

    2) EC2 대시보드 진입
        서비스 목록에서 EC2를 찾아 클릭합니다.

    3) 인스턴스 생성 시작
        좌측 메뉴에서 인스턴스 > 인스턴스 시작 버튼 클릭

    4) AMI(Amazon Machine Image) 선택
        Ubuntu Server 20.04 LTS 또는 22.04 LTS (권장) 선택

    5) 인스턴스 유형 선택
        t2.micro 선택

    6) 인스턴스 세부 정보 구성
        기본 설정 유지

    7) 태그 추가 (선택사항)
        data-weverse로 지정

    8) 키 페어 생성 및 다운로드
        data-weverse 생성 (pem 파일 다운로드 필수)

    9) 인스턴스 생성 완료 후 대기
        인스턴스가 'running' 상태가 될 때까지 대기

2. 퍼블릭 IP 접속 확인
    1) 터미널 / 명령 프롬프트 열기

    2) 키 파일 권한 설정 (Mac/Linux)
        chmod 400 data-weverse.pem

    3) SSH 접속 명령어 실행

        ssh -i data-weverse.pem ubuntu@퍼블릭IP주소

        퍼블릭IP주소 : AWS EC2 콘솔에서 확인 가능

3. Nginx 웹 서버 설치 및 브라우저에서 확인
    1) 패키지 업데이트 및 Nginx 설치
        ubuntu cmd 창에 아래 명령어 입력

        sudo apt update
        sudo apt install nginx -y
    2) 방화벽(보안 그룹) 설정 확인
        AWS 콘솔 > EC2 > 보안 그룹 > 사용 중인 보안 그룹 클릭 > 인바운드 규칙 편집 클릭

        인바운드 규칙에 다음 항목이 있는지 확인:
            HTTP | TCP | 포트 80 | 소스: 0.0.0.0/0 (전체 허용)
    3) 브라우저에서 접속 확인

        브라우저 주소창에 EC2 퍼블릭 IP 입력:
        http://13.158.37.187/

        welcome to nginx 문구가 뜨면 완료

4. CloudWatch 기본 모니터링 탭 확인(기초탐색)
    1)  기본적인 CloudWatch 지표 확인
        AWS 콘솔 > EC2 > 인스턴스 > 사용 중인 인스턴스 클릭 > 하단 탭의 모니터링 클릭

    2) CloudWatch 콘솔 직접 보기
        CloudWatch 콘솔 이동
        https://console.aws.amazon.com/cloudwatch
        좌측 메뉴 → 지표(Metrics) 클릭
        EC2 > Per-Instance Metrics 클릭

