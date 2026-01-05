# 홈 (대시보드)

## 경로
`/dashboard` 또는 `/`

## 목적
사용자의 학습 현황을 한눈에 파악할 수 있는 대시보드

## 주요 기능

### 1. 통계 카드 (4개)
- **총 학습 문제**: 전체 문제집의 문제 개수 합계
- **평균 정답률**: 완료한 테스트의 평균 정답률 (진행바 포함)
- **학습 세트**: 생성한 문제집 개수
- **모의고사 응시**: 완료한 테스트 세션 수

### 2. 합격 예측 섹션
- **예상 점수**: 최근 10회 테스트 기반 가중 평균 점수
- **합격 가능성**:
  - 75점 이상: "합격 가능" (녹색)
  - 65~74점: "합격 근접" (파란색)
  - 55~64점: "노력 필요" (노란색)
  - 55점 미만: "위험" (빨간색)
- **과락 위험 과목**: 40점 미만 과목 표시
- **링크**: "상세 보기" → `/dashboard/analysis`

### 3. 최근 학습 활동 (최대 5개)
- 문제집명
- 응시일시
- 점수 (정답/전체)
- 정답률 (%)
- 클릭 시 해당 테스트 결과 페이지로 이동

### 4. 온보딩 메시지
학습 데이터가 없을 때:
> "아직 학습 데이터가 없습니다. 문제집을 만들고 학습자료(PDF)를 업로드하여 학습을 시작하세요."

### 5. 빠른 실행 버튼 (3개)
1. **내 문제집** → `/study-sets`
2. **모의고사 응시** → `/dashboard/study`
3. **취약점 분석** → `/dashboard/analysis`

## API 엔드포인트

### GET /analysis/dashboard
**응답:**
```json
{
  "data": {
    "study_set_count": 3,
    "total_questions": 150,
    "test_count": 5,
    "avg_accuracy": 72.5,
    "recent_activity": [
      {
        "session_id": "uuid",
        "study_set_name": "정보처리기사 2024",
        "score": 72,
        "total": 100,
        "percentage": 72.0,
        "completed_at": "2025-01-15T10:30:00Z"
      }
    ],
    "has_data": true
  }
}
```

### GET /analysis/exam-prediction
**응답:**
```json
{
  "data": {
    "predicted_score": 75.5,
    "pass_probability": "high",
    "is_passing": true,
    "cutoff_subjects": []
  }
}
```

## 구현 상태
- ✅ 통계 카드
- ✅ 합격 예측 섹션
- ✅ 최근 학습 활동
- ✅ 빠른 실행 버튼
- ✅ 온보딩 메시지
- ✅ Backend API

## 파일 위치
- **Frontend**: `/frontend/src/app/(dashboard)/page.tsx`
- **Backend**: `/backend/app/services/analysis.py`
- **Layout**: Mantine UI Components
