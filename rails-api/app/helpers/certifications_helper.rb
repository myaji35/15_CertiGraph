module CertificationsHelper
  # 한국의 주요 자격증 목록 (카테고리별 분류)
  def certification_list
    {
      'IT/정보처리' => [
        '정보처리기사', '정보처리산업기사', '정보보안기사', '정보보안산업기사',
        '네트워크관리사 1급', '네트워크관리사 2급', '리눅스마스터 1급', '리눅스마스터 2급',
        '컴퓨터활용능력 1급', '컴퓨터활용능력 2급', '워드프로세서', '전자계산기조직응용기사',
        '전자계산기기사', '사무자동화산업기사', '정보처리기능사', '정보기기운용기능사',
        '사무자동화기능사', 'OCP(Oracle Certified Professional)', 'CCNA', 'CCNP',
        'AWS Certified Solutions Architect', '빅데이터분석기사', '데이터분석준전문가(ADsP)',
        '데이터분석전문가(ADP)', 'SQL개발자(SQLD)', 'SQL전문가(SQLP)'
      ],
      '사회복지' => [
        '사회복지사 1급', '사회복지사 2급', '정신건강사회복지사', '의료사회복지사',
        '학교사회복지사', '사회조사분석사 1급', '사회조사분석사 2급', '건강가정사'
      ],
      '보육/교육' => [
        '보육교사 1급', '보육교사 2급', '보육교사 3급', '유치원정교사 1급', '유치원정교사 2급',
        '특수교사', '초등교사', '중등교사', '평생교육사 1급', '평생교육사 2급', '평생교육사 3급',
        '직업상담사 1급', '직업상담사 2급', '청소년상담사 1급', '청소년상담사 2급', '청소년상담사 3급',
        '청소년지도사 1급', '청소년지도사 2급', '청소년지도사 3급'
      ],
      '의료/보건' => [
        '간호사', '간호조무사', '응급구조사 1급', '응급구조사 2급', '의료기사', '의무기록사',
        '임상병리사', '방사선사', '물리치료사', '작업치료사', '치과위생사', '치과기공사',
        '안경사', '영양사', '위생사', '보건교육사 1급', '보건교육사 2급', '보건교육사 3급',
        '약사', '한약사', '수의사'
      ],
      '요양/돌봄' => [
        '요양보호사', '장애인활동지원사', '산후조리사', '장기요양관리사', '치매전문관리사'
      ],
      '금융/회계' => [
        '공인회계사', '세무사', '전산회계 1급', '전산회계 2급', '전산세무 1급', '전산세무 2급',
        'FAT 1급', 'FAT 2급', 'TAT 1급', 'TAT 2급', '재경관리사', '회계관리 1급', '회계관리 2급',
        '금융투자분석사', '투자자산운용사', '파생상품투자권유자문인력', '증권투자권유자문인력',
        '펀드투자권유자문인력', '신용분석사', 'CFP(국제재무설계사)', 'AFPK(한국재무설계사)',
        '손해사정사', '보험계리사', '보험중개사', '여신심사역'
      ],
      '법률' => [
        '변호사', '법무사', '변리사', '공인중개사', '주택관리사(보)', '손해평가사',
        '경매사', '감정평가사', '법원사무관리직'
      ],
      '건축/토목' => [
        '건축사', '건축기사', '건축산업기사', '건축기능사', '건축설비기사', '건축설비산업기사',
        '실내건축기사', '실내건축산업기사', '토목기사', '토목산업기사', '측량기능사',
        '측량및지형공간정보기사', '건설안전기사', '건설안전산업기사', '콘크리트기사',
        '건설재료시험기사', '도시계획기사'
      ],
      '전기/전자' => [
        '전기기사', '전기산업기사', '전기공사기사', '전기공사산업기사', '전기기능사',
        '전자기사', '전자산업기사', '전자기능사', '전자계산기기능사', '정보통신기사',
        '정보통신산업기사', '무선설비기사', '무선설비산업기사', '방송통신기사'
      ],
      '기계/자동차' => [
        '기계기사', '기계산업기사', '기계설계기사', '기계설계산업기사', '기계정비기능사',
        '자동차정비기사', '자동차정비산업기사', '자동차정비기능사', '자동차검사기사',
        '자동차정비산업기사', '공조냉동기계기사', '메카트로닉스기사', '설비보전기사'
      ],
      '화학/환경' => [
        '화공기사', '화공산업기사', '위험물기능사', '위험물산업기사', '위험물기사',
        '대기환경기사', '대기환경산업기사', '수질환경기사', '수질환경산업기사',
        '폐기물처리기사', '폐기물처리산업기사', '환경영향평가사', '온실가스관리기사'
      ],
      '안전/소방' => [
        '소방설비기사(기계분야)', '소방설비기사(전기분야)', '소방설비산업기사(기계분야)',
        '소방설비산업기사(전기분야)', '소방안전관리자', '산업안전기사', '산업안전산업기사',
        '산업위생관리기사', '인간공학기사', '가스기사', '가스산업기사'
      ],
      '디자인/미디어' => [
        '시각디자인기사', '시각디자인산업기사', '제품디자인기사', '제품디자인산업기사',
        '컴퓨터그래픽스운용기능사', '웹디자인기능사', '전산응용건축제도기능사',
        '전산응용기계제도기능사', '멀티미디어콘텐츠제작전문가', '게임그래픽전문가',
        '영상편집전문가', '방송영상편집기사', '사진기능사'
      ],
      '외국어' => [
        'TOEIC', 'TOEFL', 'TEPS', 'OPIC', 'TOEIC Speaking', 'HSK 1급', 'HSK 2급', 'HSK 3급',
        'HSK 4급', 'HSK 5급', 'HSK 6급', 'JLPT N1', 'JLPT N2', 'JLPT N3', 'JLPT N4', 'JLPT N5',
        'DELF/DALF', 'DELE', 'TestDaF', '한국어능력시험(TOPIK)'
      ],
      '공무원' => [
        '7급 공무원(행정직)', '9급 공무원(행정직)', '7급 공무원(기술직)', '9급 공무원(기술직)',
        '경찰공무원', '소방공무원', '교육행정직', '법원직 공무원', '검찰직 공무원',
        '교정직 공무원', '보호직 공무원', '철도공무원'
      ],
      '서비스업' => [
        '조리기능사(한식)', '조리기능사(양식)', '조리기능사(중식)', '조리기능사(일식)',
        '조리기능사(복어)', '제과기능사', '제빵기능사', '바리스타 1급', '바리스타 2급',
        '조주기능사', '식품기사', '식품산업기사', '식품기능사', '위생사',
        '미용사(일반)', '미용사(피부)', '미용사(네일)', '미용사(메이크업)',
        '이용사', '숙박서비스사', '호텔경영사', '호텔관리사', '관광통역안내사',
        '국내여행안내사', '호텔서비스사'
      ],
      '물류/유통' => [
        '물류관리사', '유통관리사 1급', '유통관리사 2급', '유통관리사 3급',
        '보세사', '국제무역사', '관세사', '외환관리사', '원산지관리사',
        '지게차운전기능사', '굴착기운전기능사', '크레인운전기능사'
      ],
      '경영/사무' => [
        '경영지도사', '중소기업진단사', '기업교육전문가', '품질경영기사', '품질경영산업기사',
        'ISO 9001 심사원', 'ISO 14001 심사원', '인적자원관리사', '노무사', '직업상담사 1급',
        '직업상담사 2급', '사회조사분석사', '한국사능력검정시험', '한자능력검정시험'
      ],
      '부동산' => [
        '공인중개사', '감정평가사', '주택관리사(보)', '경매사', '공인중개사보조원',
        '부동산투자분석사', '부동산경매사'
      ],
      '농림수산' => [
        '농업기사', '농업산업기사', '축산기사', '축산산업기사', '임업기사', '임업산업기사',
        '수산양식기사', '수산양식산업기사', '어업생산관리기사', '식물보호기사',
        '유기농업기사', '종자기사'
      ],
      '에너지' => [
        '에너지관리기사', '에너지관리산업기사', '신재생에너지발전설비기사',
        '신재생에너지발전설비산업기사', '온실가스관리기사', '원자력기사'
      ],
      '기타' => [
        '기타 자격증'
      ]
    }
  end

  # 모든 자격증을 평면 배열로 반환 (검색용)
  def all_certifications_flat
    certification_list.values.flatten.sort
  end

  # 자격증을 검색어로 필터링
  def search_certifications(query)
    return [] if query.blank?

    all_certifications_flat.select { |cert| cert.include?(query) }
  end

  # 카테고리로 자격증 찾기
  def find_certification_category(cert_name)
    certification_list.each do |category, certs|
      return category if certs.include?(cert_name)
    end
    '기타'
  end

  # 자격증 시험 구조 정보
  def certification_structure(cert_name)
    structures = {
      '사회복지사 1급' => {
        exam_type: '필기시험',
        total_sessions: 3,
        total_questions: 225,
        passing_score: 60,
        description: '과목당 만점의 40% 이상, 전 과목 평균 60% 이상',
        sessions: [
          {
            session_number: 1,
            duration_minutes: 75,
            total_questions: 75,
            subjects: [
              { name: '인간행동과 사회환경', questions: 25 },
              { name: '사회복지조사론', questions: 50 }
            ]
          },
          {
            session_number: 2,
            duration_minutes: 75,
            total_questions: 75,
            subjects: [
              { name: '사회복지실천론', questions: 25 },
              { name: '사회복지실천기술론', questions: 25 },
              { name: '지역사회복지론', questions: 25 }
            ]
          },
          {
            session_number: 3,
            duration_minutes: 75,
            total_questions: 75,
            subjects: [
              { name: '사회복지정책론', questions: 25 },
              { name: '사회복지행정론', questions: 25 },
              { name: '사회복지법제론', questions: 25 }
            ]
          }
        ]
      },
      '정보처리기사' => {
        exam_type: '필기시험',
        total_sessions: 1,
        total_questions: 100,
        passing_score: 60,
        description: '과목당 40% 이상, 전 과목 평균 60% 이상',
        sessions: [
          {
            session_number: 1,
            duration_minutes: 150,
            total_questions: 100,
            subjects: [
              { name: '소프트웨어 설계', questions: 20 },
              { name: '소프트웨어 개발', questions: 20 },
              { name: '데이터베이스 구축', questions: 20 },
              { name: '프로그래밍 언어 활용', questions: 20 },
              { name: '정보시스템 구축관리', questions: 20 }
            ]
          }
        ]
      },
      '간호사' => {
        exam_type: '필기시험',
        total_sessions: 1,
        total_questions: 295,
        passing_score: 60,
        description: '전 과목 평균 60% 이상',
        sessions: [
          {
            session_number: 1,
            duration_minutes: 330,
            total_questions: 295,
            subjects: [
              { name: '성인간호학', questions: 90 },
              { name: '모성간호학', questions: 40 },
              { name: '아동간호학', questions: 40 },
              { name: '지역사회간호학', questions: 45 },
              { name: '정신간호학', questions: 45 },
              { name: '간호관리학', questions: 35 }
            ]
          }
        ]
      },
      '공인중개사' => {
        exam_type: '필기시험',
        total_sessions: 2,
        total_questions: 80,
        passing_score: 60,
        description: '과목당 40% 이상, 전 과목 평균 60% 이상',
        sessions: [
          {
            session_number: 1,
            duration_minutes: 90,
            total_questions: 40,
            subjects: [
              { name: '부동산학개론', questions: 20 },
              { name: '민법 및 민사특별법', questions: 20 }
            ]
          },
          {
            session_number: 2,
            duration_minutes: 90,
            total_questions: 40,
            subjects: [
              { name: '공법(공인중개사법, 부동산등기법 등)', questions: 20 },
              { name: '부동산공시법 및 부동산세법', questions: 20 }
            ]
          }
        ]
      },
      '컴퓨터활용능력 1급' => {
        exam_type: '필기+실기',
        total_sessions: 1,
        total_questions: 40,
        passing_score: 60,
        description: '필기 60점 이상, 실기 70점 이상',
        sessions: [
          {
            session_number: 1,
            duration_minutes: 40,
            total_questions: 40,
            subjects: [
              { name: '컴퓨터 일반', questions: 20 },
              { name: '스프레드시트 일반', questions: 20 }
            ]
          }
        ]
      },
      '간호조무사' => {
        exam_type: '필기시험',
        total_sessions: 1,
        total_questions: 60,
        passing_score: 60,
        description: '전 과목 평균 60% 이상',
        sessions: [
          {
            session_number: 1,
            duration_minutes: 60,
            total_questions: 60,
            subjects: [
              { name: '기초간호학 개요', questions: 12 },
              { name: '보건간호학 개요', questions: 12 },
              { name: '공중보건학 개요', questions: 12 },
              { name: '실기', questions: 24 }
            ]
          }
        ]
      },
      '요양보호사' => {
        exam_type: '필기+실기',
        total_sessions: 1,
        total_questions: 35,
        passing_score: 60,
        description: '필기 60점 이상, 실기 60점 이상',
        sessions: [
          {
            session_number: 1,
            duration_minutes: 50,
            total_questions: 35,
            subjects: [
              { name: '요양보호론', questions: 10 },
              { name: '노인복지론', questions: 10 },
              { name: '기초요양보호각론', questions: 15 }
            ]
          }
        ]
      }
    }

    structures[cert_name]
  end

  # 자격증이 시험 구조 정보를 가지고 있는지 확인
  def has_certification_structure?(cert_name)
    certification_structure(cert_name).present?
  end

  # 교시별 과목 목록 가져오기
  def session_subjects(cert_name, session_number)
    structure = certification_structure(cert_name)
    return [] unless structure

    session = structure[:sessions].find { |s| s[:session_number] == session_number }
    session ? session[:subjects] : []
  end

  # 자격증의 전체 과목 목록 가져오기
  def all_subjects(cert_name)
    structure = certification_structure(cert_name)
    return [] unless structure

    structure[:sessions].flat_map { |s| s[:subjects].map { |subj| subj[:name] } }
  end
end
