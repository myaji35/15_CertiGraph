namespace :exam_schedules do
  desc "Sync 2026 exam schedules from Q-Net API"
  task sync_2026: :environment do
    puts "🔄 Starting Q-Net API sync for 2026 exam schedules..."

    service = QNetApiService.new
    result = service.sync_to_database

    puts "✅ Sync completed!"
    puts "   - Successfully saved: #{result[:success]} schedules"
    puts "   - Errors: #{result[:errors]}"
    puts "   - Total processed: #{result[:total]}"
    puts "   - Success rate: #{result[:percentage]}%"

    # 저장된 데이터 확인
    total_count = ExamSchedule.count
    year_2026_count = ExamSchedule.where(exam_year: 2026).count

    puts "\n📊 Database Status:"
    puts "   - Total exam schedules: #{total_count}"
    puts "   - 2026 exam schedules: #{year_2026_count}"
  end

  desc "Show statistics for exam schedules"
  task stats: :environment do
    puts "\n📊 Exam Schedule Statistics:"

    # 전체 통계
    total = ExamSchedule.count
    puts "Total schedules in database: #{total}"

    # 연도별 통계
    puts "\nBy Year:"
    ExamSchedule.group(:exam_year).count.each do |year, count|
      puts "  #{year}: #{count} schedules"
    end

    # 자격증별 통계
    puts "\nBy Certification:"
    ExamSchedule.group(:certification_name).count.each do |cert, count|
      puts "  #{cert}: #{count} schedules"
    end

    # 2026년 데이터 상세
    year_2026 = ExamSchedule.where(exam_year: 2026)
    if year_2026.any?
      puts "\n2026 Exam Schedule Coverage:"
      total_certifications = year_2026.select(:certification_code).distinct.count
      puts "  - Certifications covered: #{total_certifications}"
      puts "  - Total exam rounds: #{year_2026.count}"

      # 가장 가까운 시험일정
      upcoming = year_2026.where('written_exam_date >= ?', Date.today).order(:written_exam_date).first
      if upcoming
        puts "\nNext upcoming exam (2026):"
        puts "  - #{upcoming.certification_name}"
        puts "  - Written exam: #{upcoming.written_exam_date}"
        puts "  - Registration: #{upcoming.written_exam_reg_start} ~ #{upcoming.written_exam_reg_end}"
      end
    else
      puts "\n⚠️  No 2026 exam schedules found. Run 'rails exam_schedules:sync_2026' to fetch data."
    end
  end

  desc "Clear all exam schedules from database"
  task clear: :environment do
    print "Are you sure you want to delete all exam schedules? (yes/no): "
    input = STDIN.gets.strip

    if input.downcase == 'yes'
      count = ExamSchedule.count
      ExamSchedule.destroy_all
      puts "✅ Deleted #{count} exam schedules."
    else
      puts "❌ Operation cancelled."
    end
  end

  desc "Import sample 2026 exam schedules (for testing without API key)"
  task import_sample: :environment do
    puts "📥 Importing sample 2026 exam schedules..."

    sample_data = [
      {
        certification_code: '1320',
        certification_name: '정보처리기사',
        exam_year: 2026,
        exam_round: 1,
        written_exam_date: '2026-03-07',
        written_exam_reg_start: '2026-01-13',
        written_exam_reg_end: '2026-01-16',
        practical_exam_date: '2026-04-27',
        practical_exam_reg_start: '2026-03-16',
        practical_exam_reg_end: '2026-03-19',
        announcement_date: '2026-03-19',
        exam_fee: 19400,
        exam_location: '전국'
      },
      {
        certification_code: '1320',
        certification_name: '정보처리기사',
        exam_year: 2026,
        exam_round: 2,
        written_exam_date: '2026-05-17',
        written_exam_reg_start: '2026-04-08',
        written_exam_reg_end: '2026-04-11',
        practical_exam_date: '2026-06-28',
        practical_exam_reg_start: '2026-06-09',
        practical_exam_reg_end: '2026-06-12',
        announcement_date: '2026-06-09',
        exam_fee: 19400,
        exam_location: '전국'
      },
      {
        certification_code: '1320',
        certification_name: '정보처리기사',
        exam_year: 2026,
        exam_round: 3,
        written_exam_date: '2026-08-16',
        written_exam_reg_start: '2026-07-08',
        written_exam_reg_end: '2026-07-11',
        practical_exam_date: '2026-10-17',
        practical_exam_reg_start: '2026-09-23',
        practical_exam_reg_end: '2026-09-26',
        announcement_date: '2026-09-10',
        exam_fee: 19400,
        exam_location: '전국'
      },
      {
        certification_code: '2050',
        certification_name: '사회복지사1급',
        exam_year: 2026,
        exam_round: 1,
        written_exam_date: '2026-02-08',
        written_exam_reg_start: '2026-01-06',
        written_exam_reg_end: '2026-01-10',
        practical_exam_date: nil,
        practical_exam_reg_start: nil,
        practical_exam_reg_end: nil,
        announcement_date: '2026-03-11',
        exam_fee: 25000,
        exam_location: '전국',
        additional_info: { exam_type: '필기시험만' }
      },
      {
        certification_code: '7910',
        certification_name: '한식조리기능사',
        exam_year: 2026,
        exam_round: 1,
        written_exam_date: '2026-01-27',
        written_exam_reg_start: '2026-01-06',
        written_exam_reg_end: '2026-01-09',
        practical_exam_date: '2026-03-08',
        practical_exam_reg_start: '2026-02-10',
        practical_exam_reg_end: '2026-02-13',
        announcement_date: '2026-02-05',
        exam_fee: 14500,
        exam_location: '전국'
      }
    ]

    success = 0
    sample_data.each do |data|
      exam = ExamSchedule.find_or_create_by(
        certification_code: data[:certification_code],
        exam_year: data[:exam_year],
        exam_round: data[:exam_round]
      )

      if exam.update(data)
        success += 1
        puts "  ✅ #{data[:certification_name]} - Round #{data[:exam_round]}"
      else
        puts "  ❌ Failed: #{data[:certification_name]} - Round #{data[:exam_round]}"
      end
    end

    puts "\n✅ Import completed: #{success}/#{sample_data.count} schedules imported"
    puts "📊 Total 2026 schedules in database: #{ExamSchedule.where(exam_year: 2026).count}"
  end
end