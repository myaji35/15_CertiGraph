# Knowledge Graph 테스트 데이터 생성
# Usage: rails db:seed:knowledge_graph_seed

puts "Seeding Knowledge Graph data..."

# 사용자 및 학습 자료 생성
user = User.find_or_create_by(email: 'test@graph.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.name = 'Test User'
  u.encrypted_password = BCrypt::Password.create('password123')
end

study_set = StudySet.find_or_create_by(user_id: user.id, name: 'Knowledge Graph Test')

study_material = StudyMaterial.find_or_create_by(
  study_set_id: study_set.id,
  name: 'Advanced Math Concepts'
) do |sm|
  sm.status = 'completed'
end

# 온톨로지 구조 생성: Subject -> Chapter -> Concept -> Detail
puts "Creating ontology structure..."

# Subject: Mathematics
math_subject = KnowledgeNode.find_or_create_by(
  study_material_id: study_material.id,
  name: 'Mathematics'
) do |n|
  n.level = 'subject'
  n.description = 'Advanced Mathematics'
  n.difficulty = 4
  n.importance = 5
end

# Chapters under Mathematics
algebra_chapter = KnowledgeNode.find_or_create_by(
  study_material_id: study_material.id,
  name: 'Algebra'
) do |n|
  n.level = 'chapter'
  n.description = 'Algebraic concepts and operations'
  n.difficulty = 3
  n.importance = 5
  n.parent_name = 'Mathematics'
end

calculus_chapter = KnowledgeNode.find_or_create_by(
  study_material_id: study_material.id,
  name: 'Calculus'
) do |n|
  n.level = 'chapter'
  n.description = 'Differential and Integral Calculus'
  n.difficulty = 4
  n.importance = 5
  n.parent_name = 'Mathematics'
end

# Concepts under Algebra
polynomial = KnowledgeNode.find_or_create_by(
  study_material_id: study_material.id,
  name: 'Polynomial Equations'
) do |n|
  n.level = 'concept'
  n.description = 'Understanding and solving polynomial equations'
  n.difficulty = 3
  n.importance = 4
  n.parent_name = 'Algebra'
end

linear_system = KnowledgeNode.find_or_create_by(
  study_material_id: study_material.id,
  name: 'Linear Systems'
) do |n|
  n.level = 'concept'
  n.description = 'Solving systems of linear equations'
  n.difficulty = 2
  n.importance = 4
  n.parent_name = 'Algebra'
end

matrix = KnowledgeNode.find_or_create_by(
  study_material_id: study_material.id,
  name: 'Matrix Operations'
) do |n|
  n.level = 'concept'
  n.description = 'Matrix algebra and transformations'
  n.difficulty = 3
  n.importance = 4
  n.parent_name = 'Algebra'
end

# Concepts under Calculus
derivatives = KnowledgeNode.find_or_create_by(
  study_material_id: study_material.id,
  name: 'Derivatives'
) do |n|
  n.level = 'concept'
  n.description = 'Computing and applying derivatives'
  n.difficulty = 4
  n.importance = 5
  n.parent_name = 'Calculus'
end

integrals = KnowledgeNode.find_or_create_by(
  study_material_id: study_material.id,
  name: 'Integrals'
) do |n|
  n.level = 'concept'
  n.description = 'Definite and indefinite integrals'
  n.difficulty = 4
  n.importance = 5
  n.parent_name = 'Calculus'
end

# Details
quadratic_formula = KnowledgeNode.find_or_create_by(
  study_material_id: study_material.id,
  name: 'Quadratic Formula'
) do |n|
  n.level = 'detail'
  n.description = 'Using quadratic formula to solve equations'
  n.difficulty = 2
  n.importance = 4
  n.parent_name = 'Polynomial Equations'
end

fundamental_theorem = KnowledgeNode.find_or_create_by(
  study_material_id: study_material.id,
  name: 'Fundamental Theorem of Calculus'
) do |n|
  n.level = 'detail'
  n.description = 'Connection between derivatives and integrals'
  n.difficulty = 5
  n.importance = 5
  n.parent_name = 'Calculus'
end

puts "Creating relationships..."

# Create prerequisite relationships
linear_system.add_prerequisite(matrix, weight: 0.8, reasoning: 'Matrix knowledge helps understand linear systems')
polynomial.add_prerequisite(linear_system, weight: 0.6, reasoning: 'Polynomial factoring uses linear concepts')
derivatives.add_prerequisite(polynomial, weight: 0.7, reasoning: 'Derivatives of polynomials are fundamental')
integrals.add_prerequisite(derivatives, weight: 0.9, reasoning: 'Integration is reverse of differentiation')

# Create related_to relationships
derivatives.add_related_concept(integrals, weight: 0.8, reasoning: 'Derivatives and integrals are complementary')
polynomial.add_related_concept(matrix, weight: 0.5, reasoning: 'Both used in linear algebra')

# Create part_of relationships
math_subject.add_part_of(algebra_chapter, weight: 0.9, reasoning: 'Algebra is part of Mathematics')
math_subject.add_part_of(calculus_chapter, weight: 0.9, reasoning: 'Calculus is part of Mathematics')
algebra_chapter.add_part_of(polynomial, weight: 0.9, reasoning: 'Polynomial equations are part of Algebra')
calculus_chapter.add_part_of(derivatives, weight: 0.9, reasoning: 'Derivatives are part of Calculus')

# Create example relationships
quadratic_formula.add_example(polynomial, weight: 0.7, reasoning: 'Quadratic formula is an example of solving polynomials')
fundamental_theorem.add_example(integrals, weight: 0.8, reasoning: 'Fundamental theorem exemplifies calculus concepts')

# Create user masteries
puts "Creating user mastery records..."

masteries_data = [
  { node: polynomial, correct: 8, attempts: 10 },        # 80% - learning
  { node: linear_system, correct: 9, attempts: 10 },     # 90% - mastered
  { node: matrix, correct: 4, attempts: 10 },            # 40% - weak
  { node: derivatives, correct: 6, attempts: 10 },       # 60% - learning
  { node: integrals, correct: 3, attempts: 10 },         # 30% - weak
  { node: quadratic_formula, correct: 10, attempts: 10 }, # 100% - mastered
  { node: fundamental_theorem, correct: 2, attempts: 8 }  # 25% - weak
]

masteries_data.each do |data|
  mastery = UserMastery.find_or_create_by(user_id: user.id, knowledge_node_id: data[:node].id)

  # Update mastery with attempts
  (1..data[:attempts]).each do |i|
    correct = i <= data[:correct]
    mastery.update_with_attempt(correct: correct, time_minutes: rand(5..20))
  end
end

puts "Knowledge Graph seed completed!"
puts "Created:"
puts "  - 1 User (test@graph.com)"
puts "  - 1 Study Material"
puts "  - #{KnowledgeNode.where(study_material_id: study_material.id).count} Knowledge Nodes"
puts "  - #{KnowledgeEdge.joins(:knowledge_node).where(knowledge_nodes: { study_material_id: study_material.id }).count} Relationships"
puts "  - #{UserMastery.where(user_id: user.id).count} User Masteries"
