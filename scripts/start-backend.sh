#!/bin/bash
# Start CertiGraph Backend (FastAPI)
# Port: 8015

cd /home/15_CertiGraph/backend

# Kill existing process on port 8015
pkill -f "uvicorn.*8015" 2>/dev/null || true

# Add local bin to path
export PATH=$HOME/.local/bin:$PATH

# Start FastAPI
echo "Starting CertiGraph Backend on port 8015..."
~/.local/bin/uvicorn app.main:app --host 0.0.0.0 --port 8015 --reload &

echo "Backend started. PID: $!"
