# Epic 18: Certification Information Hub - Seed Data
# 2025/2026년 자격증 시험 정보 시드 데이터

puts "Creating Certifications and Exam Schedules..."

# 1. 정보처리기사
cert_info = Certification.find_or_create_by!(name: '정보처리기사') do |c|
  c.name_en = 'Engineer Information Processing'
  c.organization = '한국산업인력공단'
  c.category = 'IT/정보통신'
  c.description = '정보시스템의 생명주기 전반에 걸친 프로젝트 업무를 수행하는 실무 능력을 검정'
  c.is_national = true
  c.pass_rate = 35.2
  c.is_active = true
  c.metadata = {
    prerequisites: '4년제 대학 관련학과 졸업(예정)자 또는 동등 자격',
    exam_subjects: ['소프트웨어 설계', '소프트웨어 개발', '데이터베이스 구축', '프로그래밍 언어 활용', '정보시스템 구축 관리']
  }
end

# 2025년 정보처리기사 시험 일정
[
  { round: 1, type: 'written', reg_start: '2025-01-06', reg_end: '2025-01-09', exam_date: '2025-03-15', result: '2025-04-02' },
  { round: 1, type: 'practical', reg_start: '2025-03-31', reg_end: '2025-04-03', exam_date: '2025-05-17', result: '2025-06-18' },
  { round: 2, type: 'written', reg_start: '2025-04-14', reg_end: '2025-04-17', exam_date: '2025-05-25', result: '2025-06-11' },
  { round: 2, type: 'practical', reg_start: '2025-06-23', reg_end: '2025-06-26', exam_date: '2025-08-10', result: '2025-09-10' }
].each do |schedule|
  ExamSchedule.find_or_create_by!(
    certification: cert_info,
    year: 2025,
    round: schedule[:round],
    exam_type: schedule[:type]
  ) do |s|
    s.registration_start_date = Date.parse(schedule[:reg_start])
    s.registration_end_date = Date.parse(schedule[:reg_end])
    s.exam_date = Date.parse(schedule[:exam_date])
    s.result_date = Date.parse(schedule[:result])
    # s.exam_fee = schedule[:type] == 'written' ? 19400 : 22600
    s.status = Date.current > Date.parse(schedule[:exam_date]) ? 'completed' : 'scheduled'
  end
end

# 2. 빅데이터분석기사
cert_bigdata = Certification.find_or_create_by!(name: '빅데이터분석기사') do |c|
  c.name_en = 'Engineer Big Data Analytics'
  c.organization = '한국데이터산업진흥원'
  c.category = '데이터/AI'
  c.description = '대용량의 데이터 집합으로부터 유용한 정보를 찾고 결과를 예측하는 전문가 자격'
  c.is_national = true
  c.pass_rate = 28.7
  # c.exam_fee =80000
  c.is_active = true
  c.metadata = {
    prerequisites: '관련 학과 2년제 이상 졸업자 또는 실무경력 2년 이상',
    exam_subjects: ['빅데이터 분석 계획', '빅데이터 탐색', '빅데이터 모델링', '빅데이터 결과 해석']
  }
end

# 2025년 빅데이터분석기사 시험 일정
[
  { round: 1, type: 'written', reg_start: '2025-02-03', reg_end: '2025-02-06', exam_date: '2025-04-12', result: '2025-05-07' },
  { round: 1, type: 'practical', reg_start: '2025-05-12', reg_end: '2025-05-15', exam_date: '2025-06-21', result: '2025-07-16' },
  { round: 2, type: 'written', reg_start: '2025-08-04', reg_end: '2025-08-07', exam_date: '2025-09-20', result: '2025-10-15' }
].each do |schedule|
  ExamSchedule.find_or_create_by!(
    certification: cert_bigdata,
    year: 2025,
    round: schedule[:round],
    exam_type: schedule[:type]
  ) do |s|
    s.registration_start_date = Date.parse(schedule[:reg_start])
    s.registration_end_date = Date.parse(schedule[:reg_end])
    s.exam_date = Date.parse(schedule[:exam_date])
    s.result_date = Date.parse(schedule[:result])
    # s.exam_fee =80000
    s.status = Date.current > Date.parse(schedule[:exam_date]) ? 'completed' : 'scheduled'
  end
end

# 3. 사회복지사 1급
cert_social = Certification.find_or_create_by!(name: '사회복지사 1급') do |c|
  c.name_en = 'Social Worker Level 1'
  c.organization = '한국사회복지사협회'
  c.category = '사회복지/상담'
  c.description = '사회복지에 관한 전문지식과 기술을 가진 전문가 자격'
  c.is_national = true
  c.pass_rate = 42.1
  # c.exam_fee =25000
  c.is_active = true
  c.metadata = {
    prerequisites: '사회복지학 학사학위 + 실습 이수',
    exam_subjects: ['사회복지기초', '사회복지실천', '사회복지정책과 제도']
  }
