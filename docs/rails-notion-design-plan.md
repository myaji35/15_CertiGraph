# Rails Notion-Style Design Implementation Plan (BMAD)

## 📋 프로젝트 개요

**목표**: Rails 애플리케이션에 Notion과 같은 심플하고 깔끔한 디자인 적용
**접근 방식**: BMAD (Business-Driven Agile Development) 방법론
**핵심 원칙**: 
- 심플함 (Simplicity)
- 일관성 (Consistency)
- 사용자 경험 우선 (UX First)

---

## 🎯 Phase 1: 기반 설정 (Foundation)

### Task 1.1: Tailwind CSS 설정 확인 및 최적화
**우선순위**: P0 (Critical)
**예상 시간**: 30분

**목표**:
- Rails 7.2에서 Tailwind CSS가 제대로 작동하는지 확인
- 필요한 설정 파일 검증 및 수정

**체크리스트**:
- [ ] `config/tailwind.config.js` 확인
- [ ] `app/assets/stylesheets/application.tailwind.css` 확인
- [ ] `bin/dev` 스크립트로 Tailwind 빌드 프로세스 확인
- [ ] 브라우저에서 Tailwind 클래스 적용 확인

**검증 방법**:
```bash
# Tailwind 빌드 확인
bin/rails tailwindcss:build

# 개발 서버 실행
bin/dev
```

---

### Task 1.2: 기본 레이아웃 구조 설계
**우선순위**: P0 (Critical)
**예상 시간**: 1시간

**목표**:
- Notion 스타일의 좌측 사이드바 + 메인 콘텐츠 레이아웃 구현

**레이아웃 구조**:
```
┌─────────────────────────────────────┐
│  Header (고정, 얇은 상단바)          │
├──────────┬──────────────────────────┤
│          │                          │
│ Sidebar  │   Main Content          │
│ (240px)  │   (나머지 공간)          │
│          │                          │
│  - 홈    │                          │
│  - 문제집│                          │
│  - 통계  │                          │
│  - 설정  │                          │
│          │                          │
└──────────┴──────────────────────────┘
```

**파일 생성**:
- [ ] `app/views/layouts/application.html.erb` 수정
- [ ] `app/views/shared/_sidebar.html.erb` 생성
- [ ] `app/views/shared/_header.html.erb` 생성

---

## 🎨 Phase 2: 디자인 시스템 구축

### Task 2.1: 색상 팔레트 정의
**우선순위**: P0 (Critical)
**예상 시간**: 30분

**Notion 스타일 색상**:
```css
/* tailwind.config.js에 추가 */
colors: {
  notion: {
    bg: '#ffffff',           // 메인 배경
    sidebar: '#f7f6f3',      // 사이드바 배경
    text: '#37352f',         // 기본 텍스트
    'text-light': '#787774', // 보조 텍스트
    border: '#e9e9e7',       // 테두리
    hover: '#f1f1ef',        // 호버 배경
    accent: '#2383e2',       // 강조 색상
  }
}
```

---

### Task 2.2: 타이포그래피 설정
**우선순위**: P1 (High)
**예상 시간**: 20분

**폰트 스택**:
```css
font-family: 
  -apple-system, BlinkMacSystemFont, 
  "Segoe UI", Helvetica, "Apple Color Emoji", 
  Arial, sans-serif, "Segoe UI Emoji", "Segoe UI Symbol";
```

**텍스트 크기**:
- 제목 (H1): 40px (2.5rem)
- 제목 (H2): 30px (1.875rem)
- 제목 (H3): 24px (1.5rem)
- 본문: 16px (1rem)
- 작은 텍스트: 14px (0.875rem)

---

## 🏗️ Phase 3: 컴포넌트 구현

### Task 3.1: 사이드바 (Sidebar) 구현
**우선순위**: P0 (Critical)
**예상 시간**: 2시간

**기능**:
- [ ] 좌측 고정 사이드바 (240px 너비)
- [ ] 네비게이션 메뉴 항목
- [ ] 현재 페이지 하이라이트
- [ ] 호버 효과
- [ ] 아이콘 + 텍스트 조합

**메뉴 구조**:
```
🏠 홈
📚 문제집
  └─ 전체 문제집
  └─ 새 문제집 만들기
📊 학습 통계
📈 성적 분석
⚙️ 설정
```

**파일**: `app/views/shared/_sidebar.html.erb`

---

### Task 3.2: 헤더 (Header) 구현
**우선순위**: P1 (High)
**예상 시간**: 1시간

**기능**:
- [ ] 얇은 상단 바 (48px 높이)
- [ ] 현재 페이지 제목 (breadcrumb)
- [ ] 사용자 프로필 (우측)
- [ ] 검색 바 (중앙)

**파일**: `app/views/shared/_header.html.erb`

---

### Task 3.3: 문제집 목록 페이지 재디자인
**우선순위**: P0 (Critical)
**예상 시간**: 2시간

**디자인 특징**:
- [ ] 카드 형식 레이아웃 (그리드)
- [ ] 깔끔한 여백과 간격
- [ ] 호버 시 부드러운 그림자 효과
- [ ] 최소한의 테두리 사용

**레이아웃**:
```
┌────────────────────────────────────┐
│  문제집                             │
│  ─────────────────────────────────│
│                                    │
│  ┌──────┐  ┌──────┐  ┌──────┐   │
│  │ 카드 │  │ 카드 │  │ 카드 │   │
│  │      │  │      │  │      │   │
│  └──────┘  └──────┘  └──────┘   │
│                                    │
└────────────────────────────────────┘
```

