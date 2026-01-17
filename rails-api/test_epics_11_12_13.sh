#!/bin/bash

# Test Script for Epic 11 (Performance Tracking), Epic 12 (Weakness Analysis), Epic 13 (Smart Recommendations)
# Rails API Testing Script

BASE_URL="http://localhost:3000"
API_BASE="$BASE_URL/api/v1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
BUGS=()

# Test result tracking
test_result() {
    local test_name=$1
    local expected_status=$2
    local actual_status=$3
    local response=$4

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    if [ "$actual_status" -eq "$expected_status" ]; then
        echo -e "${GREEN}[PASS]${NC} $test_name (Status: $actual_status)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}[FAIL]${NC} $test_name (Expected: $expected_status, Got: $actual_status)"
        echo -e "       Response: $response"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        BUGS+=("$test_name - Expected status $expected_status but got $actual_status")
        return 1
    fi
}

# Function to make authenticated request
auth_request() {
    local method=$1
    local endpoint=$2
    local data=$3

    if [ -z "$AUTH_TOKEN" ]; then
        echo -e "${YELLOW}[WARN]${NC} No auth token set. Using unauthenticated request."
        if [ -n "$data" ]; then
            curl -s -w "\n%{http_code}" -X "$method" "$endpoint" \
                -H "Content-Type: application/json" \
                -d "$data"
        else
            curl -s -w "\n%{http_code}" -X "$method" "$endpoint"
        fi
    else
        if [ -n "$data" ]; then
            curl -s -w "\n%{http_code}" -X "$method" "$endpoint" \
                -H "Authorization: Bearer $AUTH_TOKEN" \
                -H "Content-Type: application/json" \
                -d "$data"
        else
            curl -s -w "\n%{http_code}" -X "$method" "$endpoint" \
                -H "Authorization: Bearer $AUTH_TOKEN"
        fi
    fi
}

echo "=========================================="
echo "Epic 11, 12, 13 API Testing"
echo "=========================================="
echo ""

# Check if server is running
echo "Checking if Rails server is running on port 3000..."
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${GREEN}✓${NC} Rails server is running"
else
    echo -e "${RED}✗${NC} Rails server is NOT running on port 3000"
    echo "Please start the server with: rails server"
    exit 1
fi
echo ""

# Try to login and get auth token (optional, will work without auth for testing)
echo "Attempting to authenticate..."
LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/signin" \
    -H "Content-Type: application/json" \
    -d '{"user":{"email":"test@example.com","password":"password123"}}')

LOGIN_BODY=$(echo "$LOGIN_RESPONSE" | head -n -1)
LOGIN_STATUS=$(echo "$LOGIN_RESPONSE" | tail -n 1)

