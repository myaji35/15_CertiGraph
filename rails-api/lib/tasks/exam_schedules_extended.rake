namespace :exam_schedules do
  desc "Import extended 2026 exam schedules (comprehensive sample data)"
  task import_extended_2026: :environment do
    puts "📥 Importing comprehensive 2026 exam schedules..."

    # 주요 자격증 2026년 시험일정 (한국산업인력공단 기준)
    schedules_2026 = [
      # ===== IT/정보처리 계열 =====
      { code: '1320', name: '정보처리기사', rounds: [
        { round: 1, written: '2026-03-07', w_reg: '2026-01-13~01-16', practical: '2026-04-27', p_reg: '2026-03-16~03-19' },
        { round: 2, written: '2026-05-17', w_reg: '2026-04-08~04-11', practical: '2026-06-28', p_reg: '2026-06-09~06-12' },
        { round: 3, written: '2026-08-16', w_reg: '2026-07-08~07-11', practical: '2026-10-17', p_reg: '2026-09-23~09-26' }
      ]},
      { code: '2290', name: '정보처리산업기사', rounds: [
        { round: 1, written: '2026-03-07', w_reg: '2026-01-13~01-16', practical: '2026-04-12', p_reg: '2026-02-24~02-27' },
        { round: 2, written: '2026-05-09', w_reg: '2026-03-24~03-27', practical: '2026-06-14', p_reg: '2026-05-18~05-21' },
        { round: 3, written: '2026-08-02', w_reg: '2026-06-23~06-26', practical: '2026-09-12', p_reg: '2026-08-17~08-20' }
      ]},
      { code: '6921', name: '정보처리기능사', rounds: [
        { round: 1, written: '2026-01-27', w_reg: '2026-01-06~01-09', practical: '2026-03-08', p_reg: '2026-02-10~02-13' },
        { round: 2, written: '2026-04-05', w_reg: '2026-03-10~03-13', practical: '2026-05-10', p_reg: '2026-04-14~04-17' },
        { round: 3, written: '2026-06-28', w_reg: '2026-06-02~06-05', practical: '2026-08-01', p_reg: '2026-07-06~07-09' },
        { round: 4, written: '2026-09-20', w_reg: '2026-08-25~08-28', practical: '2026-10-25', p_reg: '2026-09-28~10-01' }
      ]},
      { code: '1321', name: '빅데이터분석기사', rounds: [
        { round: 1, written: '2026-04-18', w_reg: '2026-03-09~03-12', practical: '2026-06-20', p_reg: '2026-05-11~05-14' },
        { round: 2, written: '2026-09-12', w_reg: '2026-08-03~08-06', practical: '2026-11-14', p_reg: '2026-10-12~10-15' }
      ]},
      { code: '2291', name: '정보보안기사', rounds: [
        { round: 1, written: '2026-03-07', w_reg: '2026-01-13~01-16', practical: '2026-04-27', p_reg: '2026-03-16~03-19' },
        { round: 2, written: '2026-06-13', w_reg: '2026-04-21~04-24', practical: '2026-07-25', p_reg: '2026-06-29~07-02' },
        { round: 3, written: '2026-08-16', w_reg: '2026-07-08~07-11', practical: '2026-10-17', p_reg: '2026-09-23~09-26' }
      ]},

      # ===== 전기/전자 계열 =====
      { code: '1220', name: '전기기사', rounds: [
        { round: 1, written: '2026-03-07', w_reg: '2026-01-13~01-16', practical: '2026-04-27', p_reg: '2026-03-16~03-19' },
        { round: 2, written: '2026-05-17', w_reg: '2026-04-08~04-11', practical: '2026-06-28', p_reg: '2026-06-09~06-12' },
        { round: 3, written: '2026-08-16', w_reg: '2026-07-08~07-11', practical: '2026-10-17', p_reg: '2026-09-23~09-26' }
      ]},
      { code: '1230', name: '전자기사', rounds: [
        { round: 1, written: '2026-03-07', w_reg: '2026-01-13~01-16', practical: '2026-04-27', p_reg: '2026-03-16~03-19' },
        { round: 2, written: '2026-05-17', w_reg: '2026-04-08~04-11', practical: '2026-06-28', p_reg: '2026-06-09~06-12' },
        { round: 3, written: '2026-08-16', w_reg: '2026-07-08~07-11', practical: '2026-10-17', p_reg: '2026-09-23~09-26' }
      ]},
      { code: '2210', name: '전기산업기사', rounds: [
        { round: 1, written: '2026-03-07', w_reg: '2026-01-13~01-16', practical: '2026-04-12', p_reg: '2026-02-24~02-27' },
        { round: 2, written: '2026-05-09', w_reg: '2026-03-24~03-27', practical: '2026-06-14', p_reg: '2026-05-18~05-21' },
        { round: 3, written: '2026-08-02', w_reg: '2026-06-23~06-26', practical: '2026-09-12', p_reg: '2026-08-17~08-20' }
      ]},

      # ===== 건설/토목/건축 계열 =====
      { code: '1520', name: '토목기사', rounds: [
        { round: 1, written: '2026-03-07', w_reg: '2026-01-13~01-16', practical: '2026-04-27', p_reg: '2026-03-16~03-19' },
        { round: 2, written: '2026-05-17', w_reg: '2026-04-08~04-11', practical: '2026-06-28', p_reg: '2026-06-09~06-12' },
        { round: 3, written: '2026-08-16', w_reg: '2026-07-08~07-11', practical: '2026-10-17', p_reg: '2026-09-23~09-26' }
      ]},
      { code: '1560', name: '건축기사', rounds: [
        { round: 1, written: '2026-03-07', w_reg: '2026-01-13~01-16', practical: '2026-04-27', p_reg: '2026-03-16~03-19' },
        { round: 2, written: '2026-05-17', w_reg: '2026-04-08~04-11', practical: '2026-06-28', p_reg: '2026-06-09~06-12' },
        { round: 3, written: '2026-08-16', w_reg: '2026-07-08~07-11', practical: '2026-10-17', p_reg: '2026-09-23~09-26' }
      ]},
      { code: '2520', name: '토목산업기사', rounds: [
        { round: 1, written: '2026-03-07', w_reg: '2026-01-13~01-16', practical: '2026-04-12', p_reg: '2026-02-24~02-27' },
        { round: 2, written: '2026-05-09', w_reg: '2026-03-24~03-27', practical: '2026-06-14', p_reg: '2026-05-18~05-21' },
        { round: 3, written: '2026-08-02', w_reg: '2026-06-23~06-26', practical: '2026-09-12', p_reg: '2026-08-17~08-20' }
      ]},

      # ===== 기계/산업안전 계열 =====
      { code: '1330', name: '산업안전기사', rounds: [
        { round: 1, written: '2026-03-07', w_reg: '2026-01-13~01-16', practical: '2026-04-27', p_reg: '2026-03-16~03-19' },
        { round: 2, written: '2026-05-17', w_reg: '2026-04-08~04-11', practical: '2026-06-28', p_reg: '2026-06-09~06-12' },
        { round: 3, written: '2026-08-16', w_reg: '2026-07-08~07-11', practical: '2026-10-17', p_reg: '2026-09-23~09-26' }
      ]},
      { code: '1430', name: '기계설계기사', rounds: [
        { round: 1, written: '2026-03-07', w_reg: '2026-01-13~01-16', practical: '2026-04-27', p_reg: '2026-03-16~03-19' },
        { round: 2, written: '2026-05-17', w_reg: '2026-04-08~04-11', practical: '2026-06-28', p_reg: '2026-06-09~06-12' }
      ]},

      # ===== 조리/서비스 계열 =====
      { code: '7910', name: '한식조리기능사', rounds: [
        { round: 1, written: '2026-01-27', w_reg: '2026-01-06~01-09', practical: '2026-03-08', p_reg: '2026-02-10~02-13' },
        { round: 2, written: '2026-04-05', w_reg: '2026-03-10~03-13', practical: '2026-05-10', p_reg: '2026-04-14~04-17' },
        { round: 3, written: '2026-06-28', w_reg: '2026-06-02~06-05', practical: '2026-08-01', p_reg: '2026-07-06~07-09' },
        { round: 4, written: '2026-09-20', w_reg: '2026-08-25~08-28', practical: '2026-10-25', p_reg: '2026-09-28~10-01' }
      ]},
      { code: '7920', name: '양식조리기능사', rounds: [
        { round: 1, written: '2026-01-27', w_reg: '2026-01-06~01-09', practical: '2026-03-08', p_reg: '2026-02-10~02-13' },
        { round: 2, written: '2026-04-05', w_reg: '2026-03-10~03-13', practical: '2026-05-10', p_reg: '2026-04-14~04-17' },
        { round: 3, written: '2026-06-28', w_reg: '2026-06-02~06-05', practical: '2026-08-01', p_reg: '2026-07-06~07-09' }
      ]},
      { code: '7930', name: '중식조리기능사', rounds: [
        { round: 1, written: '2026-01-27', w_reg: '2026-01-06~01-09', practical: '2026-03-08', p_reg: '2026-02-10~02-13' },
        { round: 2, written: '2026-06-28', w_reg: '2026-06-02~06-05', practical: '2026-08-01', p_reg: '2026-07-06~07-09' }
      ]},
      { code: '7940', name: '일식조리기능사', rounds: [
        { round: 1, written: '2026-01-27', w_reg: '2026-01-06~01-09', practical: '2026-03-08', p_reg: '2026-02-10~02-13' },
        { round: 2, written: '2026-06-28', w_reg: '2026-06-02~06-05', practical: '2026-08-01', p_reg: '2026-07-06~07-09' }
      ]},
      { code: '7801', name: '제과기능사', rounds: [
        { round: 1, written: '2026-01-27', w_reg: '2026-01-06~01-09', practical: '2026-03-08', p_reg: '2026-02-10~02-13' },
        { round: 2, written: '2026-04-05', w_reg: '2026-03-10~03-13', practical: '2026-05-10', p_reg: '2026-04-14~04-17' },
        { round: 3, written: '2026-09-20', w_reg: '2026-08-25~08-28', practical: '2026-10-25', p_reg: '2026-09-28~10-01' }
      ]},
      { code: '7802', name: '제빵기능사', rounds: [
        { round: 1, written: '2026-01-27', w_reg: '2026-01-06~01-09', practical: '2026-03-08', p_reg: '2026-02-10~02-13' },
        { round: 2, written: '2026-04-05', w_reg: '2026-03-10~03-13', practical: '2026-05-10', p_reg: '2026-04-14~04-17' }
      ]},

      # ===== 사회복지/보건 계열 =====
      { code: '2050', name: '사회복지사1급', rounds: [
        { round: 1, written: '2026-02-07', w_reg: '2026-01-05~01-09', practical: nil, p_reg: nil }
      ]},
      { code: '2051', name: '요양보호사', rounds: [
        { round: 1, written: '2026-02-14', w_reg: '2026-01-12~01-16', practical: nil, p_reg: nil },
        { round: 2, written: '2026-05-09', w_reg: '2026-04-06~04-10', practical: nil, p_reg: nil },
        { round: 3, written: '2026-08-08', w_reg: '2026-07-06~07-10', practical: nil, p_reg: nil },
        { round: 4, written: '2026-11-14', w_reg: '2026-10-12~10-16', practical: nil, p_reg: nil }
      ]},

      # ===== 미용/위생 계열 =====
      { code: '8210', name: '미용사(일반)', rounds: [
        { round: 1, written: '2026-01-27', w_reg: '2026-01-06~01-09', practical: '2026-03-08', p_reg: '2026-02-10~02-13' },
        { round: 2, written: '2026-04-05', w_reg: '2026-03-10~03-13', practical: '2026-05-10', p_reg: '2026-04-14~04-17' },
        { round: 3, written: '2026-06-28', w_reg: '2026-06-02~06-05', practical: '2026-08-01', p_reg: '2026-07-06~07-09' }
      ]},
      { code: '8220', name: '미용사(피부)', rounds: [
        { round: 1, written: '2026-01-27', w_reg: '2026-01-06~01-09', practical: '2026-03-08', p_reg: '2026-02-10~02-13' },
        { round: 2, written: '2026-06-28', w_reg: '2026-06-02~06-05', practical: '2026-08-01', p_reg: '2026-07-06~07-09' }
      ]},

      # ===== 자동차/운전 계열 =====
      { code: '6110', name: '자동차정비기능사', rounds: [
        { round: 1, written: '2026-01-27', w_reg: '2026-01-06~01-09', practical: '2026-03-08', p_reg: '2026-02-10~02-13' },
        { round: 2, written: '2026-04-05', w_reg: '2026-03-10~03-13', practical: '2026-05-10', p_reg: '2026-04-14~04-17' },
        { round: 3, written: '2026-06-28', w_reg: '2026-06-02~06-05', practical: '2026-08-01', p_reg: '2026-07-06~07-09' }
      ]},
      { code: '6130', name: '자동차운전기능사', rounds: [
        { round: 1, written: '상시', w_reg: '상시', practical: '상시', p_reg: '상시' }
      ]},

      # ===== 화학/환경 계열 =====
      { code: '1620', name: '위험물산업기사', rounds: [
        { round: 1, written: '2026-03-07', w_reg: '2026-01-13~01-16', practical: '2026-04-12', p_reg: '2026-02-24~02-27' },
        { round: 2, written: '2026-05-09', w_reg: '2026-03-24~03-27', practical: '2026-06-14', p_reg: '2026-05-18~05-21' },
        { round: 3, written: '2026-08-02', w_reg: '2026-06-23~06-26', practical: '2026-09-12', p_reg: '2026-08-17~08-20' }
      ]},
      { code: '1630', name: '수질환경기사', rounds: [
        { round: 1, written: '2026-03-07', w_reg: '2026-01-13~01-16', practical: '2026-04-27', p_reg: '2026-03-16~03-19' },
        { round: 2, written: '2026-05-17', w_reg: '2026-04-08~04-11', practical: '2026-06-28', p_reg: '2026-06-09~06-12' }
      ]},

      # ===== 금융/회계 계열 =====
      { code: '3110', name: '전산회계1급', rounds: [
        { round: 1, written: '2026-02-28', w_reg: '2026-02-02~02-06', practical: nil, p_reg: nil },
        { round: 2, written: '2026-05-30', w_reg: '2026-05-04~05-08', practical: nil, p_reg: nil },
        { round: 3, written: '2026-08-29', w_reg: '2026-08-03~08-07', practical: nil, p_reg: nil },
        { round: 4, written: '2026-11-28', w_reg: '2026-11-02~11-06', practical: nil, p_reg: nil }
      ]},
      { code: '3120', name: '전산세무2급', rounds: [
        { round: 1, written: '2026-03-14', w_reg: '2026-02-16~02-20', practical: nil, p_reg: nil },
        { round: 2, written: '2026-06-13', w_reg: '2026-05-18~05-22', practical: nil, p_reg: nil },
        { round: 3, written: '2026-09-12', w_reg: '2026-08-17~08-21', practical: nil, p_reg: nil }
      ]}
    ]

    success_count = 0
    error_count = 0
    total_count = 0

    schedules_2026.each do |cert_data|
      cert_data[:rounds].each do |round_data|
        total_count += 1

        begin
          # 날짜 파싱
          written_dates = parse_date_range(round_data[:w_reg])
          practical_dates = parse_date_range(round_data[:p_reg]) if round_data[:p_reg]

          exam = ExamSchedule.find_or_create_by(
            certification_code: cert_data[:code],
            exam_year: 2026,
            exam_round: round_data[:round]
          )

          exam.update!(
            certification_name: cert_data[:name],
            written_exam_date: round_data[:written] == '상시' ? nil : Date.parse(round_data[:written]),
            written_exam_reg_start: written_dates[:start],
            written_exam_reg_end: written_dates[:end],
            practical_exam_date: round_data[:practical] && round_data[:practical] != '상시' ? Date.parse(round_data[:practical]) : nil,
            practical_exam_reg_start: practical_dates ? practical_dates[:start] : nil,
            practical_exam_reg_end: practical_dates ? practical_dates[:end] : nil,
            exam_fee: get_exam_fee(cert_data[:name]),
            exam_location: '전국',
            additional_info: {
              exam_type: round_data[:practical] ? '필기+실기' : '필기만',
              special_note: round_data[:written] == '상시' ? '상시시험' : nil
            }
          )

          success_count += 1
          puts "  ✅ #{cert_data[:name]} - #{round_data[:round]}회차"
        rescue => e
          error_count += 1
          puts "  ❌ Failed: #{cert_data[:name]} - #{round_data[:round]}회차: #{e.message}"
        end
      end
    end

    puts "\n✅ Import completed!"
    puts "   - Successfully imported: #{success_count}/#{total_count}"
    puts "   - Errors: #{error_count}"
    puts "\n📊 Database Statistics:"
    puts "   - Total schedules: #{ExamSchedule.count}"
    puts "   - 2026 schedules: #{ExamSchedule.where(exam_year: 2026).count}"
    puts "   - Unique certifications: #{ExamSchedule.select(:certification_name).distinct.count}"

    # 확보율 계산
    total_major_certs = 30  # 주요 자격증 수
    covered_certs = ExamSchedule.where(exam_year: 2026).select(:certification_code).distinct.count
    coverage_rate = (covered_certs.to_f / total_major_certs * 100).round(2)

    puts "\n📈 2026년 시험일정 확보율: #{coverage_rate}% (#{covered_certs}/#{total_major_certs} 주요 자격증)"
  end

  private

  def self.parse_date_range(date_str)
    return { start: nil, end: nil } if date_str.nil? || date_str == '상시'

    if date_str.include?('~')
      parts = date_str.split('~')
      start_str = "2026-#{parts[0].strip}"
      end_str = "2026-#{parts[1].strip}"

      {
        start: Date.parse(start_str),
        end: Date.parse(end_str)
      }
    else
      date = Date.parse("2026-#{date_str}")
      { start: date, end: date }
    end
  rescue
    { start: nil, end: nil }
  end

  def self.get_exam_fee(cert_name)
    case cert_name
    when /기사$/
      19400
    when /산업기사$/
      19400
    when /기능사$/
      14500
    when /조리|제과|제빵|미용/
      { written: 11900, practical: 20700 }
    when /사회복지사/
      25000
    when /요양보호사/
      32000
    when /전산회계|전산세무/
      20000
    else
      15000
    end
  end
end