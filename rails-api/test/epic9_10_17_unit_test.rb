#!/usr/bin/env ruby
# Epic 9, 10, 17 단위 테스트 (HTTP 서버 불필요)
# Epic 9: CBT Test Mode
# Epic 10: Answer Randomization
# Epic 17: Study Materials Marketplace

require_relative '../config/environment'

puts "="*80
puts "Epic 9, 10, 17 단위 테스트"
puts "="*80
puts

# 기존 샘플 데이터 사용
user = User.find_by(email: "test@example.com")
study_material = StudyMaterial.first
study_set = study_material&.study_set

unless user && study_material && study_set
  puts "❌ 테스트 데이터가 없습니다. 먼저 test/setup_epic_test_data.rb를 실행하세요."
  exit 1
end

puts "✓ 테스트 데이터 확인 완료"
puts "  User: #{user.email}"
puts "  StudySet: #{study_set.title}"
puts "  StudyMaterial: #{study_material.name}"
puts

# ============================================================================
# EPIC 9: CBT TEST MODE
# ============================================================================
puts "="*80
puts "Epic 9: CBT Test Mode (Computer-Based Testing)"
puts "="*80
puts

# Test 1: TestSession 생성
puts "Test 1: TestSession 생성"
puts "-"*40

test_session = TestSession.find_or_create_by!(
  user: user,
  study_set: study_set
) do |ts|
  ts.test_type = "practice"
  ts.status = "in_progress"
  ts.started_at = Time.current
end

puts "✓ TestSession 생성 완료"
puts "  ID: #{test_session.id}"
puts "  Type: #{test_session.test_type}"
puts "  Status: #{test_session.status}"
puts

# Test 2: TestQuestions 생성
puts "Test 2: TestQuestions 생성"
puts "-"*40

questions = Question.where(study_material: study_material).limit(3)
questions.each_with_index do |question, index|
  test_question = TestQuestion.find_or_create_by!(
    test_session: test_session,
    question: question
  ) do |tq|
    tq.question_number = index + 1
    tq.is_answered = false
  end
end

puts "✓ TestQuestions 생성 완료: #{TestQuestion.where(test_session: test_session).count}개"
puts

# Test 3: TestSession 네비게이션
puts "Test 3: TestSession 네비게이션"
puts "-"*40

if defined?(TestNavigationService)
  nav_service = TestNavigationService.new(test_session)

  puts "✓ Navigation Service 사용 가능"
  puts "  Current question: #{test_session.test_questions.first.question_number}"
  puts "  Total questions: #{test_session.test_questions.count}"
else
  puts "✓ TestQuestion count: #{test_session.test_questions.count}"
end
puts

# Test 4: 답안 제출
puts "Test 4: 답안 제출"
puts "-"*40

test_question = test_session.test_questions.first
test_answer = TestAnswer.find_or_create_by!(
  test_question: test_question
) do |ta|
  ta.selected_answer = test_question.question.answer
  ta.is_correct = true
  ta.answered_at = Time.current
end

test_question.update!(
  is_answered: true,
  time_started_at: 5.minutes.ago,
  time_spent: 300  # 5 minutes in seconds
)

puts "✓ 답안 제출 완료"
puts "  Question: #{test_question.question_number}"
puts "  Answer: #{test_answer.selected_answer}"
puts "  Correct: #{test_answer.is_correct}"
puts

# Test 5: TestSession 완료
puts "Test 5: TestSession 완료"
puts "-"*40

test_session.update!(
  status: "completed",
  completed_at: Time.current
)

score = test_session.test_answers.where(is_correct: true).count
total = test_session.test_questions.count
percentage = (score.to_f / total * 100).round(2)

puts "✓ TestSession 완료"
puts "  Score: #{score}/#{total} (#{percentage}%)"
puts

# ============================================================================
# EPIC 10: ANSWER RANDOMIZATION
# ============================================================================
puts "="*80
puts "Epic 10: Answer Randomization (선택지 순서 랜덤화)"
puts "="*80
puts

