FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
	PORT=8080

WORKDIR /app

COPY app.py /app/app.py

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
	CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health').read()"

CMD ["python", "/app/app.py"]
