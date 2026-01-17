#!/bin/bash

# Epic 18 라우팅 수정 테스트 스크립트
# 2026-01-15

echo "========================================="
echo "Epic 18: 라우팅 수정 검증"
echo "========================================="
echo ""

BASE_URL="http://localhost:3000"

# 색상 코드
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 테스트 결과 카운터
PASS=0
FAIL=0

# 테스트 함수
test_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3

    echo -n "Testing: $description ... "

    if [ "$method" == "GET" ]; then
        response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$endpoint")
    fi

    if [ "$response" == "200" ] || [ "$response" == "401" ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $response)"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $response)"
        ((FAIL++))
    fi
}

echo "1. 기존 작동 엔드포인트 검증"
echo "--------------------------------"

test_endpoint "GET" "/exam_schedules" "전체 시험 일정 조회"
test_endpoint "GET" "/exam_schedules?year=2025" "2025년 시험 일정"
test_endpoint "GET" "/exam_schedules?year=2025&month=3" "2025년 3월 시험 일정"

echo ""
echo "2. 수정된 엔드포인트 검증 (이전 404 에러)"
echo "--------------------------------"

test_endpoint "GET" "/exam_schedules/upcoming" "다가오는 시험 일정"
test_endpoint "GET" "/exam_schedules/open_registrations" "원서 접수 중인 시험"
test_endpoint "GET" "/exam_schedules/years" "사용 가능한 연도 목록"

echo ""
echo "3. 캘린더 엔드포인트"
echo "--------------------------------"

test_endpoint "GET" "/exam_schedules/calendar/2025/3" "2025년 3월 캘린더"
test_endpoint "GET" "/exam_schedules/calendar/2026/1" "2026년 1월 캘린더"

echo ""
echo "4. Certification 엔드포인트"
echo "--------------------------------"

test_endpoint "GET" "/certifications" "자격증 목록"
test_endpoint "GET" "/certifications/search?q=정보처리" "자격증 검색"

echo ""
echo "========================================="
echo "테스트 결과 요약"
echo "========================================="
echo -e "${GREEN}통과:${NC} $PASS"
echo -e "${RED}실패:${NC} $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ 모든 테스트 통과! Epic 18 라우팅 수정 완료${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ 일부 테스트 실패. 서버가 실행 중인지 확인하세요.${NC}"
    exit 1
fi
