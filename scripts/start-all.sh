#!/bin/bash
# Start all CertiGraph services
# Frontend: 3015, Backend: 8015

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Starting CertiGraph Services ==="
echo ""

# Start backend
echo "[1/2] Starting Backend..."
bash "$SCRIPT_DIR/start-backend.sh"
sleep 2

# Start frontend
echo "[2/2] Starting Frontend..."
bash "$SCRIPT_DIR/start-frontend.sh"
sleep 3

echo ""
echo "=== CertiGraph Services Started ==="
echo "Frontend: http://localhost:3015"
echo "Backend:  http://localhost:8015"
echo "API Docs: http://localhost:8015/docs"
echo ""
echo "Nginx config: /home/15_CertiGraph/nginx-certigraph.conf"
echo "Add the nginx config to enable /certigraph path on the server."