if [ "$LOGIN_STATUS" -eq 200 ] || [ "$LOGIN_STATUS" -eq 302 ]; then
    echo -e "${GREEN}✓${NC} Authentication successful"
    # Extract token if present in response
    AUTH_TOKEN=$(echo "$LOGIN_BODY" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
else
    echo -e "${YELLOW}⚠${NC} Authentication failed or not configured. Testing will continue without auth."
    AUTH_TOKEN=""
fi
echo ""

# Create a test study set for testing (if needed)
echo "Creating test study set..."
CREATE_STUDYSET_RESPONSE=$(auth_request "POST" "$API_BASE/study_sets" \
    '{"study_set":{"title":"Test Study Set for Epic Testing","description":"Test data"}}')
STUDYSET_BODY=$(echo "$CREATE_STUDYSET_RESPONSE" | head -n -1)
STUDYSET_STATUS=$(echo "$CREATE_STUDYSET_RESPONSE" | tail -n 1)
STUDY_SET_ID=$(echo "$STUDYSET_BODY" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -n "$STUDY_SET_ID" ]; then
    echo -e "${GREEN}✓${NC} Test study set created (ID: $STUDY_SET_ID)"
else
    echo -e "${YELLOW}⚠${NC} Could not create test study set. Using ID=1 for testing."
    STUDY_SET_ID=1
fi
echo ""

echo "=========================================="
echo "EPIC 11: Performance Tracking"
echo "=========================================="
echo ""

# GET /api/v1/performance/comprehensive_report
echo "Test: GET /api/v1/performance/comprehensive_report"
RESPONSE=$(auth_request "GET" "$API_BASE/performance/comprehensive_report?study_set_id=$STUDY_SET_ID")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
test_result "Epic 11.1 - Comprehensive Report" 200 "$STATUS" "$BODY"
echo ""

# GET /api/v1/performance/quick_summary
echo "Test: GET /api/v1/performance/quick_summary"
RESPONSE=$(auth_request "GET" "$API_BASE/performance/quick_summary?study_set_id=$STUDY_SET_ID")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
test_result "Epic 11.2 - Quick Summary" 200 "$STATUS" "$BODY"
echo ""

# GET /api/v1/performance/time_analysis
echo "Test: GET /api/v1/performance/time_analysis"
RESPONSE=$(auth_request "GET" "$API_BASE/performance/time_analysis?study_set_id=$STUDY_SET_ID")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
test_result "Epic 11.3 - Time Analysis" 200 "$STATUS" "$BODY"
echo ""

# GET /api/v1/performance/predictions
echo "Test: GET /api/v1/performance/predictions"
RESPONSE=$(auth_request "GET" "$API_BASE/performance/predictions?study_set_id=$STUDY_SET_ID")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
test_result "Epic 11.4 - Predictions" 200 "$STATUS" "$BODY"
echo ""

# GET /api/v1/performance/comparison
echo "Test: GET /api/v1/performance/comparison"
RESPONSE=$(auth_request "GET" "$API_BASE/performance/comparison?study_set_id=$STUDY_SET_ID")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
test_result "Epic 11.5 - Performance Comparison" 200 "$STATUS" "$BODY"
echo ""

echo "=========================================="
echo "EPIC 12: Weakness Analysis"
echo "=========================================="
echo ""

# POST /api/v1/study_materials/:id/weakness_analysis/analyze
echo "Test: POST /api/v1/study_materials/1/weakness_analysis/analyze"
RESPONSE=$(auth_request "POST" "$API_BASE/study_materials/1/weakness_analysis/analyze")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
# May return 404 if study material doesn't exist, or 200/201 if successful
if [ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 201 ] || [ "$STATUS" -eq 404 ]; then
    test_result "Epic 12.1 - Weakness Analysis" 200 "$STATUS" "$BODY" || true
else
    test_result "Epic 12.1 - Weakness Analysis" 200 "$STATUS" "$BODY"
fi
echo ""

# GET /api/v1/weakness_analysis/user_overall_analysis
echo "Test: GET /api/v1/weakness_analysis/user_overall_analysis"
RESPONSE=$(auth_request "GET" "$API_BASE/weakness_analysis/user_overall_analysis")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
test_result "Epic 12.2 - User Overall Weakness Analysis" 200 "$STATUS" "$BODY"
echo ""

# GET /api/v1/study_materials/1/weakness_analysis/error_patterns
echo "Test: GET /api/v1/study_materials/1/weakness_analysis/error_patterns"
RESPONSE=$(auth_request "GET" "$API_BASE/study_materials/1/weakness_analysis/error_patterns")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
if [ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 404 ]; then
    test_result "Epic 12.3 - Error Patterns" 200 "$STATUS" "$BODY" || true
else
    test_result "Epic 12.3 - Error Patterns" 200 "$STATUS" "$BODY"
fi
echo ""

# GET /api/v1/study_materials/1/weakness_analysis/recommendations
echo "Test: GET /api/v1/study_materials/1/weakness_analysis/recommendations"
RESPONSE=$(auth_request "GET" "$API_BASE/study_materials/1/weakness_analysis/recommendations")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
if [ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 404 ]; then
    test_result "Epic 12.4 - Weakness Recommendations" 200 "$STATUS" "$BODY" || true
else
    test_result "Epic 12.4 - Weakness Recommendations" 200 "$STATUS" "$BODY"
fi
echo ""

# A/B Tests
echo "Test: GET /api/v1/ab_tests"
RESPONSE=$(auth_request "GET" "$API_BASE/ab_tests")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
test_result "Epic 12.5 - List A/B Tests" 200 "$STATUS" "$BODY"
echo ""

# POST /api/v1/ab_tests (create)
echo "Test: POST /api/v1/ab_tests (create)"
RESPONSE=$(auth_request "POST" "$API_BASE/ab_tests" \
    '{"ab_test":{"name":"Test AB","description":"Test","test_type":"recommendation_algorithm","variants":{"A":"collaborative","B":"content_based"}}}')
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
# May fail with 403 if not admin, or 201 if successful
if [ "$STATUS" -eq 201 ] || [ "$STATUS" -eq 403 ]; then
    test_result "Epic 12.6 - Create A/B Test" 201 "$STATUS" "$BODY" || true
else
    test_result "Epic 12.6 - Create A/B Test" 201 "$STATUS" "$BODY"
fi
AB_TEST_ID=$(echo "$BODY" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo ""

# GET /api/v1/ab_tests/:id/results
if [ -n "$AB_TEST_ID" ] && [ "$AB_TEST_ID" != "" ]; then
    echo "Test: GET /api/v1/ab_tests/$AB_TEST_ID/results"
    RESPONSE=$(auth_request "GET" "$API_BASE/ab_tests/$AB_TEST_ID/results")
    BODY=$(echo "$RESPONSE" | head -n -1)
    STATUS=$(echo "$RESPONSE" | tail -n 1)
    test_result "Epic 12.7 - Get A/B Test Results" 200 "$STATUS" "$BODY"
else
    echo -e "${YELLOW}[SKIP]${NC} Epic 12.7 - Get A/B Test Results (No AB test ID available)"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi
echo ""

echo "=========================================="
echo "EPIC 13: Smart Recommendations"
echo "=========================================="
echo ""

# GET /recommendations
echo "Test: GET /recommendations"
RESPONSE=$(auth_request "GET" "$BASE_URL/recommendations?study_set_id=$STUDY_SET_ID")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
test_result "Epic 13.1 - List Recommendations" 200 "$STATUS" "$BODY"
echo ""

# POST /recommendations/generate
echo "Test: POST /recommendations/generate"
RESPONSE=$(auth_request "POST" "$BASE_URL/recommendations/generate" \
    "{\"study_set_id\":$STUDY_SET_ID}")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
if [ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 404 ] || [ "$STATUS" -eq 500 ]; then
    test_result "Epic 13.2 - Generate Recommendations" 200 "$STATUS" "$BODY" || true
else
    test_result "Epic 13.2 - Generate Recommendations" 200 "$STATUS" "$BODY"
fi
echo ""

# GET /recommendations/learning_path
echo "Test: GET /recommendations/learning_path"
RESPONSE=$(auth_request "GET" "$BASE_URL/recommendations/learning_path?study_set_id=$STUDY_SET_ID")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
if [ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 404 ] || [ "$STATUS" -eq 500 ]; then
    test_result "Epic 13.3 - Learning Path" 200 "$STATUS" "$BODY" || true
else
    test_result "Epic 13.3 - Learning Path" 200 "$STATUS" "$BODY"
fi
echo ""

# GET /recommendations/personalized
echo "Test: GET /recommendations/personalized"
RESPONSE=$(auth_request "GET" "$BASE_URL/recommendations/personalized?study_set_id=$STUDY_SET_ID&limit=5")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
if [ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 404 ] || [ "$STATUS" -eq 500 ]; then
    test_result "Epic 13.4 - Personalized Recommendations" 200 "$STATUS" "$BODY" || true
else
    test_result "Epic 13.4 - Personalized Recommendations" 200 "$STATUS" "$BODY"
fi
echo ""

# GET /recommendations/optimal_path
echo "Test: GET /recommendations/optimal_path"
RESPONSE=$(auth_request "GET" "$BASE_URL/recommendations/optimal_path?study_set_id=$STUDY_SET_ID")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
if [ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 404 ] || [ "$STATUS" -eq 500 ]; then
    test_result "Epic 13.5 - Optimal Learning Path" 200 "$STATUS" "$BODY" || true
else
    test_result "Epic 13.5 - Optimal Learning Path" 200 "$STATUS" "$BODY"
fi
echo ""

# GET /recommendations/next_steps
echo "Test: GET /recommendations/next_steps"
RESPONSE=$(auth_request "GET" "$BASE_URL/recommendations/next_steps?study_set_id=$STUDY_SET_ID")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
if [ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 404 ] || [ "$STATUS" -eq 500 ]; then
    test_result "Epic 13.6 - Next Steps" 200 "$STATUS" "$BODY" || true
else
    test_result "Epic 13.6 - Next Steps" 200 "$STATUS" "$BODY"
fi
echo ""

# POST /recommendations/cf_generate
echo "Test: POST /recommendations/cf_generate"
RESPONSE=$(auth_request "POST" "$BASE_URL/recommendations/cf_generate" \
    "{\"study_set_id\":$STUDY_SET_ID,\"limit\":5}")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
if [ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 404 ] || [ "$STATUS" -eq 500 ]; then
    test_result "Epic 13.7 - Collaborative Filtering Recommendations" 200 "$STATUS" "$BODY" || true
else
    test_result "Epic 13.7 - Collaborative Filtering Recommendations" 200 "$STATUS" "$BODY"
fi
echo ""

# POST /recommendations/hybrid_generate
echo "Test: POST /recommendations/hybrid_generate"
RESPONSE=$(auth_request "POST" "$BASE_URL/recommendations/hybrid_generate" \
    "{\"study_set_id\":$STUDY_SET_ID,\"cf_weight\":0.6,\"cb_weight\":0.4}")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
if [ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 404 ] || [ "$STATUS" -eq 500 ]; then
    test_result "Epic 13.8 - Hybrid Recommendations" 200 "$STATUS" "$BODY" || true
else
    test_result "Epic 13.8 - Hybrid Recommendations" 200 "$STATUS" "$BODY"
fi
echo ""

# GET /recommendations/algorithm_comparison
echo "Test: GET /recommendations/algorithm_comparison"
RESPONSE=$(auth_request "GET" "$BASE_URL/recommendations/algorithm_comparison?period=30")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
if [ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 500 ]; then
    test_result "Epic 13.9 - Algorithm Comparison" 200 "$STATUS" "$BODY" || true
else
    test_result "Epic 13.9 - Algorithm Comparison" 200 "$STATUS" "$BODY"
fi
echo ""

# GET /recommendations/user_engagement
echo "Test: GET /recommendations/user_engagement"
RESPONSE=$(auth_request "GET" "$BASE_URL/recommendations/user_engagement?period=30")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)
if [ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 500 ]; then
    test_result "Epic 13.10 - User Engagement Metrics" 200 "$STATUS" "$BODY" || true
else
    test_result "Epic 13.10 - User Engagement Metrics" 200 "$STATUS" "$BODY"
fi
echo ""

echo "=========================================="
echo "TEST SUMMARY"
echo "=========================================="
echo ""
echo "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo ""

if [ ${#BUGS[@]} -gt 0 ]; then
    echo "BUGS FOUND:"
    echo "==========="
    for bug in "${BUGS[@]}"; do
        echo -e "${RED}•${NC} $bug"
    done
    echo ""
fi

# Generate JSON report
cat > /tmp/epic_test_report.json <<EOF
{
  "total_tests": $TOTAL_TESTS,
  "passed": $PASSED_TESTS,
  "failed": $FAILED_TESTS,
  "bugs": [
$(IFS=$'\n'; for bug in "${BUGS[@]}"; do echo "    \"$bug\","; done | sed '$ s/,$//')
  ],
  "recommendations": [
    "Ensure all service classes (PerformanceReportService, TimeBasedAnalysisService, etc.) are properly implemented",
    "Verify authentication middleware is correctly configured",
    "Check database migrations for all required tables",
    "Implement proper error handling for missing study materials",
    "Add proper authorization checks for admin-only endpoints",
    "Consider adding integration tests for service layer",
    "Add proper data seeding for comprehensive testing",
    "Implement proper logging for debugging failed requests"
  ]
}
EOF

echo "JSON Report saved to: /tmp/epic_test_report.json"
cat /tmp/epic_test_report.json
echo ""

# Exit with appropriate code
if [ $FAILED_TESTS -gt 0 ]; then
    exit 1
else
    exit 0
fi
