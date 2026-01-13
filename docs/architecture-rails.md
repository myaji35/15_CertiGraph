# Architecture Decision Document - Rails Version

_Rails 기반 Certi-Graph 아키텍처 설계 문서_

---

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
- FR-1: PDF 업로드 및 OCR 파싱 (Upstage API)
- FR-2: 지능형 청킹 (지문 복제 전략 포함)
- FR-3: Knowledge Graph 구축 (Neo4j, LLM 자동 태깅)
- FR-4: CBT 테스트 엔진 (보기 랜덤 셔플링)
- FR-5: GraphRAG 기반 오답 분석
- FR-6: 사용자 인증 (Devise 또는 Clerk Rails SDK)
- FR-7: 결제 시스템 (토스페이먼츠 10,000원 시즌패스)

**Non-Functional Requirements:**
- 성능: PDF 50p 파싱 3분 이내, 문제 로딩 1초 이내, LCP 2.5초
- 보안: HTTPS, 환경변수 API 키 관리, 최소 개인정보 수집
- 확장성: MVP 100명 동시접속, 1,000명 총 사용자
- 접근성: WCAG AA, 반응형 디자인
- 비용: 인프라 월 30만원, LLM API 월 50만원 제한

---

## Rails Architecture Design

### Technology Stack

#### Core Framework
- **Rails 7.2.2** with Ruby 3.3.0
- **Turbo** for SPA-like interactions
- **Stimulus** for JavaScript behaviors
- **Tailwind CSS 2.x** for styling (v2 for compatibility)

#### Database Layer
- **SQLite3** - Primary database (simple, file-based, perfect for MVP)
- **SQLite VSS** - Vector similarity search extension for SQLite3
- **Neo4j AuraDB** - Knowledge Graph (via REST API, optional for MVP)
- **Solid Cache** - SQLite-based caching (Rails 7.2+ built-in)

#### Background Processing
- **Sidekiq** - Background jobs (PDF processing, embeddings)
- **Active Job** - Job abstraction layer

#### File Storage
- **Active Storage** - File uploads
- **Direct Upload** - Client-side uploads to cloud storage

#### External Services
- **Upstage API** - PDF OCR and parsing
- **OpenAI API** - GPT-4o/4o-mini, embeddings
- **Toss Payments** - Payment processing

---

## System Architecture

### Layered Architecture

```
┌─────────────────────────────────────────────┐
│          Presentation Layer                  │
│  (Rails Views + Turbo + Stimulus + Three.js)│
└─────────────────────────────────────────────┘
                      │
┌─────────────────────────────────────────────┐
│          Controller Layer                    │
│         (Rails Controllers)                  │
└─────────────────────────────────────────────┘
                      │
┌─────────────────────────────────────────────┐
│          Service Layer                       │
│    (Service Objects / Business Logic)        │
└─────────────────────────────────────────────┘
                      │
┌─────────────────────────────────────────────┐
│          Data Access Layer                   │
│     (Active Record + Repository Pattern)     │
└─────────────────────────────────────────────┘
                      │
┌─────────────────────────────────────────────┐
│          Infrastructure Layer                │
│   (PostgreSQL, pgvector, Neo4j, Redis)      │
└─────────────────────────────────────────────┘
```

---

## Component Architecture

### 1. Authentication & Authorization

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  has_many :study_sets
  has_one :subscription

  enum role: { free: 0, paid: 1, admin: 2 }
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  private

  def authenticate_user!
    redirect_to login_path unless current_user
  end
end
```

### 2. PDF Processing Pipeline

```ruby
# app/services/pdf_processor_service.rb
class PdfProcessorService
  def initialize(study_material)
    @study_material = study_material
  end

  def process
    # 1. Upload to cloud storage
    # 2. Queue OCR job
    PdfOcrJob.perform_later(@study_material)
  end
end

# app/jobs/pdf_ocr_job.rb
class PdfOcrJob < ApplicationJob
  def perform(study_material)
    # 1. Call Upstage API
    # 2. Parse results
    # 3. Create questions
    # 4. Generate embeddings
    # 5. Update graph
  end
