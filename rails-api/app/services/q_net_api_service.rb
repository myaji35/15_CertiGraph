require 'httparty'

class QNetApiService
  include HTTParty
  base_uri 'http://apis.data.go.kr/B490007/qualExamSchd'

  # 한국산업인력공단 Q-Net API 서비스
  # 공공데이터포털에서 발급받은 API 키 필요
  # https://www.data.go.kr/data/15077778/openapi.do

  def initialize
    # 디코딩된 API 키 사용 (유효성 확인됨)
    @api_key = ENV['Q_NET_API_KEY'] || 'Fp/4WVioB7bIOpSNIyVppjLfZCOlNtFTrFzVOm138SVfBs7tf9l3DXabIror0XfhXvTUWKcXPc59xKmtxiuq1Q=='
    @default_options = {
      query: {
        serviceKey: @api_key,
        numOfRows: 100,
        pageNo: 1,
        dataFormat: 'json',
        implYy: 2026  # 2026년 시험일정
      }
    }
  end

  # 2026년 국가기술자격 시험일정 조회
  def fetch_exam_schedules(year = 2026)
    Rails.logger.info "Fetching exam schedules for year: #{year}"

    # 인기 자격증 목록
    certifications = [
      { code: '1320', name: '정보처리기사' },
      { code: '2290', name: '정보처리산업기사' },
      { code: '6921', name: '정보처리기능사' },
      { code: '1220', name: '전기기사' },
      { code: '1230', name: '전자기사' },
      { code: '1330', name: '산업안전기사' },
      { code: '7910', name: '한식조리기능사' },
      { code: '7920', name: '양식조리기능사' },
      { code: '1520', name: '토목기사' },
      { code: '1560', name: '건축기사' },
      { code: '2050', name: '사회복지사1급' }  # Q-Net API에 없을 수 있음
    ]

    schedules = []

    certifications.each do |cert|
      begin
        response = fetch_schedule_for_certification(cert[:code], year)
        if response && response['items']
          schedules.concat(parse_exam_schedule(response['items'], cert))
        end
      rescue => e
        Rails.logger.error "Error fetching schedule for #{cert[:name]}: #{e.message}"
      end
    end

    schedules
  end

  # 특정 자격증의 시험일정 조회
  def fetch_schedule_for_certification(certification_code, year)
    options = @default_options.deep_dup
    options[:query][:qualgbCd] = certification_code
    options[:query][:implYy] = year

    response = self.class.get('/getQualExamSchdList', options)

    if response.success?
      JSON.parse(response.body)
    else
      Rails.logger.error "API request failed: #{response.code} - #{response.body}"
      nil
    end
  end

  # 시험일정 데이터 파싱
  def parse_exam_schedule(items, certification_info)
    return [] unless items.is_a?(Array)

    items.map do |item|
      {
        certification_code: certification_info[:code],
        certification_name: certification_info[:name] || item['description'],
        exam_year: item['implYy'],
        exam_round: item['implSeq'],

        # 필기시험
        written_exam_date: parse_date(item['docExamStartDt']),
        written_exam_reg_start: parse_date(item['docRegStartDt']),
        written_exam_reg_end: parse_date(item['docRegEndDt']),

        # 실기시험
        practical_exam_date: parse_date(item['pracExamStartDt']),
        practical_exam_reg_start: parse_date(item['pracRegStartDt']),
        practical_exam_reg_end: parse_date(item['pracRegEndDt']),

        # 합격발표
        announcement_date: parse_date(item['docPassDt']),

        # 추가정보
        exam_fee: item['fee'],
        exam_location: item['examArea'],
        additional_info: {
          description: item['description'],
          exam_type: item['examTyp'],
          practical_announcement: item['pracPassDt']
        }
      }
    end
  end

  # 데이터베이스에 시험일정 저장
  def sync_to_database
    schedules = fetch_exam_schedules(2026)

    success_count = 0
    error_count = 0

    schedules.each do |schedule_data|
      begin
        exam_schedule = ExamSchedule.find_or_initialize_by(
          certification_code: schedule_data[:certification_code],
          exam_year: schedule_data[:exam_year],
          exam_round: schedule_data[:exam_round]
        )

        exam_schedule.update!(schedule_data)
        success_count += 1
      rescue => e
        error_count += 1
        Rails.logger.error "Failed to save exam schedule: #{e.message}"
      end
    end

    Rails.logger.info "Sync completed: #{success_count} saved, #{error_count} errors"

    {
      success: success_count,
      errors: error_count,
      total: schedules.count,
      percentage: schedules.count > 0 ? (success_count.to_f / schedules.count * 100).round(2) : 0
    }
  end

  # 한국보건의료인국가시험원 API (의료 관련 자격증)
  def fetch_medical_exam_schedules
    # 간호사, 의사, 약사 등 의료 자격증 시험일정
    # 별도 API 엔드포인트 필요
    []
  end

  # 한국사회복지사협회 API (사회복지사)
  def fetch_social_worker_schedules
    # 사회복지사 1급 시험일정
    # 별도 API 엔드포인트 필요
    []
  end

  private

  def parse_date(date_string)
    return nil if date_string.blank?

    # YYYYMMDD 형식을 Date 객체로 변환
    if date_string.length == 8
      Date.parse("#{date_string[0..3]}-#{date_string[4..5]}-#{date_string[6..7]}")
    else
      Date.parse(date_string)
    end
  rescue
    nil
  end
end