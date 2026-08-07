#!/bin/bash
set -e
sudo cp /tmp/DashboardPage.tsx /opt/leaks-frontend/web/src/pages/DashboardPage.tsx
sudo cp /tmp/DonutChart.tsx /opt/leaks-frontend/web/src/components/DonutChart.tsx
cd /opt/leaks-frontend
docker compose up -d --build frontend
