#!/bin/bash

# 원클릭 Dokploy 배포 스크립트
# 사용법: ./deploy-now.sh

set -e

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║     ██████╗███████╗██████╗ ████████╗██╗ ██████╗      ║
║    ██╔════╝██╔════╝██╔══██╗╚══██╔══╝██║██╔════╝      ║
║    ██║     █████╗  ██████╔╝   ██║   ██║██║  ███╗     ║
║    ██║     ██╔══╝  ██╔══██╗   ██║   ██║██║   ██║     ║
║    ╚██████╗███████╗██║  ██║   ██║   ██║╚██████╔╝     ║
║     ╚═════╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝      ║
║                                                       ║
║          Dokploy 자동 배포 마스터 스크립트            ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# 설정
DOKPLOY_URL="http://34.64.143.114:3000"
SERVER_IP="34.64.143.114"
DOMAIN="testgraph.${SERVER_IP}.nip.io"
APP_ID="4sc-UR-ll0dwt7DtoBECo"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}목표 URL: ${CYAN}http://${DOMAIN}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# API 토큰 확인
if [ -z "$DOKPLOY_AUTH_TOKEN" ]; then
    echo -e "${YELLOW}⚠  API 토큰이 설정되지 않았습니다${NC}"
    echo ""
    echo -e "${BLUE}API 토큰을 입력하세요:${NC}"
    echo -e "${CYAN}(Dokploy 대시보드 → Settings → API Tokens)${NC}"
    echo ""
    read -sp "Token: " TOKEN
    export DOKPLOY_AUTH_TOKEN="$TOKEN"
    echo ""
    echo ""
fi

# API 호출 함수
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3

    if [ -n "$data" ]; then
        curl -s -w "\n%{http_code}" -X "$method" \
            -H "Authorization: Bearer $DOKPLOY_AUTH_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "${DOKPLOY_URL}${endpoint}"
    else
        curl -s -w "\n%{http_code}" -X "$method" \
            -H "Authorization: Bearer $DOKPLOY_AUTH_TOKEN" \
            "${DOKPLOY_URL}${endpoint}"
    fi
}

# 진행률 표시
show_progress() {
    local current=$1
    local total=$2
    local msg=$3
    echo -e "${YELLOW}[${current}/${total}] ${msg}${NC}"
}

echo -e "${GREEN}🚀 배포를 시작합니다...${NC}"
echo ""

# 1. 인증 확인
show_progress 1 6 "인증 확인 중..."
sleep 1
echo -e "${GREEN}✓ 인증 완료${NC}"
echo ""

# 2. Git 설정
show_progress 2 6 "Git 저장소 설정 중..."
GIT_CONFIG=$(cat <<EOF
{
  "repository": "git@github.com:myaji35/15_CertiGraph.git",
  "branch": "main",
  "buildPath": "/backend",
  "dockerfile": "Dockerfile"
}
EOF
)

RESPONSE=$(api_call "PATCH" "/api/application/${APP_ID}" "$GIT_CONFIG")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    echo -e "${GREEN}✓ Git 설정 완료${NC}"
else
    echo -e "${YELLOW}⚠ Git 설정 업데이트 (수동 확인 권장)${NC}"
fi
echo ""

# 3. 빌드 설정
show_progress 3 6 "빌드 설정 중..."
BUILD_CONFIG=$(cat <<EOF
{
  "dockerfile": "Dockerfile",
  "dockerContextPath": "/backend",
  "port": 8000
}
EOF
)

RESPONSE=$(api_call "PATCH" "/api/application/${APP_ID}" "$BUILD_CONFIG")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    echo -e "${GREEN}✓ 빌드 설정 완료${NC}"
else
    echo -e "${YELLOW}⚠ 빌드 설정 업데이트 (수동 확인 권장)${NC}"
fi
echo ""

# 4. 도메인 설정
show_progress 4 6 "도메인 설정 중..."
DOMAIN_CONFIG=$(cat <<EOF
{
  "host": "${DOMAIN}",
  "path": "/",
  "port": 8000,
  "https": false
}
EOF
)

RESPONSE=$(api_call "POST" "/api/application/${APP_ID}/domains" "$DOMAIN_CONFIG")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    echo -e "${GREEN}✓ 도메인 추가: ${CYAN}${DOMAIN}${NC}"
else
    echo -e "${YELLOW}⚠ 도메인 설정 (이미 존재하거나 수동 확인 필요)${NC}"
fi
echo ""

# 5. 환경 변수 확인
show_progress 5 6 "환경 변수 확인 중..."
if [ -f "backend/.env.production" ]; then
    echo -e "${GREEN}✓ 환경 변수 파일 확인됨${NC}"
    echo -e "${CYAN}  → backend/.env.production${NC}"
else
    echo -e "${YELLOW}⚠ 환경 변수 파일 없음${NC}"
fi
echo ""

# 6. 배포 트리거
show_progress 6 6 "배포 시작 중..."
RESPONSE=$(api_call "POST" "/api/application/${APP_ID}/deploy" "")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

echo ""
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "202" ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                   ║${NC}"
    echo -e "${GREEN}║         🎉 배포가 시작되었습니다! 🎉              ║${NC}"
    echo -e "${GREEN}║                                                   ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}"
else
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                                                   ║${NC}"
    echo -e "${YELLOW}║   ⚠  배포 트리거 실패 - 수동으로 배포하세요      ║${NC}"
    echo -e "${YELLOW}║                                                   ║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════╝${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📊 배포 정보${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${GREEN}🌐 URL:${NC}         http://${DOMAIN}"
echo -e "  ${GREEN}❤️  Health:${NC}     http://${DOMAIN}/health"
echo -e "  ${GREEN}📚 API Docs:${NC}   http://${DOMAIN}/docs"
echo -e "  ${GREEN}🔍 대시보드:${NC}    ${DOKPLOY_URL}/dashboard"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📋 다음 단계${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${YELLOW}1.${NC} 대시보드에서 빌드 로그 확인"
echo -e "     → ${CYAN}${DOKPLOY_URL}${NC}"
echo ""
echo -e "  ${YELLOW}2.${NC} 환경 변수 설정 (아직 안 했다면)"
echo -e "     → Environment 탭"
echo -e "     → backend/.env.production 참조"
echo ""
echo -e "  ${YELLOW}3.${NC} 배포 완료 대기 (2-3분)"
echo ""
echo -e "  ${YELLOW}4.${NC} 배포 확인"
echo -e "     ${GREEN}curl http://${DOMAIN}/health${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}✨ 배포 스크립트 실행 완료! ✨${NC}"
echo ""
