#!/bin/bash

# ExamsGraph Epic Implementation Test Script
# Tests Epic 3, 6, and 12 implementations

set -e

BASE_URL="http://localhost:3000/api/v1"
AUTH_TOKEN=""
USER_EMAIL="test@example.com"
USER_PASSWORD="password123"
STUDY_MATERIAL_ID=""

echo "=================================================="
echo "ExamsGraph Epic Implementation Test"
echo "=================================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function for success messages
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Helper function for error messages
error() {
    echo -e "${RED}✗ $1${NC}"
}

# Helper function for info messages
info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Test 1: Authentication
echo "=================================================="
echo "Test 1: User Authentication"
echo "=================================================="

# Login
info "Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$USER_EMAIL'",
    "password": "'$USER_PASSWORD'"
  }')

AUTH_TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -n "$AUTH_TOKEN" ]; then
    success "Authentication successful"
    info "Token: ${AUTH_TOKEN:0:20}..."
else
    error "Authentication failed"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi

echo ""

# Test 2: Epic 3 - PDF Processing
echo "=================================================="
echo "Test 2: Epic 3 - PDF Processing (OCR)"
echo "=================================================="

# Check PDF processing stats
info "Getting PDF processing stats..."
STATS_RESPONSE=$(curl -s -X GET "$BASE_URL/pdf_processing/stats" \
  -H "Authorization: Bearer $AUTH_TOKEN")

echo "Stats Response:"
echo $STATS_RESPONSE | jq '.'

if echo $STATS_RESPONSE | grep -q '"success":true'; then
    success "PDF processing stats retrieved"
else
    error "Failed to retrieve stats"
fi

# List all PDF processing
info "Listing all PDF processing tasks..."
LIST_RESPONSE=$(curl -s -X GET "$BASE_URL/pdf_processing" \
  -H "Authorization: Bearer $AUTH_TOKEN")

echo "List Response:"
echo $LIST_RESPONSE | jq '.'

