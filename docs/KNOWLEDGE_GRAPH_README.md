# Knowledge Graph System - 구현 완료 가이드

## 개요

Knowledge Graph는 CertiGraph의 핵심 기능으로, 학생들의 학습 진도를 추적하고 개념 간의 관계를 시각화하여 약점 분석 및 개인화된 학습 경로를 제시합니다.

## 구현 완료 내용

### 1. 데이터 모델

#### 마이그레이션 파일 (3개)
- **20260115120000_create_knowledge_nodes.rb** - 지식 노드 테이블
- **20260115120001_create_knowledge_edges.rb** - 노드 간 관계 테이블
- **20260115120002_create_user_masteries.rb** - 사용자 숙달도 테이블

#### 모델 클래스 (3개)
- **app/models/knowledge_node.rb** - 개념, 챕터, 주제 모델
  - 온톨로지 계층 구조 지원
  - 관계 조작 메서드 (add_prerequisite, add_related_concept 등)
  - 경로 탐색 (all_prerequisites, all_dependents)
  - JSON 직렬화 (to_graph_json, to_detailed_json)

- **app/models/knowledge_edge.rb** - 개념 간 관계
  - 5가지 관계 유형 지원 (prerequisite, related_to, part_of, example_of, leads_to)
  - 관계 강도 (weight: 0.0 ~ 1.0)
  - JSON 직렬화

- **app/models/user_mastery.rb** - 사용자 숙달도 추적
  - 숙달도 계산 (0.0 ~ 1.0)
  - 상태 관리 (untested, learning, mastered, weak)
  - 색상 코딩 (gray, green, red, yellow)
  - 학습 이력 추적 (JSON)
  - 정확도 및 통계 계산

### 2. 서비스 클래스

#### KnowledgeGraphService
```ruby
# 개념 추출 및 그래프 자동 구축
extract_and_build_graph_from_question(question)

# LLM 기반 개념 추출
extract_concepts(question)

# LLM 기반 관계 추출
extract_relationships(question, concepts)

# 개념 노드 생성/업데이트
create_or_update_node(concept_data)

# 관계 생성
create_relationship(relationship_data, concept_nodes)

# 온톨로지 계층 구조 자동 구축
build_ontology_hierarchy

# BFS 기반 경로 탐색
find_learning_path(from_node, to_node)

# 그래프 통계
graph_statistics

# 그래프 데이터 내보내기
export_graph_as_json(user)
```

#### GraphAnalysisService
```ruby
# 약점 식별 (빨간 노드)
identify_weak_areas

# 강점 식별 (초록 노드)
identify_strong_areas

# 개인화된 학습 경로 추천
recommend_learning_path(limit: 10)

# 3D 시각화용 개념 맵
generate_concept_map

# 학습 진도 계산
calculate_progress_percentage

# 가중 평균 난이도 계산
calculate_overall_difficulty

# 재학습 필요한 개념 식별
identify_review_needed(days: 7)

# 대시보드 요약
dashboard_summary

# 개인화된 학습 전략
suggest_learning_strategy

# 선수 개념 의존성 분석
analyze_dependency_chains
```

### 3. 백그라운드 작업

#### UpdateKnowledgeGraphJob
- PDF 처리 시 자동으로 개념 추출 및 그래프 구축
- Sidekiq 기반 비동기 처리
- 실패 시 3회 재시도

#### UpdateUserMasteryJob
- 학생이 문제를 풀면 숙달도 업데이트
- 해당 개념의 mastery_level 갱신
- 상태 및 색상 자동 계산

#### AnalyzeLearningGapsJob
- 주기적 학습 간격 분석
- 약점 분석 및 추천
- 의존성 분석
- Redis 캐시에 결과 저장

### 4. API 컨트롤러 (2개)

