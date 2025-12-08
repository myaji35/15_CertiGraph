#!/bin/bash

# CertiGraph Backend Server Startup Script
# Usage: ./start_server.sh

# Change to backend directory
cd "$(dirname "$0")"

# Activate virtual environment
source venv/bin/activate

# Kill any existing server on port 8015
echo "Stopping any existing server on port 8015..."
lsof -ti:8015 | xargs kill -9 2>/dev/null || true
sleep 1

# Start the server
echo "Starting CertiGraph backend server on http://localhost:8015..."
uvicorn app.main:app --host 0.0.0.0 --port 8015 --reload
