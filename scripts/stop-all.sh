#!/bin/bash
# Stop all CertiGraph services

echo "Stopping CertiGraph services..."

# Stop frontend
pkill -f "next.*3015" 2>/dev/null && echo "Frontend stopped" || echo "Frontend not running"

# Stop backend
pkill -f "uvicorn.*8015" 2>/dev/null && echo "Backend stopped" || echo "Backend not running"

echo "All services stopped."
