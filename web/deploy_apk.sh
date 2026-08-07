#!/bin/bash
set -e
sudo cp /tmp/leaks-survey.apk /opt/leaks-frontend/web/apk/leaks-survey.apk
cd /opt/leaks-frontend
docker compose up -d --build frontend
