#!/bin/bash

# CertiGraph 서비스 종료 스크립트
# 사용법: ./stop-all.sh

echo "🛑 CertiGraph 서비스를 종료합니다..."

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 프론트엔드 종료
echo -e "${YELLOW}프론트엔드 서버 종료 중...${NC}"
lsof -ti:3030 | xargs kill -9 2>/dev/null || true

# 백엔드 종료
echo -e "${YELLOW}백엔드 서버 종료 중...${NC}"
lsof -ti:8015 | xargs kill -9 2>/dev/null || true

# Cloud SQL 프록시는 유지 (필요시 수동으로 종료)
echo -e "${YELLOW}참고: Cloud SQL 프록시는 유지됩니다 (수동 종료 필요시: lsof -ti:5433 | xargs kill -9)${NC}"

sleep 1

# 상태 확인
echo ""
echo "상태 확인:"

if ! lsof -i:3030 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 프론트엔드 서버가 종료되었습니다${NC}"
else
    echo -e "${RED}✗ 프론트엔드 서버가 아직 실행 중입니다${NC}"
fi

if ! lsof -i:8015 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 백엔드 서버가 종료되었습니다${NC}"
else
    echo -e "${RED}✗ 백엔드 서버가 아직 실행 중입니다${NC}"
fi

echo ""
echo -e "${GREEN}✓ 서비스 종료 완료${NC}"