end
```

### 3. Knowledge Graph Integration

```ruby
# app/services/graph_service.rb
class GraphService
  include HTTParty
  base_uri ENV['NEO4J_URL']

  def create_concept(name, properties = {})
    query = "CREATE (c:Concept {name: $name}) SET c += $props RETURN c"
    execute_cypher(query, name: name, props: properties)
  end

  def link_concepts(from_id, to_id, relationship)
    query = "MATCH (a:Concept {id: $from}), (b:Concept {id: $to})
             CREATE (a)-[r:#{relationship}]->(b) RETURN r"
    execute_cypher(query, from: from_id, to: to_id)
  end

  private

  def execute_cypher(query, params = {})
    self.class.post('/db/neo4j/tx',
      headers: auth_headers,
      body: { statements: [{ statement: query, parameters: params }] }.to_json
    )
  end
end
```

### 4. Test Engine with Randomization

```ruby
# app/models/question.rb
class Question < ApplicationRecord
  belongs_to :study_material
  has_many :options
  has_many :user_answers

  # Store embeddings using pgvector
  has_neighbors :embedding

  def randomized_options
    options.shuffle
  end
end

# app/controllers/exams_controller.rb
class ExamsController < ApplicationController
  def show
    @exam = current_user.exams.find(params[:id])
    @questions = @exam.questions.includes(:options)

    # Client-side shuffling via Stimulus
    render :show
  end
end
```

### 5. Frontend Architecture (Stimulus Controllers)

```javascript
// app/javascript/controllers/exam_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["question", "option"]

  connect() {
    this.shuffleOptions()
  }

  shuffleOptions() {
    this.optionTargets.forEach(questionOptions => {
      const options = Array.from(questionOptions.children)
      for (let i = options.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1))
        questionOptions.appendChild(options[j])
      }
    })
  }
}

// app/javascript/controllers/graph_visualization_controller.js
import { Controller } from "@hotwired/stimulus"
import * as THREE from 'three'

export default class extends Controller {
  static targets = ["canvas"]

  connect() {
    this.initThreeJS()
    this.loadGraphData()
  }

  initThreeJS() {
    this.scene = new THREE.Scene()
    this.camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000)
    this.renderer = new THREE.WebGLRenderer({ canvas: this.canvasTarget })
    // ... Three.js setup
  }

  loadGraphData() {
    fetch('/api/knowledge_graph')
      .then(response => response.json())
      .then(data => this.renderGraph(data))
  }
}
```

---

## Database Schema

### SQLite3 Schema

```ruby
# db/migrate/001_create_users.rb
class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :encrypted_password, null: false
      t.integer :role, default: 0
      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end

# db/migrate/002_create_study_sets.rb
class CreateStudySets < ActiveRecord::Migration[7.2]
  def change
    create_table :study_sets do |t|
      t.references :user, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.date :exam_date
      t.timestamps
    end
  end
end

# db/migrate/003_create_study_materials.rb
class CreateStudyMaterials < ActiveRecord::Migration[7.2]
  def change
    create_table :study_materials do |t|
      t.references :study_set, foreign_key: true
      t.string :name
      t.string :status, default: 'pending'
      t.integer :parsing_progress, default: 0
      t.timestamps
    end
  end
end

# db/migrate/004_create_questions.rb
class CreateQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :questions do |t|
      t.references :study_material, foreign_key: true
      t.text :content, null: false
      t.text :explanation
      t.integer :difficulty
      t.text :embedding_json  # Store as JSON string for SQLite
      t.timestamps
    end

    add_index :questions, :study_material_id
  end
end

# db/migrate/005_create_vector_store.rb
class CreateVectorStore < ActiveRecord::Migration[7.2]
  def change
    # Separate table for vector operations
    create_table :question_embeddings do |t|
      t.references :question, foreign_key: true
      t.json :vector  # SQLite3 JSON support
      t.float :magnitude
      t.timestamps
    end

    add_index :question_embeddings, :question_id, unique: true
  end
end
```

#### Vector Similarity Search for SQLite3

```ruby
# app/models/concerns/vector_searchable.rb
module VectorSearchable
  extend ActiveSupport::Concern

  included do
    has_one :question_embedding, dependent: :destroy
  end

  class_methods do
    def similar_to(embedding, limit: 10)
      # Simple cosine similarity implementation for SQLite3
      embeddings = QuestionEmbedding.all

      similarities = embeddings.map do |qe|
        score = cosine_similarity(embedding, JSON.parse(qe.vector))
        { question_id: qe.question_id, score: score }
      end

      question_ids = similarities.sort_by { |s| -s[:score] }
                                 .first(limit)
                                 .map { |s| s[:question_id] }

      where(id: question_ids)
    end

    private

    def cosine_similarity(vec1, vec2)
      dot_product = vec1.zip(vec2).map { |a, b| a * b }.sum
      magnitude1 = Math.sqrt(vec1.map { |a| a**2 }.sum)
      magnitude2 = Math.sqrt(vec2.map { |b| b**2 }.sum)

      return 0 if magnitude1 == 0 || magnitude2 == 0
      dot_product / (magnitude1 * magnitude2)
    end
  end
