# Epic 3: 자격증 시험 구조 및 문제집 관리 - 완료 보고서

## 구현 날짜
2026-01-16

## 개요
자격증 시험의 구조적 정보(교시, 과목)를 관리하고 학습 세트에 메타데이터를 추가하여 사용자가 자격증별 시험 구조를 확인할 수 있는 기능을 구현했습니다.

## 구현된 기능

### 1. 자격증 데이터베이스 (Phase 1 완료)

#### 1.1 자격증 목록 Helper
**파일**: `app/helpers/certifications_helper.rb`

**구현 내용**:
- 200+ 개의 한국 자격증 데이터 (20개 카테고리 분류)
- 자격증 검색 및 필터링 헬퍼 메서드
- 플랫 리스트 및 카테고리별 리스트 제공

**카테고리**:
```ruby
- IT/개발 (정보처리기사, 정보보안기사 등)
- 의료/보건 (간호사, 물리치료사 등)
- 복지/사회 (사회복지사, 요양보호사 등)
- 법률/행정 (변호사, 법무사 등)
- 건축/토목 (건축사, 토목기사 등)
- 전기/전자 (전기기사, 전자기사 등)
- 기계/자동차 (기계기사, 자동차정비기사 등)
- 화학/환경 (화공기사, 환경기사 등)
- 금융/경영 (공인회계사, 세무사 등)
- 교육 (유치원정교사, 초등교사 등)
... (총 20개 카테고리)
```

#### 1.2 시험 구조 데이터
**메서드**: `certification_structure(cert_name)`

**구현된 자격증** (7개):
1. 사회복지사 1급
2. 정보처리기사
3. 간호사
4. 공인중개사
5. 컴퓨터활용능력 1급
6. 간호조무사
7. 요양보호사

**데이터 구조**:
```ruby
{
  exam_type: '필기시험',
  total_sessions: 3,
  total_questions: 225,
  passing_score: 60,
  description: '과목당 만점의 40% 이상, 전 과목 평균 60% 이상',
  sessions: [
    {
      session_number: 1,
      duration_minutes: 75,
      total_questions: 75,
      subjects: [
        { name: '인간행동과 사회환경', questions: 25 },
        { name: '사회복지조사론', questions: 50 }
      ]
    },
    ...
  ]
}
```

#### 1.3 헬퍼 메서드
```ruby
# 자격증 구조 데이터 존재 여부 확인
has_certification_structure?(cert_name)

# 특정 교시의 과목 목록
session_subjects(cert_name, session_number)

# 자격증의 전체 과목 목록
all_subjects(cert_name)
```

### 2. Study Set 모델 확장 (Phase 1 완료)

#### 2.1 데이터베이스 필드 추가
**파일**: `db/schema.rb`

**추가된 필드**:
```ruby
t.date "exam_date"           # 시험 예정일
t.string "certification"      # 자격증 명칭
```

**Strong Parameters 업데이트**:
```ruby
# app/controllers/study_sets_controller.rb
def study_set_params
  params.require(:study_set).permit(:title, :description, :exam_date, :certification)
end
```

### 3. 학습 세트 편집 폼 (Phase 2 완료)

#### 3.1 Exam Date Picker
**파일**: `app/views/study_sets/edit.html.erb` (lines 45-50)

**기능**:
- HTML5 date input 사용
- 시험일자 선택 기능

#### 3.2 자격증 검색 및 선택
**파일**: `app/views/study_sets/edit.html.erb` (lines 52-205)

**구현된 기능**:
1. **Searchable Text Input**:
   - HTML5 datalist를 활용한 네이티브 자동완성
   - 200+ 자격증에서 실시간 검색

2. **Category Quick Select Buttons**:
   - 8개 주요 카테고리 바로가기 버튼
   - 클릭 시 해당 카테고리의 자격증 목록 표시

3. **Dynamic Dropdown**:
   - JavaScript 기반 실시간 필터링
   - 카테고리별 그룹화 표시
   - 검색어 1자 이상 입력 시 작동

4. **UI/UX**:
   - 검색 아이콘 표시
   - Hover 효과
   - 외부 클릭 시 드롭다운 자동 닫힘

