# Phase 2 UI 개선 작업 목록

## 🐛 **발견된 버그**

### 1. **Study Materials 상태 표시 오류**
- **문제**: 모든 자료가 "처리 실패"로 표시됨
- **원인**: 스크립트로 직접 생성한 자료의 `status` 업데이트 누락
- **해결**: `ProcessPdfJob`에서 `status` 올바르게 업데이트

### 2. **Practice Mode / Exam 시작 오류**
- **문제**: `RecordNotFound` 에러 발생
- **원인**: 세션 생성 로직 또는 권한 검증 문제
- **해결**: 컨트롤러 로직 수정 필요

### 3. **Questions 목록 접근 불가**
- **문제**: `/study_sets/9/questions` 라우트 없음
- **원인**: 라우팅 설정 누락
- **해결**: `routes.rb`에 라우트 추가

---

## ✅ **수정 계획**

### **우선순위 1: Status 업데이트 수정**
- `ProcessPdfJob` 완료 시 `status = 'completed'` 설정
- 진행률 100% 설정

### **우선순위 2: Questions 라우트 추가**
- `study_sets/:id/questions` 라우트 추가
- Questions 목록 페이지 생성

### **우선순위 3: Session 생성 버그 수정**
- Test/Exam 세션 생성 로직 검토
- 권한 검증 수정

---

**작성일**: 2026-01-18
