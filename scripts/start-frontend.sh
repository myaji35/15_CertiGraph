#!/bin/bash
# Start CertiGraph Frontend (Next.js)
# Port: 3015

cd /home/15_CertiGraph/frontend

# Kill existing process on port 3015
pkill -f "next.*3015" 2>/dev/null || true

# Build if needed
if [ ! -d ".next" ]; then
    echo "Building Next.js app..."
    npm run build
fi

# Start in production mode
echo "Starting CertiGraph Frontend on port 3015..."
PORT=3015 npm run start &

echo "Frontend started. PID: $!"