#### KnowledgeGraphsController
```ruby
GET  #show              - 전체 그래프 조회
GET  #nodes             - 노드 목록 (페이징)
GET  #edges             - 엣지 목록 (페이징)
GET  #statistics        - 그래프 통계
GET  #analysis          - 학습 분석
GET  #concept_map       - 3D 시각화용 개념 맵
GET  #learning_strategy - 개인화된 학습 전략
POST #build             - 그래프 자동 구축

GET  /knowledge_nodes/:id             - 노드 상세 조회
GET  /knowledge_nodes/:id/prerequisites - 선수 개념 조회
GET  /knowledge_nodes/:id/dependents    - 후속 개념 조회
```

#### UserMasteriesController
```ruby
GET  #show                    - 개별 숙달도 조회
PUT  #update                  - 숙달도 업데이트
GET  #study_material_masteries - 학습 자료의 모든 숙달도
GET  #by_status/:status       - 상태별 숙달도 조회
GET  #weak_areas              - 약점 영역 조회
GET  #strong_areas            - 강점 영역 조회
GET  #statistics              - 통계 조회
```

### 5. 라우팅 설정

```ruby
# Knowledge Graph
resources :study_sets do
  resources :study_materials do
    resources :knowledge_graphs, only: [:show] do
      collection do
        get :nodes, :edges, :statistics, :analysis, :concept_map, :learning_strategy
        post :build
      end
    end
  end
end

# Knowledge Nodes
resources :knowledge_nodes, only: [:show] do
  member do
    get :prerequisites, :dependents
  end
end

# User Masteries
get 'study_materials/:study_material_id/masteries'
get 'masteries/by_status/:status'
get 'masteries/weak_areas'
get 'masteries/strong_areas'
get 'masteries/statistics'
```

### 6. 테스트

#### Factory 파일 (3개)
- `spec/factories/knowledge_nodes.rb` - 노드 팩토리
- `spec/factories/knowledge_edges.rb` - 엣지 팩토리
- `spec/factories/user_masteries.rb` - 숙달도 팩토리

#### 단위 테스트 (2개)
- `spec/models/knowledge_node_spec.rb` - 50+ 테스트
- `spec/models/user_mastery_spec.rb` - 40+ 테스트

#### 서비스 테스트 (2개)
- `spec/services/knowledge_graph_service_spec.rb` - 그래프 서비스 테스트
- `spec/services/graph_analysis_service_spec.rb` - 분석 서비스 테스트

#### 통합 테스트 (1개)
- `spec/integration/knowledge_graph_integration_spec.rb` - API 통합 테스트

### 7. 시드 데이터

#### db/seeds/knowledge_graph_seed.rb
```bash
rails db:seed:knowledge_graph_seed
```

생성되는 테스트 데이터:
- 1 User (test@graph.com)
- 1 Study Material
- 11 Knowledge Nodes (수학 온톨로지)
  - 1 Subject (Mathematics)
  - 2 Chapters (Algebra, Calculus)
  - 7 Concepts (Polynomial, Linear Systems, Matrix, Derivatives, Integrals 등)
  - 1 Detail (Quadratic Formula)
- 11 Relationships (prerequisite, part_of, related_to, example_of)
- 7 User Masteries (다양한 숙달도 상태)

### 8. 문서

#### docs/knowledge-graph-implementation.md
- 아키텍처 설명
- 데이터 모델 상세
- 서비스 메서드 설명
- API 엔드포인트
- 사용 예시
- 성능 최적화 팁

#### docs/knowledge-graph-api.md
- API 레퍼런스
- 요청/응답 예시
- 에러 응답
- 페이징 설명
- SDK 예시

## 설치 및 실행

### 1. 마이그레이션 실행
```bash
cd rails-api
rails db:migrate
```

### 2. 테스트 데이터 생성
```bash
rails db:seed:knowledge_graph_seed
```

### 3. 테스트 실행
```bash
# 모든 테스트
rspec

# 특정 모델 테스트
rspec spec/models/knowledge_node_spec.rb

# 특정 서비스 테스트
rspec spec/services/knowledge_graph_service_spec.rb

# 통합 테스트
rspec spec/integration/knowledge_graph_integration_spec.rb
```

### 4. 로컬 테스트

