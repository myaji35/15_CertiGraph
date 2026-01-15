# ExamsGraph Complete Architecture Document

_Comprehensive Technical Architecture for AI-Powered Certification Study Platform_

**Version:** 2.0
**Date:** 2025-01-14
**Author:** Winston (System Architect)
**Project:** ExamsGraph (AI 자격증 마스터)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Architecture Overview](#system-architecture-overview)
3. [AI/ML Pipeline Architecture](#aiml-pipeline-architecture)
4. [GraphRAG Service Architecture](#graphrag-service-architecture)
5. [Payment Integration Architecture](#payment-integration-architecture)
6. [Background Job Architecture](#background-job-architecture)
7. [Service Layer Design](#service-layer-design)
8. [Database Architecture](#database-architecture)
9. [Security Architecture](#security-architecture)
10. [Performance & Scaling](#performance--scaling)
11. [Deployment Architecture](#deployment-architecture)

---

## Executive Summary

ExamsGraph is a Rails 8.0 full-stack application that transforms static PDF exam materials into dynamic learning experiences using AI/ML and Knowledge Graph technologies. This document details the complete technical architecture required to implement the remaining 40% of MVP functionality.

### Current State (60% Complete)
- ✅ Rails 8.0 application structure
- ✅ Authentication (Devise + Google OAuth)
- ✅ Study Set CRUD operations
- ✅ Basic PDF processing (pdf-reader gem)
- ✅ Mock exam system with timer
- ✅ Ultra Modern UI (Glass morphism, 3D effects)

### To Be Implemented (40% Remaining)
- ⏳ AI/ML Pipeline (OpenAI integration)
- ⏳ GraphRAG analysis system
- ⏳ Payment system (Toss Payments)
- ⏳ Knowledge Graph (Neo4j)
- ⏳ Background job processing (Solid Queue)
- ⏳ 3D Brain Map visualization

---

## System Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     User Interface Layer                     │
│         Rails Views + Turbo + Stimulus + Three.js           │
│              Ultra Modern UI (Glass morphism)                │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────┴─────────────────────────────────────┐
│                    Application Layer                         │
│              Rails Controllers + Service Objects             │
│                    Business Logic & Validation               │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────┴─────────────────────────────────────┐
│                     Service Layer                            │
│   AI Services | Payment Services | Graph Services | Jobs     │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────┴─────────────────────────────────────┐
│                    Data Access Layer                         │
│         Active Record Models + Repository Pattern            │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────┴─────────────────────────────────────┐
│                  Infrastructure Layer                        │
│     SQLite3 (Primary) | Neo4j (Graph) | Redis (Cache)       │
│        OpenAI API | Upstage API | Toss Payments API         │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack Detail

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | Rails ERB + Turbo + Stimulus | SPA-like interactions |
| **Styling** | Tailwind CSS + Ultra Modern CSS | Glass morphism UI |
| **3D Visualization** | Three.js via importmap | Knowledge Graph display |
| **Primary DB** | SQLite3 with JSON1 extension | All application data |
| **Graph DB** | Neo4j AuraDB (REST API) | Knowledge relationships |
| **Vector Store** | SQLite3 JSON columns | Embedding storage |
| **Cache** | Solid Cache (SQLite-based) | Query caching |
| **Background Jobs** | Solid Queue | Async processing |
| **File Storage** | Active Storage (local/S3) | PDF storage |
| **AI/ML** | OpenAI GPT-4o/4o-mini | Text processing |
| **OCR** | Upstage Document Parse | PDF extraction |
| **Payments** | Toss Payments | Season pass sales |

---

## AI/ML Pipeline Architecture

### Overview
The AI/ML pipeline processes uploaded PDFs through multiple stages to extract questions, generate embeddings, and build knowledge relationships.

### Pipeline Flow

```
[PDF Upload]
    ↓
[Upstage OCR API]
    ↓
[Text Extraction & Cleaning]
    ↓
[Question Parsing & Chunking] ← [Passage Replication Strategy]
    ↓
[OpenAI GPT-4o Processing]
    ├─→ [Concept Extraction]
    ├─→ [Prerequisite Analysis]
    └─→ [Difficulty Assessment]
    ↓
[OpenAI Embeddings API]
    ↓
[Vector Storage (SQLite3)]
    ↓
[Neo4j Graph Update]
```

### Detailed Service Implementation

#### 1. PDF Processing Service

```ruby
# app/services/ai/pdf_processing_service.rb
module AI
  class PdfProcessingService
    def initialize(study_material)
      @study_material = study_material
      @upstage_client = UpstageClient.new
      @openai_client = OpenAIClient.new
    end

    def process
      # Step 1: OCR Processing
      ocr_result = extract_text_via_ocr

      # Step 2: Intelligent Chunking
      chunks = apply_passage_replication_strategy(ocr_result)

      # Step 3: Question Extraction
      questions = extract_questions(chunks)

      # Step 4: AI Enhancement
      enhanced_questions = enhance_with_ai(questions)

      # Step 5: Generate Embeddings
      generate_and_store_embeddings(enhanced_questions)

      # Step 6: Update Knowledge Graph
      update_knowledge_graph(enhanced_questions)

      enhanced_questions
    end

    private

    def extract_text_via_ocr
      @upstage_client.parse_document(
        file_url: @study_material.pdf.url,
        output_format: 'markdown',
        ocr_mode: 'auto'
      )
    end

    def apply_passage_replication_strategy(text)
      # Detect passages that apply to multiple questions
      passages = text.scan(/다음 글을 읽고.*?(?=\n\d+\.|$)/m)

      chunks = []
      passages.each do |passage|
        related_questions = extract_related_questions(passage)
        related_questions.each do |question|
          chunks << {
            passage: passage,
            question: question,
            combined_text: "#{passage}\n\n#{question}"
          }
        end
      end

      chunks
    end

    def enhance_with_ai(questions)
      questions.map do |question|
        prompt = build_enhancement_prompt(question)

        response = @openai_client.chat(
          model: 'gpt-4o-mini',
          messages: [
            { role: 'system', content: AI_ENHANCEMENT_SYSTEM_PROMPT },
            { role: 'user', content: prompt }
          ],
          response_format: { type: 'json_object' }
        )

        enhanced_data = JSON.parse(response.dig('choices', 0, 'message', 'content'))
        question.merge(enhanced_data)
      end
    end

    def generate_and_store_embeddings(questions)
      questions.each do |question|
        embedding = @openai_client.embeddings(
          model: 'text-embedding-3-small',
          input: question[:combined_text]
        )

        QuestionEmbedding.create!(
          question_id: question[:id],
          vector: embedding['data'][0]['embedding'],
          magnitude: calculate_magnitude(embedding['data'][0]['embedding'])
        )
      end
    end
  end
end
```

#### 2. Embedding Service

```ruby
# app/services/ai/embedding_service.rb
module AI
  class EmbeddingService
    EMBEDDING_MODEL = 'text-embedding-3-small'
    EMBEDDING_DIMENSIONS = 1536
    BATCH_SIZE = 100

    def initialize
      @client = OpenAIClient.new
    end

    def generate_embedding(text)
      response = @client.embeddings(
        model: EMBEDDING_MODEL,
        input: truncate_text(text)
      )

      response.dig('data', 0, 'embedding')
    end

    def generate_batch_embeddings(texts)
      texts.in_groups_of(BATCH_SIZE, false).flat_map do |batch|
        response = @client.embeddings(
          model: EMBEDDING_MODEL,
          input: batch.map { |text| truncate_text(text) }
        )

        response['data'].map { |item| item['embedding'] }
      end
    end

    def find_similar(embedding, limit: 10, threshold: 0.8)
      # SQLite3 implementation for vector similarity
      results = []

      QuestionEmbedding.find_each do |qe|
        similarity = cosine_similarity(embedding, JSON.parse(qe.vector))
        if similarity >= threshold
          results << { question_id: qe.question_id, similarity: similarity }
        end
      end

      results.sort_by { |r| -r[:similarity] }.first(limit)
    end

    private

    def truncate_text(text, max_tokens: 8000)
      # Approximate truncation to stay within token limits
      text.truncate(max_tokens * 4) # ~4 chars per token
    end

    def cosine_similarity(vec1, vec2)
      dot_product = vec1.zip(vec2).sum { |a, b| a * b }
      magnitude1 = Math.sqrt(vec1.sum { |x| x**2 })
      magnitude2 = Math.sqrt(vec2.sum { |x| x**2 })

      return 0 if magnitude1 == 0 || magnitude2 == 0
      dot_product / (magnitude1 * magnitude2)
    end

    def calculate_magnitude(vector)
      Math.sqrt(vector.sum { |x| x**2 })
    end
  end
end
```

#### 3. Concept Extraction Service

```ruby
# app/services/ai/concept_extraction_service.rb
module AI
  class ConceptExtractionService
    EXTRACTION_PROMPT = <<~PROMPT
      분석할 문제를 제공합니다. 다음을 추출해주세요:

      1. 핵심 개념 (key_concepts): 문제에서 다루는 주요 개념들
      2. 선행 지식 (prerequisites): 이 문제를 풀기 위해 필요한 사전 지식
      3. 난이도 (difficulty): 1-5 척도
      4. 인지 수준 (cognitive_level): 암기/이해/적용/분석/종합/평가
      5. 관련 법규 (related_regulations): 언급된 법률이나 규정 (있는 경우)

      JSON 형식으로 응답하세요.
    PROMPT

    def extract(question_text)
      response = OpenAIClient.new.chat(
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: EXTRACTION_PROMPT },
          { role: 'user', content: question_text }
        ],
        response_format: { type: 'json_object' }
      )

      JSON.parse(response.dig('choices', 0, 'message', 'content'))
    end

    def extract_batch(questions)
      questions.map { |q| extract(q) }
    end
  end
end
```

---

## GraphRAG Service Architecture

### Overview
GraphRAG combines Knowledge Graph structure with Retrieval-Augmented Generation to provide deep analysis of learning gaps and personalized recommendations.

### Graph Structure

```
[User Node]
    ├─[ATTEMPTED]→ [Question Node]
    ├─[MASTERED]→ [Concept Node]
    └─[WEAK_IN]→ [Concept Node]
           ↓
    [Concept Node]
        ├─[REQUIRES]→ [Prerequisite Concept]
        ├─[RELATED_TO]→ [Related Concept]
        └─[TESTED_BY]→ [Question Node]
```

### GraphRAG Analysis Service

```ruby
# app/services/graph/graphrag_analysis_service.rb
module Graph
  class GraphRAGAnalysisService
    def initialize(user)
      @user = user
      @neo4j_client = Neo4jClient.new
      @openai_client = OpenAIClient.new
    end

    def analyze_wrong_answer(exam_answer)
      # Step 1: Get question context
      question = exam_answer.question
      selected_option = exam_answer.selected_option
      correct_answer = question.correct_answer

      # Step 2: Fetch knowledge graph context
      graph_context = fetch_graph_context(question)

      # Step 3: Build GraphRAG prompt
      prompt = build_graphrag_prompt(
        question: question,
        selected: selected_option,
        correct: correct_answer,
        graph: graph_context
      )

      # Step 4: Get AI analysis with graph context
      analysis = perform_graphrag_analysis(prompt)

      # Step 5: Update user's knowledge state
      update_knowledge_state(analysis)

      # Step 6: Generate recommendations
      recommendations = generate_recommendations(analysis)

      {
        root_cause: analysis[:root_cause],
        knowledge_gaps: analysis[:missing_concepts],
        misconceptions: analysis[:misconceptions],
        recommendations: recommendations,
        confidence: analysis[:confidence]
      }
    end

    private

    def fetch_graph_context(question)
      cypher_query = <<~CYPHER
        MATCH (q:Question {id: $question_id})-[:TESTS]->(c:Concept)
        OPTIONAL MATCH (c)-[:REQUIRES*1..3]->(pre:Concept)
        OPTIONAL MATCH (c)-[:RELATED_TO*1..2]->(rel:Concept)
        OPTIONAL MATCH (u:User {id: $user_id})-[r:ATTEMPTED|MASTERED|WEAK_IN]->(c2:Concept)
        WHERE c2 IN [c] + collect(pre) + collect(rel)
        RETURN
          c.name as concept,
          collect(DISTINCT pre.name) as prerequisites,
          collect(DISTINCT rel.name) as related,
          collect(DISTINCT {concept: c2.name, relationship: type(r), score: r.score}) as user_state
      CYPHER

      @neo4j_client.execute(cypher_query, {
        question_id: question.id,
        user_id: @user.id
      })
    end

    def build_graphrag_prompt(question:, selected:, correct:, graph:)
      <<~PROMPT
        ## 문제 분석 컨텍스트

        **문제**: #{question.content}
        **사용자 선택**: #{selected}
        **정답**: #{correct}

        ## 지식 그래프 컨텍스트

        **핵심 개념**: #{graph[:concept]}
        **선행 지식**: #{graph[:prerequisites].join(', ')}
        **관련 개념**: #{graph[:related].join(', ')}
        **사용자 현재 상태**: #{graph[:user_state].to_json}

        ## 분석 요청

        1. 오답의 근본 원인을 분석하세요
        2. 부족한 개념을 구체적으로 식별하세요
        3. 잘못 이해하고 있는 부분을 찾으세요
        4. 개선을 위한 학습 경로를 제안하세요

        JSON 형식으로 응답하세요.
      PROMPT
    end

    def perform_graphrag_analysis(prompt)
      response = @openai_client.chat(
        model: 'gpt-4o',
        messages: [
          {
            role: 'system',
            content: 'You are an expert educational psychologist specializing in knowledge gap analysis.'
          },
          { role: 'user', content: prompt }
        ],
        response_format: { type: 'json_object' },
        temperature: 0.3
      )

      JSON.parse(response.dig('choices', 0, 'message', 'content'), symbolize_names: true)
    end

    def update_knowledge_state(analysis)
      # Update Neo4j with new knowledge state
      analysis[:missing_concepts].each do |concept|
        cypher = <<~CYPHER
          MERGE (u:User {id: $user_id})
          MERGE (c:Concept {name: $concept})
          MERGE (u)-[r:WEAK_IN]->(c)
          SET r.identified_at = timestamp(),
              r.confidence = $confidence
        CYPHER

        @neo4j_client.execute(cypher, {
          user_id: @user.id,
          concept: concept,
          confidence: analysis[:confidence]
        })
      end
    end

    def generate_recommendations(analysis)
      # Find questions that test the weak concepts
      weak_concepts = analysis[:missing_concepts]

      recommendations = []
      weak_concepts.each do |concept|
        questions = find_questions_for_concept(concept)
        recommendations << {
          concept: concept,
          priority: calculate_priority(concept, analysis),
          practice_questions: questions,
          study_materials: find_study_materials(concept)
        }
      end

      recommendations.sort_by { |r| -r[:priority] }
    end
  end
end
```

### Neo4j Integration Service

```ruby
# app/services/graph/neo4j_client.rb
module Graph
  class Neo4jClient
    include HTTParty
    base_uri ENV['NEO4J_AURA_URI']

    def initialize
      @auth = {
        username: ENV['NEO4J_USERNAME'],
        password: ENV['NEO4J_PASSWORD']
      }
    end

    def execute(query, params = {})
      response = self.class.post(
        '/db/neo4j/tx/commit',
        basic_auth: @auth,
        headers: {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        },
        body: {
          statements: [{
            statement: query,
            parameters: params
          }]
        }.to_json
      )

      parse_response(response)
    end

    def create_concept(name, properties = {})
      query = <<~CYPHER
        MERGE (c:Concept {name: $name})
        SET c += $properties
        RETURN c
      CYPHER

      execute(query, name: name, properties: properties)
    end

    def create_prerequisite(from_concept, to_concept, strength = 1.0)
      query = <<~CYPHER
        MATCH (a:Concept {name: $from})
        MATCH (b:Concept {name: $to})
        MERGE (a)-[r:REQUIRES {strength: $strength}]->(b)
        RETURN r
      CYPHER

      execute(query, from: from_concept, to: to_concept, strength: strength)
    end

    def get_knowledge_subgraph(user_id, depth = 3)
      query = <<~CYPHER
        MATCH (u:User {id: $user_id})-[r:ATTEMPTED|MASTERED|WEAK_IN]-(c:Concept)
        OPTIONAL MATCH path = (c)-[*1..#{depth}]-(related:Concept)
        RETURN c, r, path
      CYPHER

      execute(query, user_id: user_id)
    end

    private

    def parse_response(response)
      return nil unless response.success?

      data = response.parsed_response
      return nil if data['errors'].present?

      results = data.dig('results', 0, 'data')
      results.map { |row| row['row'] }.flatten if results
    end
  end
end
```

---

## Payment Integration Architecture

### Overview
Integration with Toss Payments for 10,000 KRW season pass purchases.

### Payment Flow

```
[User Clicks Purchase]
    ↓
[Create Payment Intent]
    ↓
[Redirect to Toss Checkout]
    ↓
[Toss Payment Processing]
    ↓
[Success/Failure Callback]
    ↓
[Webhook Verification]
    ↓
[Grant Access / Handle Error]
```

### Payment Service Implementation

```ruby
# app/services/payment/toss_payment_service.rb
module Payment
  class TossPaymentService
    include HTTParty
    base_uri 'https://api.tosspayments.com/v1'

    SEASON_PASS_PRICE = 10_000

    def initialize
      @secret_key = ENV['TOSS_SECRET_KEY']
      @client_key = ENV['TOSS_CLIENT_KEY']
    end

    def create_payment(user)
      order_id = generate_order_id(user)

      payment_data = {
        amount: SEASON_PASS_PRICE,
        orderId: order_id,
        orderName: "ExamsGraph 시즌패스 - #{user.target_exam}",
        customerName: user.name,
        customerEmail: user.email,
        successUrl: success_url(order_id),
        failUrl: fail_url(order_id),
        # Metadata for webhook processing
        metadata: {
          userId: user.id,
          productType: 'season_pass',
          examDate: user.exam_date
        }
      }

      response = self.class.post(
        '/payments',
        headers: auth_headers,
        body: payment_data.to_json
      )

      handle_payment_response(response, order_id)
    end

    def confirm_payment(payment_key, order_id, amount)
      response = self.class.post(
        "/payments/#{payment_key}",
        headers: auth_headers,
        body: {
          orderId: order_id,
          amount: amount
        }.to_json
      )

      if response.success?
        process_successful_payment(response.parsed_response)
      else
        handle_payment_error(response)
      end
    end

    def handle_webhook(payload, signature)
      # Verify webhook signature
      return false unless verify_webhook_signature(payload, signature)

      event = JSON.parse(payload)

      case event['eventType']
      when 'PAYMENT_STATUS_CHANGED'
        handle_payment_status_change(event)
      when 'PAYMENT_FAILED'
        handle_payment_failure(event)
      end

      true
    end

    private

    def generate_order_id(user)
      "EXAMSGRAPH_#{user.id}_#{Time.current.to_i}"
    end

    def auth_headers
      {
        'Authorization' => "Basic #{Base64.encode64("#{@secret_key}:").strip}",
        'Content-Type' => 'application/json'
      }
    end

    def verify_webhook_signature(payload, signature)
      expected_signature = Base64.encode64(
        OpenSSL::HMAC.digest('SHA256', @secret_key, payload)
      ).strip

      ActiveSupport::SecurityUtils.secure_compare(signature, expected_signature)
    end

    def process_successful_payment(payment_data)
      ActiveRecord::Base.transaction do
        # Create payment record
        payment = Payment.create!(
          user_id: payment_data['metadata']['userId'],
          amount: payment_data['totalAmount'],
          payment_key: payment_data['paymentKey'],
          order_id: payment_data['orderId'],
          status: 'completed',
          method: payment_data['method'],
          paid_at: payment_data['approvedAt']
        )

        # Grant season pass access
        user = User.find(payment_data['metadata']['userId'])
        user.subscriptions.create!(
          type: 'season_pass',
          starts_at: Time.current,
          expires_at: Date.parse(payment_data['metadata']['examDate']),
          payment: payment
        )

        # Send confirmation email
        PaymentMailer.confirmation(payment).deliver_later
      end
    end

    def handle_payment_error(response)
      error_data = response.parsed_response

      Rails.logger.error "Toss Payment Error: #{error_data}"

      PaymentError.create!(
        code: error_data['code'],
        message: error_data['message'],
        details: error_data
      )

      raise PaymentError, error_data['message']
    end
  end
end
```

### Payment Controller

```ruby
# app/controllers/payments_controller.rb
class PaymentsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:webhook]

  def new
    @payment_service = Payment::TossPaymentService.new
    @payment_data = @payment_service.create_payment(current_user)

    if @payment_data[:success]
      redirect_to @payment_data[:checkout_url], allow_other_host: true
    else
      flash[:error] = "결제 준비 중 오류가 발생했습니다."
      redirect_to pricing_path
    end
  end

  def success
    payment_key = params[:paymentKey]
    order_id = params[:orderId]
    amount = params[:amount].to_i

    service = Payment::TossPaymentService.new
    result = service.confirm_payment(payment_key, order_id, amount)

    if result[:success]
      flash[:success] = "결제가 완료되었습니다! 시험일까지 무제한으로 이용하세요."
      redirect_to dashboard_path
    else
      flash[:error] = "결제 확인 중 오류가 발생했습니다: #{result[:error]}"
      redirect_to pricing_path
    end
  end

  def fail
    flash[:error] = "결제가 취소되었습니다."
    redirect_to pricing_path
  end

  def webhook
    payload = request.body.read
    signature = request.headers['X-Toss-Signature']

    service = Payment::TossPaymentService.new
    if service.handle_webhook(payload, signature)
      head :ok
    else
      head :bad_request
    end
  end
end
```

---

## Background Job Architecture

### Overview
Using Solid Queue (SQLite-based) for background job processing to handle PDF processing, AI analysis, and other async operations.

### Job Queue Structure

```
┌─────────────────────────────────────┐
│         High Priority Queue         │
│   - Payment confirmations           │
│   - User notifications              │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│        Medium Priority Queue        │
│   - PDF processing                  │
│   - Embedding generation            │
│   - Graph updates                   │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│         Low Priority Queue          │
│   - Analytics                       │
│   - Report generation               │
│   - Data cleanup                    │
└─────────────────────────────────────┘
```

### Solid Queue Configuration

```ruby
# config/solid_queue.yml
production:
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "critical"
      threads: 5
      processes: 1
      polling_interval: 0.1
    - queues: "default"
      threads: 3
      processes: 2
      polling_interval: 0.5
    - queues: "low"
      threads: 2
      processes: 1
      polling_interval: 2

# config/application.rb
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }
```

### Job Implementations

```ruby
# app/jobs/pdf_processing_job.rb
class PdfProcessingJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(study_material_id)
    study_material = StudyMaterial.find(study_material_id)

    # Update status
    study_material.update!(status: 'processing')

    # Process PDF
    service = AI::PdfProcessingService.new(study_material)
    questions = service.process

    # Create question records
    questions.each do |q_data|
      study_material.questions.create!(q_data)
    end

    # Update status
    study_material.update!(
      status: 'completed',
      question_count: questions.count
    )

    # Notify user
    UserMailer.pdf_processed(study_material).deliver_later

    # Trigger next jobs
    GenerateEmbeddingsJob.perform_later(study_material_id)
    UpdateKnowledgeGraphJob.perform_later(study_material_id)
  rescue => e
    study_material.update!(status: 'failed', error_message: e.message)
    raise # Re-raise for retry logic
  end
end

# app/jobs/generate_embeddings_job.rb
class GenerateEmbeddingsJob < ApplicationJob
  queue_as :low

  def perform(study_material_id)
    study_material = StudyMaterial.find(study_material_id)
    embedding_service = AI::EmbeddingService.new

    study_material.questions.find_each.with_index do |question, index|
      # Generate embedding
      embedding = embedding_service.generate_embedding(question.combined_text)

      # Store in database
      QuestionEmbedding.create!(
        question: question,
        vector: embedding.to_json,
        magnitude: calculate_magnitude(embedding)
      )

      # Broadcast progress
      broadcast_progress(study_material, index + 1, study_material.questions.count)
    end
  end

  private

  def broadcast_progress(study_material, current, total)
    ActionCable.server.broadcast(
      "pdf_processing_#{study_material.id}",
      {
        stage: 'embeddings',
        progress: (current.to_f / total * 100).round,
        message: "임베딩 생성 중... (#{current}/#{total})"
      }
    )
  end
end

# app/jobs/graphrag_analysis_job.rb
class GraphRAGAnalysisJob < ApplicationJob
  queue_as :default

  def perform(exam_answer_id)
    exam_answer = ExamAnswer.find(exam_answer_id)
    service = Graph::GraphRAGAnalysisService.new(exam_answer.user)

    analysis = service.analyze_wrong_answer(exam_answer)

    # Store analysis
    WrongNote.create!(
      exam_answer: exam_answer,
      analysis: analysis,
      status: 'analyzed'
    )

    # Update user's weak points
    UpdateWeakPointsJob.perform_later(exam_answer.user_id, analysis[:knowledge_gaps])
  end
end
```

---

## Service Layer Design

### Service Object Architecture

The service layer encapsulates business logic and provides a clean interface between controllers and models.

```ruby
# app/services/base_service.rb
class BaseService
  def self.call(...)
    new(...).call
  end

  private

  def success(data = {})
    OpenStruct.new(success?: true, data: data)
  end

  def failure(errors = {})
    OpenStruct.new(success?: false, errors: errors)
  end
end
```

### Core Services Overview

| Service | Responsibility | Key Methods |
|---------|---------------|-------------|
| **PdfProcessingService** | PDF parsing and question extraction | `process`, `extract_questions` |
| **EmbeddingService** | Generate and manage embeddings | `generate`, `find_similar` |
| **ConceptExtractionService** | Extract concepts from questions | `extract`, `extract_batch` |
| **KnowledgeGraphService** | Manage knowledge graph | `build_graph`, `update_mastery` |
| **GraphRAGAnalysisService** | Analyze wrong answers | `analyze`, `recommend` |
| **ExamEngineService** | Manage exam sessions | `create_session`, `grade` |
| **PaymentService** | Handle payments | `create_payment`, `confirm` |
| **UserProgressService** | Track learning progress | `calculate_progress`, `weak_points` |
| **RecommendationService** | Generate study recommendations | `recommend_next`, `learning_path` |
| **NotificationService** | Send notifications | `notify`, `broadcast` |

### Detailed Service Implementations

#### 1. Exam Engine Service

```ruby
# app/services/exam_engine_service.rb
class ExamEngineService < BaseService
  def initialize(user, study_set)
    @user = user
    @study_set = study_set
  end

  def call(mode:, options: {})
    exam_session = create_exam_session(mode, options)
    questions = select_questions(mode, options)

    # Apply randomization
    questions = randomize_questions(questions) if options[:randomize]

    # Store session data
    exam_session.update!(
      question_ids: questions.pluck(:id),
      total_questions: questions.count,
      time_limit: calculate_time_limit(questions.count, mode)
    )

    success(
      session: exam_session,
      questions: prepare_questions_for_display(questions)
    )
  rescue => e
    failure(error: e.message)
  end

  private

  def create_exam_session(mode, options)
    ExamSession.create!(
      user: @user,
      study_set: @study_set,
      mode: mode,
      config: options,
      started_at: Time.current
    )
  end

  def select_questions(mode, options)
    case mode
    when 'practice'
      select_practice_questions(options)
    when 'mock'
      select_mock_exam_questions(options)
    when 'review'
      select_review_questions(options)
    when 'weak_points'
      select_weak_point_questions
    end
  end

  def select_weak_point_questions
    # Get user's weak concepts from graph
    weak_concepts = @user.weak_concepts.pluck(:name)

    # Find questions testing those concepts
    Question.joins(:concepts)
            .where(concepts: { name: weak_concepts })
            .distinct
            .limit(20)
  end

  def randomize_questions(questions)
    questions.shuffle.map do |question|
      # Randomize option order
      question.options = question.options.shuffle
      question
    end
  end

  def prepare_questions_for_display(questions)
    questions.map do |q|
      {
        id: q.id,
        content: q.content,
        options: q.options.map.with_index { |opt, idx|
          {
            id: idx,
            text: opt.text,
            display_order: SecureRandom.hex(4) # For client-side ordering
          }
        },
        has_passage: q.passage.present?,
        passage: q.passage
      }
    end
  end
end
```

#### 2. User Progress Service

```ruby
# app/services/user_progress_service.rb
class UserProgressService < BaseService
  def initialize(user)
    @user = user
    @neo4j = Graph::Neo4jClient.new
  end

  def calculate_overall_progress
    total_concepts = fetch_total_concepts
    mastered = fetch_mastered_concepts
    weak = fetch_weak_concepts
    untested = total_concepts - mastered - weak

    {
      total: total_concepts,
      mastered: mastered,
      mastered_percentage: (mastered.to_f / total_concepts * 100).round,
      weak: weak,
      weak_percentage: (weak.to_f / total_concepts * 100).round,
      untested: untested,
      untested_percentage: (untested.to_f / total_concepts * 100).round,
      strength_score: calculate_strength_score,
      predicted_score: predict_exam_score
    }
  end

  def identify_weak_points
    query = <<~CYPHER
      MATCH (u:User {id: $user_id})-[r:WEAK_IN]->(c:Concept)
      OPTIONAL MATCH (c)-[:REQUIRES]->(pre:Concept)
      OPTIONAL MATCH (q:Question)-[:TESTS]->(c)
      RETURN c.name as concept,
             r.score as weakness_score,
             collect(DISTINCT pre.name) as prerequisites,
             count(DISTINCT q) as practice_questions_available
      ORDER BY r.score ASC
      LIMIT 10
    CYPHER

    @neo4j.execute(query, user_id: @user.id)
  end

  def generate_learning_path
    weak_points = identify_weak_points

    learning_path = []
    weak_points.each do |point|
      # Check if prerequisites are mastered
      unmastered_prereqs = point[:prerequisites].reject do |prereq|
        concept_mastered?(prereq)
      end

      if unmastered_prereqs.any?
        # Learn prerequisites first
        unmastered_prereqs.each do |prereq|
          learning_path << {
            concept: prereq,
            type: 'prerequisite',
            priority: 'high',
            reason: "Required for #{point[:concept]}"
          }
        end
      end

      # Then the main concept
      learning_path << {
        concept: point[:concept],
        type: 'weak_point',
        priority: calculate_priority(point),
        practice_questions: point[:practice_questions_available]
      }
    end

    learning_path.uniq { |item| item[:concept] }
  end

  private

  def calculate_strength_score
    # Weighted score based on concept mastery
    mastered_weight = 1.0
    weak_weight = 0.3
    untested_weight = 0.0

    mastered = fetch_mastered_concepts
    weak = fetch_weak_concepts
    total = fetch_total_concepts
    untested = total - mastered - weak

    score = (mastered * mastered_weight +
             weak * weak_weight +
             untested * untested_weight) / total

    (score * 100).round
  end

  def predict_exam_score
    # Based on historical performance and current mastery
    strength = calculate_strength_score
    practice_bonus = calculate_practice_bonus

    predicted = strength * 0.7 + practice_bonus * 0.3
    [predicted, 100].min.round
  end
end
```

#### 3. Recommendation Service

```ruby
# app/services/recommendation_service.rb
class RecommendationService < BaseService
  def initialize(user)
    @user = user
    @progress_service = UserProgressService.new(user)
  end

  def recommend_next_study_session
    weak_points = @progress_service.identify_weak_points
    learning_path = @progress_service.generate_learning_path

    # Select next concept to study
    next_concept = learning_path.first

    # Find relevant questions
    questions = find_questions_for_concept(next_concept[:concept])

    # Determine session type
    session_type = determine_session_type(next_concept)

    {
      concept: next_concept[:concept],
      reason: next_concept[:reason],
      session_type: session_type,
      questions: questions,
      estimated_time: estimate_study_time(questions.count),
      expected_improvement: calculate_expected_improvement(next_concept)
    }
  end

  def recommend_study_materials(concept)
    # Find materials that explain this concept
    materials = StudyMaterial.joins(:questions => :concepts)
                             .where(concepts: { name: concept })
                             .distinct

    # Rank by relevance
    ranked_materials = materials.map do |material|
      {
        material: material,
        relevance_score: calculate_relevance(material, concept),
        difficulty_match: match_difficulty(material, @user)
      }
    end.sort_by { |m| -m[:relevance_score] }

    ranked_materials.first(5)
  end

  private

  def determine_session_type(concept_data)
    case concept_data[:type]
    when 'prerequisite'
      'learning' # New concept introduction
    when 'weak_point'
      'practice' # Reinforcement
    else
      'review'   # Maintenance
    end
  end

  def calculate_expected_improvement(concept_data)
    base_improvement = 10 # Base improvement percentage

    # Adjust based on concept importance
    importance_multiplier = concept_data[:priority] == 'high' ? 1.5 : 1.0

    # Adjust based on available practice questions
    practice_multiplier = [concept_data[:practice_questions] / 10.0, 2.0].min

    (base_improvement * importance_multiplier * practice_multiplier).round
  end
end
```

---

## Database Architecture

### Hybrid Database Strategy

```
┌─────────────────────────────────────────────┐
│             SQLite3 (Primary)                │
│  - Users, StudySets, Questions               │
│  - Payments, Sessions, Analytics             │
│  - Vector embeddings (JSON columns)          │
│  - Cached graph data (JSON columns)          │
└───────────────┬─────────────────────────────┘
                │
                ├── Synchronization Layer
                │
┌───────────────▼─────────────────────────────┐
│          Neo4j AuraDB (Graph)                │
│  - Concept nodes and relationships           │
│  - User knowledge state                      │
│  - Prerequisite chains                       │
│  - GraphRAG queries                          │
└─────────────────────────────────────────────┘
```

### SQLite3 Schema Extensions

```ruby
# db/migrate/add_json_columns_for_graph_data.rb
class AddJsonColumnsForGraphData < ActiveRecord::Migration[7.2]
  def change
    # Store graph data in JSON for fast access
    add_column :questions, :graph_data, :json, default: {}
    add_column :users, :knowledge_state, :json, default: {}
    add_column :study_sets, :concept_map, :json, default: {}

    # Indexes for JSON queries
    add_index :questions, :graph_data, using: :gin
    add_index :users, :knowledge_state, using: :gin
  end
end

# db/migrate/add_vector_similarity_function.rb
class AddVectorSimilarityFunction < ActiveRecord::Migration[7.2]
  def up
    # Create custom function for vector similarity
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS vector_cache (
        id INTEGER PRIMARY KEY,
        question_id INTEGER NOT NULL,
        vector TEXT NOT NULL,
        magnitude REAL NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (question_id) REFERENCES questions(id)
      );

      CREATE INDEX IF NOT EXISTS idx_vector_cache_question
      ON vector_cache(question_id);
    SQL
  end

  def down
    execute "DROP TABLE IF EXISTS vector_cache;"
  end
end
```

### Data Synchronization

```ruby
# app/services/data_sync_service.rb
class DataSyncService
  def sync_to_neo4j(question)
    # Extract concepts from SQLite
    concepts = question.graph_data['concepts'] || []

    # Create/update in Neo4j
    neo4j_client = Graph::Neo4jClient.new
    concepts.each do |concept|
      neo4j_client.create_concept(
        concept['name'],
        concept.except('name')
      )
    end

    # Create relationships
    question.graph_data['relationships']&.each do |rel|
      neo4j_client.execute(
        "MATCH (a:Concept {name: $from}), (b:Concept {name: $to})
         CREATE (a)-[:#{rel['type']}]->(b)",
        from: rel['from'],
        to: rel['to']
      )
    end
  end

  def cache_from_neo4j(user)
    # Fetch user's knowledge state from Neo4j
    neo4j_data = Graph::Neo4jClient.new.get_knowledge_subgraph(user.id)

    # Cache in SQLite JSON column
    user.update!(
      knowledge_state: {
        concepts: neo4j_data[:concepts],
        relationships: neo4j_data[:relationships],
        last_synced: Time.current
      }
    )
  end
end
```

---

## Security Architecture

### Security Layers

```
┌─────────────────────────────────────────────┐
│          Application Security                │
│   - CSRF Protection                          │
│   - XSS Prevention                           │
│   - SQL Injection Prevention                 │
└─────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────┐
│         Authentication & Authorization        │
│   - Devise + JWT                             │
│   - Role-based Access Control                │
│   - Session Management                       │
└─────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────┐
│            API Security                      │
│   - Rate Limiting                            │
│   - API Key Management                       │
│   - Webhook Verification                     │
└─────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────┐
│            Data Security                     │
│   - Encryption at Rest                       │
│   - Secure File Storage                      │
│   - PII Protection                           │
└─────────────────────────────────────────────┘
```

### Implementation Details

```ruby
# config/initializers/security.rb
Rails.application.config.middleware.use Rack::Attack

Rack::Attack.throttle('api/ip', limit: 100, period: 1.minute) do |req|
  req.ip if req.path.start_with?('/api')
end

Rack::Attack.throttle('login/email', limit: 5, period: 1.minute) do |req|
  req.params['email'] if req.path == '/login' && req.post?
end

# app/controllers/api/base_controller.rb
class Api::BaseController < ApplicationController
  before_action :verify_api_key
  before_action :set_rate_limit_headers

  private

  def verify_api_key
    api_key = request.headers['X-API-Key']

    unless valid_api_key?(api_key)
      render json: { error: 'Invalid API key' }, status: :unauthorized
    end
  end

  def valid_api_key?(key)
    # Implement API key validation
    ApiKey.active.where(key: key).exists?
  end
end
```

---

## Performance & Scaling

### Performance Optimization Strategies

1. **Database Optimization**
   - Proper indexing on foreign keys and frequently queried columns
   - Query optimization using EXPLAIN ANALYZE
   - N+1 query prevention with includes/preload

2. **Caching Strategy**
   ```ruby
   # config/environments/production.rb
   config.cache_store = :solid_cache_store

   # app/models/question.rb
   def similar_questions
     Rails.cache.fetch("similar_questions/#{id}", expires_in: 1.hour) do
       # Expensive similarity calculation
       AI::EmbeddingService.new.find_similar(embedding, limit: 10)
     end
   end
   ```

3. **Background Processing**
   - Offload heavy operations to background jobs
   - Use different priority queues
   - Implement job batching for bulk operations

4. **Asset Optimization**
   - CDN for static assets
   - Image optimization with Active Storage variants
   - JavaScript and CSS minification

### Scaling Plan

| Users | Infrastructure | Estimated Cost |
|-------|---------------|----------------|
| 0-100 | Single server (4GB RAM) | $20/month |
| 100-1,000 | Load balanced (2 servers) | $80/month |
| 1,000-10,000 | Auto-scaling + CDN | $300/month |
| 10,000+ | Kubernetes cluster | $1,000+/month |

---

## Deployment Architecture

### Production Deployment with Kamal

```yaml
# config/deploy.yml
service: examsgraph
image: examsgraph/app

servers:
  web:
    - 165.232.143.237
  job:
    hosts:
      - 165.232.143.238
    cmd: bundle exec solid_queue:start

registry:
  username: examsgraph
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    RAILS_LOG_TO_STDOUT: true
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
    - NEO4J_URI
    - OPENAI_API_KEY
    - UPSTAGE_API_KEY
    - TOSS_SECRET_KEY

accessories:
  redis:
    image: redis:7
    host: 165.232.143.237
    port: 6379
    volumes:
      - /var/lib/redis:/data

traefik:
  options:
    publish:
      - "443:443"
    volume:
      - "/letsencrypt/acme.json:/letsencrypt/acme.json"
  args:
    entryPoints.web.address: ":80"
    entryPoints.websecure.address: ":443"
    certificatesResolvers.letsencrypt.acme.email: "admin@examsgraph.com"
    certificatesResolvers.letsencrypt.acme.storage: "/letsencrypt/acme.json"
    certificatesResolvers.letsencrypt.acme.httpchallenge: true
    certificatesResolvers.letsencrypt.acme.httpchallenge.entrypoint: "web"

healthcheck:
  path: /health
  port: 3000
  max_attempts: 10
  interval: 20s
```

### Health Monitoring

```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    checks = {
      database: check_database,
      redis: check_redis,
      neo4j: check_neo4j,
      storage: check_storage
    }

    if checks.values.all?
      render json: { status: 'healthy', checks: checks }
    else
      render json: { status: 'unhealthy', checks: checks }, status: :service_unavailable
    end
  end

  private

  def check_database
    ActiveRecord::Base.connection.active?
  rescue
    false
  end

  def check_redis
    Redis.current.ping == 'PONG'
  rescue
    false
  end

  def check_neo4j
    Graph::Neo4jClient.new.execute('RETURN 1').present?
  rescue
    false
  end

  def check_storage
    ActiveStorage::Blob.service.exist?('health-check')
  rescue
    true # Storage is optional
  end
end
```

---

## Conclusion

This comprehensive architecture document provides the complete technical blueprint for implementing the remaining 40% of ExamsGraph MVP functionality. The architecture emphasizes:

1. **Pragmatic Technology Choices** - Using boring technology that works (Rails, SQLite3)
2. **Scalable Design** - Starting simple but designed to scale when needed
3. **AI/ML Integration** - Clear pipeline for processing and analysis
4. **User Experience Focus** - Every technical decision supports better learning outcomes
5. **Cost Efficiency** - Optimized for MVP budget constraints while maintaining quality

The modular service architecture ensures clean separation of concerns, making the system maintainable and testable. The hybrid database approach leverages the strengths of both SQLite3 (simplicity) and Neo4j (graph analysis) without unnecessary complexity.

With this architecture, ExamsGraph can deliver on its promise of transforming static PDF materials into dynamic, personalized learning experiences while maintaining development velocity and operational simplicity.

---

**Next Steps:**
1. Review and approve architecture
2. Generate detailed story implementations
3. Begin sprint planning for remaining features
4. Start implementation with payment system (highest business value)

---

_"The best architecture is the one that ships and scales when it needs to."_ - Winston