#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.

echo "Running Flask application..."
exec gunicorn app:app \
    --bind 0.0.0.0:5000 \
    --chdir /app/ \
    --workers 2 \
    --worker-tmp-dir /dev/shm \
    --pid /dev/shm/gunicorn.pid \
    --timeout 3600 \
    --graceful-timeout 30 \
    --keep-alive 5 \
    --max-requests 1000 \
    --max-requests-jitter 50 \
    --access-logfile '-' \
    --capture-output