#### Rails 콘솔에서 테스트
```ruby
# 1. 테스트 사용자 및 자료 생성
user = User.find_or_create_by(email: 'test@graph.com') { |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.name = 'Test User'
}

study_set = StudySet.find_or_create_by(user_id: user.id, name: 'Test Set')
study_material = StudyMaterial.find_or_create_by(
  study_set_id: study_set.id,
  name: 'Test Material'
)

# 2. 개념 생성
math = KnowledgeNode.create!(
  study_material_id: study_material.id,
  name: 'Mathematics',
  level: 'subject',
  difficulty: 4,
  importance: 5
)

algebra = KnowledgeNode.create!(
  study_material_id: study_material.id,
  name: 'Algebra',
  level: 'chapter',
  parent_name: 'Mathematics',
  difficulty: 3,
  importance: 5
)

polynomial = KnowledgeNode.create!(
  study_material_id: study_material.id,
  name: 'Polynomial Equations',
  level: 'concept',
  parent_name: 'Algebra',
  difficulty: 3,
  importance: 4
)

# 3. 관계 생성
algebra.add_part_of(polynomial)
math.add_part_of(algebra)

# 4. 사용자 숙달도 생성 및 업데이트
mastery = UserMastery.create!(
  user_id: user.id,
  knowledge_node_id: polynomial.id,
  mastery_level: 0.5
)

# 문제 풀이 시뮬레이션
5.times do |i|
  mastery.update_with_attempt(correct: i < 4, time_minutes: rand(5..15))
end

puts "Mastery: #{mastery.mastery_level}, Status: #{mastery.status}, Color: #{mastery.color}"

# 5. 분석 서비스 테스트
analysis = GraphAnalysisService.new(user, study_material)
weak_areas = analysis.identify_weak_areas
strong_areas = analysis.identify_strong_areas
progress = analysis.calculate_progress_percentage

puts "Progress: #{progress}%"
puts "Weak areas: #{weak_areas.map { |w| w[:node].name }}"
puts "Strong areas: #{strong_areas.map { |s| s[:node].name }}"

# 6. 그래프 서비스 테스트
graph_service = KnowledgeGraphService.new(study_material)
stats = graph_service.graph_statistics
puts "Graph stats: #{stats}"
```

## 온톨로지 구조 예시

### 수학
```
Mathematics (Subject)
├── Algebra (Chapter)
│   ├── Linear Systems (Concept) [마스터됨 - Green]
│   │   ├── Matrix Operations (Concept) [약함 - Red]
│   │   └── Gaussian Elimination (Detail)
│   ├── Polynomial Equations (Concept) [학습중 - Yellow]
│   │   ├── Quadratic Formula (Detail) [마스터됨 - Green]
│   │   └── Factorization (Detail)
│   └── Quadratic Equations (Concept) [미학습 - Gray]
└── Calculus (Chapter)
    ├── Derivatives (Concept) [학습중 - Yellow]
    │   ├── Power Rule (Detail)
    │   ├── Chain Rule (Detail)
    │   └── Product Rule (Detail)
    └── Integrals (Concept) [약함 - Red]
        ├── Definite Integrals (Detail)
        └── Indefinite Integrals (Detail)
```

### 관계 예시
- Linear Systems → (prerequisite) → Polynomial Equations
- Polynomial Equations → (prerequisite) → Derivatives
- Derivatives → (prerequisite) → Integrals
- Algebra → (part_of) → Mathematics
- Quadratic Formula → (example_of) → Polynomial Equations

## 색상 코드

| 색상 | 범위 | 의미 | 학습 상태 |
|------|------|------|---------|
| 초록 (Green) | 0.8-1.0 | 완벽히 이해함 ✓ | Mastered |
| 노랑 (Yellow) | 0.5-0.8 | 이해하고 있음 △ | Learning |
| 빨강 (Red) | 0.0-0.5 | 이해 부족 ✗ | Weak |
| 회색 (Gray) | 미테스트 | 아직 배우지 않음 ? | Untested |

## 숙달도 계산 알고리즘

```
현재 숙달도 = (정답률 × 최근_가중치) + (이전_숙달도 × 과거_가중치)
                최근_가중치 = 0.7
                과거_가중치 = 0.3
```