**JavaScript 기능**:
```javascript
// 입력 시 필터링
input.addEventListener('input', function(e) {
  if (e.target.value.length >= 1) {
    showDropdown(e.target.value);
  }
});

// Focus 시 전체 카테고리 표시
input.addEventListener('focus', function() {
  if (input.value.length === 0) {
    showDropdown('');
  }
});

// 카테고리 버튼 클릭 처리
categoryButtons.forEach(button => {
  button.addEventListener('click', function() {
    // 해당 카테고리의 자격증 목록 표시
  });
});
```

### 4. 학습 세트 상세 페이지 (Phase 3 완료)

#### 4.1 자격증 및 시험일 표시
**파일**: `app/views/study_sets/show.html.erb` (lines 78-95)

**기능**:
- 자격증 아이콘 + 자격증명 표시
- 시험일자 아이콘 + 날짜 표시 (yyyy년 mm월 dd일)
- Conditional 렌더링 (데이터 있을 때만 표시)

#### 4.2 시험 구조 섹션
**파일**: `app/views/study_sets/show.html.erb` (lines 128-200)

**구현된 기능**:

1. **Collapsible Header** (NEW):
   - 접기/펼치기 토글 버튼
   - 클릭 시 세션 상세 내용 숨김/표시
   - 아이콘 변경: expand_less ⇄ expand_more
   - 부드러운 전환 애니메이션

2. **시험 개요 (Inline)**:
   - 시험 유형 (필기시험/실기시험)
   - 총 교시 수 + 총 문항수
   - 합격 기준 점수

3. **교시별 상세 정보**:
   - 좌측 파란색 보더로 구분
   - 교시 번호 배지
   - 시험 시간 (분)
   - 총 문항수

4. **과목별 칩**:
   - 과목명 + 문항수
   - 책 아이콘
   - Compact한 chip 스타일

**UI 특징**:
- Compact하고 슬림한 디자인
- text-xs 크기로 공간 절약
- Flex-wrap으로 반응형 레이아웃
- 최소한의 padding과 border

**JavaScript 토글 기능**:
```javascript
function toggleExamStructure() {
  const content = document.getElementById('exam-structure-content');
  const icon = document.getElementById('exam-structure-icon');

  if (content.style.display === 'none') {
    content.style.display = 'block';
    icon.textContent = 'expand_less';
  } else {
    content.style.display = 'none';
    icon.textContent = 'expand_more';
  }
}
```

## 구현 체크리스트

### Phase 1: 기본 구조 ✅
- [x] certifications_helper.rb에 자격증 리스트 추가 (200+ 개)
- [x] certifications_helper.rb에 자격증 구조 데이터 추가 (7개)
- [x] StudySet에 exam_date, certification 필드 추가
- [x] Strong parameters 업데이트

### Phase 2: 편집 UI ✅
- [x] 학습 세트 편집 폼에 exam_date 필드 추가
- [x] 자격증 검색 가능한 텍스트 입력 구현
- [x] HTML5 datalist 자동완성 구현
- [x] JavaScript 동적 드롭다운 구현
- [x] 카테고리 빠른 선택 버튼 구현
- [x] 검색어 필터링 기능
- [x] 외부 클릭 시 드롭다운 닫힘

### Phase 3: 상세 페이지 ✅
- [x] 학습 세트 상세 페이지에 자격증 표시
- [x] 학습 세트 상세 페이지에 시험일 표시
- [x] 시험 구조 섹션 구현
- [x] 교시별 세부 정보 표시
- [x] 과목별 문항수 표시
- [x] Compact한 디자인 적용
- [x] 접기/펼치기 토글 기능 추가

### Phase 4: 문제집 메타데이터 (미구현)
- [ ] StudyMaterial에 exam_year, exam_round, session_number, subject 필드 추가
- [ ] 문제집 업로드 시 메타데이터 입력 폼
- [ ] 교시 선택 시 과목 자동 표시
- [ ] 파일명 자동 생성

### Phase 5: 진행 상태 표시 (미구현)
- [ ] 실시간 진행 상태 폴링
- [ ] 진행률 UI
- [ ] 완료/실패 알림

