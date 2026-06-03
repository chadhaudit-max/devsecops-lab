# Dockerfile
# ❌ Using an older base image - Trivy will find CVEs here
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

# ❌ Running as root (bad practice)
EXPOSE 5000

CMD ["python", "app.py"]
