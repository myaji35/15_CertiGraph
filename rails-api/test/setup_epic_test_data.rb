#!/usr/bin/env ruby
# Epic 4, 7, 8 테스트를 위한 샘플 데이터 생성 스크립트

require_relative '../config/environment'

puts "="*80
puts "Epic 4, 7, 8 테스트용 샘플 데이터 생성"
puts "="*80
puts

# 1. User 생성
puts "1. User 생성..."
user = User.find_or_create_by!(email: "test@example.com") do |u|
  u.name = "Test User"
  u.password = "password123"
  u.role = 0
end
puts "✓ User created: #{user.email}"

# 2. StudySet 생성
puts "\n2. StudySet 생성..."
study_set = StudySet.find_or_create_by!(
  user: user,
  title: "정보처리기사 2023"
) do |ss|
  ss.description = "Test study set for Epic 4, 7, 8"
  ss.certification = "정보처리기사"
end
puts "✓ StudySet created: #{study_set.title}"

# 3. StudyMaterial 생성
puts "\n3. StudyMaterial 생성..."
study_material = StudyMaterial.find_or_create_by!(
  study_set: study_set,
  name: "정보처리기사 2023년 1회 필기"
) do |sm|
  sm.status = "completed"
  sm.category = "information_processing"
  sm.difficulty = 3
end
puts "✓ StudyMaterial created: #{study_material.name}"

# 4. Passages 생성
puts "\n4. Passages 생성..."
passage1 = Passage.find_or_create_by!(
  study_material: study_material,
  content: "데이터베이스는 여러 사용자가 공유하여 사용할 목적으로 통합하여 관리되는 데이터의 집합이다."
) do |p|
  p.passage_type = "text"
  p.position = 1
end

passage2 = Passage.find_or_create_by!(
  study_material: study_material,
  content: "소프트웨어 개발 생명주기(SDLC)는 요구사항 분석, 설계, 구현, 테스팅, 유지보수 단계로 구성된다."
) do |p|
  p.passage_type = "text"
  p.position = 2
end
puts "✓ Created #{Passage.where(study_material: study_material).count} passages"

# 5. Questions 생성 (Epic 4: Question Extraction)
puts "\n5. Questions 생성..."
question1 = Question.find_or_create_by!(
  study_material: study_material,
  question_number: 1
) do |q|
  q.content = "데이터베이스의 특징이 아닌 것은?"
  q.options = [
    "실시간 접근성",
    "계속적인 변화",
    "동시 공유",
    "데이터 중복성"
  ]
  q.answer = "데이터 중복성"
  q.correct_answer_index = 3
  q.question_type = "multiple_choice"
  q.topic = "데이터베이스"
  q.difficulty = 2
  q.explanation = "데이터베이스는 데이터 중복을 최소화하는 것이 특징입니다."
  q.validation_status = "validated"
  q.ai_confidence_score = 0.95
end

question2 = Question.find_or_create_by!(
  study_material: study_material,
  question_number: 2
) do |q|
  q.content = "SDLC의 첫 번째 단계는?"
  q.options = [
    "설계",
    "요구사항 분석",
    "구현",
    "테스팅"
  ]
  q.answer = "요구사항 분석"
  q.correct_answer_index = 1
  q.question_type = "multiple_choice"
  q.topic = "소프트웨어공학"
  q.difficulty = 1
  q.explanation = "SDLC는 요구사항 분석 단계부터 시작합니다."
  q.validation_status = "validated"
  q.ai_confidence_score = 0.98
end

question3 = Question.find_or_create_by!(
  study_material: study_material,
  question_number: 3
) do |q|
  q.content = "정규화의 목적은?"
  q.options = [
    "데이터 중복 제거",
    "속도 향상",
    "보안 강화",
    "인덱스 생성"
  ]
  q.answer = "데이터 중복 제거"
  q.correct_answer_index = 0
  q.question_type = "multiple_choice"
  q.topic = "데이터베이스"
  q.difficulty = 2
  q.explanation = "정규화는 데이터 중복을 제거하고 무결성을 유지하기 위한 과정입니다."
  q.validation_status = "validated"
  q.ai_confidence_score = 0.92
