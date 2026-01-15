# Knowledge Graph API Reference

## Base URL
```
https://api.certigraph.com/api/v1
```

## Authentication
모든 요청에 JWT 토큰 필수:
```
Authorization: Bearer {JWT_TOKEN}
```

---

## Knowledge Graph Endpoints

### 1. 그래프 조회

#### GET /study_sets/{study_set_id}/study_materials/{study_material_id}/knowledge_graphs
전체 그래프 조회 (노드 + 엣지 + 통계)

**Parameters:**
- None

**Response:**
```json
{
  "success": true,
  "data": {
    "nodes": [
      {
        "id": 1,
        "name": "Polynomial Equations",
        "level": "concept",
        "description": "Understanding and solving polynomial equations",
        "difficulty": 3,
        "importance": 4,
        "color": "green",
        "mastery_level": 0.85,
        "metadata": {}
      }
    ],
    "edges": [
      {
        "id": 1,
        "from_id": 2,
        "from_name": "Linear Systems",
        "to_id": 1,
        "to_name": "Polynomial Equations",
        "relationship_type": "prerequisite",
        "relationship_name": "선수 개념",
        "weight": 0.8,
        "reasoning": "Linear algebra foundation needed"
      }
    ],
    "stats": {
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
      },
      "avg_connections_per_node": 1.33
    }
  }
}
```

---

### 2. 노드 관리

#### GET /study_sets/{study_set_id}/study_materials/{study_material_id}/knowledge_graphs/nodes
노드 목록 조회 (페이징 지원)

**Parameters:**
```
page: integer (default: 1)
per_page: integer (default: 20)
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Derivatives",
      "level": "concept",
      "description": "Computing and applying derivatives",
      "difficulty": 4,
      "importance": 5,
      "parent_name": "Calculus",
      "active": true,
      "color": "yellow",
      "mastery_level": 0.65,
      "prerequisites": ["Polynomial Equations"],
      "dependents": ["Integrals"],
      "children_count": 1,
      "mastery_details": {
        "status": "learning",
        "attempts": 5,
        "correct_attempts": 4,
        "accuracy": 80.0,
        "last_tested_at": "2024-01-15T10:30:00Z",
        "total_time_minutes": 45
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

#### GET /knowledge_nodes/{id}
개별 노드 상세 조회

**Response:**
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
    "mastery_details": {
      "status": "learning",
      "attempts": 5,
      "correct_attempts": 4,
      "accuracy": 80.0,
      "last_tested_at": "2024-01-15T10:30:00Z",
      "total_time_minutes": 45
    }
  }
}
```

#### GET /knowledge_nodes/{id}/prerequisites
선수 개념 조회 (모든 직간접 선수 개념)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 3,
      "name": "Polynomial Equations",
      "level": "concept",
      "difficulty": 3,
      "importance": 4,
      "color": "green",
      "mastery_level": 0.92
    },
    {
      "id": 4,
      "name": "Linear Systems",
      "level": "concept",
      "difficulty": 2,
      "importance": 4,
      "color": "green",
      "mastery_level": 0.95
    }
  ]
}
```

#### GET /knowledge_nodes/{id}/dependents
후속 개념 조회 (이 개념이 선수 개념인 모든 개념)

---

### 3. 엣지(관계) 조회

#### GET /study_sets/{study_set_id}/study_materials/{study_material_id}/knowledge_graphs/edges
관계 목록 조회 (페이징 지원)

**Parameters:**
```
page: integer (default: 1)
per_page: integer (default: 50)
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "from_id": 2,
      "from_name": "Polynomial Equations",
      "to_id": 3,
      "to_name": "Derivatives",
      "relationship_type": "prerequisite",
      "relationship_name": "선수 개념",
      "weight": 0.8,
      "reasoning": "Derivatives of polynomials are fundamental",
      "active": true
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 1,
    "total_count": 20
  }
}
```

---

### 4. 통계 및 분석

#### GET /study_sets/{study_set_id}/study_materials/{study_material_id}/knowledge_graphs/statistics
그래프 통계

**Response:**
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
    "nodes_by_difficulty": {
      "1": 2,
      "2": 3,
      "3": 5,
      "4": 3,
      "5": 2
    },
    "relationships_by_type": {
      "prerequisite": 8,
      "related_to": 5,
      "part_of": 7,
      "example_of": 0,
      "leads_to": 0
    },
    "avg_connections_per_node": 1.33
  }
}
```

