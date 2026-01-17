# Epic 3 Test Data Seed Script
# Creates test study_set and questions for exam testing

puts "🌱 Starting Epic 3 test data seed..."

# Find or create test user
user = User.find_or_create_by!(email: 'test@example.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.name = 'Test User'
end

puts "✅ User found/created: #{user.email}"

# Clean up existing test data
user.study_sets.where(title: 'Epic 3 Test Study Set').destroy_all
puts "🧹 Cleaned up existing test data"

# Create study set
study_set = user.study_sets.create!(
  title: 'Epic 3 Test Study Set',
  description: 'Test study set for Epic 3 mock exam tests',
  certification: 'information-processing'
)

puts "✅ Study set created: #{study_set.title} (ID: #{study_set.id})"

# Create study material
study_material = study_set.study_materials.create!(
  name: 'Epic 3 Test Material',
  category: 'information-processing',
  difficulty_level: 'intermediate',
  status: 'completed'
)

puts "✅ Study material created: #{study_material.name} (ID: #{study_material.id})"

# Create 150 questions across 4 chapters with varying difficulties
difficulties = ['easy', 'medium', 'hard']
chapters = [1, 2, 3, 4]

150.times do |i|
  chapter = chapters[i % 4]
  difficulty = difficulties[i % 3]
  question_num = i + 1

  # Build options hash
  options_hash = {}
  4.times do |opt_num|
    option_label = "#{opt_num + 1}"
    options_hash[option_label] = "선택지 #{opt_num + 1}"
  end

  question = study_material.questions.create!(
    question_number: question_num,
    content: "테스트 문제 #{question_num}: 정보처리기사 관련 문제입니다.",
    options: options_hash,
    answer: (i % 4 + 1).to_s, # Answers: 1, 2, 3, 4
    difficulty: difficulty,
    topic: "챕터 #{chapter} - 주제 #{i % 5 + 1}",
    explanation: "이것은 #{question_num}번 문제의 해설입니다."
  )

  print "." if (i + 1) % 10 == 0
end

puts "\n✅ Created 150 questions with options"

# Update study_material parsing progress
study_material.update_columns(
  parsing_progress: 100
)

puts "✅ Updated study material parsing progress"

# Output final summary
puts "\n" + "="*50
puts "✅ Epic 3 Test Data Seed Complete!"
puts "="*50
puts "User: #{user.email}"
puts "Study Set ID: #{study_set.id}"
puts "Study Set Title: #{study_set.title}"
puts "Study Material ID: #{study_material.id}"
puts "Total Questions: #{study_material.questions.count}"
puts ""
puts "Difficulty Distribution:"
puts "  Easy: #{study_material.questions.where(difficulty: 'easy').count}"
puts "  Medium: #{study_material.questions.where(difficulty: 'medium').count}"
puts "  Hard: #{study_material.questions.where(difficulty: 'hard').count}"
puts ""
puts "Chapter Distribution:"
chapters.each do |ch|
  count = study_material.questions.where(chapter: "챕터 #{ch}").count
  puts "  Chapter #{ch}: #{count} questions"
end
puts "="*50
