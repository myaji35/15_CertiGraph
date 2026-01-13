# Rails API Implementation Guide for Certi-Graph

## 프로젝트 구조 (UI/UX 유지 전략)

```
15_CertiGraph/
├── frontend/               # Next.js Frontend (기존 UI 유지)
│   ├── src/
│   │   ├── app/           # App Router pages
│   │   ├── components/    # React components
│   │   ├── services/      # API 통신 서비스
│   │   └── hooks/         # Custom React hooks
│   └── package.json
│
├── rails-api/             # Rails API Backend (새로 추가)
│   ├── app/
│   │   ├── controllers/api/v1/
│   │   ├── models/
│   │   ├── services/      # 비즈니스 로직
│   │   ├── jobs/          # Background jobs
│   │   └── channels/      # WebSocket
│   ├── config/
│   └── Gemfile
│
└── docs/                  # 문서
```

## Rails API 초기 설정

### 1. Rails API 프로젝트 생성

```bash
# Rails API 프로젝트 생성 (SQLite3 사용)
rails new rails-api --api --skip-test  # SQLite3가 기본값

cd rails-api

# 필요한 gem 추가
bundle add jwt
bundle add bcrypt
bundle add rack-cors
bundle add sidekiq
bundle add sqlite3  # 이미 포함되어 있음
bundle add solid_cache  # SQLite 기반 캐싱
bundle add solid_queue  # SQLite 기반 job queue
bundle add httparty  # for external API calls
```

### 2. Gemfile 설정

```ruby
# Gemfile
source "https://rubygems.org"

gem "rails", "~> 7.2.2"
gem "sqlite3", "~> 1.4"  # SQLite3 database
gem "puma", ">= 5.0"

# API
gem "rack-cors"
gem "jwt"
gem "bcrypt"

# Background Jobs (SQLite-based)
gem "solid_queue"  # Rails 7.2+ SQLite-based job queue
gem "solid_cache"  # Rails 7.2+ SQLite-based cache

# External APIs
gem "httparty"

# File uploads
gem "aws-sdk-s3", require: false  # for Active Storage (optional)

group :development, :test do
  gem "debug"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  gem "listen"
  gem "spring"
  gem "rubocop-rails"
end
```

## Core API 구현

### 1. 인증 시스템 (JWT)

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  before_action :authenticate_request

  private

  def authenticate_request
    header = request.headers['Authorization']
    header = header.split(' ').last if header

    begin
      decoded = JwtService.decode(header)
      @current_user = User.find(decoded[:user_id])
    rescue JWT::DecodeError => e
      render json: { errors: e.message }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: { errors: 'User not found' }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end
end

# app/services/jwt_service.rb
class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base

  def self.encode(payload)
    payload[:exp] = 24.hours.from_now.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  end
end

