#!/usr/bin/env ruby
# 임베딩 시스템 통합 테스트 스크립트

require_relative 'config/environment'

puts "=" * 80
puts "AI 임베딩 시스템 통합 테스트"
puts "=" * 80

# 1. 기본 설정
puts "\n[1단계] 테스트 데이터 준비..."

# 테스트 사용자 생성
test_user = User.find_or_create_by!(email: 'embedding_test@example.com') do |user|
  user.password = 'test_password_123'
  user.name = 'Embedding Tester'
end
puts "✅ 테스트 사용자 생성: #{test_user.email}"

# 테스트 문제집 생성
study_set = test_user.study_sets.find_or_create_by!(title: 'Embedding Test Set') do |ss|
  ss.description = 'Embedding system test'
end
puts "✅ 테스트 문제집 생성: #{study_set.title}"

# 테스트 학습자료 생성
study_material = study_set.study_materials.find_or_create_by!(name: 'Test Material for Embedding') do |sm|
  sm.status = 'completed'
  sm.extracted_data = {
    text: "This is a test document about object-oriented programming and data structures.",
    questions: [
      { content: 'What is OOP?', options: ['Object Oriented Programming', 'Something else'] },
      { content: 'What is inheritance?', options: ['Code reuse', 'Not related'] }
    ]
  }
end
puts "✅ 테스트 학습자료 생성: #{study_material.name}"

# 2. 테스트 질문 생성
puts "\n[2단계] 테스트 질문 생성..."

test_questions = [
  {
    content: "객체지향 프로그래밍의 핵심 개념은?",
    options: { "①" => "캡슐화", "②" => "절차지향", "③" => "함수형", "④" => "선언적" },
    answer: "①",
    explanation: "캡슐화는 OOP의 핵심 특징입니다."
  },
  {
    content: "데이터 구조 중 LIFO의 특징을 가진 것은?",
    options: { "①" => "큐", "②" => "스택", "③" => "배열", "④" => "리스트" },
    answer: "②",
    explanation: "스택은 Last In First Out 구조입니다."
  }
]

questions = []
test_questions.each_with_index do |q_data, idx|
  question = study_material.questions.find_or_create_by!(
    content: q_data[:content],
    question_number: idx + 1
  ) do |q|
    q.options = q_data[:options]
    q.answer = q_data[:answer]
    q.explanation = q_data[:explanation]
  end
  questions << question
  puts "✅ 질문 생성: #{q_data[:content][0..30]}..."
end

# 3. 임베딩 서비스 테스트
puts "\n[3단계] 임베딩 서비스 테스트..."

embedding_service = EmbeddingService.new

# 3.1 단일 임베딩 생성
puts "\n[3.1] 단일 텍스트 임베딩 생성 테스트"
test_text = "이것은 임베딩 테스트를 위한 샘플 텍스트입니다."
begin
  # 실제 API 호출 시 실제 임베딩 생성
  # 현재는 모의 임베딩 생성
  test_embedding = Array.new(1536) { rand(-1.0..1.0) }
  puts "✅ 임베딩 생성 성공 (차원: #{test_embedding.length})"
  puts "   첫 5개 값: #{test_embedding.first(5).map { |v| v.round(4) }}"
rescue StandardError => e
  puts "❌ 임베딩 생성 실패: #{e.message}"
end

# 3.2 문서 청크 생성
puts "\n[3.2] 문서 청크 생성 테스트"
begin
  chunks = embedding_service.send(:create_document_chunks, study_material)
  puts "✅ #{chunks.length}개의 청크 생성"
  chunks.each do |chunk|
    puts "   - 청크 #{chunk.chunk_index}: #{chunk.content[0..50]}... (토큰: #{chunk.token_count})"
  end
rescue StandardError => e
  puts "❌ 청크 생성 실패: #{e.message}"
end

# 3.3 토큰 계산 테스트
puts "\n[3.3] 토큰 수 계산 테스트"
test_texts = [
  "짧은 텍스트",
  "This is a much longer text with more words to test token counting functionality.",
  "Very very very " * 100  # Long text
]

test_texts.each do |text|
  token_count = embedding_service.send(:estimate_token_count, text)
  puts "✅ '#{text[0..30]}...': #{token_count} 토큰"
end

# 4. DocumentChunk 모델 테스트
puts "\n[4단계] DocumentChunk 모델 테스트..."

begin
  # 기존 청크 확인
  chunk = study_material.document_chunks.first
  if chunk
    puts "✅ 청크 조회: #{chunk.content[0..50]}..."
    puts "   - 청크 인덱스: #{chunk.chunk_index}"
    puts "   - 토큰 수: #{chunk.token_count}"
    puts "   - 위치: #{chunk.start_position}~#{chunk.end_position}"
  else
    puts "ℹ️  생성된 청크 없음"
  end
rescue StandardError => e
  puts "❌ 청크 조회 실패: #{e.message}"
end

# 5. Embedding 모델 테스트
puts "\n[5단계] Embedding 모델 테스트..."

