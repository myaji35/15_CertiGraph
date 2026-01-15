# Rails ExamsGraph Design Implementation Plan

## 📋 프로젝트 개요

**목표**: 제공된 ExamsGraph HTML 디자인을 Rails 애플리케이션에 적용
**기간**: 2-3일
**우선순위**: P0 (Critical)

---

## 🎨 Phase 1: 디자인 시스템 설정 (1-2시간)

### Task 1.1: Tailwind CSS 설정
**파일**: `config/tailwind.config.js`

```javascript
module.exports = {
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: '#137fec',
        'background-light': '#f6f7f8',
        'background-dark': '#101922',
      },
      fontFamily: {
        display: ['Space Grotesk', 'Noto Sans KR'],
        sans: ['Noto Sans KR', 'sans-serif']
      },
    },
  },
}
```

### Task 1.2: Google Fonts 추가
**파일**: `app/views/layouts/application.html.erb`

```erb
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300;400;500;600;700&family=Noto+Sans+KR:wght@300;400;500;700;900&display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap" rel="stylesheet"/>
```

---

## 🏗️ Phase 2: 레이아웃 구조 (2-3시간)

### Task 2.1: Application Layout
**파일**: `app/views/layouts/application.html.erb`

**구조**:
```
┌─────────────────────────────────────┐
│  Header (고정)                       │
├──────────┬──────────────────────────┤
│          │                          │
│ Sidebar  │   Main Content          │
│ (264px)  │                          │
│          │                          │
└──────────┴──────────────────────────┘
```

### Task 2.2: Sidebar Component
**파일**: `app/views/shared/_sidebar.html.erb`

**메뉴 구조**:
- 대시보드
- 시험 일정
- 문제집 관리 ✓ (현재 활성)
- 랭킹
- 설정
- 로그아웃

### Task 2.3: Header Component
**파일**: `app/views/shared/_header.html.erb`

**요소**:
- 로고 + 브랜드명
- 검색바
- 다크모드 토글
- 사용자 프로필

---

## 📄 Phase 3: 페이지별 구현 (4-6시간)

### Task 3.1: 문제집 목록 페이지
**파일**: `app/views/study_sets/index.html.erb`
**참고**: 제공된 HTML의 "문제집 관리 센터" 디자인

**주요 요소**:
- Grid 레이아웃 (카드 형식)
- 필터 (카테고리, 학습 상태)
- 검색 기능
- "새 문제집 추가" 버튼
- Glass Card 효과

### Task 3.2: 문제집 상세 페이지
**파일**: `app/views/study_sets/show.html.erb`
**참고**: 제공된 HTML의 "문제집 상세 관리" 디자인

**섹션**:
1. **헤더**
   - Breadcrumb
   - 액션 버튼 (PDF 업로드, AI 분석, 학습 시작)

2. **좌측 (7 columns)**
   - PDF 미리보기
   - 문제집 정보
   - 챕터 목록

3. **우측 (5 columns)**
   - 학습 통계
   - 학습 히스토리

### Task 3.3: 업로드 모달
**파일**: `app/views/shared/_upload_modal.html.erb`

**기능**:
- 드래그 앤 드롭
- 파일 선택
- 진행률 표시

---

## 🎯 Phase 4: 인터랙티브 요소 (2-3시간)

### Task 4.1: Stimulus Controllers

**파일 생성**:
1. `app/javascript/controllers/sidebar_controller.js` - 사이드바 토글
2. `app/javascript/controllers/theme_controller.js` - 다크모드 전환
3. `app/javascript/controllers/modal_controller.js` - 모달 관리
4. `app/javascript/controllers/upload_controller.js` - 파일 업로드

### Task 4.2: CSS 애니메이션

**파일**: `app/assets/stylesheets/application.tailwind.css`

```css
@layer components {
  .glass-card {
    @apply bg-slate-800/60 backdrop-blur-xl border border-white/5;
  }
  
  .btn-primary {
    @apply bg-primary hover:bg-primary/90 text-white font-bold px-6 py-3 rounded-xl transition-all shadow-lg shadow-primary/30;
  }
}
```

---

## 📊 Phase 5: 데이터 통합 (2-3시간)

### Task 5.1: Controller 업데이트

**파일**: `app/controllers/study_sets_controller.rb`

```ruby
def index
  @study_sets = StudySet.all
  # 필터링 로직
  @study_sets = @study_sets.where(status: params[:status]) if params[:status].present?
end

def show
  @study_set = StudySet.find(params[:id])
  @materials = @study_set.study_materials
  @statistics = calculate_statistics(@study_set)
end
```

### Task 5.2: Helper Methods

**파일**: `app/helpers/study_sets_helper.rb`

```ruby
def status_badge(status)
  case status
  when 'completed'
    content_tag(:span, '완료', class: 'badge badge-success')
  when 'processing'
    content_tag(:span, 'AI 학습 중', class: 'badge badge-warning')
  else
    content_tag(:span, '대기 중', class: 'badge badge-default')
  end
end
```

---

## 🧪 Phase 6: 테스트 및 검증 (1-2시간)

### Task 6.1: 브라우저 테스트
- [ ] Chrome (다크모드)
- [ ] Safari (다크모드)
- [ ] 반응형 (1920px, 1366px, 768px)

### Task 6.2: 기능 테스트
- [ ] 사이드바 네비게이션
- [ ] 다크모드 전환
- [ ] 파일 업로드
- [ ] 필터링/검색
- [ ] 모달 동작

---

## 📝 구현 순서 (우선순위)

### Day 1: 기반 구축
1. ✅ Tailwind 설정 (Task 1.1)
2. ✅ Google Fonts 추가 (Task 1.2)
3. ✅ Application Layout (Task 2.1)
4. ✅ Sidebar (Task 2.2)
5. ✅ Header (Task 2.3)

### Day 2: 페이지 구현
6. ✅ 문제집 목록 (Task 3.1)
7. ✅ 문제집 상세 (Task 3.2)
8. ✅ 업로드 모달 (Task 3.3)

### Day 3: 완성도 향상
9. ✅ Stimulus Controllers (Task 4.1)
10. ✅ CSS 애니메이션 (Task 4.2)
11. ✅ 데이터 통합 (Task 5.1, 5.2)
12. ✅ 테스트 (Task 6.1, 6.2)

---

## 🎨 주요 디자인 패턴

### 1. Glass Card
```html
<div class="glass-card rounded-xl p-6">
  <!-- Content -->
</div>
```

### 2. Primary Button
```html
<button class="btn-primary">
  <span class="material-symbols-outlined">add_circle</span>
  새 문제집 추가
</button>
```

### 3. Status Badge
```html
<span class="inline-flex items-center rounded-full bg-green-100 px-2 py-1 text-xs font-medium text-green-700">
  완료
</span>
```

---

## 🚀 즉시 시작

**첫 번째 작업**: Tailwind 설정 파일 생성 및 Google Fonts 추가

준비되셨으면 시작하겠습니다!
