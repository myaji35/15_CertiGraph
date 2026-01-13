# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Create test user
test_user = User.find_or_create_by!(email: 'test@example.com') do |user|
  user.password = 'password123'
  user.name = 'Test User'
  user.role = 'free'
end

puts "✅ Created test user: #{test_user.email}"

# Create sample study set (use 'title' instead of 'name')
study_set = test_user.study_sets.find_or_create_by!(title: '정보처리기사 실기 모의고사') do |set|
  set.description = '2024년 정보처리기사 실기 대비 모의고사 문제집'
  set.certification = 'engineer_information_processing'
end

puts "✅ Created study set: #{study_set.title}"

# Create sample study material
material = study_set.study_materials.find_or_create_by!(name: '2024년 1회차 기출문제') do |mat|
  mat.status = 'completed'
  mat.parsing_progress = 100
  mat.extracted_data = { total_questions: 10, chunks: 3 }
end

puts "✅ Created study material: #{material.name}"

# Sample questions with JSON options
questions_data = [
  {
    content: "다음 중 객체지향 프로그래밍의 특징이 아닌 것은?",
    options: {
      "①" => "캡슐화(Encapsulation)",
      "②" => "상속(Inheritance)",
      "③" => "다형성(Polymorphism)",
      "④" => "절차지향(Procedural)"
    },
    answer: "④",
    explanation: "절차지향은 객체지향이 아닌 프로그래밍 패러다임입니다.",
    topic: "프로그래밍 언어",
    difficulty: 1
  },
  {
    content: "TCP와 UDP의 차이점으로 옳지 않은 것은?",
    options: {
      "①" => "TCP는 연결 지향적이다",
      "②" => "UDP는 비연결 지향적이다",
      "③" => "TCP는 신뢰성을 보장한다",
      "④" => "UDP가 TCP보다 느리다"
    },
    answer: "④",
    explanation: "UDP는 TCP보다 빠릅니다. 신뢰성 검사를 하지 않기 때문입니다.",
    topic: "네트워크",
    difficulty: 2
  },
  {
    content: "다음 중 스택(Stack) 자료구조의 특징은?",
    options: {
      "①" => "FIFO (First In First Out)",
      "②" => "LIFO (Last In First Out)",
      "③" => "Random Access",
      "④" => "Priority Based"
    },
    answer: "②",
    explanation: "스택은 LIFO(Last In First Out) 구조를 가집니다.",
    topic: "자료구조",
    difficulty: 1
  },
  {
    content: "HTTP 상태 코드 404가 의미하는 것은?",
    options: {
      "①" => "성공(Success)",
      "②" => "리다이렉션(Redirection)",
      "③" => "클라이언트 에러 - Not Found",
      "④" => "서버 에러(Server Error)"
    },
    answer: "③",
    explanation: "404는 요청한 리소스를 찾을 수 없음을 의미합니다.",
    topic: "웹 프로그래밍",
    difficulty: 1
  },
  {
    content: "Git에서 브랜치를 병합하는 명령어는?",
    options: {
      "①" => "git commit",
      "②" => "git push",
      "③" => "git merge",
      "④" => "git pull"
    },
    answer: "③",
    explanation: "git merge 명령어를 사용하여 브랜치를 병합합니다.",
    topic: "형상관리",
    difficulty: 1
  }
]

# Create questions
questions_data.each_with_index do |q_data, index|
  Question.find_or_create_by!(
    study_material: material,
    content: q_data[:content],
    question_number: index + 1
  ) do |q|
    q.options = q_data[:options]
    q.answer = q_data[:answer]
    q.explanation = q_data[:explanation]
    q.topic = q_data[:topic]
    q.difficulty = q_data[:difficulty]
  end
end

puts "✅ Created #{questions_data.length} questions"
puts "🎉 Seeding completed successfully!"
puts "\n📝 Test credentials:"
puts "   Email: test@example.com"
puts "   Password: password123"
puts "\n🔗 Visit: http://localhost:3001/study_sets to start testing!"
