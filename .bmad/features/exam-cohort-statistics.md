# Feature: Exam Cohort Statistics Dashboard

## Overview
같은 시험일정에 도전하는 응시자들의 통계를 대시보드에 표시하여 경쟁적 학습 동기를 부여하는 기능입니다. Duolingo의 리그 시스템, Strava의 세그먼트 리더보드와 유사한 게이미피케이션 요소를 자격증 학습에 적용합니다.

## User Story
**AS A** 자격증 시험 준비생
**I WANT** 나와 같은 시험일정을 준비하는 다른 응시자들의 통계와 나의 상대적 위치를 보고 싶다
**SO THAT** 경쟁 의식을 통해 학습 동기를 높이고, 내 학습 진도를 객관적으로 평가할 수 있다

## Business Value
- **학습 동기 부여**: 경쟁 요소를 통한 지속적 학습 유도
- **사용자 참여도 향상**: 리더보드 순위 향상을 위한 반복 방문 증가
- **커뮤니티 형성**: 같은 목표를 가진 사용자 간 유대감 형성
- **데이터 인사이트**: 문제별 난이도, 사용자 학습 패턴 분석 가능
- **바이럴 효과**: 순위 공유를 통한 자연스러운 플랫폼 홍보

## Feature Requirements

### FR-1: Cohort Definition
시험 코호트(Cohort) 정의 및 자동 그룹화

**Cohort 정의:**
- 동일한 자격증 + 동일한 시험 회차 + 동일한 시험 유형(필기/실기)을 준비하는 사용자 그룹
- 예: "정보처리기사 2026년 1회 필기" 코호트

**Acceptance Criteria:**
- [ ] 사용자가 학습 세트 생성 시 자동으로 코호트에 배정
- [ ] 코호트 ID 생성 규칙: `{cert_id}_{year}_{round}_{exam_type}`
  - 예: `cert_pe_info_2026_1_written`
- [ ] 시험일 기준 D-90일 전부터 코호트 활성화
- [ ] 시험 당일 이후 D+30일까지 통계 유지 (아카이빙)
- [ ] 사용자는 여러 코호트에 동시 참여 가능

### FR-2: Cohort Statistics Display
코호트 통계 대시보드 위젯

**표시 정보:**
1. **전체 응시자 수**
   - 해당 코호트에 참여 중인 총 사용자 수
   - 전일 대비 증가/감소 표시

2. **총 문제 풀이 횟수**
   - 코호트 전체의 누적 문제 풀이 횟수
   - 일평균 문제 풀이 수

3. **평균 정답률**
   - 코호트 전체의 평균 정답률 (%)
   - 과목별 평균 정답률

4. **나의 등수**
   - 정답률 기준 순위
   - 상위 N% 표시
   - 전일 대비 순위 변동 (▲2, ▼1 등)

5. **나의 통계**
   - 나의 정답률
   - 나의 총 문제 풀이 수
   - 나의 학습 일수 (연속 학습 일수 포함)
   - 예상 합격 가능성 (%)

**Acceptance Criteria:**
- [ ] 대시보드 메인 페이지에 "시험 코호트 통계" 섹션 추가
- [ ] 실시간 업데이트 (캐싱 5분)
- [ ] 응답속도 최적화 (1초 이내)
- [ ] 모바일 반응형 디자인
- [ ] 통계 데이터 시각화 (차트/그래프)

### FR-3: Leaderboard System
코호트 리더보드 (순위표)

**리더보드 기준:**
- **기본 랭킹**: 정답률 (동점 시 문제 풀이 수로 정렬)
- **옵션 랭킹**:
  - 문제 풀이 횟수 랭킹
  - 연속 학습일 랭킹
  - 과목별 정답률 랭킹

**표시 정보:**
- Top 10 사용자 (닉네임 또는 익명)
- 각 사용자의 정답률, 문제 풀이 수, 뱃지
- 나의 순위 하이라이트

