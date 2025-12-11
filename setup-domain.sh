#!/bin/bash

# Dokploy 도메인 자동 설정 스크립트
# 사용법: export DOKPLOY_AUTH_TOKEN="your-token" && ./setup-domain.sh

set -e

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 설정
DOKPLOY_URL="http://34.64.143.114:3000"
SERVER_IP="34.64.143.114"
SUBDOMAIN="testgraph"
DOMAIN="${SUBDOMAIN}.${SERVER_IP}.nip.io"
APP_ID="4sc-UR-ll0dwt7DtoBECo"
PROJECT_ID="SVSYksCZ8lAr2Mdrg8902"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Dokploy 도메인 자동 설정            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}도메인: ${DOMAIN}${NC}"
echo ""

# 토큰 확인
if [ -z "$DOKPLOY_AUTH_TOKEN" ]; then
    echo -e "${RED}Error: DOKPLOY_AUTH_TOKEN not set${NC}"
    echo ""
    echo "Usage:"
    echo "  export DOKPLOY_AUTH_TOKEN='your-api-token'"
    echo "  ./setup-domain.sh"
    exit 1
fi

# API 호출 함수
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $DOKPLOY_AUTH_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "${DOKPLOY_URL}${endpoint}"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $DOKPLOY_AUTH_TOKEN" \
            "${DOKPLOY_URL}${endpoint}"
    fi
}

echo -e "${YELLOW}[1/5] 인증 확인...${NC}"
export DOKPLOY_URL
if dokploy verify > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 인증 성공${NC}"
else
    echo -e "${YELLOW}⚠ CLI 인증 실패, API로 진행${NC}"
fi

echo ""
echo -e "${YELLOW}[2/5] Git 저장소 설정...${NC}"

GIT_CONFIG=$(cat <<EOF
{
  "repository": "git@github.com:myaji35/15_CertiGraph.git",
  "branch": "main",
  "buildPath": "/backend",
  "dockerfile": "Dockerfile"
}
EOF
)

api_call "PATCH" "/api/application/${APP_ID}" "$GIT_CONFIG" > /dev/null 2>&1
echo -e "${GREEN}✓ Git 설정 완료${NC}"

echo ""
echo -e "${YELLOW}[3/5] 빌드 설정...${NC}"

BUILD_CONFIG=$(cat <<EOF
{
  "applicationId": "${APP_ID}",
  "dockerfile": "Dockerfile",
  "dockerContextPath": "/backend",
  "buildPath": "/backend",
  "port": 8000
}
EOF
)

api_call "PATCH" "/api/application/${APP_ID}" "$BUILD_CONFIG" > /dev/null 2>&1
echo -e "${GREEN}✓ 빌드 설정 완료${NC}"

echo ""
echo -e "${YELLOW}[4/5] 도메인 추가...${NC}"

DOMAIN_CONFIG=$(cat <<EOF
{
  "host": "${DOMAIN}",
  "path": "/",
  "port": 8000,
  "https": false,
  "applicationId": "${APP_ID}"
}
EOF
)

DOMAIN_RESPONSE=$(api_call "POST" "/api/application/${APP_ID}/domains" "$DOMAIN_CONFIG" 2>&1)

if echo "$DOMAIN_RESPONSE" | grep -q "error" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠ 도메인 추가 실패 (이미 존재하거나 권한 문제)${NC}"
    echo -e "${BLUE}→ 수동 설정: Dokploy 대시보드 → Domains 탭${NC}"
else
    echo -e "${GREEN}✓ 도메인 추가 완료: ${DOMAIN}${NC}"
fi

echo ""
echo -e "${YELLOW}[5/5] 환경 변수 설정...${NC}"

if [ -f "backend/.env.production" ]; then
    echo -e "${BLUE}→ backend/.env.production 파일 확인됨${NC}"
    echo -e "${BLUE}→ Dokploy 대시보드 → Environment 탭에서 설정하세요${NC}"
else
    echo -e "${YELLOW}⚠ .env.production 파일 없음${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   설정 완료!                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}도메인: ${GREEN}http://${DOMAIN}${NC}"
echo -e "${BLUE}Health Check: ${GREEN}http://${DOMAIN}/health${NC}"
echo -e "${BLUE}API Docs: ${GREEN}http://${DOMAIN}/docs${NC}"
echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}다음 단계:${NC}"
echo ""
echo "1. 환경 변수 설정 (Dokploy 대시보드):"
echo "   → http://34.64.143.114:3000"
echo "   → Environment 탭"
echo ""
echo "2. 배포:"
echo "   → General 탭 → Deploy 버튼"
echo ""
echo "3. 확인:"
echo "   curl http://${DOMAIN}/health"
echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
