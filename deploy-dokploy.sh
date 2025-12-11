#!/bin/bash

# Dokploy CLI를 사용한 배포 스크립트
# 사용법: ./deploy-dokploy.sh YOUR_API_TOKEN

set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# API 토큰 확인
if [ -z "$1" ]; then
    echo -e "${RED}Error: API token required${NC}"
    echo "Usage: $0 YOUR_API_TOKEN"
    echo ""
    echo "To get your API token:"
    echo "1. Go to http://34.64.143.114:3000"
    echo "2. Settings → API Tokens"
    echo "3. Create Token"
    exit 1
fi

API_TOKEN="$1"
DOKPLOY_URL="http://34.64.143.114:3000"

# 환경 변수 설정
export DOKPLOY_URL
export DOKPLOY_AUTH_TOKEN="$API_TOKEN"

echo -e "${BLUE}=== Dokploy CLI Deployment ===${NC}\n"

# 1. 인증 확인
echo -e "${YELLOW}[1/6] Verifying authentication...${NC}"
if dokploy verify; then
    echo -e "${GREEN}✓ Authentication successful${NC}\n"
else
    echo -e "${RED}✗ Authentication failed${NC}"
    exit 1
fi

# 2. 기존 프로젝트 목록
echo -e "${YELLOW}[2/6] Listing existing projects...${NC}"
dokploy project list
echo ""

# 3. 프로젝트 선택 또는 생성
echo -e "${YELLOW}[3/6] Select or create project${NC}"
read -p "Enter existing project ID (or press Enter to create new): " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    echo "Creating new project..."
    dokploy project create
    read -p "Enter the newly created project ID: " PROJECT_ID
fi

echo -e "${GREEN}✓ Using project: $PROJECT_ID${NC}\n"

# 4. 앱 생성
echo -e "${YELLOW}[4/6] Creating application...${NC}"
echo "Repository: git@github.com:myaji35/15_CertiGraph.git"
echo "Branch: main"
echo "Build Path: /backend"
echo ""

# 대화형으로 앱 생성
dokploy app create

echo -e "${GREEN}✓ Application created${NC}\n"

# 5. 환경 변수 안내
echo -e "${YELLOW}[5/6] Environment variables${NC}"
echo "Please set the following environment variables in Dokploy dashboard:"
echo ""
cat <<EOF
Required:
  CLERK_JWKS_URL=...
  SUPABASE_URL=...
  SUPABASE_SERVICE_KEY=...
  OPENAI_API_KEY=...
  GOOGLE_API_KEY=...
  CORS_ORIGINS=https://your-frontend-domain.vercel.app

Optional:
  ANTHROPIC_API_KEY=...
  UPSTAGE_API_KEY=...
  PINECONE_API_KEY=...
  PLANE_API_KEY=...
  INNGEST_EVENT_KEY=...
EOF
echo ""

read -p "Press Enter after setting environment variables in dashboard..."

# 6. 배포
echo -e "${YELLOW}[6/6] Deploying application...${NC}"
read -p "Enter application ID to deploy: " APP_ID

if [ -n "$APP_ID" ]; then
    dokploy app deploy --app-id "$APP_ID"
    echo -e "${GREEN}✓ Deployment initiated${NC}\n"
else
    echo -e "${YELLOW}Skipping deployment. You can deploy from the dashboard.${NC}\n"
fi

# 완료
echo -e "${GREEN}=== Deployment Setup Complete! ===${NC}"
echo ""
echo "Next steps:"
echo "1. Monitor deployment in Dokploy dashboard"
echo "2. Check health endpoint: curl http://YOUR_DOMAIN/health"
echo "3. View API docs: http://YOUR_DOMAIN/docs"
echo ""
echo "Dashboard: http://34.64.143.114:3000"