#### GET /study_sets/{study_set_id}/study_materials/{study_material_id}/knowledge_graphs/analysis
학습 분석 및 진도

**Response:**
```json
{
  "success": true,
  "data": {
    "weak_areas": [
      {
        "node": {
          "id": 7,
          "name": "Integrals",
          "difficulty": 4
        },
        "mastery_level": 0.3,
        "attempts": 10,
        "accuracy": 30.0,
        "status": "weak"
      }
    ],
    "strong_areas": [
      {
        "node": {
          "id": 4,
          "name": "Linear Systems",
          "difficulty": 2
        },
        "mastery_level": 0.95,
        "attempts": 20,
        "accuracy": 95.0,
        "status": "mastered"
      }
    ],
    "recommended_path": [
      {
        "id": 3,
        "name": "Polynomial Equations",
        "level": "concept"
      }
    ],
    "progress_percentage": 45.5,
    "overall_difficulty": 3.2,
    "dashboard_summary": {
      "progress_percentage": 45.5,
      "weak_areas_count": 3,
      "strong_areas_count": 5,
      "overall_difficulty": 3.2,
      "recent_activity": {
        "total_attempts_7d": 25,
        "avg_accuracy_7d": 75.5,
        "recently_tested": [
          {
            "name": "Derivatives",
            "accuracy": 80.0,
            "last_tested_at": "2024-01-15T10:30:00Z",
            "mastery_level": 0.65
          }
        ]
      }
    }
  }
}
```

#### GET /study_sets/{study_set_id}/study_materials/{study_material_id}/knowledge_graphs/concept_map
3D 시각화용 개념 맵

**Response:**
```json
{
  "success": true,
  "data": {
    "nodes": [
      {
        "id": 1,
        "name": "Derivatives",
        "level": "concept",
        "difficulty": 4,
        "importance": 5,
        "color": "yellow",
        "mastery_level": 0.65,
        "x": 345,
        "y": 289,
        "z": 120
      }
    ],
    "edges": [
      {
        "id": 1,
        "source": 2,
        "target": 1,
        "type": "prerequisite",
        "weight": 0.8,
        "label": "선수 개념"
      }
    ],
    "layout": "force-directed"
  }
}
```

#### GET /study_sets/{study_set_id}/study_materials/{study_material_id}/knowledge_graphs/learning_strategy
개인화된 학습 전략

**Response:**
```json
{
  "success": true,
  "data": {
    "focus_area": "Integrals",
    "current_mastery": 0.3,
    "current_accuracy": 30.0,
    "blocker_concepts": [
      "Derivatives",
      "Polynomial Equations"
    ],
    "next_steps": [
      "먼저 다음 선수 개념을 학습하세요: Derivatives, Polynomial Equations",
      "각 선수 개념마다 5-10개의 문제를 풀어보세요"
    ],
    "estimated_time_hours": 3.5
  }
}
```

---

### 5. 그래프 구축

#### POST /study_sets/{study_set_id}/study_materials/{study_material_id}/knowledge_graphs/build
PDF에서 지식 그래프 자동 구축

**Parameters:**
- None (기존 질문 데이터 기반)

**Response:**
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

---

## User Mastery Endpoints

### 6. 개별 숙달도 관리

#### GET /knowledge_nodes/{knowledge_node_id}/mastery
특정 개념의 사용자 숙달도 조회

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 10,
    "user_id": 1,
    "knowledge_node_id": 5,
    "knowledge_node_name": "Derivatives",
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

#### PUT /knowledge_nodes/{knowledge_node_id}/mastery
문제 풀이 후 숙달도 업데이트

**Request:**
```json
{
  "attempt": {
    "correct": true,
    "time_minutes": 5
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 10,
    "knowledge_node_id": 5,
    "mastery_level": 0.67,
    "status": "learning",
    "color": "yellow",
    "attempts": 6,
    "correct_attempts": 5,
    "accuracy": 83.33
  }
}
```

---

### 7. 대량 숙달도 조회

#### GET /study_materials/{study_material_id}/masteries
학습 자료의 모든 숙달도 조회 (페이징)

**Parameters:**
```
page: integer (default: 1)
per_page: integer (default: 20)
```

**Response:**
```json
{
  "success": true,
  "data": [...],
  "pagination": {
    "current_page": 1,
    "total_pages": 2,
    "total_count": 35
  }
}
```

#### GET /masteries/by_status/{status}
상태별 숙달도 조회

