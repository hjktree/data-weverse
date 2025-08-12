FROM python:3.12-slim

# 보안/재현성에 유리한 기본 설정
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# 의존성 먼저 설치 (빌드 캐시 최적화)
COPY requirement.txt .
RUN pip install --no-cache-dir -r requirement.txt

# 소스 복사
COPY . .

EXPOSE 5000

# 워커 2개로 gunicorn 실행 (app:app -> 파일명:변수명)
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:5000", "app:app"]
