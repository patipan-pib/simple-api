# syntax=docker/dockerfile:1
FROM python:3.11-alpine

WORKDIR /app

# ใช้ requirements.txt ที่ ROOT (ของ repo)
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /app/requirements.txt

# คัดลอกซอร์สจริงจากโฟลเดอร์ app/
COPY app/ /app/

ENV PYTHONUNBUFFERED=1
ENV TEACHER_CODE=UNSET
EXPOSE 5000

# ถ้าใน app/app.py มี Flask instance ชื่อ app
CMD ["gunicorn", "-b", "0.0.0.0:5000", "app:app", "--workers", "2", "--threads", "4", "--timeout", "60"]
