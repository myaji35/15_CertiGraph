#!/bin/bash

# 배포 상태 확인 스크립트
echo "======================================"
echo "   ExamsGraph 배포 상태 확인"
echo "======================================"
echo ""

# 색상 코드
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "1. GitHub 최신 커밋 확인..."
LATEST_COMMIT=$(git log -1 --pretty=format:"%h - %s" 2>/dev/null)
echo "   최신 커밋: $LATEST_COMMIT"
echo ""

echo "2. Dokploy 서버 상태..."
if curl -s -o /dev/null -w "%{http_code}" http://34.64.143.114:3000 | grep -q "200"; then
    echo -e "   ${GREEN}✓ Dokploy 서버 정상${NC}"
else
    echo -e "   ${RED}✗ Dokploy 서버 응답 없음${NC}"
fi
echo ""

echo "3. 배포된 애플리케이션 상태..."
ENDPOINTS=(
    "http://34.64.191.91:3000"
    "http://examsgraph.34.64.191.91.nip.io"
)

for endpoint in "${ENDPOINTS[@]}"; do
    echo -n "   $endpoint ... "
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 $endpoint)
    if [ "$STATUS" = "200" ]; then
        echo -e "${GREEN}✓ 작동 중${NC}"
    elif [ "$STATUS" = "404" ]; then
        echo -e "${YELLOW}⚠ 404 (배포 진행 중)${NC}"
    else
        echo -e "${RED}✗ 응답 없음 (코드: $STATUS)${NC}"
    fi
done
echo ""

echo "4. 배포 확인 방법:"
echo "   • Dokploy 대시보드: http://34.64.143.114:3000"
echo "   • 프로젝트 페이지: http://34.64.143.114:3000/project/SVSYksCZ8lAr2Mdrg8902"
echo ""

echo "5. 수동 배포 방법:"
echo "   1) 위 대시보드 접속"
echo "   2) CertiGraph 프로젝트 선택"
echo "   3) Deploy 버튼 클릭"
echo ""

echo "======================================"
echo "배포가 자동으로 진행되지 않는 경우,"
echo "Dokploy 대시보드에서 수동으로 배포하세요."
echo "======================================"