# app/controllers/api/v1/auth_controller.rb
module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request, only: [:login, :register]

      def register
        user = User.new(user_params)

        if user.save
          token = JwtService.encode(user_id: user.id)
          render json: {
            token: token,
            user: UserSerializer.new(user)
          }, status: :created
        else
          render json: { errors: user.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def login
        user = User.find_by(email: params[:email])

        if user&.authenticate(params[:password])
          token = JwtService.encode(user_id: user.id)
          render json: {
            token: token,
            user: UserSerializer.new(user)
          }
        else
          render json: { error: 'Invalid credentials' },
                 status: :unauthorized
        end
      end

      private

      def user_params
        params.permit(:email, :password, :name)
      end
    end
  end
end
```

### 2. 문제집 관리 API

```ruby
# app/models/study_set.rb
class StudySet < ApplicationRecord
  belongs_to :user
  has_many :study_materials, dependent: :destroy
  has_many :questions, through: :study_materials

  validates :name, presence: true
  validates :exam_date, presence: true

  scope :active, -> { where('exam_date >= ?', Date.today) }
end

# app/controllers/api/v1/study_sets_controller.rb
module Api
  module V1
    class StudySetsController < ApplicationController
      before_action :set_study_set, only: [:show, :update, :destroy]

      def index
        study_sets = current_user.study_sets.includes(:study_materials)
        render json: study_sets.map { |set| study_set_json(set) }
      end

      def show
        render json: study_set_json(@study_set)
      end

      def create
        study_set = current_user.study_sets.build(study_set_params)

        if study_set.save
          render json: study_set_json(study_set), status: :created
        else
          render json: { errors: study_set.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def update
        if @study_set.update(study_set_params)
          render json: study_set_json(@study_set)
        else
          render json: { errors: @study_set.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def destroy
        @study_set.destroy
        head :no_content
      end

      private

      def set_study_set
        @study_set = current_user.study_sets.find(params[:id])
      end

      def study_set_params
        params.permit(:name, :description, :exam_date, :certification_id)
      end

      def study_set_json(study_set)
        {
          id: study_set.id,
          name: study_set.name,
          description: study_set.description,
          exam_date: study_set.exam_date,
          created_at: study_set.created_at,
          materials_count: study_set.study_materials.count,
          questions_count: study_set.questions.count,
          progress: calculate_progress(study_set)
        }
      end

      def calculate_progress(study_set)
        total = study_set.questions.count
        answered = study_set.questions.joins(:user_answers)
                           .where(user_answers: { user: current_user })
                           .distinct.count

        return 0 if total.zero?
        (answered.to_f / total * 100).round(2)
      end
    end
  end
end
```

### 3. PDF 업로드 및 처리

```ruby
# app/controllers/api/v1/study_materials_controller.rb
module Api
  module V1
    class StudyMaterialsController < ApplicationController
      def create
        study_set = current_user.study_sets.find(params[:study_set_id])
        study_material = study_set.study_materials.build(material_params)

        if study_material.save
          # Background job으로 PDF 처리
          PdfProcessingJob.perform_later(study_material)

          render json: {
            id: study_material.id,
            status: 'processing',
            message: 'PDF processing started'
          }, status: :created
        else
          render json: { errors: study_material.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def upload_status
        material = StudyMaterial.find(params[:id])
        render json: {
          id: material.id,
          status: material.processing_status,
          progress: material.processing_progress,
          questions_count: material.questions.count
        }
      end

      private

      def material_params
        params.permit(:name, :pdf_file)
      end
    end
  end
end

# app/jobs/pdf_processing_job.rb
class PdfProcessingJob < ApplicationJob
  queue_as :default

  def perform(study_material)
    processor = PdfProcessorService.new(study_material)

    # 진행 상황 브로드캐스트
    ActionCable.server.broadcast(
      "pdf_processing_#{study_material.id}",
      { progress: 10, status: 'uploading' }
    )

    # Upstage API 호출
    result = processor.parse_with_upstage

    ActionCable.server.broadcast(
      "pdf_processing_#{study_material.id}",
      { progress: 50, status: 'parsing' }
    )

    # 문제 추출 및 저장
    questions = processor.extract_questions(result)

    ActionCable.server.broadcast(
      "pdf_processing_#{study_material.id}",
      { progress: 80, status: 'generating_embeddings' }
    )

    # 임베딩 생성
    EmbeddingGeneratorService.new(questions).generate

    # 완료
    study_material.update!(
      processing_status: 'completed',
      processing_progress: 100
    )

    ActionCable.server.broadcast(
      "pdf_processing_#{study_material.id}",
      { progress: 100, status: 'completed', questions_count: questions.count }
    )
  end
end

# app/services/pdf_processor_service.rb
class PdfProcessorService
  include HTTParty

  def initialize(study_material)
    @study_material = study_material
  end

  def parse_with_upstage
    response = self.class.post(
      ENV['UPSTAGE_API_URL'],
      body: {
        document: Base64.encode64(@study_material.pdf_file.download),
        options: {
          ocr: true,
          table_extraction: true
        }
      }.to_json,
      headers: {
        'Authorization' => "Bearer #{ENV['UPSTAGE_API_KEY']}",
        'Content-Type' => 'application/json'
      }
    )

    JSON.parse(response.body)
  end

  def extract_questions(parsed_data)
    questions = []

    parsed_data['pages'].each do |page|
      # 문제 패턴 매칭 및 추출 로직
      # ...
    end

    questions
  end
end
```

### 4. 시험 엔진 API

```ruby
# app/controllers/api/v1/exams_controller.rb
module Api
  module V1
    class ExamsController < ApplicationController
      def create
        study_set = current_user.study_sets.find(params[:study_set_id])

        exam = ExamGeneratorService.new(
          study_set: study_set,
          user: current_user,
          options: exam_params
        ).generate

        render json: exam_json(exam), status: :created
      end

      def show
        exam = current_user.exams.find(params[:id])
        render json: exam_json_with_questions(exam)
      end

      def submit
        exam = current_user.exams.find(params[:id])

        # 답안 저장
        params[:answers].each do |answer_data|
          UserAnswer.create!(
            user: current_user,
            question_id: answer_data[:question_id],
            selected_option_id: answer_data[:option_id],
            exam: exam
          )
        end

        # 채점 및 분석
        result = ExamAnalyzerService.new(exam).analyze

        render json: result
      end

      private

      def exam_params
        params.permit(:question_count, :mode, :weak_points_only)
      end

      def exam_json(exam)
        {
          id: exam.id,
          study_set_id: exam.study_set_id,
          mode: exam.mode,
          question_count: exam.questions.count,
          created_at: exam.created_at
        }
      end

      def exam_json_with_questions(exam)
        exam_json(exam).merge({
          questions: exam.questions.map { |q| question_json(q) }
        })
      end

      def question_json(question)
        {
          id: question.id,
          content: question.content,
          passage: question.passage,
          options: question.options.shuffle.map { |opt|
            {
              id: opt.id,
              content: opt.content
            }
          }
        }
      end
    end
  end
end
```

### 5. Knowledge Graph API

```ruby
# app/controllers/api/v1/knowledge_graph_controller.rb
module Api
  module V1
    class KnowledgeGraphController < ApplicationController
      def show
        graph_data = KnowledgeGraphService.new(current_user).generate
        render json: graph_data
      end

      def weak_points
        weak_concepts = WeakPointAnalyzer.new(current_user).analyze
        render json: weak_concepts
      end
    end
  end
end

# app/services/knowledge_graph_service.rb
class KnowledgeGraphService
  def initialize(user)
    @user = user
  end

  def generate
    nodes = generate_nodes
    edges = generate_edges

    {
      nodes: nodes,
      edges: edges,
      stats: calculate_stats(nodes)
    }
  end

  private

  def generate_nodes
    concepts = @user.concepts.includes(:user_concept_scores)

    concepts.map do |concept|
      score = concept.user_concept_scores.find_by(user: @user)

      {
        id: concept.id,
        name: concept.name,
        category: concept.category,
        status: determine_status(score),
        position: calculate_3d_position(concept),
        size: calculate_node_size(concept)
      }
    end
  end

  def determine_status(score)
    return 'gray' if score.nil?
    return 'green' if score.accuracy >= 0.8
    return 'red' if score.accuracy < 0.5
    'yellow'
  end

  def calculate_3d_position(concept)
    # Force-directed graph 알고리즘으로 3D 좌표 계산
    {
      x: rand(-100..100),
      y: rand(-100..100),
      z: rand(-100..100)
    }
  end
end
```

## Frontend 연동 (Next.js)

### API 서비스 클래스

```typescript
// frontend/src/services/apiService.ts
export class ApiService {
  private baseUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001'
  private token: string | null = null

  constructor() {
    if (typeof window !== 'undefined') {
      this.token = localStorage.getItem('token')
    }
  }

  private async request(path: string, options: RequestInit = {}) {
    const response = await fetch(`${this.baseUrl}/api/v1${path}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': this.token ? `Bearer ${this.token}` : '',
        ...options.headers,
      },
    })

    if (!response.ok) {
      throw new Error(`API Error: ${response.statusText}`)
    }

    return response.json()
  }

  // Auth
  async login(email: string, password: string) {
    const data = await this.request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    })

    this.token = data.token
    localStorage.setItem('token', data.token)
    return data.user
  }

  // Study Sets
  async getStudySets() {
    return this.request('/study_sets')
  }

  async createStudySet(data: CreateStudySetDto) {
    return this.request('/study_sets', {
      method: 'POST',
      body: JSON.stringify(data),
    })
  }

  // PDF Upload
  async uploadPDF(studySetId: number, file: File) {
    const formData = new FormData()
    formData.append('pdf_file', file)

    const response = await fetch(
      `${this.baseUrl}/api/v1/study_sets/${studySetId}/materials`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.token}`,
        },
        body: formData,
      }
    )

    return response.json()
  }

  // Knowledge Graph
  async getKnowledgeGraph() {
    return this.request('/knowledge_graph')
  }
}
```

### WebSocket 연결

```typescript
// frontend/src/hooks/useWebSocket.ts
import { useEffect, useState } from 'react'
import { createConsumer } from '@rails/actioncable'

export function usePdfProcessing(materialId: number) {
  const [progress, setProgress] = useState(0)
  const [status, setStatus] = useState('idle')

  useEffect(() => {
    const cable = createConsumer('ws://localhost:3001/cable')

    const channel = cable.subscriptions.create(
      {
        channel: 'PdfProcessingChannel',
        study_material_id: materialId
      },
      {
        received(data) {
          setProgress(data.progress)
          setStatus(data.status)
        },
      }
    )

    return () => {
      channel.unsubscribe()
    }
  }, [materialId])

  return { progress, status }
}
```

## 배포 구성

### Docker Compose (개발 환경 - SQLite3 버전)

```yaml
# docker-compose.yml
version: '3.8'

services:
  rails-api:
    build: ./rails-api
    command: bundle exec rails server -b 0.0.0.0
    volumes:
      - ./rails-api:/app
      - ./rails-api/db:/app/db  # SQLite3 파일 영속화
      - ./rails-api/storage:/app/storage  # Active Storage
    ports:
      - "3001:3000"
    environment:
      RAILS_ENV: development
      RAILS_MASTER_KEY: ${RAILS_MASTER_KEY}

  solid-queue:
    build: ./rails-api
    command: bundle exec rails solid_queue:start
    volumes:
      - ./rails-api:/app
      - ./rails-api/db:/app/db  # 동일한 SQLite3 접근
    environment:
      RAILS_ENV: development

  frontend:
    build: ./frontend
    command: npm run dev
    volumes:
      - ./frontend:/app
      - /app/node_modules
    ports:
      - "3000:3000"
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:3001

  # Neo4j는 선택사항 (MVP 이후)
  # neo4j:
  #   image: neo4j:5
  #   environment:
  #     NEO4J_AUTH: neo4j/password
  #   ports:
  #     - "7474:7474"
  #     - "7687:7687"
  #   volumes:
  #     - neo4j_data:/data

volumes:
  neo4j_data:  # 나중에 사용
```

### 간단한 개발 환경 설정 (Docker 없이)

```bash
# Rails API 서버 실행
cd rails-api
bin/rails db:create
bin/rails db:migrate
bin/rails server -p 3001

# 별도 터미널: Solid Queue 실행
cd rails-api
bin/rails solid_queue:start

# 별도 터미널: Frontend 실행
cd frontend
npm install
npm run dev
```

### SQLite3 설정 (config/database.yml)

```yaml
# config/database.yml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  <<: *default
  database: db/development.sqlite3

test:
  <<: *default
  database: db/test.sqlite3

production:
  <<: *default
  database: db/production.sqlite3
  # Production에서도 SQLite3 사용 가능 (작은 규모 앱)
  # 나중에 PostgreSQL로 마이그레이션 가능
```

### Solid Queue 설정 (SQLite 기반 Job Queue)

```ruby
# config/application.rb
module RailsApi
  class Application < Rails::Application
    # ...

    # Solid Queue를 Active Job 어댑터로 사용
    config.active_job.queue_adapter = :solid_queue

    # Solid Cache를 캐시 스토어로 사용
    config.cache_store = :solid_cache_store
  end
end

# config/solid_queue.yml
default: &default
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "*"
      threads: 5
      processes: 1
      polling_interval: 0.1

development:
  <<: *default

test:
  <<: *default

production:
  <<: *default
  workers:
    - queues: "*"
      threads: 5
      processes: 2
      polling_interval: 0.1
```

## 마이그레이션 체크리스트

- [ ] Rails API 프로젝트 생성
- [ ] 데이터베이스 스키마 설계 및 마이그레이션
- [ ] 인증 시스템 구현 (JWT)
- [ ] 문제집 CRUD API
- [ ] PDF 업로드 및 처리 시스템
- [ ] 시험 엔진 API
- [ ] Knowledge Graph API
- [ ] WebSocket 실시간 통신
- [ ] Frontend API 서비스 레이어
- [ ] 기존 UI 컴포넌트 연결
- [ ] 테스트 작성
- [ ] 배포 환경 설정

이 가이드를 따라 기존 UI/UX를 유지하면서 Rails API 백엔드로 전환할 수 있습니다.