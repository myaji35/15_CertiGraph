# 프로젝트 루트 디렉토리 정리 계획

## 📁 현재 문제점
- 131개의 파일이 루트 디렉토리에 산재
- PDF 시험 문제 파일들이 루트에 위치
- 마크다운 문서들이 정리되지 않음
- 테스트 관련 파일들이 분산
- 이미지 파일들이 정리되지 않음

## 🎯 정리 계획

### 1. `/sample-data/` - 샘플 PDF 파일
```
sample-data/
├── 2021년 제19회 사회복지사 1급 국가자격시험 최종정답 (1).pdf
├── 2021년 제19회 사회복지사 1급 국가자격시험 최종정답.hwp
├── 2022년도 제20회 사회복지사1급 자격시험 확정정답.pdf
├── 2023년 제21회 사회복지사 1급 최종정답.pdf
├── 2024년 제22회 사회복지사1급 자격시험 최종확정정답.pdf
├── 2025년 제23회 사회복지사 1급 1교시 원본 문제지.pdf
├── 제19회 사회복지사 1급_1교시_B형.pdf
├── 제19회 사회복지사 1급_2교시_A형.pdf
├── 제19회 사회복지사 1급_2교시_B형.pdf
├── 제19회 사회복지사 1급_3교시_A형.pdf
├── 제19회 사회복지사 1급_3교시_B형.pdf
├── 제20회 사회복지사 1급 시험 1교시 A형.hwp
├── 제20회 사회복지사 1급 시험 2교시 A형.hwp
├── 제20회 사회복지사 1급 시험 3교시 A형.hwp
├── 제21회 사회복지사 1급 시험 1교시 A형.hwp
├── 제21회 사회복지사 1급 시험 2교시 A형.hwp
├── 제21회 사회복지사 1급 시험 3교시 A형.hwp
├── 제22회 사회복지사 1급 시험 1교시 A형.hwp
├── 제22회 사회복지사 1급 시험 2교시 A형.hwp
└── 제22회 사회복지사 1급 시험 3교시 A형.hwp
```

### 2. `/docs/archive/` - 완료된 문서들
```
docs/archive/
├── BMAD_TEST_SCENARIOS_VERIFICATION.md
├── BUG_FIX_PLAN.md
├── E2E_TEST_FAILURE_ANALYSIS.md
├── EPIC2_DELIVERABLES.md
├── FAILED_TESTS_ANALYSIS.md
├── FINAL_IMPLEMENTATION_REPORT.md
├── FINAL_SETUP.md
├── FINAL_TEST_REPORT.md
├── GCP_MIGRATION_STATUS.md
├── GCP_MIGRATION_SUMMARY.md
├── GRAPHRAG_IMPLEMENTATION_SUMMARY.md
├── IMPLEMENTATION_SUMMARY.md
├── MLFLOW_ADMIN_VS_SYSTEM.md
├── MLFLOW_INTEGRATION_PLAN.md
├── ORCHESTRATION_PLAYBOOK.md
├── P0_FIXES_COMPLETE.md
├── P1_REVIEW_PAGE_COMPLETE.md
├── PARALLEL_TEST_EXECUTION_GUIDE.md
├── PARALLEL_TEST_SUMMARY.md
├── PHASE2_AUTH_TEST_REPORT.md
├── PHASE2_COMPLETE_SUMMARY.md
├── TDD_BUGFIX_COMPLETE_SUMMARY.md
├── TEST_EXECUTION_REPORT_v1.1.md
├── TEST_EXECUTION_RESULTS.md
├── TEST_EXECUTION_UPDATE.md
├── TEST_FAILURE_SUMMARY.md
├── TEST_FILES_SUMMARY.md
├── TEST_FINAL_SUMMARY.md
├── TEST_FIXES_SUMMARY.md
├── TEST_PARALLELIZATION_STRATEGY.md
├── UNTESTED_FEATURES_SUMMARY.md
├── VIP_PASS_IMPLEMENTATION.md
├── VIP_TEST_RESULTS.md
└── WORK_COMPLETE_123.md
```

### 3. `/docs/deployment/` - 배포 관련 문서
```
docs/deployment/
├── DEPLOY.md
├── DEPLOYMENT.md
├── DEPLOYMENT_STABILITY.md
├── DEPLOY_INSTRUCTIONS.md
├── DOKPLOY_SETUP.md
├── DOMAIN_SETUP.md
├── GCP_CREDENTIALS.md
├── GET_TOKEN.md
└── QUICK_DEPLOY.md
```

### 4. `/docs/guides/` - 가이드 문서
```
docs/guides/
├── CLAUDE.md
├── COPY_PASTE_SETUP.md
├── NEW_STRUCTURE.md
├── Rails_dev.md
├── ROADMAP.md
├── START_HERE.md
└── URL_GUIDE.md
```

### 5. `/assets/images/` - 이미지 파일
```
assets/images/
├── ExamsGraph logo.png
├── examsgraph-home.png
├── examsgraph-signin.png
├── examsgraph-signup.png
├── ultra-modern-design.png
├── ultra-modern-direct.png
├── ultra-modern-final-success.png
├── ultra-modern-refined.png
└── ultra-modern-test-final.png
```

### 6. `/scripts/deployment/` - 배포 스크립트
```
scripts/deployment/
├── auto-deploy-dokploy.sh
├── check-deployment.sh
├── deploy-dokploy.sh
├── deploy-now.sh
├── deploy.sh
├── run-parallel-tests.sh
├── setup-domain.sh
├── start-all.sh
└── stop-all.sh
```

### 7. `/scripts/test/` - 테스트 스크립트
```
scripts/test/
├── capture-screenshot.js
├── check-calendar.js
├── debug-calendar.spec.ts
├── manual-vip-test.js
├── rails-quick-test.spec.ts
├── seed.spec.ts
├── test-calendar.spec.ts
├── test-exam-data.js
├── test-rails-parallel.js
├── test-vip-pass-comprehensive.spec.ts
├── test-vip-pass.html
├── test-vip-pass.spec.ts
├── test_clerk_auth.js
└── test_vip_subscription.spec.ts
```

### 8. `/config/` - 설정 파일
```
config/
├── docker-compose.yaml
├── dokploy-complete-setup.json
├── dokploy-config.json
├── dokploy.yaml
├── nginx-certigraph.conf
├── nginx.conf
├── playwright.config.js
└── playwright.config.ts
```

### 9. 루트에 유지할 파일
```
/
├── .bmad/
├── .claude/
├── .env
├── .env.example
├── .env.production
├── .gitignore
├── .mcp.json
├── backend/
├── docs/
├── frontend/
├── rails-api/
├── scripts/
├── assets/
├── sample-data/
├── config/
├── package.json
├── package-lock.json
├── prd.md
├── README.md (생성 필요)
└── rails-api-implementation-guide.md
```

## 🚀 실행 순서
1. 디렉토리 생성
2. 파일 이동
3. .gitignore 업데이트
4. README.md 생성
5. Git 커밋

## ⚠️ 주의사항
- .env 파일들은 이동하지 않음 (루트 유지)
- node_modules, .venv는 이동하지 않음
- backend.tar.gz는 삭제 고려
- test-results/ 디렉토리는 .gitignore 추가