**Acceptance Criteria:**
- [ ] 리더보드 페이지 구현 (`/cohort/{cohort_id}/leaderboard`)
- [ ] 페이지네이션 (50명씩)
- [ ] 랭킹 필터링 옵션
- [ ] 익명 모드 옵션 (프로필 공개/비공개 설정)
- [ ] 부정행위 방지: 동일 문제 반복 풀이 제한

### FR-4: Cohort Progress Tracking
코호트 전체의 학습 진행도 추적

**표시 정보:**
1. **일별 활동 그래프**
   - 일별 총 문제 풀이 수 추이 (라인 차트)
   - 일별 활성 사용자 수 추이

2. **과목별 진행도**
   - 각 과목별 평균 완료율
   - 과목별 평균 정답률

3. **난이도별 정답률**
   - 쉬움/보통/어려움별 평균 정답률

4. **D-Day 타임라인**
   - 시험까지 남은 일수
   - 권장 학습 진도와 실제 진도 비교

**Acceptance Criteria:**
- [ ] 시각화 라이브러리 사용 (Chart.js or Recharts)
- [ ] 주간/월간 통계 조회 옵션
- [ ] CSV/PDF 내보내기 기능

### FR-5: Social Features & Gamification
사회적 요소 및 게이미피케이션

**기능:**
1. **성취 뱃지**
   - "Top 10 진입" 뱃지
   - "100문제 돌파" 뱃지
   - "7일 연속 학습" 뱃지

2. **랭킹 알림**
   - 순위 변동 푸시 알림
   - 주간 요약 리포트 이메일

3. **스터디 그룹**
   - 같은 코호트 내 스터디 그룹 생성
   - 그룹 평균 vs 전체 평균 비교

4. **격려 메시지**
   - 순위 하락 시 격려 메시지
   - 목표 달성 시 축하 메시지

**Acceptance Criteria:**
- [ ] 뱃지 시스템 DB 스키마 설계
- [ ] 뱃지 획득 조건 로직 구현
- [ ] 알림 시스템 통합
- [ ] 스터디 그룹 CRUD API

## Technical Specifications

### Database Schema

```sql
-- 시험 코호트 테이블
CREATE TABLE exam_cohorts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cohort_code VARCHAR(200) UNIQUE NOT NULL,  -- cert_id_year_round_examtype
    certification_id VARCHAR(100) NOT NULL,
    exam_year INTEGER NOT NULL,
    exam_round VARCHAR(20) NOT NULL,
    exam_type VARCHAR(20) NOT NULL,  -- written, practical
    exam_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(certification_id, exam_year, exam_round, exam_type)
);

-- 사용자 코호트 참여 테이블
CREATE TABLE user_cohort_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    cohort_id UUID NOT NULL REFERENCES exam_cohorts(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_anonymous BOOLEAN DEFAULT false,  -- 리더보드 익명 표시 여부

    UNIQUE(user_id, cohort_id)
);

-- 코호트 통계 집계 테이블 (캐시용)
CREATE TABLE cohort_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cohort_id UUID NOT NULL REFERENCES exam_cohorts(id) ON DELETE CASCADE,
    stats_date DATE NOT NULL DEFAULT CURRENT_DATE,

    total_members INTEGER DEFAULT 0,
    active_members INTEGER DEFAULT 0,  -- 최근 7일 내 활동
    total_questions_solved INTEGER DEFAULT 0,
    average_accuracy_rate DECIMAL(5,2) DEFAULT 0.00,

    -- 과목별 통계 (JSONB)
    subject_stats JSONB DEFAULT '{}',

    -- 난이도별 통계 (JSONB)
    difficulty_stats JSONB DEFAULT '{}',

    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(cohort_id, stats_date)
);

-- 사용자별 코호트 통계
CREATE TABLE user_cohort_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    cohort_id UUID NOT NULL REFERENCES exam_cohorts(id) ON DELETE CASCADE,

    total_questions_solved INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    accuracy_rate DECIMAL(5,2) DEFAULT 0.00,
    consecutive_study_days INTEGER DEFAULT 0,
    last_activity_date DATE,

    -- 과목별 통계
    subject_accuracy JSONB DEFAULT '{}',

    -- 랭킹 정보
    rank INTEGER,
    rank_percentile DECIMAL(5,2),
    last_rank_update TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(user_id, cohort_id)
);

-- 인덱스
CREATE INDEX idx_cohorts_code ON exam_cohorts(cohort_code);
CREATE INDEX idx_cohorts_exam_date ON exam_cohorts(exam_date);
CREATE INDEX idx_cohorts_active ON exam_cohorts(is_active) WHERE is_active = true;

CREATE INDEX idx_cohort_memberships_user ON user_cohort_memberships(user_id);
CREATE INDEX idx_cohort_memberships_cohort ON user_cohort_memberships(cohort_id);

CREATE INDEX idx_cohort_stats_cohort_date ON cohort_statistics(cohort_id, stats_date);

CREATE INDEX idx_user_cohort_stats_user ON user_cohort_stats(user_id);
CREATE INDEX idx_user_cohort_stats_cohort_rank ON user_cohort_stats(cohort_id, rank);
CREATE INDEX idx_user_cohort_stats_accuracy ON user_cohort_stats(cohort_id, accuracy_rate DESC);
```

