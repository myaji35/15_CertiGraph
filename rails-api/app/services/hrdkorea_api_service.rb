require 'net/http'
require 'json'
require 'uri'

class HrdkoreaApiService
  BASE_URL = 'http://apis.data.go.kr/B490007/qualExamSchd'

  def initialize(api_key = nil)
    @api_key = api_key || ENV['HRDKOREA_API_KEY']
  end

  # 2025/2026년 시험 일정 조회
  def fetch_exam_schedules(year = Date.current.year)
    return mock_data(year) unless @api_key

    endpoint = "#{BASE_URL}/getQualExamSchdList"
    params = {
      serviceKey: @api_key,
      numOfRows: 1000,
      pageNo: 1,
      dataFormat: 'json',
      implYy: year
    }

    response = make_request(endpoint, params)
    parse_schedules(response)
  rescue => e
    Rails.logger.error "HRDKorea API Error: #{e.message}"
    mock_data(year)
  end

  # 특정 자격증 시험 일정 조회
  def fetch_certification_schedule(certification_code, year = Date.current.year)
    return mock_certification_data(certification_code, year) unless @api_key

    endpoint = "#{BASE_URL}/getQualExamSchdList"
    params = {
      serviceKey: @api_key,
      numOfRows: 100,
      pageNo: 1,
      dataFormat: 'json',
      implYy: year,
      qualgbCd: certification_code
    }

    response = make_request(endpoint, params)
    parse_schedules(response)
  rescue => e
    Rails.logger.error "HRDKorea API Error: #{e.message}"
    mock_certification_data(certification_code, year)
  end

  # 자격증 목록 조회
  def fetch_certifications
    return mock_certifications unless @api_key

    endpoint = "#{BASE_URL}/getQualList"
    params = {
      serviceKey: @api_key,
      numOfRows: 1000,
      pageNo: 1,
      dataFormat: 'json'
    }

    response = make_request(endpoint, params)
    parse_certifications(response)
  rescue => e
    Rails.logger.error "HRDKorea API Error: #{e.message}"
    mock_certifications
  end

  # 데이터베이스에 시험 일정 동기화
  def sync_exam_schedules(year = Date.current.year)
    schedules = fetch_exam_schedules(year)

    schedules.each do |schedule_data|
      certification = find_or_create_certification(schedule_data)
      next unless certification

      exam_schedule = ExamSchedule.find_or_initialize_by(
        certification: certification,
        year: year,
        round: schedule_data[:round],
        exam_type: map_exam_type(schedule_data[:exam_type])
      )

      exam_schedule.update!(
        registration_start_date: schedule_data[:registration_start],
        registration_end_date: schedule_data[:registration_end],
        exam_date: schedule_data[:exam_date],
        result_date: schedule_data[:result_date],
        exam_fee: schedule_data[:exam_fee],
        status: 'scheduled'
      )
    end

    { success: true, count: schedules.count }
  rescue => e
    Rails.logger.error "Sync Error: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def make_request(endpoint, params)
    uri = URI(endpoint)
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)

    if response.code == '200'
      JSON.parse(response.body)
    else
      raise "API request failed: #{response.code} - #{response.body}"
    end
  end

  def parse_schedules(response)
    return [] unless response && response['response'] && response['response']['body']

    items = response['response']['body']['items']
    return [] unless items

    items.map do |item|
      {
        certification_name: item['jmfldnm'],
        certification_code: item['jmcd'],
        round: item['implseq']&.to_i,
        exam_type: item['qualgbcd'],
        registration_start: parse_date(item['docregstartdt']),
        registration_end: parse_date(item['docregenddt']),
        exam_date: parse_date(item['docexamdt']),
        result_date: parse_date(item['docpassdt']),
        exam_fee: item['fee']&.to_i
      }
    end
  end

  def parse_certifications(response)
    return [] unless response && response['response'] && response['response']['body']

    items = response['response']['body']['items']
    return [] unless items

    items.map do |item|
      {
        name: item['jmfldnm'],
        code: item['jmcd'],
        series: item['seriesnm'],
        category: item['obligfldnm'],
        organization: item['mdobligfldnm'] || '한국산업인력공단'
      }
    end
  end

  def parse_date(date_string)
    return nil if date_string.blank?
    Date.parse(date_string.to_s)
  rescue
    nil
  end

  def find_or_create_certification(schedule_data)
    Certification.find_or_create_by(
      name: schedule_data[:certification_name]
    ) do |cert|
      cert.organization = '한국산업인력공단'
      cert.is_national = true
    end
  rescue => e
    Rails.logger.error "Failed to create certification: #{e.message}"
    nil
  end

  def map_exam_type(type_code)
    case type_code
    when 'T', '필기'
      'written'
    when 'S', '실기'
      'practical'
    when 'I', '면접'
      'interview'
    else
      'written'
    end
  end

  # Mock 데이터 (API 키가 없을 때 사용)
  def mock_data(year)
    [
      {
        certification_name: '정보처리기사',
        certification_code: '1320',
        round: 1,
        exam_type: 'T',
        registration_start: Date.new(year, 1, 6),
        registration_end: Date.new(year, 1, 9),
        exam_date: Date.new(year, 3, 15),
        result_date: Date.new(year, 4, 2),
        exam_fee: 19400
      },
      {
        certification_name: '정보처리기사',
        certification_code: '1320',
        round: 1,
        exam_type: 'S',
        registration_start: Date.new(year, 3, 31),
        registration_end: Date.new(year, 4, 3),
        exam_date: Date.new(year, 5, 17),
        result_date: Date.new(year, 6, 18),
        exam_fee: 22600
      },
      {
        certification_name: '사회복지사 1급',
        certification_code: '3120',
        round: 1,
        exam_type: 'T',
        registration_start: Date.new(year, 12, 2, -1), # 전년도 12월
        registration_end: Date.new(year, 12, 6, -1),
        exam_date: Date.new(year, 1, 18),
        result_date: Date.new(year, 3, 11),
        exam_fee: 25000
      },
      {
        certification_name: '빅데이터분석기사',
        certification_code: '4320',
        round: 1,
        exam_type: 'T',
        registration_start: Date.new(year, 2, 3),
        registration_end: Date.new(year, 2, 6),
        exam_date: Date.new(year, 4, 12),
        result_date: Date.new(year, 5, 7),
        exam_fee: 19400
      }
    ]
  end

  def mock_certification_data(certification_code, year)
    mock_data(year).select { |d| d[:certification_code] == certification_code }
  end

  def mock_certifications
    [
      {
        name: '정보처리기사',
        code: '1320',
        series: '기사',
        category: '정보통신',
        organization: '한국산업인력공단'
      },
      {
        name: '사회복지사 1급',
        code: '3120',
        series: '1급',
        category: '사회복지',
        organization: '한국산업인력공단'
      },
      {
        name: '빅데이터분석기사',
        code: '4320',
        series: '기사',
        category: '데이터',
        organization: '한국산업인력공단'
      },
      {
        name: '컴퓨터활용능력 1급',
        code: '2290',
        series: '1급',
        category: '사무',
        organization: '대한상공회의소'
      }
    ]
  end
end