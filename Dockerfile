# Paperless conversion backend — LibreOffice + Python in one image.
FROM python:3.11-slim

# LibreOffice (Writer/Calc/Impress) does the Office<->PDF conversions.
# qpdf + fonts make encryption and rendering reliable.
RUN apt-get update && apt-get install -y --no-install-recommends \
        libreoffice-writer \
        libreoffice-calc \
        libreoffice-impress \
        qpdf \
        fonts-dejavu \
        fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8080

# 2 workers, long timeout because LibreOffice cold-starts can be slow.
CMD ["gunicorn", "-b", "0.0.0.0:8080", "-w", "2", "--timeout", "180", "app:app"]