end
```

---

## Deployment Architecture

### Development Environment

```bash
# Procfile.dev
web: bin/rails server -p 3000
css: bin/rails tailwindcss:watch
js: yarn build --watch
worker: bundle exec sidekiq
```

### Production Deployment

#### Option 1: Traditional VPS (Recommended for MVP)
- **Server**: DigitalOcean Droplet or AWS EC2
- **Web Server**: Nginx + Puma
- **Process Manager**: Systemd
- **SSL**: Let's Encrypt

#### Option 2: Platform-as-a-Service
- **Heroku** or **Render.com**
- Automatic scaling and deployment
- Higher cost but simpler management

#### Option 3: Containerized (Docker)
- **Kamal** for deployment orchestration
- Docker Compose for local development
- Kubernetes for scale (future)

---

## Development Guidelines

### Rails-Specific Best Practices

1. **Service Objects Pattern**
   ```ruby
   # app/services/base_service.rb
   class BaseService
     def self.call(...)
       new(...).call
     end
   end
   ```

2. **Stimulus Fallback Pattern**
   ```javascript
   // Fallback for external libraries
   document.addEventListener('DOMContentLoaded', function() {
     if (typeof LibraryName === 'undefined') {
       setTimeout(() => initializeFallback(), 1000)
     }
   })
   ```

3. **Tailwind Configuration**
   ```javascript
   // config/tailwind.config.js (NOT in root!)
   module.exports = {
     content: [
       './app/views/**/*.html.erb',
       './app/helpers/**/*.rb',
       './app/javascript/**/*.js'
     ],
     safelist: [
       'bg-green-500',
       'bg-red-500',
       'bg-yellow-500'
     ]
   }
   ```

4. **Background Job Best Practices**
   - Use Active Job for abstraction
   - Implement idempotent jobs
   - Add retry logic with exponential backoff

5. **API Integration Pattern**
   ```ruby
   # app/services/upstage_api_service.rb
   class UpstageApiService < BaseService
     include HTTParty
     base_uri ENV['UPSTAGE_API_URL']

     def call
       response = self.class.post('/parse',
         body: request_body,
         headers: headers
       )

       handle_response(response)
     rescue => e
       Rails.logger.error "Upstage API Error: #{e.message}"
       raise
     end
   end
   ```

---

## Security Considerations

1. **Authentication**: Use Devise or implement secure session management
2. **Authorization**: Implement role-based access control
3. **API Security**: Rate limiting, API key rotation
4. **Data Protection**: Encrypt sensitive data at rest
5. **CORS**: Configure for API endpoints if needed
6. **CSP**: Content Security Policy headers

---

## Performance Optimization

1. **Database**
   - Index foreign keys and frequently queried columns
   - Use database views for complex queries
   - Implement query result caching

2. **Caching Strategy**
   - Page caching for static content
   - Fragment caching for dynamic parts
   - Russian doll caching for nested content

3. **Asset Optimization**
   - Use Rails asset pipeline
   - CDN for static assets
   - Image optimization with Active Storage variants

4. **Background Processing**
   - Offload heavy operations to background jobs
   - Use Redis for job queue persistence

---

## Monitoring & Observability

1. **Application Monitoring**
   - New Relic or Scout APM
   - Custom metrics with StatsD

2. **Error Tracking**
   - Sentry or Rollbar
   - Rails error reporter API

3. **Logging**
   - Structured logging with Lograge
   - Centralized log management

4. **Health Checks**
   ```ruby
   # config/routes.rb
   get '/health', to: proc { [200, {}, ['OK']] }
   ```

---

## UI/UX 유지 전략 (Hybrid Architecture)

### 핵심 원칙
**기존 Next.js 기반 UI/UX를 최대한 유지하면서 Rails 백엔드의 장점을 활용**

### Architecture Pattern: Rails API + Next.js Frontend

```
┌─────────────────────────────────┐
│     Next.js Frontend (유지)      │
│   - 기존 UI 컴포넌트 재사용      │
│   - React + TypeScript           │
│   - Tailwind CSS                 │
│   - Three.js 시각화              │
└─────────────────────────────────┘
           │ REST API / GraphQL
┌─────────────────────────────────┐
│      Rails API Backend           │
│   - API-only mode                │
│   - Service Objects              │
│   - Background Jobs              │
│   - Database Management          │
└─────────────────────────────────┘
```

### Implementation Strategy

#### Option 1: Rails API-Only Mode (권장) ✅
```ruby
# Rails를 API 서버로만 사용
rails new certigraph-api --api --database=postgresql

# config/application.rb
module CertigraphApi
  class Application < Rails::Application
    config.api_only = true

    # CORS 설정으로 Next.js와 통신
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins 'http://localhost:3000'
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head]
      end
    end
  end