**파일**: `app/views/study_sets/index.html.erb`

---

### Task 3.4: 문제집 상세 페이지 재디자인
**우선순위**: P0 (Critical)
**예상 시간**: 3시간

**섹션 구조**:
1. **헤더 영역**
   - 문제집 제목 (큰 텍스트, 굵게)
   - 메타 정보 (작은 텍스트, 회색)
   - 액션 버튼 (우측 정렬)

2. **업로드 영역**
   - 심플한 드래그 앤 드롭 영역
   - 최소한의 테두리
   - 아이콘 + 텍스트

3. **학습자료 목록**
   - 깔끔한 테이블 (테두리 최소화)
   - 행 호버 효과
   - 아이콘 버튼 (텍스트 없이)

**파일**: `app/views/study_sets/show.html.erb`

---

## 🎯 Phase 4: 인터랙션 및 애니메이션

### Task 4.1: 호버 효과 추가
**우선순위**: P2 (Medium)
**예상 시간**: 1시간

**적용 대상**:
- [ ] 사이드바 메뉴 항목
- [ ] 카드 컴포넌트
- [ ] 버튼
- [ ] 테이블 행

**효과**:
- 배경색 변경 (부드러운 전환)
- 그림자 추가 (카드)
- 커서 변경

---

### Task 4.2: 페이지 전환 애니메이션
**우선순위**: P3 (Low)
**예상 시간**: 1시간

**Turbo Frame 활용**:
- [ ] 부드러운 페이지 전환
- [ ] 로딩 인디케이터
- [ ] 스켈레톤 UI

---

## 📊 Phase 5: 테스트 및 검증

### Task 5.1: 반응형 디자인 테스트
**우선순위**: P1 (High)
**예상 시간**: 1시간

**테스트 해상도**:
- [ ] 데스크톱 (1920px)
- [ ] 노트북 (1366px)
- [ ] 태블릿 (768px)
- [ ] 모바일 (375px)

---

### Task 5.2: 브라우저 호환성 테스트
**우선순위**: P2 (Medium)
**예상 시간**: 30분

**테스트 브라우저**:
- [ ] Chrome
- [ ] Safari
- [ ] Firefox
- [ ] Edge

---

## 📝 구현 순서 (우선순위별)

### Week 1: 기반 구축
1. ✅ Tailwind CSS 설정 확인 (Task 1.1)
2. ✅ 기본 레이아웃 구조 (Task 1.2)
3. ✅ 색상 팔레트 정의 (Task 2.1)
4. ✅ 타이포그래피 설정 (Task 2.2)

### Week 2: 핵심 컴포넌트
5. ✅ 사이드바 구현 (Task 3.1)
6. ✅ 헤더 구현 (Task 3.2)
7. ✅ 문제집 목록 페이지 (Task 3.3)
8. ✅ 문제집 상세 페이지 (Task 3.4)

### Week 3: 완성도 향상
9. ✅ 호버 효과 (Task 4.1)
10. ✅ 반응형 테스트 (Task 5.1)
11. ⏸️ 페이지 전환 애니메이션 (Task 4.2)
12. ⏸️ 브라우저 호환성 테스트 (Task 5.2)

---

## 🎨 디자인 원칙

### 1. 여백 (Spacing)
- 일관된 간격 사용: 4px, 8px, 12px, 16px, 24px, 32px
- 섹션 간 충분한 여백 확보

### 2. 색상 (Colors)
- 최소한의 색상 사용
- 회색 톤 중심
- 강조 색상은 파란색 계열

### 3. 타이포그래피 (Typography)
- 명확한 계층 구조
- 충분한 행간 (line-height: 1.5)
- 적절한 글자 간격

### 4. 인터랙션 (Interaction)
- 부드러운 전환 효과 (transition: 150ms)
- 명확한 피드백
- 직관적인 동작

---

## 🚀 즉시 시작 가능한 첫 단계

### Step 1: Tailwind 설정 확인
```bash
cd certigraph
cat config/tailwind.config.js
cat app/assets/stylesheets/application.tailwind.css
```

### Step 2: 레이아웃 파일 생성
```bash
# 사이드바 partial 생성
touch app/views/shared/_sidebar.html.erb

# 헤더 partial 생성
touch app/views/shared/_header.html.erb
```

### Step 3: 기본 레이아웃 수정
`app/views/layouts/application.html.erb` 파일을 Notion 스타일로 수정

---

## 📌 주의사항

1. **점진적 개선**: 한 번에 모든 것을 바꾸지 말고, 하나씩 테스트하며 진행
2. **Git 커밋**: 각 Task 완료 후 커밋하여 롤백 가능하도록 유지
3. **브라우저 테스트**: 변경 후 즉시 브라우저에서 확인
4. **사용자 피드백**: 각 단계마다 사용자 확인 필요

---

## 🎯 성공 기준

- [ ] Tailwind CSS가 정상적으로 작동
- [ ] 좌측 사이드바가 모든 페이지에 표시
- [ ] Notion과 유사한 심플한 디자인
- [ ] 모든 페이지가 일관된 스타일 유지
- [ ] 반응형 디자인 지원
- [ ] 부드러운 인터랙션 효과

---

**다음 단계**: Task 1.1 (Tailwind CSS 설정 확인)부터 시작하시겠습니까?
