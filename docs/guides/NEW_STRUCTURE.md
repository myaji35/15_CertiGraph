# 문제집 및 학습자료 새 구조

## 개념 정리

### 1. 문제집 (Study Set) - 컨테이너
- 회원이 임의로 이름을 지정
- 여러 개의 학습자료(PDF)를 담는 그룹
- 형식: `{문제집명}:{자격증명}_{시험일자}`
- 예시:
  - `2024년 대비:사회복지사1급_2026-01-17`
  - `기출문제 모음:SQLD_2025-05-10`
  - `핵심정리:정보처리기사_2025-08-15`

### 2. 학습자료 (Study Material) - PDF 파일
- 문제집 안에 업로드되는 개별 PDF 파일
- 각 PDF마다 독립적인 파싱 프로세스
- 여러 PDF의 문제들이 하나의 문제집으로 통합
- 예시:
  - 문제집 "2024년 대비" 안에:
    - `1회 기출문제.pdf`
    - `2회 기출문제.pdf`
    - `3회 모의고사.pdf`

## 데이터베이스 구조

### study_sets 테이블 (문제집)
```sql
- id: UUID
- clerk_id: TEXT (소유자)
- certification_id: UUID (자격증)
- exam_date_id: UUID (시험일자)
- title: TEXT (문제집명)
- description: TEXT
- total_materials: INTEGER (포함된 PDF 수)
- total_questions: INTEGER (전체 문제 수)
- created_at, updated_at
```

### study_materials 테이블 (학습자료)
```sql
- id: UUID
- study_set_id: UUID (어느 문제집에 속하는지)
- clerk_id: TEXT (소유자)
- title: TEXT (자료명)
- pdf_url: TEXT
- pdf_hash: TEXT (중복 방지)
- status: TEXT (uploaded, processing, completed, failed)
- total_questions: INTEGER
- processing_progress: INTEGER
- created_at, updated_at, processed_at
```

## 사용자 플로우

### A. 문제집 생성
1. 사용자가 "문제집 만들기" 클릭
2. 문제집 이름 입력 (예: "2024년 대비")
3. 자격증은 이용권에서 자동 선택됨
4. 시험일자도 이용권에서 자동 선택됨
5. DB에 study_set 레코드 생성 (PDF 없이)
6. 자동으로 학습자료 업로드 화면으로 이동

### B. 학습자료 업로드
1. 문제집 상세 페이지에서 "학습자료 추가" 클릭
2. PDF 파일 업로드
3. 자료 이름 입력 (예: "1회 기출문제")
4. DB에 study_material 레코드 생성
5. 백그라운드에서 문제 파싱 시작
6. 파싱 완료되면 study_set의 total_questions 자동 업데이트

### C. 대시보드 표시
```
문제집: 2024년 대비 (사회복지사1급 | 2026-01-17)
├─ 학습자료 3개
├─ 전체 문제 150개
└─ 파싱 완료 100%
```

## 마이그레이션 단계

### 1단계: DB 스키마 업데이트 ✅
- `migration_study_materials.sql` 생성 완료
- `study_materials` 테이블 추가
- `study_sets`에 `exam_date_id`, `total_materials`, `total_questions` 컬럼 추가
- 자동 업데이트 트리거 추가

### 2단계: Backend API 수정 (예정)
- `POST /study-sets` - 문제집 생성 (PDF 없이)
- `POST /study-sets/{id}/materials` - 학습자료 업로드
- `GET /study-sets/{id}/materials` - 학습자료 목록
- `DELETE /study-materials/{id}` - 학습자료 삭제

### 3단계: Frontend UI 수정 (예정)
- 문제집 생성 폼 (이름만 입력)
- 문제집 상세 페이지 (학습자료 목록 + 추가 버튼)
- 학습자료 업로드 모달
- 대시보드에 문제집 카드 (자료 수, 문제 수 표시)

## 장점

1. **유연성**: 하나의 문제집에 여러 PDF 추가 가능
2. **조직화**: 관련 자료들을 하나로 그룹화
3. **진행 상황**: 각 PDF의 파싱 상태 개별 추적
4. **확장성**: 나중에 다른 타입의 자료(동영상, 이미지) 추가 가능
