#!/bin/bash

# CertiGraph 테스트 실행 및 버그 수정 자동화 스크립트

set -e

echo "🚀 CertiGraph 병렬 테스트 실행 시작"
echo "======================================"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 테스트 결과 디렉토리 생성
mkdir -p test-results/reports
mkdir -p test-results/screenshots
mkdir -p test-results/videos
mkdir -p test-results/traces

# 로그 파일
LOG_FILE="test-results/test-execution-$(date +%Y%m%d-%H%M%S).log"
SUMMARY_FILE="test-results/test-summary-$(date +%Y%m%d-%H%M%S).md"

# 함수: 테스트 그룹 실행
run_test_group() {
    local group_name=$1
    local project=$2
    local description=$3
    
    echo -e "${BLUE}📦 테스트 그룹: ${group_name}${NC}"
    echo -e "${BLUE}   프로젝트: ${project}${NC}"
    echo -e "${BLUE}   설명: ${description}${NC}"
    echo ""
    
    # 테스트 실행
    if SKIP_SERVER=true npx playwright test --project=${project} --reporter=list --reporter=html 2>&1 | tee -a ${LOG_FILE}; then
        echo -e "${GREEN}✅ ${group_name} 테스트 성공${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}❌ ${group_name} 테스트 실패${NC}"
        echo ""
        return 1
    fi
}

# 함수: 실패한 테스트 재실행
retry_failed_tests() {
    echo -e "${YELLOW}🔄 실패한 테스트 재실행${NC}"
    echo ""
    
    if SKIP_SERVER=true npx playwright test --last-failed --reporter=list 2>&1 | tee -a ${LOG_FILE}; then
        echo -e "${GREEN}✅ 재시도 성공${NC}"
        return 0
    else
        echo -e "${RED}❌ 재시도 실패 - 버그 수정 필요${NC}"
        return 1
    fi
}

# 함수: 테스트 결과 요약 생성
generate_summary() {
    echo "# 테스트 실행 결과 요약" > ${SUMMARY_FILE}
    echo "" >> ${SUMMARY_FILE}
    echo "**실행 일시**: $(date '+%Y-%m-%d %H:%M:%S')" >> ${SUMMARY_FILE}
    echo "" >> ${SUMMARY_FILE}
    
    # HTML 리포트에서 통계 추출 (간단한 버전)
    if [ -f "test-results/html-report/index.html" ]; then
        echo "## 📊 테스트 통계" >> ${SUMMARY_FILE}
        echo "" >> ${SUMMARY_FILE}
        echo "상세 결과는 HTML 리포트를 확인하세요:" >> ${SUMMARY_FILE}
        echo "\`\`\`bash" >> ${SUMMARY_FILE}
        echo "npm run test:report" >> ${SUMMARY_FILE}
        echo "\`\`\`" >> ${SUMMARY_FILE}
    fi
    
    echo "" >> ${SUMMARY_FILE}
    echo "## 📁 결과 파일" >> ${SUMMARY_FILE}
    echo "" >> ${SUMMARY_FILE}
    echo "- 로그: ${LOG_FILE}" >> ${SUMMARY_FILE}
    echo "- HTML 리포트: test-results/html-report/index.html" >> ${SUMMARY_FILE}
    echo "- JSON 결과: test-results/results.json" >> ${SUMMARY_FILE}
    
    cat ${SUMMARY_FILE}
}

# 메인 실행 플로우
main() {
    echo "🎯 테스트 실행 계획"
    echo "===================="
    echo "1. 독립적인 E2E 테스트 (병렬)"
    echo "2. 인증 포괄 테스트 (부분 병렬)"
    echo "3. 학습 자료 및 시험 (부분 병렬)"
    echo "4. 통합 테스트 (순차)"
    echo "5. 결제 플로우 (순차)"
    echo ""
    echo "예상 소요 시간: 40-60분"
    echo ""
    
    read -p "계속 진행하시겠습니까? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "테스트 실행 취소"
        exit 0
    fi
    
    # 시작 시간 기록
    START_TIME=$(date +%s)
    
    # Phase 1: 독립적인 E2E 테스트
    if run_test_group "Phase 1" "independent-e2e" "지식 그래프, 성능, 보안 테스트"; then
        PHASE1_SUCCESS=true
    else
        PHASE1_SUCCESS=false
    fi
    
    # Phase 2: 인증 포괄 테스트
    if run_test_group "Phase 2" "auth-comprehensive" "인증 및 소셜 로그인 테스트"; then
        PHASE2_SUCCESS=true
    else
        PHASE2_SUCCESS=false
    fi
    
    # Phase 3: 학습 자료 및 시험
    if run_test_group "Phase 3" "study-exam-partial" "학습 자료 업로드 및 모의시험"; then
        PHASE3_SUCCESS=true
    else
        PHASE3_SUCCESS=false
    fi
    
    # Phase 4: 통합 테스트
    if run_test_group "Phase 4" "integration-sequential" "전체 플로우 통합 테스트"; then
        PHASE4_SUCCESS=true
    else
        PHASE4_SUCCESS=false
    fi
    
    # Phase 5: 결제 플로우
    if run_test_group "Phase 5" "payment-sequential" "결제 및 구독 테스트"; then
        PHASE5_SUCCESS=true
    else
        PHASE5_SUCCESS=false
    fi
    
    # 종료 시간 기록
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    echo ""
    echo "======================================"
    echo "🏁 테스트 실행 완료"
    echo "======================================"
    echo ""
    echo "⏱️  총 소요 시간: ${MINUTES}분 ${SECONDS}초"
    echo ""
    
    # 결과 요약
    echo "📊 Phase별 결과:"
    [ "$PHASE1_SUCCESS" = true ] && echo -e "${GREEN}✅ Phase 1: 성공${NC}" || echo -e "${RED}❌ Phase 1: 실패${NC}"
    [ "$PHASE2_SUCCESS" = true ] && echo -e "${GREEN}✅ Phase 2: 성공${NC}" || echo -e "${RED}❌ Phase 2: 실패${NC}"
    [ "$PHASE3_SUCCESS" = true ] && echo -e "${GREEN}✅ Phase 3: 성공${NC}" || echo -e "${RED}❌ Phase 3: 실패${NC}"
    [ "$PHASE4_SUCCESS" = true ] && echo -e "${GREEN}✅ Phase 4: 성공${NC}" || echo -e "${RED}❌ Phase 4: 실패${NC}"
    [ "$PHASE5_SUCCESS" = true ] && echo -e "${GREEN}✅ Phase 5: 성공${NC}" || echo -e "${RED}❌ Phase 5: 실패${NC}"
    echo ""
    
    # 실패한 테스트가 있으면 재시도 옵션 제공
    if [ "$PHASE1_SUCCESS" = false ] || [ "$PHASE2_SUCCESS" = false ] || [ "$PHASE3_SUCCESS" = false ] || [ "$PHASE4_SUCCESS" = false ] || [ "$PHASE5_SUCCESS" = false ]; then
        echo -e "${YELLOW}⚠️  일부 테스트가 실패했습니다.${NC}"
        echo ""
        read -p "실패한 테스트를 재실행하시겠습니까? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            retry_failed_tests
        fi
    else
        echo -e "${GREEN}🎉 모든 테스트가 성공했습니다!${NC}"
    fi
    
    # 결과 요약 생성
    echo ""
    echo "📝 테스트 결과 요약 생성 중..."
    generate_summary
    
    echo ""
    echo "🔍 상세 결과 확인:"
    echo "   npm run test:report"
    echo ""
}

# 스크립트 실행
main
