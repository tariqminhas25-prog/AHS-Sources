FROM python:3.12-slim

# WeasyPrint needs pango/harfbuzz; the Noto fonts give Arabic text in the PDF reports.
RUN apt-get update && apt-get install -y --no-install-recommends \
      libpango-1.0-0 libpangoft2-1.0-0 libharfbuzz-subset0 fonts-noto-core fonts-dejavu-core tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /srv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app app
COPY wsgi.py .

RUN useradd -r -u 10001 ahs && mkdir -p /data && chown ahs /data
ENV DATABASE_PATH=/data/ahs.sqlite FLASK_APP=app
VOLUME /data
EXPOSE 8000

# One worker on purpose: it also runs the daily email scheduler, and several workers would send duplicates.
# Starts as root only to fix ownership of the mounted data disk, then drops to the unprivileged user.
CMD ["sh", "-c", "chown -R ahs /data && exec setpriv --reuid=ahs --regid=ahs --clear-groups gunicorn --workers 1 --threads 4 --timeout 120 --bind 0.0.0.0:${PORT:-8000} wsgi:app"]
