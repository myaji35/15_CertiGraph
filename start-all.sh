#!/bin/bash

# CertiGraph 전체 서비스 시작 스크립트
# 사용법: ./start-all.sh

echo "🚀 CertiGraph 서비스를 시작합니다..."

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 기존 프로세스 종료
echo -e "${YELLOW}기존 프로세스를 종료합니다...${NC}"
lsof -ti:8015 | xargs kill -9 2>/dev/null || true
lsof -ti:3030 | xargs kill -9 2>/dev/null || true
sleep 1

# 2. Cloud SQL 프록시 확인 (이미 실행 중이면 재시작하지 않음)
if ! lsof -i:5433 > /dev/null 2>&1; then
    echo -e "${YELLOW}Cloud SQL 프록시를 시작합니다...${NC}"
    cloud-sql-proxy postgresql-479201:asia-northeast3:certigraph-db --port=5433 &
    sleep 2
else
    echo -e "${GREEN}✓ Cloud SQL 프록시가 이미 실행 중입니다 (포트 5433)${NC}"
fi

# 3. 백엔드 서버 시작
echo -e "${YELLOW}백엔드 서버를 시작합니다 (포트 8015)...${NC}"
cd backend
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8015 --reload &
BACKEND_PID=$!
cd ..

# 백엔드가 시작될 때까지 대기
sleep 3

# 백엔드 상태 확인
if lsof -i:8015 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 백엔드 서버가 성공적으로 시작되었습니다${NC}"
else
    echo -e "${RED}✗ 백엔드 서버 시작 실패${NC}"
    exit 1
fi

# 4. 프론트엔드 서버 시작
echo -e "${YELLOW}프론트엔드 서버를 시작합니다 (포트 3030)...${NC}"
cd frontend
npm run dev -- -p 3030 &
FRONTEND_PID=$!
cd ..

# 프론트엔드가 시작될 때까지 대기
sleep 5

# 프론트엔드 상태 확인
if lsof -i:3030 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 프론트엔드 서버가 성공적으로 시작되었습니다${NC}"
else
    echo -e "${RED}✗ 프론트엔드 서버 시작 실패${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ 모든 서비스가 성공적으로 시작되었습니다!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "📌 접속 정보:"
echo "   - 프론트엔드: http://localhost:3030"
echo "   - 백엔드 API: http://localhost:8015"
echo "   - API 문서: http://localhost:8015/docs"
echo ""
echo "📌 서버 종료 방법:"
echo "   - 이 터미널에서 Ctrl+C를 누르거나"
echo "   - ./stop-all.sh 실행"
echo ""
echo -e "${YELLOW}로그를 확인하려면 이 터미널을 열어두세요${NC}"

# 프로세스 대기
wait $BACKEND_PID $FRONTEND_PID