# Knowledge Graph Implementation Guide

## Overview

Knowledge Graph는 CertiGraph의 핵심 시스템으로, 학생들의 학습 진도를 추적하고 개념 간의 관계를 관리하여 약점 분석 및 학습 경로 추천을 제공합니다.

## Architecture

### Database Schema

#### 1. knowledge_nodes (지식 노드)
- **목적**: 개념, 챕터, 주제 저장
- **주요 필드**:
  - `name`: 개념명 (예: "미분", "적분")
  - `level`: 계층 (subject, chapter, concept, detail)
  - `difficulty`: 난이도 (1-5)
  - `importance`: 중요도 (1-5)
  - `description`: 설명
  - `parent_name`: 상위 개념명
  - `metadata`: JSON 추가 정보

#### 2. knowledge_edges (노드 간 관계)
- **목적**: 개념 간의 관계 정의
- **관계 유형**:
  - `prerequisite`: 선수 개념 (A를 하려면 B를 먼저 해야 함)
  - `related_to`: 관련 개념 (함께 공부하면 도움됨)
  - `part_of`: 상위 개념 (계층 구조)
  - `example_of`: 예시 관계
  - `leads_to`: 다음 개념

#### 3. user_masteries (사용자 숙달도)
- **목적**: 사용자별 개념 숙달도 추적
- **주요 필드**:
  - `mastery_level`: 0.0 ~ 1.0 숙달도
  - `status`: untested, learning, mastered, weak
  - `color`: gray, green, red, yellow (시각화용)
  - `attempts`: 시도 횟수
  - `correct_attempts`: 정답 횟수
  - `history`: JSON 시도 기록

### 온톨로지 구조

```
Subject (과목)
  ├── Chapter (챕터)
  │   ├── Concept (핵심 개념)
  │   │   └── Detail (세부사항)
```

예시: 수학
```
Mathematics
├── Algebra
│   ├── Polynomial Equations
│   │   └── Quadratic Formula
│   ├── Linear Systems
│   └── Matrix Operations
└── Calculus
    ├── Derivatives
    │   └── Fundamental Theorem of Calculus
    └── Integrals
```

## Service 클래스

### 1. KnowledgeGraphService

**역할**: 그래프 구축 및 쿼리

주요 메서드:
```ruby
# 질문에서 개념 추출
extract_concepts(question)

# 개념 노드 생성/업데이트
create_or_update_node(concept_data)

# 관계 생성
create_relationship(relationship_data, concept_nodes)

# 온톨로지 계층 구조 구축
build_ontology_hierarchy

# 경로 탐색 (BFS)
find_learning_path(from_node, to_node)

# 그래프 통계
graph_statistics

# 그래프 데이터 내보내기
export_graph_as_json(user)
```

### 2. GraphAnalysisService

**역할**: 학습 분석 및 추천

주요 메서드:
```ruby
# 약점 식별 (빨간 노드)
identify_weak_areas

# 강점 식별 (초록 노드)
identify_strong_areas

# 학습 경로 추천
recommend_learning_path(limit: 10)

# 개념 맵 생성 (시각화용)
generate_concept_map

# 학습 진도 계산
calculate_progress_percentage

# 난이도 계산
calculate_overall_difficulty

# 재학습 필요 개념
identify_review_needed(days: 7)

# 학습 전략 제시
suggest_learning_strategy

# 의존성 분석
analyze_dependency_chains

# 대시보드 요약
dashboard_summary
```

## API Endpoints

### Knowledge Graph 조회

#### GET /api/v1/study_sets/:study_set_id/study_materials/:study_material_id/knowledge_graphs
전체 그래프 조회
```json
{
  "success": true,
  "data": {
    "nodes": [...],
    "edges": [...],
    "stats": {
      "total_nodes": 15,
      "total_edges": 20,
      "avg_connections_per_node": 1.33
    }
  }
}
```