end
```

**장점:**
- 기존 Next.js UI를 100% 유지
- Frontend/Backend 명확한 분리
- 독립적인 배포 가능
- 기존 개발 워크플로우 유지

#### Option 2: Rails + React Integration
```ruby
# Rails 내에서 React 컴포넌트 사용
gem 'react-rails'
gem 'webpacker'

# ERB 템플릿에서 React 컴포넌트 렌더링
<%= react_component("Dashboard", { user: @current_user }) %>
```

**장점:**
- 단일 애플리케이션으로 관리
- SSR 지원
- Rails의 뷰 헬퍼 활용 가능

### 기존 메뉴 구조 Rails 라우팅 매핑

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # 홈
      get 'dashboard', to: 'dashboard#index'

      # 학습
      resources :study_sets do
        resources :questions
      end
      resources :study_materials do
        post 'upload', on: :member
      end
      get 'knowledge_graph', to: 'knowledge_graph#show'
      get 'weak_points', to: 'weak_points#index'

      # 진도
      get 'achievements', to: 'achievements#index'
      get 'statistics', to: 'statistics#index'

      # 자격증
      resources :certifications do
        collection do
          get 'search'
        end
      end

      # 인증
      post 'auth/login', to: 'auth#login'
      post 'auth/logout', to: 'auth#logout'
      post 'auth/register', to: 'auth#register'
    end
  end
end
```

### Frontend Integration Points

#### 1. API 서비스 레이어 (Next.js)
```typescript
// frontend/services/api.ts
class ApiService {
  private baseUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001'

  async getStudySets() {
    return fetch(`${this.baseUrl}/api/v1/study_sets`)
      .then(res => res.json())
  }

  async uploadPDF(file: File, studySetId: number) {
    const formData = new FormData()
    formData.append('pdf', file)

    return fetch(`${this.baseUrl}/api/v1/study_materials/${studySetId}/upload`, {
      method: 'POST',
      body: formData
    })
  }
}
```

#### 2. 실시간 업데이트 (Action Cable + Next.js)
```ruby
# Rails: app/channels/pdf_processing_channel.rb
class PdfProcessingChannel < ApplicationCable::Channel
  def subscribed
    stream_from "pdf_processing_#{params[:study_material_id]}"
  end
end

# Rails: 진행 상황 브로드캐스트
ActionCable.server.broadcast(
  "pdf_processing_#{study_material.id}",
  { progress: 50, status: 'parsing' }
)
```

```typescript
// Next.js: WebSocket 연결
import { createConsumer } from '@rails/actioncable'

const cable = createConsumer('ws://localhost:3001/cable')
const channel = cable.subscriptions.create(
  { channel: 'PdfProcessingChannel', study_material_id: id },
  {
    received(data) {
      updateProgress(data.progress)
    }
  }
)
```

### Three.js 지식 그래프 통합

```ruby
# Rails: app/controllers/api/v1/knowledge_graph_controller.rb
class Api::V1::KnowledgeGraphController < ApplicationController
  def show
    nodes = current_user.knowledge_nodes
    edges = current_user.knowledge_edges

    render json: {
      nodes: nodes.map { |n| node_json(n) },
      edges: edges.map { |e| edge_json(e) },
      stats: {
        mastered: nodes.mastered.count,
        weak: nodes.weak.count,
        untested: nodes.untested.count
      }
    }
  end

  private

  def node_json(node)
    {
      id: node.id,
      name: node.concept_name,
      status: node.status, # green, red, gray
      position: node.position_3d, # {x, y, z}
      connections: node.edge_ids
    }
  end
end
```

### 단계별 마이그레이션 계획

#### Phase 1: Rails API 서버 구축 (Week 1)
1. Rails API-only 프로젝트 생성
2. 데이터베이스 스키마 마이그레이션
3. 인증 시스템 구현 (JWT)
4. CORS 설정

#### Phase 2: 핵심 API 구현 (Week 2)
1. 문제집 CRUD API
2. PDF 업로드 및 처리 API
3. 시험 엔진 API
4. WebSocket 실시간 통신

#### Phase 3: Frontend 연결 (Week 3)
1. API 서비스 레이어 구현
2. 기존 컴포넌트 API 연결
3. 실시간 업데이트 통합
4. 에러 처리 및 로딩 상태

#### Phase 4: 고급 기능 (Week 4)
1. Knowledge Graph API
2. GraphRAG 분석 서비스
3. 결제 시스템 통합
4. 성능 최적화

---

## Conclusion

This Rails-based architecture provides:
- **Simplicity**: Single framework for full-stack development
- **Productivity**: Rails conventions and generators
- **Scalability**: Proven architecture patterns
- **Cost-Effective**: Reduced operational complexity
- **Community**: Large ecosystem and support

The architecture maintains the core functionality while leveraging Rails' strengths for rapid development and deployment.