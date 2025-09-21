# syntax=docker/dockerfile:1
FROM python:3.11-alpine
WORKDIR /app
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
EXPOSE 5000
COPY . .
CMD ["flask", "run"]