# Test 1: AnswerRandomizer 서비스
puts "Test 1: AnswerRandomizer 서비스"
puts "-"*40

if defined?(AnswerRandomizer)
  question = Question.where(study_material: study_material).first

  randomizer = AnswerRandomizer.new(strategy: 'full_random')
  original_options = question.options
  result = randomizer.randomize_question_options(question)
  randomized_options = result[:randomized_options]

  puts "✓ AnswerRandomizer 서비스 사용 가능"
  puts "  Original options: #{original_options.keys.join(', ')}"
  puts "  Randomized count: #{randomized_options.size}"
  puts "  Original correct: #{result[:original_correct_index]}"
  puts "  New correct: #{result[:new_correct_index]}"
  puts "  Seed: #{result[:seed][0..7]}..."
else
  puts "⚠ AnswerRandomizer 서비스 미구현"
end
puts

# Test 2: ExamSession with Randomization
puts "Test 2: ExamSession with Randomization"
puts "-"*40

exam_session = ExamSession.find_or_create_by!(
  user: user,
  study_set: study_set
) do |session|
  session.status = "in_progress"
  session.exam_type = "practice"
  session.started_at = Time.current
  session.randomization_enabled = true
  session.randomization_strategy = "full_random"
  session.total_questions = 10
end

puts "✓ ExamSession 생성 완료 (randomization_enabled=true)"
puts "  ID: #{exam_session.id}"
puts "  Randomization enabled: #{exam_session.randomization_enabled}"
puts "  Randomization strategy: #{exam_session.randomization_strategy}"
puts

# Test 3: RandomizationStats 추적
puts "Test 3: RandomizationStats 추적"
puts "-"*40

if defined?(RandomizationStat)
  question = Question.where(study_material: study_material).first

  # RandomizationStat tracks position statistics, not individual randomizations
  # Create a stat for tracking option position frequencies
  option_keys = question.options.keys
  first_option_key = option_keys.first

  stat = RandomizationStat.find_or_create_by!(
    study_material: study_material,
    question: question,
    option_id: 1,  # Using index as placeholder
    option_label: first_option_key
  ) do |s|
    s.position_0_count = 5
    s.position_1_count = 3
    s.position_2_count = 4
    s.position_3_count = 2
    s.total_randomizations = 14
    s.bias_score = 0.15
  end

  puts "✓ RandomizationStat 생성 완료 (통계 추적용)"
  puts "  Question ID: #{question.id}"
  puts "  Option label: #{stat.option_label}"
  puts "  Total randomizations: #{stat.total_randomizations}"
  puts "  Bias score: #{stat.bias_score}"
else
  puts "⚠ RandomizationStat 모델 미구현"
end
puts

# Test 4: RandomizationAnalyzer 서비스
puts "Test 4: RandomizationAnalyzer 서비스"
puts "-"*40

if defined?(RandomizationAnalyzer)
  analyzer = RandomizationAnalyzer.new(exam_session)

  puts "✓ RandomizationAnalyzer 사용 가능"
  puts "  ExamSession ID: #{exam_session.id}"
else
  puts "⚠ RandomizationAnalyzer 서비스 미구현"
end
puts

# ============================================================================
# EPIC 17: STUDY MATERIALS MARKETPLACE
# ============================================================================
puts "="*80
puts "Epic 17: Study Materials Marketplace"
puts "="*80
puts

# Test 1: StudyMaterial Marketplace 필드
puts "Test 1: StudyMaterial Marketplace 필드"
puts "-"*40

marketplace_material = StudyMaterial.find_or_create_by!(
  study_set: user.study_sets.first || user.study_sets.create!(title: "Test Set"),
  name: "Marketplace 테스트 교재"
) do |sm|
  sm.status = "completed"
  sm.category = "정보처리"
  sm.is_public = true
  sm.price = 9900
  sm.difficulty = 3
  sm.published_at = Time.current
end

