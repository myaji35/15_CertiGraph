# 🧪 제19회 사회복지사 1급 PDF 파싱 테스트
# 3개 교시 파일을 순차적으로 처리

puts "=" * 80
puts "🧪 제19회 사회복지사 1급 PDF 파싱 테스트"
puts "=" * 80
puts ""

# PDF 파일 경로 (프로젝트 루트 기준)
project_root = File.expand_path('../..', __dir__)
pdf_files = [
  { path: File.join(project_root, "제19회 사회복지사 1급_1교시_B형.pdf"), name: "1교시" },
  { path: File.join(project_root, "제19회 사회복지사 1급_2교시_B형.pdf"), name: "2교시" },
  { path: File.join(project_root, "제19회 사회복지사 1급_3교시_B형.pdf"), name: "3교시" }
]

# 테스트용 Study Set 생성 또는 찾기
study_set = StudySet.find_or_create_by!(title: "제19회 사회복지사 1급 (테스트)") do |ss|
  ss.user_id = User.first&.id || 1
  ss.certification = "사회복지사 1급"
  ss.description = "Python 파서 테스트용 - 3개 교시"
end

puts "📚 Study Set: #{study_set.title} (ID: #{study_set.id})"
puts ""

# 각 PDF 파일 처리
results = []

pdf_files.each_with_index do |pdf_info, index|
  puts "-" * 80
  puts "📄 #{index + 1}/3: #{pdf_info[:name]} 처리 중..."
  puts "-" * 80
  
  pdf_path = pdf_info[:path]
  
  unless File.exist?(pdf_path)
    puts "❌ 파일을 찾을 수 없습니다: #{pdf_path}"
    next
  end
  
  puts "✅ 파일 확인: #{File.basename(pdf_path)} (#{File.size(pdf_path) / 1024}KB)"
  
  # StudyMaterial 생성
  study_material = StudyMaterial.create!(
    study_set: study_set,
    name: "제19회 사회복지사 1급 #{pdf_info[:name]}",
    status: 'pending'
  )
  
  # PDF 첨부
  study_material.pdf_file.attach(
    io: File.open(pdf_path),
    filename: File.basename(pdf_path),
    content_type: 'application/pdf'
  )
  
  puts "📎 PDF 첨부 완료"
  
  # Python 파서 실행
  puts "🐍 Python 파서 실행 중..."
  start_time = Time.now
  
  begin
    ProcessPdfJob.perform_now(study_material.id)
    end_time = Time.now
    duration = (end_time - start_time).round(2)
    
    # 결과 확인
    study_material.reload
    
    if study_material.status == 'completed'
      question_count = study_material.questions.count
      puts "✅ 처리 완료! (#{duration}초)"
      puts "📊 추출된 문제: #{question_count}개"
      
      results << {
        name: pdf_info[:name],
        status: 'success',
        questions: question_count,
        duration: duration
      }
      
      # 샘플 문제 표시
      if question_count > 0
        puts ""
        puts "📝 샘플 문제 (처음 2개):"
        study_material.questions.limit(2).each_with_index do |q, i|
          puts "  #{i + 1}. [Q#{q.question_number}] #{q.content&.truncate(80)}"
          puts "     난이도: #{q.difficulty}, 주제: #{q.topic}"
        end
      end
    else
      puts "❌ 처리 실패: #{study_material.error_message}"
      results << {
        name: pdf_info[:name],
        status: 'failed',
        error: study_material.error_message
      }
    end
    
  rescue => e
    puts "❌ 에러 발생: #{e.message}"
    results << {
      name: pdf_info[:name],
      status: 'error',
      error: e.message
    }
  end
  
  puts ""
end

# 최종 결과 요약
puts "=" * 80
puts "📊 최종 결과 요약"
puts "=" * 80
puts ""

total_questions = 0
success_count = 0

results.each do |result|
  status_icon = result[:status] == 'success' ? '✅' : '❌'
  puts "#{status_icon} #{result[:name]}: #{result[:status]}"
  
  if result[:status] == 'success'
    puts "   문제 수: #{result[:questions]}개, 소요 시간: #{result[:duration]}초"
    total_questions += result[:questions]
    success_count += 1
  else
    puts "   에러: #{result[:error]}"
  end
end

puts ""
puts "=" * 80
puts "✅ 성공: #{success_count}/#{pdf_files.length}"
puts "📚 총 추출된 문제: #{total_questions}개"
puts "🎯 Study Set ID: #{study_set.id}"
puts ""
puts "브라우저에서 확인:"
puts "  http://localhost:3000/study_sets/#{study_set.id}"
puts "=" * 80
