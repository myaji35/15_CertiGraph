#!/bin/bash

# Epic 18: Certification Information Hub API 테스트 스크립트
# 2025/2026년 자격증 시험 정보 API 테스트

API_BASE="http://localhost:3000"
echo "================================================"
echo "Epic 18: Certification Information Hub API Test"
echo "================================================"
echo ""

# 색상 코드
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 테스트 함수
test_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3
    local data=$4

    echo -e "${YELLOW}Testing:${NC} $description"
    echo "  Method: $method"
    echo "  Endpoint: $endpoint"

    if [ "$method" == "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" "$API_BASE$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$API_BASE$endpoint")
    fi

    http_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | head -n -1)

    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "  Status: ${GREEN}✓ $http_code${NC}"
        echo "  Response Preview: $(echo "$body" | head -c 200)..."
    else
        echo -e "  Status: ${RED}✗ $http_code${NC}"
        echo "  Error: $body"
    fi
    echo ""
}

echo "1. CERTIFICATIONS API TESTS"
echo "----------------------------"

# 1.1 자격증 목록 조회
test_endpoint "GET" "/certifications" \
    "Get all certifications"

# 1.2 IT 카테고리 자격증 조회
test_endpoint "GET" "/certifications?category=IT/정보통신" \
    "Get IT category certifications"

# 1.3 국가자격증만 조회
test_endpoint "GET" "/certifications?national=true" \
    "Get national certifications only"

# 1.4 인기순 정렬
test_endpoint "GET" "/certifications?sort=popular" \
    "Get certifications sorted by popularity"

# 1.5 자격증 검색
test_endpoint "GET" "/certifications/search?q=정보처리" \
    "Search certifications with keyword '정보처리'"

echo ""
echo "2. EXAM SCHEDULES API TESTS"
echo "----------------------------"

# 2.1 2025년 전체 시험 일정
test_endpoint "GET" "/exam_schedules?year=2025" \
    "Get all exam schedules for 2025"

# 2.2 2025년 3월 시험 일정
test_endpoint "GET" "/exam_schedules?year=2025&month=3" \
    "Get exam schedules for March 2025"

# 2.3 다가오는 시험 일정 (10개)
test_endpoint "GET" "/exam_schedules/upcoming?limit=10" \
    "Get upcoming 10 exam schedules"

# 2.4 원서접수 중인 시험
test_endpoint "GET" "/exam_schedules/open_registrations" \
    "Get exams with open registration"

# 2.5 2025년 3월 캘린더 데이터
test_endpoint "GET" "/exam_schedules/calendar/2025/3" \
    "Get calendar data for March 2025"

# 2.6 사용 가능한 연도 목록
test_endpoint "GET" "/exam_schedules/years" \
    "Get available years for exam schedules"

echo ""
echo "3. CERTIFICATION-SPECIFIC SCHEDULES"
echo "------------------------------------"

# 먼저 자격증 ID를 가져오기
cert_id=$(curl -s "$API_BASE/certifications" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)

if [ ! -z "$cert_id" ]; then
    # 3.1 특정 자격증의 시험 일정
    test_endpoint "GET" "/certifications/$cert_id" \
        "Get specific certification details (ID: $cert_id)"

    # 3.2 특정 자격증의 시험 일정
    test_endpoint "GET" "/certifications/$cert_id/exam_schedules" \
        "Get exam schedules for certification $cert_id"

    # 3.3 특정 자격증의 다가오는 시험
    test_endpoint "GET" "/certifications/$cert_id/upcoming_exams?year=2025" \
        "Get upcoming exams for certification $cert_id in 2025"
fi

echo ""
echo "4. NOTIFICATION TESTS (Requires Authentication)"
echo "-----------------------------------------------"

# 인증이 필요한 엔드포인트 테스트 (401 예상)
exam_id=$(curl -s "$API_BASE/exam_schedules/upcoming?limit=1" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)

if [ ! -z "$exam_id" ]; then
    test_endpoint "POST" "/exam_schedules/$exam_id/register_notification" \
        "Register notification for exam $exam_id (Expected: 401 Unauthorized)" \
        '{"notification_type":"exam_reminder_week","channel":"email"}'
fi

echo ""
echo "5. API STATISTICS"
echo "-----------------"

# 통계 수집
total_certs=$(curl -s "$API_BASE/certifications" | grep -o '"id"' | wc -l)
upcoming_exams=$(curl -s "$API_BASE/exam_schedules/upcoming" | grep -o '"id"' | wc -l)
open_regs=$(curl -s "$API_BASE/exam_schedules/open_registrations" | grep -o '"id"' | wc -l)

echo -e "Total Certifications: ${GREEN}$total_certs${NC}"
echo -e "Upcoming Exams: ${GREEN}$upcoming_exams${NC}"
echo -e "Open Registrations: ${GREEN}$open_regs${NC}"

echo ""
echo "================================================"
echo "Epic 18 API Testing Complete!"
echo "================================================"