#### GET /api/v1/study_sets/:study_set_id/study_materials/:study_material_id/knowledge_graphs/nodes
노드 목록 조회 (페이징)
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Derivatives",
      "level": "concept",
      "difficulty": 4,
      "importance": 5,
      "color": "yellow",
      "mastery_level": 0.65,
      "prerequisites": ["Polynomial Equations"],
      "mastery_details": {
        "status": "learning",
        "attempts": 5,
        "accuracy": 80.0,
        "last_tested_at": "2024-01-15T10:30:00Z"
      }
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 2,
    "total_count": 25
  }
}
```

#### GET /api/v1/study_sets/:study_set_id/study_materials/:study_material_id/knowledge_graphs/statistics
그래프 통계
```json
{
  "success": true,
  "data": {
    "total_nodes": 15,
    "total_edges": 20,
    "nodes_by_level": {
      "subject": 1,
      "chapter": 2,
      "concept": 10,
      "detail": 2
    },
    "relationships_by_type": {
      "prerequisite": 8,
      "related_to": 5,
      "part_of": 7
    }
  }
}
```

#### GET /api/v1/study_sets/:study_set_id/study_materials/:study_material_id/knowledge_graphs/analysis
학습 분석
```json
{
  "success": true,
  "data": {
    "weak_areas": [
      {
        "node": {...},
        "mastery_level": 0.2,
        "attempts": 5,
        "accuracy": 20.0,
        "status": "weak"
      }
    ],
    "strong_areas": [...],
    "recommended_path": [...],
    "progress_percentage": 45.5,
    "overall_difficulty": 3.2,
    "dashboard_summary": {
      "weak_areas_count": 3,
      "strong_areas_count": 5,
      "recent_activity": {...}
    }
  }
}
```

#### GET /api/v1/knowledge_nodes/:id
개별 노드 상세 조회
```json
{
  "success": true,
  "data": {
    "id": 5,
    "name": "Derivatives",
    "level": "concept",
    "description": "Computing and applying derivatives",
    "difficulty": 4,
    "importance": 5,
    "color": "yellow",
    "mastery_level": 0.65,
    "prerequisites": ["Polynomial Equations"],
    "dependents": ["Integrals"],
    "children_count": 2,
    "mastery_details": {...}
  }
}
```

#### GET /api/v1/knowledge_nodes/:id/prerequisites
선수 개념 조회
```json
{
  "success": true,
  "data": [
    {
      "id": 3,
      "name": "Polynomial Equations",
      "level": "concept",
      "difficulty": 3,
      ...
    }
  ]
}
```

### 사용자 숙달도

#### GET /api/v1/knowledge_nodes/:knowledge_node_id/mastery
개별 개념의 사용자 숙달도 조회
```json
{
  "success": true,
  "data": {
    "id": 10,
    "user_id": 1,
    "knowledge_node_id": 5,
    "mastery_level": 0.65,
    "status": "learning",
    "color": "yellow",
    "attempts": 5,
    "correct_attempts": 4,
    "accuracy": 80.0,
    "last_tested_at": "2024-01-15T10:30:00Z",
    "total_time_minutes": 45,
    "recent_accuracy_7d": 85.5,
    "days_since_last_test": 2
  }
}
```

#### PUT /api/v1/knowledge_nodes/:knowledge_node_id/mastery
숙달도 업데이트 (문제 푼 후)
```bash
curl -X PUT http://localhost:3000/api/v1/knowledge_nodes/5/mastery \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer JWT_TOKEN" \
  -d '{
    "attempt": {
      "correct": true,
      "time_minutes": 10
    }
  }'
```

#### GET /api/v1/masteries/weak_areas
약점 영역 조회
```json
{
  "success": true,
  "data": [
    {
      "id": 10,
      "knowledge_node_id": 8,
      "knowledge_node_name": "Integrals",
      "mastery_level": 0.3,
      "color": "red",
      "accuracy": 30.0,
      ...
    }
  ]
}
```

#### GET /api/v1/masteries/strong_areas
강점 영역 조회

#### GET /api/v1/masteries/statistics
전체 통계 조회
```json
{
  "success": true,
  "data": {
    "total_concepts": 15,
    "mastered": 5,
    "learning": 6,
    "weak": 3,
    "untested": 1,
    "avg_mastery_level": 0.62,
    "avg_accuracy": 75.5,
    "total_study_time_hours": 12.5,
    "progress_percentage": 33.3
  }
}
```

### 그래프 구축

#### POST /api/v1/study_sets/:study_set_id/study_materials/:study_material_id/knowledge_graphs/build
PDF에서 자동으로 그래프 구축
```json
{
  "success": true,
  "message": "Knowledge graph built successfully",
  "data": {
    "concepts_created": 45,
    "questions_processed": 120
  }
}
```

## 색상 코드 (시각화)

| 색상 | 숙달도 범위 | 의미 |
|------|----------|------|
| **초록 (Green)** | 0.8 ~ 1.0 | 숙달함 ✓ |
| **노랑 (Yellow)** | 0.5 ~ 0.8 | 학습 중 △ |
| **빨강 (Red)** | 0.0 ~ 0.5 | 약함 ✗ |
| **회색 (Gray)** | 미테스트 | 미학습 ? |

## 사용 예시

### 1. 학생 대시보드 구축

```ruby
user = User.find(1)
study_material = StudyMaterial.find(10)
analysis = GraphAnalysisService.new(user, study_material)

