FROM python:3.9-slim
RUN apt-get update && apt-get install -y --no-install-recommends curl \
 && apt-get clean && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
ARG APP_VERSION=v1.0
ENV APP_VERSION=${APP_VERSION}
ENV PYTHONUNBUFFERED=1
EXPOSE 5000
EXPOSE 8080
RUN groupadd -r appuser && useradd -r -g appuser appuser && \
    chown -R appuser:appuser /app
USER appuser
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "3", "--timeout", "60", "app:app"]