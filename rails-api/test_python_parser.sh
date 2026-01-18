#!/bin/bash
# Python Parser Integration Test Script

set -e

echo "========================================================================"
echo "Option C: Python Parser Integration Test"
echo "========================================================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Python
echo ""
echo -e "${YELLOW}1. Checking Python...${NC}"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✅ Python found: $PYTHON_VERSION${NC}"
else
    echo -e "${RED}❌ Python3 not found${NC}"
    exit 1
fi

# Check pdfplumber
echo ""
echo -e "${YELLOW}2. Checking pdfplumber...${NC}"
if python3 -c "import pdfplumber" 2>/dev/null; then
    PDFPLUMBER_VERSION=$(python3 -c "import pdfplumber; print(pdfplumber.__version__)")
    echo -e "${GREEN}✅ pdfplumber installed: $PDFPLUMBER_VERSION${NC}"
else
    echo -e "${RED}❌ pdfplumber not installed${NC}"
    echo "Installing dependencies..."
    pip3 install -r requirements.txt
fi

# Check Python parser file
echo ""
echo -e "${YELLOW}3. Checking Python parser file...${NC}"
if [ -f "lib/python_parsers/exam_pdf_parser_v2.py" ]; then
    echo -e "${GREEN}✅ Parser file found${NC}"
else
    echo -e "${RED}❌ Parser file not found${NC}"
    exit 1
fi

# Test Python parser directly
echo ""
echo -e "${YELLOW}4. Testing Python parser...${NC}"
if [ -f "tmp/test.pdf" ]; then
    echo "Testing with tmp/test.pdf"
    python3 lib/python_parsers/exam_pdf_parser_v2.py tmp/test.pdf > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Python parser works${NC}"
    else
        echo -e "${RED}❌ Python parser failed${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  No test PDF found (tmp/test.pdf)${NC}"
    echo "Skipping direct parser test"
fi

# Check Rails dependencies
echo ""
echo -e "${YELLOW}5. Checking Rails services...${NC}"
if [ -f "app/services/python_parser_bridge.rb" ]; then
    echo -e "${GREEN}✅ PythonParserBridge found${NC}"
else
    echo -e "${RED}❌ PythonParserBridge not found${NC}"
    exit 1
fi

if [ -f "app/services/passage_detection_service.rb" ]; then
    echo -e "${GREEN}✅ PassageDetectionService found${NC}"
else
    echo -e "${RED}❌ PassageDetectionService not found${NC}"
    exit 1
fi

if [ -f "app/services/question_validation_service.rb" ]; then
    echo -e "${GREEN}✅ QuestionValidationService found${NC}"
else
    echo -e "${RED}❌ QuestionValidationService not found${NC}"
    exit 1
fi

# Check ProcessPdfJob
echo ""
echo -e "${YELLOW}6. Checking ProcessPdfJob...${NC}"
if grep -q "PythonParserBridge" app/jobs/process_pdf_job.rb; then
    echo -e "${GREEN}✅ ProcessPdfJob updated${NC}"
else
    echo -e "${RED}❌ ProcessPdfJob not updated${NC}"
    exit 1
fi

# Summary
echo ""
echo "========================================================================"
echo -e "${GREEN}✅ All checks passed!${NC}"
echo "========================================================================"
echo ""
echo "📋 Next steps:"
echo "  1. Start Rails server: bundle exec rails s"
echo "  2. Upload a PDF via web UI"
echo "  3. Check logs for Python parser output"
echo ""
echo "🔧 Manual testing:"
echo "  rails console"
echo "  > material = StudyMaterial.create!(name: 'Test', status: 'pending')"
echo "  > material.pdf_file.attach(io: File.open('test.pdf'), filename: 'test.pdf')"
echo "  > ProcessPdfJob.perform_now(material.id)"
echo ""
echo "========================================================================"