end

puts "✓ Created #{Question.where(study_material: study_material).count} questions"

# 6. Question-Passage 연결
puts "\n6. Question-Passage 연결..."
QuestionPassage.find_or_create_by!(question: question1, passage: passage1)
QuestionPassage.find_or_create_by!(question: question2, passage: passage2)
puts "✓ Linked questions to passages"

# 7. KnowledgeNodes 생성 (Epic 7: Concept Extraction)
puts "\n7. KnowledgeNodes 생성..."
node1 = KnowledgeNode.find_or_create_by!(
  study_material: study_material,
  name: "데이터베이스"
) do |n|
  n.level = "concept"
  n.description = "데이터의 집합"
  n.importance = 5
end

node2 = KnowledgeNode.find_or_create_by!(
  study_material: study_material,
  name: "정규화"
) do |n|
  n.level = "concept"
  n.description = "데이터 중복 제거 과정"
  n.importance = 4
end

node3 = KnowledgeNode.find_or_create_by!(
  study_material: study_material,
  name: "소프트웨어공학"
) do |n|
  n.level = "concept"
  n.description = "소프트웨어 개발 방법론"
  n.importance = 5
end

node4 = KnowledgeNode.find_or_create_by!(
  study_material: study_material,
  name: "SDLC"
) do |n|
  n.level = "concept"
  n.description = "소프트웨어 개발 생명주기"
  n.importance = 4
end

puts "✓ Created #{KnowledgeNode.where(study_material: study_material).count} knowledge nodes"

# 8. KnowledgeEdges 생성 (Epic 8: Prerequisite Mapping)
puts "\n8. KnowledgeEdges 생성 (선수 관계)..."
edge1 = KnowledgeEdge.find_or_create_by!(
  knowledge_node_id: node1.id,
  related_node_id: node2.id
) do |e|
  e.relationship_type = "prerequisite"
  e.weight = 0.9
  e.strength = "mandatory"
  e.confidence_score = 0.9
end

edge2 = KnowledgeEdge.find_or_create_by!(
  knowledge_node_id: node3.id,
  related_node_id: node4.id
) do |e|
  e.relationship_type = "prerequisite"
  e.weight = 0.85
  e.strength = "recommended"
  e.confidence_score = 0.85
end

puts "✓ Created #{KnowledgeEdge.count} knowledge edges"

# 9. QuestionConcepts 연결
puts "\n9. Question-Concept 연결..."
QuestionConcept.find_or_create_by!(question: question1, knowledge_node: node1) do |qc|
  qc.relevance_score = 0.95
end

QuestionConcept.find_or_create_by!(question: question3, knowledge_node: node2) do |qc|
  qc.relevance_score = 0.92
end

QuestionConcept.find_or_create_by!(question: question2, knowledge_node: node4) do |qc|
  qc.relevance_score = 0.90
end

puts "✓ Linked questions to concepts"

# 10. ConceptSynonyms 생성
puts "\n10. ConceptSynonyms 생성..."
ConceptSynonym.find_or_create_by!(
  knowledge_node: node1,
  synonym_name: "DB"
)
ConceptSynonym.find_or_create_by!(
  knowledge_node: node1,
  synonym_name: "데이터베이스 시스템"
)
puts "✓ Created concept synonyms"

# 요약
puts "\n" + "="*80
puts "샘플 데이터 생성 완료!"
puts "="*80
puts "User: #{User.count}"
puts "StudySet: #{StudySet.count}"
puts "StudyMaterial: #{StudyMaterial.count}"
puts "Passages: #{Passage.count}"
puts "Questions: #{Question.count}"
puts "KnowledgeNodes: #{KnowledgeNode.count}"
puts "KnowledgeEdges: #{KnowledgeEdge.count}"
puts "QuestionPassages: #{QuestionPassage.count}"
puts "QuestionConcepts: #{QuestionConcept.count}"
puts "ConceptSynonyms: #{ConceptSynonym.count}"
puts "="*80