puts "✓ Marketplace StudyMaterial 생성"
puts "  Name: #{marketplace_material.name}"
puts "  Public: #{marketplace_material.is_public}"
puts "  Price: #{marketplace_material.price}원"
puts "  Difficulty: #{marketplace_material.difficulty}"
puts

# Test 2: Reviews 생성
puts "Test 2: Reviews 생성"
puts "-"*40

if defined?(Review)
  review = Review.find_or_create_by!(
    study_material: marketplace_material,
    user: user
  ) do |r|
    r.rating = 5
    r.comment = "매우 유용한 교재입니다. 시험 준비에 큰 도움이 되었습니다."
    r.helpful_count = 10
    r.verified_purchase = true
  end

  puts "✓ Review 생성 완료"
  puts "  Rating: #{review.rating}/5"
  puts "  Comment: #{review.comment[0..30]}..."
  puts "  Helpful: #{review.helpful_count}"
  puts "  Verified: #{review.verified_purchase}"
else
  puts "⚠ Review 모델 미구현"
end
puts

# Test 3: Purchases 생성
puts "Test 3: Purchases 생성"
puts "-"*40

if defined?(Purchase)
  purchase = Purchase.find_or_create_by!(
    user: user,
    study_material: marketplace_material
  ) do |p|
    p.price = marketplace_material.price
    p.status = "completed"
    p.purchased_at = Time.current
  end

  puts "✓ Purchase 생성 완료"
  puts "  Price: #{purchase.price}원"
  puts "  Status: #{purchase.status}"
  puts "  Downloaded: #{purchase.download_count}/#{purchase.download_limit}"
else
  puts "⚠ Purchase 모델 미구현"
end
puts

# Test 4: MarketplaceSearchService
puts "Test 4: MarketplaceSearchService"
puts "-"*40

if defined?(MarketplaceSearchService)
  search_params = {
    q: "정보처리",
    category: "정보처리",
    min_rating: 4.0
  }

  search_service = MarketplaceSearchService.new(search_params, user)
  results = search_service.search

  puts "✓ MarketplaceSearchService 사용 가능"
  puts "  Search params: #{search_params.keys.join(', ')}"
  puts "  Search results: #{results.count}개"
else
  puts "⚠ MarketplaceSearchService 미구현"
end
puts

# Test 5: ReviewVotes
puts "Test 5: ReviewVotes"
puts "-"*40

if defined?(ReviewVote) && defined?(Review)
  review = Review.first

  if review
    vote = ReviewVote.find_or_create_by!(
      review: review,
      user: user
    ) do |v|
      v.helpful = true
    end

    puts "✓ ReviewVote 생성 완료"
    puts "  Review ID: #{review.id}"
    puts "  Helpful: #{vote.helpful}"
  else
    puts "⚠ Review 데이터 없음"
  end
else
  puts "⚠ ReviewVote 모델 미구현"
end
puts

# ============================================================================
# SUMMARY
# ============================================================================
puts "="*80
puts "테스트 완료 Summary"
puts "="*80
puts

puts "Epic 9: CBT Test Mode"
puts "  ✓ TestSession: #{TestSession.count}개"
puts "  ✓ TestQuestions: #{TestQuestion.count}개"
puts "  ✓ TestAnswers: #{TestAnswer.count}개"
puts

puts "Epic 10: Answer Randomization"
puts "  ✓ ExamSessions: #{ExamSession.count}개"
if defined?(RandomizationStat)
  puts "  ✓ RandomizationStats: #{RandomizationStat.count}개"
else
  puts "  ⚠ RandomizationStats 미구현"
end
puts

puts "Epic 17: Study Materials Marketplace"
puts "  ✓ Public Materials: #{StudyMaterial.where(is_public: true).count}개"
if defined?(Review)
  puts "  ✓ Reviews: #{Review.count}개"
else
  puts "  ⚠ Reviews 미구현"
end
if defined?(Purchase)
  puts "  ✓ Purchases: #{Purchase.count}개"
else
  puts "  ⚠ Purchases 미구현"
end
puts

puts "="*80
puts "✓ Epic 9, 10, 17 단위 테스트 완료!"
puts "="*80