### API Endpoints

#### 1. Cohort Management
```
POST   /api/v1/cohorts                     # 코호트 생성 (자동)
GET    /api/v1/cohorts/{cohort_id}         # 코호트 정보 조회
POST   /api/v1/cohorts/{cohort_id}/join    # 코호트 가입
DELETE /api/v1/cohorts/{cohort_id}/leave   # 코호트 탈퇴
```

#### 2. Cohort Statistics
```
GET /api/v1/cohorts/{cohort_id}/statistics
```

**Response Example:**
```json
{
  "cohort": {
    "id": "uuid",
    "code": "cert_pe_info_2026_1_written",
    "certification_name": "정보처리기사",
    "exam_date": "2026-03-15",
    "d_day": 45
  },
  "statistics": {
    "total_members": 1234,
    "active_members": 892,
    "total_questions_solved": 145678,
    "average_accuracy_rate": 72.5,
    "subject_stats": {
      "소프트웨어 설계": {
        "avg_accuracy": 75.2,
        "completion_rate": 68.5
      },
      "소프트웨어 개발": {
        "avg_accuracy": 70.1,
        "completion_rate": 65.3
      }
    }
  },
  "my_stats": {
    "rank": 45,
    "rank_percentile": 96.4,
    "rank_change": 2,  // 양수: 상승, 음수: 하락
    "accuracy_rate": 85.3,
    "total_questions_solved": 523,
    "consecutive_study_days": 14
  }
}
```

#### 3. Leaderboard
```
GET /api/v1/cohorts/{cohort_id}/leaderboard?page=1&limit=50&sort=accuracy
```

**Response Example:**
```json
{
  "cohort_id": "uuid",
  "page": 1,
  "total_pages": 25,
  "total_members": 1234,
  "leaderboard": [
    {
      "rank": 1,
      "user_id": "uuid",
      "display_name": "StudyHero",
      "is_anonymous": false,
      "accuracy_rate": 95.8,
      "total_questions": 1250,
      "badges": ["top_10", "100_questions", "7_day_streak"]
    },
    {
      "rank": 2,
      "user_id": "uuid",
      "display_name": "익명_A3F2",
      "is_anonymous": true,
      "accuracy_rate": 94.2,
      "total_questions": 980,
      "badges": ["top_10", "100_questions"]
    }
  ],
  "my_position": {
    "rank": 45,
    "rank_percentile": 96.4
  }
}
```

#### 4. Progress Tracking
```
GET /api/v1/cohorts/{cohort_id}/progress?period=week
```

**Response Example:**
```json
{
  "period": "week",
  "daily_activity": [
    {
      "date": "2026-01-29",
      "total_questions": 5420,
      "active_users": 456
    },
    {
      "date": "2026-01-30",
      "total_questions": 6123,
      "active_users": 512
    }
  ],
  "subject_progress": [
    {
      "subject": "소프트웨어 설계",
      "avg_completion": 68.5,
      "avg_accuracy": 75.2
    }
  ]
}
```