예시:
- 정답률: 80% (0.8)
- 이전 숙달도: 0.5
- 계산: (0.8 × 0.7) + (0.5 × 0.3) = 0.56 + 0.15 = 0.71

## 학습 경로 추천 알고리즘

1. 약점 개념 식별
2. 약점 개념의 모든 선수 개념 추출
3. 아직 학습하지 않은 선수 개념 필터링
4. 중요도 높고 난이도 낮은 순서로 정렬
5. 상위 N개 추천

## API 사용 예시

### cURL로 테스트
```bash
# JWT 토큰 생성
TOKEN=$(curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@graph.com","password":"password123"}' | jq -r '.token')

# 그래프 조회
curl -X GET http://localhost:3000/api/v1/study_sets/1/study_materials/1/knowledge_graphs \
  -H "Authorization: Bearer $TOKEN" | jq

# 분석 조회
curl -X GET http://localhost:3000/api/v1/study_sets/1/study_materials/1/knowledge_graphs/analysis \
  -H "Authorization: Bearer $TOKEN" | jq

# 숙달도 업데이트
curl -X PUT http://localhost:3000/api/v1/knowledge_nodes/3/mastery \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"attempt":{"correct":true,"time_minutes":5}}' | jq

# 통계 조회
curl -X GET http://localhost:3000/api/v1/masteries/statistics \
  -H "Authorization: Bearer $TOKEN" | jq
```

## 성능 최적화

### 1. 인덱싱
```sql
CREATE INDEX idx_knowledge_nodes_material_level
  ON knowledge_nodes(study_material_id, level);

CREATE INDEX idx_knowledge_edges_relationship
  ON knowledge_edges(knowledge_node_id, relationship_type, weight);

CREATE INDEX idx_user_masteries_user_status
  ON user_masteries(user_id, status);
```

### 2. N+1 쿼리 방지
```ruby
# Bad
KnowledgeNode.all.each { |node| puts node.related_nodes }

# Good
KnowledgeNode.includes(:related_nodes).all
```

### 3. 캐싱
```ruby
# 캐시 설정
Rails.cache.write("graph:#{study_material.id}", graph_data, expires_in: 1.hour)
Rails.cache.read("graph:#{study_material.id}")
```

## 향후 개선 사항

### Phase 2
1. **그래프 레이아웃 알고리즘**
   - Force-directed 레이아웃으로 자동 좌표 생성
   - D3.js/Three.js 통합

2. **고급 분석**
   - 커뮤니티 감지 (Community Detection)
   - 노드 중심성 분석 (Centrality Analysis)
   - 최적 학습 순서 계산 (Topological Sort)

3. **적응형 학습**
   - 동적 난이도 조절
   - 개인 맞춤형 학습 경로

4. **협업 필터링**
   - 비슷한 학생의 학습 경로 추천
   - 학습 패턴 분석

### Phase 3
1. **실시간 업데이트**
   - WebSocket 기반 실시간 그래프 동기화
   - 그룹 학습 지원

2. **고급 시각화**
   - Interactive 3D 뇌 맵
   - Augmented Reality 지원

3. **머신러닝**
   - 성공 확률 예측
   - 개념 난이도 자동 추정
   - 학습 시간 예측

## 문제 해결

### 개념 추출이 실패하는 경우
1. LLM API 키 확인 (환경 변수)
2. 프롬프트 개선
3. 에러 로그 확인: `tail -f log/sidekiq.log`

### 그래프가 느린 경우
1. 인덱스 확인: `rails db:indexes`
2. 쿼리 분석: `EXPLAIN ANALYZE`
3. N+1 쿼리 감지: Bullet gem 사용

### 순환 관계 문제
- BFS 구현 시 visited Set으로 방지
- 데이터 검증: `validate_no_cycles` 메서드 추가

## 참고 자료

- CLAUDE.md - 프로젝트 가이드
- prd.md - 기능 요구사항
- docs/knowledge-graph-implementation.md - 구현 상세 가이드
- docs/knowledge-graph-api.md - API 레퍼런스

## 라이선스

MIT License

## 연락처

문제나 질문이 있으면 이슈를 생성해주세요.