### Phase 6: 문제집 관리 (미구현)
- [ ] 업로드된 문제집 카드 UI
- [ ] 년도/회차/교시별 필터링
- [ ] 정렬 기능

## 파일 변경 사항

### 생성된 파일
1. `app/helpers/certifications_helper.rb` (NEW) - 자격증 데이터 및 헬퍼 메서드

### 수정된 파일
1. `db/schema.rb` - StudySet 테이블에 exam_date, certification 추가
2. `app/controllers/study_sets_controller.rb` - Strong parameters 업데이트
3. `app/views/study_sets/edit.html.erb` - 편집 폼 확장
4. `app/views/study_sets/show.html.erb` - 상세 페이지 확장

## 데이터 예시

### 사회복지사 1급 구조
```
총 3교시 | 총 225문항 | 합격 60점

1교시 (75분, 75문항)
  - 인간행동과 사회환경 (25문항)
  - 사회복지조사론 (50문항)

2교시 (75분, 75문항)
  - 사회복지실천론 (25문항)
  - 사회복지실천기술론 (25문항)
  - 지역사회복지론 (25문항)

3교시 (75분, 75문항)
  - 사회복지정책론 (25문항)
  - 사회복지행정론 (25문항)
  - 사회복지법제론 (25문항)
```

## 사용자 워크플로우

1. **학습 세트 생성/편집**
   - 제목, 설명 입력
   - 시험일자 선택 (date picker)
   - 자격증 검색 및 선택 (검색 또는 카테고리 선택)
   - 저장

2. **학습 세트 조회**
   - 자격증명 및 시험일 확인
   - 시험 구조 섹션에서 교시/과목 구조 확인
   - 필요 시 토글 버튼으로 접기/펼치기
   - 문제집 업로드 및 학습 진행

## 향후 확장 계획

### 단기 (Phase 4-6)
- StudyMaterial 메타데이터 필드 추가
- 문제집 업로드 UI 개선
- 진행 상태 실시간 추적
- 문제집 관리 기능

### 중기
- 더 많은 자격증 구조 데이터 추가
- 교시별 모의고사 기능
- 과목별 약점 분석
- 년도별/회차별 난이도 비교

### 장기
- 출제 경향 분석
- 교시별 학습 진도율 표시
- AI 기반 학습 추천
- 과목별 개념 지도 연동

## 기술 스택

- **Backend**: Rails 7.2
- **Frontend**: ERB Templates, Stimulus (optional), Vanilla JavaScript
- **Styling**: Tailwind CSS
- **Icons**: Material Symbols Outlined
- **Data Storage**: Rails Helpers (temporary), 향후 데이터베이스 이전 예정

## 성능 고려사항

1. **자격증 데이터 로딩**: Helper 메서드는 각 요청마다 Ruby 해시를 생성하므로 향후 캐싱 또는 데이터베이스 이전 고려
2. **JavaScript 검색**: 200+ 자격증 대상 클라이언트 측 검색은 충분히 빠름
3. **Collapsible UI**: CSS display toggle은 가볍고 빠른 방식

## 테스트 권장사항

### Manual Testing
1. 학습 세트 편집 폼에서 자격증 검색 테스트
2. 카테고리 버튼 클릭 테스트
3. 시험일자 선택 테스트
4. 학습 세트 상세 페이지에서 시험 구조 표시 확인
5. 접기/펼치기 토글 기능 테스트

### Automated Testing (TODO)
- RSpec: Helper 메서드 단위 테스트
- Capybara: 폼 제출 통합 테스트
- Playwright: 검색 및 선택 E2E 테스트

## 결론

Epic 3의 Phase 1-3가 성공적으로 완료되었습니다. 사용자는 이제:
- 200+ 개의 자격증 중 선택 가능
- 시험일자 설정 가능
- 7개 주요 자격증의 상세 시험 구조 확인 가능
- 접기/펼치기 기능으로 화면 공간 효율적 사용

다음 단계로 문제집 메타데이터 관리 (Phase 4-6)를 진행하면 더욱 체계적인 학습 관리가 가능해질 것입니다.