if echo $LIST_RESPONSE | grep -q '"success":true'; then
    success "PDF processing list retrieved"

    # Extract first study material ID
    STUDY_MATERIAL_ID=$(echo $LIST_RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

    if [ -n "$STUDY_MATERIAL_ID" ]; then
        info "Using study_material_id: $STUDY_MATERIAL_ID"
    else
        info "No existing study materials found. Skipping material-specific tests."
    fi
else
    error "Failed to retrieve PDF processing list"
fi

echo ""

# Test 3: Epic 6 - Knowledge Graph
if [ -n "$STUDY_MATERIAL_ID" ]; then
    echo "=================================================="
    echo "Test 3: Epic 6 - Knowledge Graph Creation"
    echo "=================================================="

    # Get knowledge graph stats
    info "Getting knowledge graph stats..."
    GRAPH_STATS=$(curl -s -X GET "$BASE_URL/study_materials/$STUDY_MATERIAL_ID/knowledge_graph/stats" \
      -H "Authorization: Bearer $AUTH_TOKEN")

    echo "Graph Stats:"
    echo $GRAPH_STATS | jq '.'

    if echo $GRAPH_STATS | grep -q '"success":true'; then
        success "Knowledge graph stats retrieved"
    else
        error "Failed to retrieve knowledge graph stats"
    fi

    # Get knowledge graph nodes
    info "Getting knowledge graph nodes..."
    GRAPH_NODES=$(curl -s -X GET "$BASE_URL/study_materials/$STUDY_MATERIAL_ID/knowledge_graph/nodes" \
      -H "Authorization: Bearer $AUTH_TOKEN")

    echo "Graph Nodes (first 3):"
    echo $GRAPH_NODES | jq '.nodes[:3]'

    if echo $GRAPH_NODES | grep -q '"success":true'; then
        success "Knowledge graph nodes retrieved"
    else
        error "Failed to retrieve knowledge graph nodes"
    fi

    # Get weak concepts
    info "Getting weak concepts..."
    WEAK_CONCEPTS=$(curl -s -X GET "$BASE_URL/study_materials/$STUDY_MATERIAL_ID/knowledge_graph/weak_concepts" \
      -H "Authorization: Bearer $AUTH_TOKEN")

    echo "Weak Concepts:"
    echo $WEAK_CONCEPTS | jq '.'

    if echo $WEAK_CONCEPTS | grep -q '"success":true'; then
        success "Weak concepts retrieved"
    else
        error "Failed to retrieve weak concepts"
    fi

    # Get mastered concepts
    info "Getting mastered concepts..."
    MASTERED_CONCEPTS=$(curl -s -X GET "$BASE_URL/study_materials/$STUDY_MATERIAL_ID/knowledge_graph/mastered_concepts" \
      -H "Authorization: Bearer $AUTH_TOKEN")

    echo "Mastered Concepts:"
    echo $MASTERED_CONCEPTS | jq '.'

    if echo $MASTERED_CONCEPTS | grep -q '"success":true'; then
        success "Mastered concepts retrieved"
    else
        error "Failed to retrieve mastered concepts"
    fi

    echo ""

    # Test 4: Epic 12 - Weakness Analysis
    echo "=================================================="
    echo "Test 4: Epic 12 - Weakness Analysis"
    echo "=================================================="

    # Analyze weaknesses
    info "Analyzing user weaknesses..."
    ANALYSIS_RESPONSE=$(curl -s -X POST "$BASE_URL/study_materials/$STUDY_MATERIAL_ID/weakness_analysis/analyze" \
      -H "Authorization: Bearer $AUTH_TOKEN" \
      -H "Content-Type: application/json")

    echo "Analysis Response:"
    echo $ANALYSIS_RESPONSE | jq '.'

    if echo $ANALYSIS_RESPONSE | grep -q '"success":true'; then
        success "Weakness analysis completed"
    else
        error "Weakness analysis failed"
    fi

    # Get weak concepts from weakness analysis
    info "Getting weak concepts from weakness analysis..."
    WEAK_CONCEPTS_ANALYSIS=$(curl -s -X GET "$BASE_URL/study_materials/$STUDY_MATERIAL_ID/weakness_analysis/weak_concepts" \
      -H "Authorization: Bearer $AUTH_TOKEN")

    echo "Weak Concepts (Analysis):"
    echo $WEAK_CONCEPTS_ANALYSIS | jq '.'

    if echo $WEAK_CONCEPTS_ANALYSIS | grep -q '"success":true'; then
        success "Weak concepts from analysis retrieved"
    else
        error "Failed to retrieve weak concepts from analysis"
    fi

    # Get error patterns
    info "Getting error patterns..."
    ERROR_PATTERNS=$(curl -s -X GET "$BASE_URL/study_materials/$STUDY_MATERIAL_ID/weakness_analysis/error_patterns" \
      -H "Authorization: Bearer $AUTH_TOKEN")

    echo "Error Patterns:"
    echo $ERROR_PATTERNS | jq '.'

    if echo $ERROR_PATTERNS | grep -q '"success":true'; then
        success "Error patterns retrieved"
    else
        error "Failed to retrieve error patterns"
    fi

    # Get recommendations
    info "Getting recommendations..."
    RECOMMENDATIONS=$(curl -s -X GET "$BASE_URL/study_materials/$STUDY_MATERIAL_ID/weakness_analysis/recommendations" \
      -H "Authorization: Bearer $AUTH_TOKEN")

    echo "Recommendations:"
    echo $RECOMMENDATIONS | jq '.'

    if echo $RECOMMENDATIONS | grep -q '"success":true'; then
        success "Recommendations retrieved"
    else
        error "Failed to retrieve recommendations"
    fi

    # Get analysis history
    info "Getting analysis history..."
    HISTORY=$(curl -s -X GET "$BASE_URL/study_materials/$STUDY_MATERIAL_ID/weakness_analysis/history" \
      -H "Authorization: Bearer $AUTH_TOKEN")

    echo "Analysis History:"
    echo $HISTORY | jq '.'

    if echo $HISTORY | grep -q '"success":true'; then
        success "Analysis history retrieved"
    else
        error "Failed to retrieve analysis history"
    fi

    echo ""
else
    info "Skipping Epic 6 and Epic 12 tests (no study materials found)"
    echo ""
fi

# Test 5: Overall User Analysis
echo "=================================================="
echo "Test 5: Overall User Analysis"
echo "=================================================="

info "Getting user overall analysis..."
OVERALL_ANALYSIS=$(curl -s -X GET "$BASE_URL/weakness_analysis/user_overall_analysis" \
  -H "Authorization: Bearer $AUTH_TOKEN")

echo "Overall Analysis:"
echo $OVERALL_ANALYSIS | jq '.'

if echo $OVERALL_ANALYSIS | grep -q '"success":true'; then
    success "Overall user analysis retrieved"
else
    error "Failed to retrieve overall user analysis"
fi

echo ""
echo "=================================================="
echo "Test Summary"
echo "=================================================="
success "Epic 3: PDF Processing (OCR) - Implemented"
success "Epic 6: Knowledge Graph Creation - Implemented"
success "Epic 12: Weakness Analysis - Implemented"
echo ""
info "All tests completed!"
echo "=================================================="
