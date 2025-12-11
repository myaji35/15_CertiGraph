#!/bin/bash

# Dokploy 자동 배포 스크립트 (API 토큰 필요)
# 사용법: export DOKPLOY_AUTH_TOKEN="your-token" && ./auto-deploy-dokploy.sh

set -e

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOKPLOY_URL="http://34.64.143.114:3000"
PROJECT_ID="SVSYksCZ8lAr2Mdrg8902"
APP_ID="4sc-UR-ll0dwt7DtoBECo"

# 토큰 확인
if [ -z "$DOKPLOY_AUTH_TOKEN" ]; then
    echo -e "${RED}Error: DOKPLOY_AUTH_TOKEN environment variable not set${NC}"
    echo ""
    echo "Usage:"
    echo "  export DOKPLOY_AUTH_TOKEN='your-api-token'"
    echo "  ./auto-deploy-dokploy.sh"
    echo ""
    echo "Get token from: http://34.64.143.114:3000 → Settings → API Tokens"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Dokploy 자동 배포 스크립트          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

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
            "$DOKPLOY_URL/api/v1$endpoint"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $DOKPLOY_AUTH_TOKEN" \
            "$DOKPLOY_URL/api/v1$endpoint"
    fi
}

echo -e "${YELLOW}[1/4] Git 저장소 설정...${NC}"

# Git 설정 업데이트
GIT_CONFIG=$(cat <<EOF
{
  "repository": "git@github.com:myaji35/15_CertiGraph.git",
  "branch": "main",
  "buildPath": "/backend",
  "dockerfile": "Dockerfile"
}
EOF
)

if api_call "PATCH" "/applications/$APP_ID/git" "$GIT_CONFIG" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Git 저장소 설정 완료${NC}"
else
    echo -e "${YELLOW}⚠ Git 설정 업데이트 실패 (수동으로 설정 필요)${NC}"
fi

echo ""
echo -e "${YELLOW}[2/4] 빌드 설정...${NC}"

BUILD_CONFIG=$(cat <<EOF
{
  "port": 8000,
  "healthCheckPath": "/health",
  "healthCheckPort": 8000,
  "healthCheckInterval": 30,
  "healthCheckTimeout": 5,
  "healthCheckRetries": 3
}
EOF
)

if api_call "PATCH" "/applications/$APP_ID/settings" "$BUILD_CONFIG" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 빌드 설정 완료${NC}"
else
    echo -e "${YELLOW}⚠ 빌드 설정 업데이트 실패 (수동으로 설정 필요)${NC}"
fi

echo ""
echo -e "${YELLOW}[3/4] 환경 변수 설정...${NC}"

if [ -f "backend/.env.production" ]; then
    echo -e "${GREEN}✓ backend/.env.production 파일 발견${NC}"
    echo -e "${BLUE}→ Dokploy 대시보드에서 환경 변수를 수동으로 복사하세요${NC}"
    echo -e "${BLUE}→ 파일 경로: $(pwd)/backend/.env.production${NC}"
else
    echo -e "${YELLOW}⚠ .env.production 파일 없음${NC}"
fi

echo ""
echo -e "${YELLOW}[4/4] 배포 트리거...${NC}"

if api_call "POST" "/applications/$APP_ID/deploy" "" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 배포 시작됨!${NC}"
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   배포가 시작되었습니다!              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "대시보드에서 배포 로그 확인:"
    echo "→ http://34.64.143.114:3000/dashboard/project/$PROJECT_ID"
else
    echo -e "${RED}✗ 배포 트리거 실패${NC}"
    echo -e "${YELLOW}→ 대시보드에서 수동으로 Deploy 버튼을 클릭하세요${NC}"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}다음 단계:${NC}"
echo ""
echo "1. 대시보드에서 환경 변수 설정:"
echo "   → Environment 탭"
echo "   → backend/.env.production 내용 복사"
echo ""
echo "2. 배포 로그 모니터링:"
echo "   → Logs 탭"
echo ""
echo "3. 배포 완료 후 확인:"
echo "   → curl http://YOUR_DOMAIN/health"
echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