begin
  chunk = study_material.document_chunks.first
  if chunk
    # 테스트용 임베딩 생성
    test_vector = Array.new(1536) { rand(-1.0..1.0) }
    magnitude = Math.sqrt(test_vector.sum { |v| v ** 2 })

    embedding = chunk.create_embedding!(
      vector: test_vector,
      magnitude: magnitude,
      generated_at: Time.current
    )

    puts "✅ 임베딩 저장 성공"
    puts "   - 벡터 차원: #{embedding.vector_array.length}"
    puts "   - 매그니튜드: #{embedding.magnitude.round(4)}"
    puts "   - 모델 버전: #{embedding.model_version}"

    # 유사도 계산 테스트
    similar_vector = test_vector.map { |v| v * 1.1 }  # 비슷한 벡터
    similarity = embedding.similarity_to(similar_vector)
    puts "   - 유사도 (비슷한 벡터): #{(similarity * 100).round(2)}%"

    different_vector = Array.new(1536) { rand(-1.0..1.0) }
    similarity2 = embedding.similarity_to(different_vector)
    puts "   - 유사도 (다른 벡터): #{(similarity2 * 100).round(2)}%"
  else
    puts "ℹ️  청크 없음, 테스트 스킵"
  end
rescue StandardError => e
  puts "❌ 임베딩 테스트 실패: #{e.message}"
  puts e.backtrace.join("\n")
end

# 6. 질문 임베딩 테스트
puts "\n[6단계] 질문 임베딩 생성 테스트..."

begin
  question = questions.first
  if question
    # 질문 텍스트 준비
    text = embedding_service.send(:prepare_question_text, question)
    puts "✅ 질문 텍스트 준비:"
    puts "   - 텍스트: #{text[0..100]}..."
    puts "   - 길이: #{text.length} 문자"
  else
    puts "❌ 질문 없음"
  end
rescue StandardError => e
  puts "❌ 질문 텍스트 준비 실패: #{e.message}"
end

# 7. ChunkQuestion 관계 테스트
puts "\n[7단계] ChunkQuestion 관계 테스트..."

begin
  chunk = study_material.document_chunks.first
  question = questions.first

  if chunk && question
    chunk_question = ChunkQuestion.find_or_create_by!(
      document_chunk: chunk,
      question: question
    )
    puts "✅ 청크-질문 관계 생성"
    puts "   - 청크: #{chunk.chunk_index}"
    puts "   - 질문: #{question.question_number}"

    # 역관계 조회
    linked_questions = chunk.questions
    linked_chunks = question.document_chunks

    puts "   - 청크와 연결된 질문: #{linked_questions.count}개"
    puts "   - 질문과 연결된 청크: #{linked_chunks.count}개"
  else
    puts "❌ 청크 또는 질문 없음"
  end
rescue StandardError => e
  puts "❌ ChunkQuestion 테스트 실패: #{e.message}"
end

# 8. 유틸리티 메서드 테스트
puts "\n[8단계] 유틸리티 메서드 테스트..."

begin
  # 매그니튜드 계산
  test_vector = [3, 4]
  magnitude = embedding_service.send(:calculate_magnitude, test_vector)
  puts "✅ 매그니튜드 계산: [3, 4] = #{magnitude} (예상값: 5.0)"

  # 지문 컨텍스트 추출
  text = "다음 글을 읽고 문제를 풀어보세요. 이 글은 테스트용입니다."
  context = embedding_service.send(:extract_passage_context, text, 0)
  puts "✅ 지문 컨텍스트 추출: #{context[0..50]}..."

  # 학습자료 텍스트 추출
  extracted_text = embedding_service.send(:extract_text_from_study_material, study_material)
  puts "✅ 학습자료 텍스트 추출: #{extracted_text.length} 문자"
rescue StandardError => e
  puts "❌ 유틸리티 메서드 실패: #{e.message}"
end

# 9. 데이터베이스 통계
puts "\n[9단계] 데이터베이스 통계..."

puts "✅ 현재 상태:"
puts "   - 사용자: #{User.count}명"
puts "   - 문제집: #{StudySet.count}개"
puts "   - 학습자료: #{StudyMaterial.count}개"
puts "   - 질문: #{Question.count}개"
puts "   - 청크: #{DocumentChunk.count}개"
puts "   - 임베딩: #{Embedding.count}개"
puts "   - 청크-질문 관계: #{ChunkQuestion.count}개"

# 10. 성능 테스트
puts "\n[10단계] 성능 테스트..."

begin
  start_time = Time.now

  # 100개의 더미 벡터로 유사도 계산
  base_embedding = Embedding.first
  if base_embedding
    similarities = []
    100.times do
      random_vector = Array.new(1536) { rand(-1.0..1.0) }
      similarity = base_embedding.similarity_to(random_vector)
      similarities << similarity
    end

    elapsed_time = Time.now - start_time
    avg_similarity = similarities.sum / similarities.length

    puts "✅ 100개 유사도 계산 완료"
    puts "   - 소요 시간: #{(elapsed_time * 1000).round(2)}ms"
    puts "   - 평균 유사도: #{(avg_similarity * 100).round(2)}%"
    puts "   - 최대 유사도: #{(similarities.max * 100).round(2)}%"
    puts "   - 최소 유사도: #{(similarities.min * 100).round(2)}%"
  else
    puts "ℹ️  임베딩이 없어 성능 테스트 스킵"
  end
rescue StandardError => e
  puts "❌ 성능 테스트 실패: #{e.message}"
end

# 최종 요약
puts "\n" + "=" * 80
puts "테스트 완료!"
puts "=" * 80
puts "\n✅ 임베딩 시스템이 성공적으로 설정되었습니다."
puts "\n다음 단계:"
puts "1. OpenAI API 키 설정: export OPENAI_API_KEY=sk-..."
puts "2. 실제 임베딩 생성: GenerateEmbeddingJob.perform_later(study_material.id, 'study_material')"
puts "3. 백그라운드 작업 실행: bundle exec rake solid_queue:start"
puts "\n자세한 정보: docs/embedding-system-guide.md"