**Parameters:**
```
status: "untested" | "learning" | "mastered" | "weak" (required)
page: integer (default: 1)
per_page: integer (default: 20)
```

**Example:**
```
GET /masteries/by_status/weak?page=1&per_page=10
```

#### GET /masteries/weak_areas
약한 영역 조회 (mastery_level 낮은 순서)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 12,
      "knowledge_node_id": 7,
      "knowledge_node_name": "Integrals",
      "mastery_level": 0.25,
      "color": "red",
      "accuracy": 25.0,
      "attempts": 12,
      "last_tested_at": "2024-01-14T15:20:00Z"
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 1,
    "total_count": 3
  }
}
```

#### GET /masteries/strong_areas
강한 영역 조회 (mastery_level 높은 순서)

#### GET /masteries/statistics
전체 통계 조회

**Response:**
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

---

## Error Responses

### 401 Unauthorized
```json
{
  "success": false,
  "message": "Unauthorized - Invalid or missing JWT token"
}
```

### 403 Forbidden
```json
{
  "success": false,
  "message": "Forbidden - Access denied to this resource"
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Not found"
}
```

### 422 Unprocessable Entity
```json
{
  "success": false,
  "message": "Invalid status. Must be one of: untested, learning, mastered, weak"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "message": "Internal server error"
}
```

---

## Rate Limiting

API는 다음의 rate limit을 적용합니다:
- 일반 사용자: 분당 60 요청
- Premium 사용자: 분당 300 요청
- 관리자: 무제한

Rate limit 헤더:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1642300800
```

---

## Pagination

### Page-based Pagination
```json
{
  "pagination": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 100,
    "per_page": 20
  }
}
```

**Parameters:**
```
page: 1-based page number (default: 1)
per_page: items per page (default: 20, max: 100)
```

---

## Examples

### 1. 학생 대시보드 로드
```bash
# 분석 데이터 조회
curl -X GET https://api.certigraph.com/api/v1/study_sets/1/study_materials/5/knowledge_graphs/analysis \
  -H "Authorization: Bearer JWT_TOKEN"

# 개념 맵 조회
curl -X GET https://api.certigraph.com/api/v1/study_sets/1/study_materials/5/knowledge_graphs/concept_map \
  -H "Authorization: Bearer JWT_TOKEN"

# 통계 조회
curl -X GET https://api.certigraph.com/api/v1/masteries/statistics \
  -H "Authorization: Bearer JWT_TOKEN"
```

### 2. 문제 풀이 후 처리
```bash
# 1. 문제 풀이
# ... 사용자가 문제를 풀고 정답/오답 판정

# 2. 숙달도 업데이트
curl -X PUT https://api.certigraph.com/api/v1/knowledge_nodes/5/mastery \
  -H "Authorization: Bearer JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "attempt": {
      "correct": true,
      "time_minutes": 5
    }
  }'
```

### 3. 약점 분석 및 학습 경로
```bash
# 약점 영역 확인
curl -X GET https://api.certigraph.com/api/v1/masteries/weak_areas \
  -H "Authorization: Bearer JWT_TOKEN"

# 학습 전략 조회
curl -X GET https://api.certigraph.com/api/v1/study_sets/1/study_materials/5/knowledge_graphs/learning_strategy \
  -H "Authorization: Bearer JWT_TOKEN"
```

---

## SDK Examples

### Ruby on Rails
```ruby
class StudyDashboardController < ApplicationController
  def show
    user = current_user
    study_material = StudyMaterial.find(params[:study_material_id])
    analysis = GraphAnalysisService.new(user, study_material)

    @weak_areas = analysis.identify_weak_areas
    @strong_areas = analysis.identify_strong_areas
    @recommended_path = analysis.recommend_learning_path
    @strategy = analysis.suggest_learning_strategy
  end
end
```

### JavaScript/React
```javascript
const fetchAnalysis = async (studySetId, materialId) => {
  const response = await fetch(
    `/api/v1/study_sets/${studySetId}/study_materials/${materialId}/knowledge_graphs/analysis`,
    {
      headers: { 'Authorization': `Bearer ${token}` }
    }
  );
  return response.json();
};

const updateMastery = async (nodeId, correct, timeMinutes) => {
  const response = await fetch(
    `/api/v1/knowledge_nodes/${nodeId}/mastery`,
    {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        attempt: { correct, time_minutes: timeMinutes }
      })
    }
  );
  return response.json();
};
```