## Frontend Components

### CohortStatsWidget Component
```tsx
interface CohortStatsWidgetProps {
  cohortId: string;
  compact?: boolean;
}

export function CohortStatsWidget({ cohortId, compact }: CohortStatsWidgetProps) {
  // 코호트 통계 위젯 UI
  // - 전체 응시자 수
  // - 평균 정답률
  // - 나의 순위
  // - D-Day 카운터
}
```

### LeaderboardTable Component
```tsx
interface LeaderboardTableProps {
  cohortId: string;
  currentUserId: string;
  sortBy?: "accuracy" | "questions" | "streak";
}

export function LeaderboardTable({ cohortId, currentUserId, sortBy }: LeaderboardTableProps) {
  // 리더보드 테이블 UI
  // - 순위, 사용자명, 정답률, 문제 수
  // - 나의 순위 하이라이트
  // - 페이지네이션
}
```

### CohortProgressChart Component
```tsx
interface CohortProgressChartProps {
  cohortId: string;
  chartType: "daily_activity" | "subject_progress" | "difficulty";
}

export function CohortProgressChart({ cohortId, chartType }: CohortProgressChartProps) {
  // 진행도 차트 UI (Chart.js or Recharts)
}
```

## Implementation Phases

### Phase 1: Core Infrastructure (Priority: High)
- [ ] 코호트 DB 스키마 생성 및 마이그레이션
- [ ] 코호트 자동 생성 로직 구현 (학습 세트 생성 시)
- [ ] 기본 통계 집계 배치 작업 (매시간 실행)
- [ ] Cohort Statistics API 구현
- [ ] 대시보드에 코호트 통계 위젯 추가

### Phase 2: Leaderboard & Ranking (Priority: High)
- [ ] 랭킹 계산 로직 구현
- [ ] Leaderboard API 구현
- [ ] 리더보드 페이지 UI 구현
- [ ] 익명 모드 기능
- [ ] 실시간 순위 업데이트

### Phase 3: Gamification (Priority: Medium)
- [ ] 성취 뱃지 시스템
- [ ] 랭킹 변동 알림
- [ ] 주간 요약 리포트
- [ ] 스터디 그룹 기능

### Phase 4: Advanced Analytics (Priority: Low)
- [ ] 과목별/난이도별 상세 통계
- [ ] 진행도 차트 시각화
- [ ] 예상 합격 가능성 AI 모델
- [ ] 통계 내보내기 (CSV/PDF)

## Performance Considerations

### Caching Strategy
- 코호트 전체 통계: Redis 캐싱 (5분 TTL)
- 리더보드 Top 100: Redis 캐싱 (10분 TTL)
- 사용자별 통계: 실시간 조회 (캐싱 없음)

### Batch Processing
- 매시간 정각: 코호트 통계 집계
- 매일 자정: 전일 통계 아카이빙
- 매주 월요일: 주간 리포트 발송

### Database Optimization
- 통계 집계용 Materialized View 활용
- 파티셔닝: 날짜별로 통계 테이블 파티션
- 인덱스 최적화: 복합 인덱스 (cohort_id, accuracy_rate DESC)

## Privacy & Security

### 개인정보 보호
- 익명 모드 옵션 제공
- 리더보드 노출 동의 필요
- 개인 통계는 본인만 조회 가능

### 부정행위 방지
- 동일 문제 반복 풀이 제한 (1일 3회)
- 비정상적 패턴 감지 (자동 풀이 봇)
- 신고 시스템

## Success Metrics
- 코호트 참여율 (전체 사용자 대비)
- 리더보드 조회수
- 순위 향상을 위한 문제 풀이 증가율
- 연속 학습 일수 평균
- 리더보드 공유 빈도

## Related Documentation
- [Duolingo Leaderboard System](https://blog.duolingo.com/leaderboards/)
- [Strava Segment Leaderboards](https://www.strava.com/features/segments)
- [Khan Academy Progress Tracking](https://www.khanacademy.org/)

## Change Log
| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2026-01-06 | 1.0 | Initial feature specification | Claude Code |