end

# 2026년 시험 일정 (1월 시험)
ExamSchedule.find_or_create_by!(
  certification: cert_social,
  year: 2026,
  round: 1,
  exam_type: 'written'
) do |s|
  s.registration_start_date = Date.parse('2025-12-02')
  s.registration_end_date = Date.parse('2025-12-06')
  s.exam_date = Date.parse('2026-01-18')
  s.result_date = Date.parse('2026-03-11')
  s.exam_fee = 25000
  s.status = 'scheduled'
  s.metadata = {
    exam_time: '09:30',
    exam_duration: 150,
    passing_score: 60
  }
end

# 4. 컴퓨터활용능력 1급
cert_computer = Certification.find_or_create_by!(name: '컴퓨터활용능력 1급') do |c|
  c.name_en = 'Computer Specialist Level 1'
  c.organization = '대한상공회의소'
  c.category = '사무/OA'
  c.description = '컴퓨터 활용능력 전문가 자격 검정'
  c.is_national = false
  c.pass_rate = 22.5
  # c.exam_fee =17000
  c.is_active = true
end

# 2025년 컴퓨터활용능력 시험 일정 (상시)
(1..12).each do |month|
  next if month == 1 # 1월은 시험 없음

  # 매월 첫째주, 셋째주 토요일 시험
  [1, 3].each do |week|
    exam_date = Date.new(2025, month, 1)
    # 해당 월의 첫 토요일 찾기
    exam_date += (6 - exam_date.wday) % 7
    # 주차 조정
    exam_date += (week - 1) * 7

    ExamSchedule.find_or_create_by!(
      certification: cert_computer,
      year: 2025,
      round: (month - 1) * 2 + (week == 1 ? 1 : 2),
      exam_type: 'written',
      exam_date: exam_date
    ) do |s|
      s.registration_start_date = exam_date - 14
      s.registration_end_date = exam_date - 7
      s.result_date = exam_date + 7
      # s.exam_fee =17000
      s.status = Date.current > exam_date ? 'completed' : 'scheduled'
    end
  end
end

# 5. SQLD (SQL 개발자)
cert_sqld = Certification.find_or_create_by!(name: 'SQLD') do |c|
  c.name_en = 'SQL Developer'
  c.organization = '한국데이터산업진흥원'
  c.category = '데이터/DB'
  c.description = 'SQL 개발자 자격 검정'
  c.is_national = false
  c.pass_rate = 45.3
  # c.exam_fee =100000
  c.is_active = true
end

# 2025년 SQLD 시험 일정
[
  { round: 51, exam_date: '2025-03-08' },
  { round: 52, exam_date: '2025-05-24' },
  { round: 53, exam_date: '2025-08-30' },
  { round: 54, exam_date: '2025-11-08' }
].each do |schedule|
  ExamSchedule.find_or_create_by!(
    certification: cert_sqld,
    year: 2025,
    round: schedule[:round],
    exam_type: 'written'
  ) do |s|
    exam_date = Date.parse(schedule[:exam_date])
    s.registration_start_date = exam_date - 60
    s.registration_end_date = exam_date - 30
    s.exam_date = exam_date
    s.result_date = exam_date + 30
    # s.exam_fee =100000
    s.status = Date.current > exam_date ? 'completed' : 'scheduled'
  end
end

puts "Created #{Certification.count} certifications"
puts "Created #{ExamSchedule.count} exam schedules"

# 테스트용 알림 생성 (첫 번째 사용자가 있다면)
if User.any?
  user = User.first
  upcoming_exams = ExamSchedule.upcoming.limit(3)

  upcoming_exams.each do |exam|
    # 시험 1개월 전 알림
    if exam.exam_date > Date.current + 30.days
      ExamNotification.find_or_create_by!(
        user: user,
        exam_schedule: exam,
        notification_type: 'exam_reminder_month'
      ) do |n|
        n.channel = 'email'
        n.scheduled_at = exam.exam_date - 30.days
        n.status = 'pending'
      end
    end

    # 원서접수 시작 알림
    if exam.registration_start_date > Date.current
      ExamNotification.find_or_create_by!(
        user: user,
        exam_schedule: exam,
        notification_type: 'registration_open'
      ) do |n|
        n.channel = 'email'
        n.scheduled_at = exam.registration_start_date - 3.days
        n.status = 'pending'
      end
    end
  end

  puts "Created #{ExamNotification.count} test notifications for user: #{user.email}"
end

puts "Seed data for Epic 18: Certification Information Hub completed!"