dashboard_data = {
  progress: analysis.calculate_progress_percentage,
  weak_areas: analysis.identify_weak_areas,
  strong_areas: analysis.identify_strong_areas,
  recommended_next: analysis.recommend_learning_path(limit: 5),
  strategy: analysis.suggest_learning_strategy
}
```

### 2. 문제 풀이 후 숙달도 업데이트

```ruby
user = User.find(1)
question = Question.find(42)
study_material = question.study_material

# 질문 풀이
time_spent = 5 # minutes
answer_correct = true

# Knowledge Graph 업데이트
UpdateUserMasteryJob.perform_async(user.id, question.id, correct: answer_correct, time_minutes: time_spent)

# 학습 분석
AnalyzeLearningGapsJob.perform_async(user.id, study_material.id)
```

### 3. 3D 시각화용 개념 맵 생성

```ruby
analysis = GraphAnalysisService.new(user, study_material)
concept_map = analysis.generate_concept_map

# 응답 예시:
{
  nodes: [
    { id: 1, name: "Derivatives", x: 500, y: 300, z: 100, color: "yellow", ... },
    { id: 2, name: "Integrals", x: 600, y: 400, z: 150, color: "red", ... }
  ],
  edges: [
    { source: 1, target: 2, type: "prerequisite", weight: 0.9 }
  ],
  layout: "force-directed"
}
```

## 배경 작업 (Background Jobs)

### 1. UpdateKnowledgeGraphJob
PDF 처리 시 자동으로 개념 추출 및 그래프 구축

```ruby
UpdateKnowledgeGraphJob.perform_async(question_id)
```

### 2. UpdateUserMasteryJob
학생이 문제를 풀면 숙달도 업데이트

```ruby
UpdateUserMasteryJob.perform_async(user_id, question_id, correct: true, time_minutes: 5)
```

### 3. AnalyzeLearningGapsJob
주기적으로 학습 간격 분석 및 추천

```ruby
AnalyzeLearningGapsJob.perform_async(user_id, study_material_id)
```

## 테스트 데이터 생성

```bash
# 테스트 데이터 생성
rails db:seed:knowledge_graph_seed

# 결과:
# - 1 User (test@graph.com)
# - 1 Study Material
# - 11 Knowledge Nodes
# - 11 Relationships
# - 7 User Masteries
```

## 성능 최적화

### 1. 인덱싱
```sql
-- knowledge_nodes
CREATE INDEX idx_knowledge_nodes_study_material_level ON knowledge_nodes(study_material_id, level);
CREATE INDEX idx_knowledge_nodes_parent_name ON knowledge_nodes(study_material_id, parent_name);

-- knowledge_edges
CREATE INDEX idx_knowledge_edges_types ON knowledge_edges(knowledge_node_id, relationship_type);

-- user_masteries
CREATE INDEX idx_user_masteries_user_status ON user_masteries(user_id, status);
CREATE INDEX idx_user_masteries_color ON user_masteries(color);
```

### 2. 쿼리 최적화
- N+1 쿼리 방지: `includes(:knowledge_node)` 사용
- 대량 업데이트: Bulk insert 사용
- 캐싱: Redis 사용하여 자주 조회하는 데이터 캐시

### 3. 그래프 알고리즘
- BFS: 경로 탐색 (단순 경로)
- 메모이제이션: 반복되는 계산 캐싱
- 제한된 깊이: 무한 루프 방지

## 향후 개선 사항

1. **그래프 레이아웃 알고리즘**: Force-directed 레이아웃으로 3D 좌표 자동 생성
2. **고급 분석**: 커뮤니티 감지, 중심성 분석
3. **협업 필터링**: 비슷한 학생들의 학습 경로 추천
4. **적응형 학습**: 개인 맞춤형 난이도 조절
5. **그래프 업데이트**: 실시간 개념 추출 및 관계 자동 생성

## 문제 해결

### 성능 느림
- 인덱스 확인: `rails db:indexes`
- 쿼리 분석: `rails db:analyze`
- N+1 쿼리 확인: Bullet gem 활성화

### 개념 추출 오류
- LLM 프롬프트 개선
- 파싱 로직 디버깅
- 에러 로그 확인: `tail -f log/sidekiq.log`

### 그래프 구조 문제
- 순환 관계 확인: `detect_cycles` 메서드 추가
- 고아 노드 정리: `cleanup_orphaned_nodes` 메서드 추가
