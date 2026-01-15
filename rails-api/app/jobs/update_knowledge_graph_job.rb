class UpdateKnowledgeGraphJob < ApplicationJob
  queue_as :graph_update

  # Neo4j 연결 실패 시 재시도
  retry_on Timeout::Error, wait: 15.seconds, attempts: 4
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  # 직렬화 에러 폐기
  discard_on ActiveJob::SerializationError

  def perform(question_id, user_id = nil)
    question = Question.find(question_id)

    begin
      Rails.logger.info("Updating knowledge graph for question: #{question_id}")

      # 그래프 서비스 초기화
      graph_service = KnowledgeGraphService.new

      # 질문에서 개념 추출
      concepts = extract_concepts_from_question(question)

      # Neo4j에 개념과 관계 저장
      update_graph_with_concepts(graph_service, question, concepts)

      # 사용자 성과 데이터가 있으면 그래프 업데이트
      if user_id.present?
        user = User.find_by(id: user_id)
        update_user_performance_graph(graph_service, user, question) if user.present?
      end

      Rails.logger.info("Knowledge graph updated successfully for question: #{question_id}")
    rescue => e
      Rails.logger.error("Error updating knowledge graph for question #{question_id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise e  # 재시도를 위해 에러 발생
    end
  end

  private

  def extract_concepts_from_question(question)
    # LLM을 사용하여 질문에서 개념 추출
    concept_extraction_service = ConceptExtractionService.new

    concepts = concept_extraction_service.extract(
      question_content: question.content,
      passage: question.passage,
      topic: question.topic
    )

    # 응답 파싱 (JSON 형식으로 개념과 관계 반환)
    parse_concepts_from_response(concepts)
  rescue => e
    Rails.logger.warn("Failed to extract concepts from question #{question.id}: #{e.message}")
    []  # 개념 추출 실패 시 빈 배열 반환
  end

  def parse_concepts_from_response(response)
    return [] unless response.present?

    concepts = []

    # 응답에서 개념 추출 (구조: { concepts: [...], relationships: [...] })
    if response.is_a?(Hash)
      concepts = response['concepts'] || response[:concepts] || []
    elsif response.is_a?(String)
      begin
        parsed = JSON.parse(response)
        concepts = parsed['concepts'] || []
      rescue JSON::ParserError
        Rails.logger.warn("Failed to parse concepts from response: #{response}")
        concepts = []
      end
    end

    concepts
  end

  def update_graph_with_concepts(graph_service, question, concepts)
    # 질문 노드 생성/업데이트
    question_node = {
      id: question.id,
      type: "Question",
      properties: {
        content: question.content,
        topic: question.topic,
        difficulty: question.difficulty,
        embedding: question.embedding
      }
    }

    # 개념 노드와 관계 생성
    concepts.each do |concept|
      concept_node = {
        id: "concept_#{concept['id']}",
        type: "Concept",
        properties: {
          name: concept['name'],
          category: concept['category'],
          description: concept['description']
        }
      }

      # Neo4j에 노드 생성
      graph_service.create_or_update_node(concept_node)

      # 질문과 개념 간 관계 생성
      relationship = {
        from: question_node[:id],
        to: concept_node[:id],
        type: concept['relationship_type'] || "TESTS",
        properties: {
          importance: concept['importance'] || 1.0
        }
      }

      graph_service.create_relationship(relationship)
    end

    # 전제 조건 관계 생성 (개념 간 의존성)
    prerequisites = extract_prerequisites_from_concepts(concepts)
    prerequisites.each do |prerequisite|
      relationship = {
        from: prerequisite['from_concept_id'],
        to: prerequisite['to_concept_id'],
        type: "PREREQUISITE",
        properties: {
          strength: prerequisite['strength'] || 0.5
        }
      }

      graph_service.create_relationship(relationship)
    end
  rescue => e
    Rails.logger.error("Error updating graph with concepts: #{e.message}")
    # 그래프 업데이트 실패해도 계속 진행 (부분 실패 허용)
  end

  def update_user_performance_graph(graph_service, user, question)
    # 사용자 노드 생성/업데이트
    user_node = {
      id: user.id,
      type: "User",
      properties: {
        email: user.email,
        name: user.name
      }
    }

    graph_service.create_or_update_node(user_node)

    # 사용자와 문제 간 시도 관계 생성
    relationship = {
      from: user_node[:id],
      to: question.id,
      type: "ATTEMPTED",
      properties: {
        timestamp: Time.current,
        metadata: {}
      }
    }

    graph_service.create_relationship(relationship)
  rescue => e
    Rails.logger.warn("Error updating user performance graph: #{e.message}")
    # 사용자 성과 그래프 업데이트 실패해도 무시
  end

  def extract_prerequisites_from_concepts(concepts)
    # 개념 간 전제 조건 관계 추출
    prerequisites = []

    concepts.each do |concept|
      if concept['prerequisites'].is_a?(Array)
        concept['prerequisites'].each do |prerequisite_id|
          prerequisites << {
            from_concept_id: "concept_#{prerequisite_id}",
            to_concept_id: "concept_#{concept['id']}",
            strength: concept['prerequisite_strength'] || 0.7
          }
        end
      end
    end

    prerequisites
  end
end
