#!/bin/bash

# 개선된 Dokploy 배포 스크립트
# 토큰을 .dokploy.env 파일에서 자동으로 읽음

set -e

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     ExamsGraph 자동 배포 시스템        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# .dokploy.env 파일에서 환경 변수 로드
if [ -f ".dokploy.env" ]; then
    echo -e "${GREEN}✓ .dokploy.env 파일 발견${NC}"
    export $(grep -v '^#' .dokploy.env | xargs)
else
    echo -e "${RED}✗ .dokploy.env 파일을 찾을 수 없습니다${NC}"
    echo -e "${YELLOW}  → .dokploy.env 파일을 생성하고 DOKPLOY_AUTH_TOKEN을 설정하세요${NC}"
    exit 1
fi

# 토큰 확인
if [ -z "$DOKPLOY_AUTH_TOKEN" ] || [ "$DOKPLOY_AUTH_TOKEN" == "your-dokploy-api-token-here" ]; then
    echo -e "${RED}✗ 유효한 DOKPLOY_AUTH_TOKEN이 설정되지 않았습니다${NC}"
    echo ""
    echo -e "${CYAN}토큰 설정 방법:${NC}"
    echo "1. http://34.64.143.114:3000 접속"
    echo "2. Settings → API Tokens 에서 토큰 생성"
    echo "3. .dokploy.env 파일의 DOKPLOY_AUTH_TOKEN 값 업데이트"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ API 토큰 확인됨${NC}"
echo ""

# API 호출 함수
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3

    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Authorization: Bearer $DOKPLOY_AUTH_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$DOKPLOY_URL/api/v1$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Authorization: Bearer $DOKPLOY_AUTH_TOKEN" \
            "$DOKPLOY_URL/api/v1$endpoint")
    fi

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)

    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo "$body"
        return 0
    else
        return 1
    fi
}

# 1. Git 최신 코드 푸시 확인
echo -e "${YELLOW}[1/5] Git 상태 확인...${NC}"
if git status --porcelain | grep -q .; then
    echo -e "${YELLOW}⚠ 커밋되지 않은 변경사항이 있습니다${NC}"
    read -p "계속 진행하시겠습니까? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 최신 커밋 정보
LATEST_COMMIT=$(git rev-parse --short HEAD)
COMMIT_MESSAGE=$(git log -1 --pretty=%B)
echo -e "${GREEN}✓ 최신 커밋: $LATEST_COMMIT${NC}"
echo -e "  ${CYAN}$COMMIT_MESSAGE${NC}"
echo ""

# 2. 프로젝트 상태 확인
echo -e "${YELLOW}[2/5] Dokploy 프로젝트 상태 확인...${NC}"
if PROJECT_INFO=$(api_call "GET" "/projects/$DOKPLOY_PROJECT_ID"); then
    echo -e "${GREEN}✓ 프로젝트 연결됨: CertiGraph${NC}"
else
    echo -e "${RED}✗ 프로젝트 연결 실패${NC}"
    exit 1
fi
echo ""

# 3. 애플리케이션 설정 업데이트
echo -e "${YELLOW}[3/5] 애플리케이션 설정 업데이트...${NC}"

APP_CONFIG=$(cat <<EOF
{
  "name": "examsgraph-app",
  "repository": "git@github.com:myaji35/15_CertiGraph.git",
  "branch": "main",
  "buildPath": "/",
  "dockerfile": "docker-compose.yaml",
  "port": 3030
}
EOF
)

if api_call "PATCH" "/applications/$DOKPLOY_APP_ID" "$APP_CONFIG" > /dev/null; then
    echo -e "${GREEN}✓ 애플리케이션 설정 업데이트 완료${NC}"
else
    echo -e "${YELLOW}⚠ 설정 업데이트 실패 (계속 진행)${NC}"
fi
echo ""

# 4. 환경 변수 확인
echo -e "${YELLOW}[4/5] 환경 변수 확인...${NC}"
if [ -f ".env.dokploy" ]; then
    echo -e "${GREEN}✓ 환경 변수 파일 확인${NC}"
    echo -e "${CYAN}  필요한 환경 변수:${NC}"
    grep -v '^#' .env.dokploy | grep -v '^$' | cut -d'=' -f1 | while read var; do
        echo "    • $var"
    done
else
    echo -e "${YELLOW}⚠ .env.dokploy 파일이 없습니다${NC}"
fi
echo ""

# 5. 배포 트리거
echo -e "${YELLOW}[5/5] 배포 시작...${NC}"

DEPLOY_DATA=$(cat <<EOF
{
  "trigger": "manual",
  "commit": "$LATEST_COMMIT",
  "message": "$COMMIT_MESSAGE"
}
EOF
)

if DEPLOY_RESULT=$(api_call "POST" "/applications/$DOKPLOY_APP_ID/deploy" "$DEPLOY_DATA"); then
    echo -e "${GREEN}✓ 배포가 시작되었습니다!${NC}"
    echo ""

    # 배포 ID 추출 (있을 경우)
    DEPLOY_ID=$(echo "$DEPLOY_RESULT" | grep -o '"deploymentId":"[^"]*' | cut -d'"' -f4)

    if [ -n "$DEPLOY_ID" ]; then
        echo -e "${CYAN}배포 ID: $DEPLOY_ID${NC}"
    fi

    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         배포 모니터링                  ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "📍 대시보드에서 실시간 확인:"
    echo "   $DOKPLOY_URL/project/$DOKPLOY_PROJECT_ID/application/$DOKPLOY_APP_ID"
    echo ""
    echo "📊 배포 상태 확인 명령어:"
    echo "   ./deploy.sh status"
    echo ""
else
    echo -e "${RED}✗ 배포 시작 실패${NC}"
    echo -e "${YELLOW}대시보드에서 수동으로 배포를 시작하세요:${NC}"
    echo "   $DOKPLOY_URL"
    exit 1
fi

# 상태 확인 옵션
if [ "$1" == "status" ]; then
    echo ""
    echo -e "${YELLOW}배포 상태 확인 중...${NC}"
    if STATUS=$(api_call "GET" "/applications/$DOKPLOY_APP_ID/deployments?limit=1"); then
        echo "$STATUS" | python3 -m json.tool 2>/dev/null || echo "$STATUS"
    fi
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  배포가 성공적으로 시작되었습니다!    ${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"