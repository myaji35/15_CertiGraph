// 한국 자격증 전체 카테고리 분류 체계
// 한국산업인력공단, 각 협회, 민간자격 포함

export interface CertificationCategory {
  id: string;
  name: string;
  description: string;
  subcategories: string[];
  certifications: CertificationInfo[];
  color: string;
  icon?: string;
}

export interface CertificationInfo {
  name: string;
  englishName?: string;
  levels?: string[]; // 기사, 산업기사, 기능사 등
  organization: string;
  examType: 'national' | 'private' | 'international'; // 국가자격, 민간자격, 국제자격
  popularity?: number; // 인기도 (응시자 수 기반)
  difficulty?: 1 | 2 | 3 | 4 | 5; // 난이도
  averagePassRate?: number; // 평균 합격률
}

export const certificationCategories: CertificationCategory[] = [
  {
    id: 'it-tech',
    name: 'IT/정보통신',
    description: '정보처리, 네트워크, 보안, 클라우드, AI/빅데이터 관련 자격증',
    color: 'bg-blue-100',
    subcategories: ['정보처리', '네트워크', '정보보안', '클라우드', 'AI/빅데이터', '게임/멀티미디어'],
    certifications: [
      // 정보처리 계열
      { name: '정보처리기사', levels: ['기사', '산업기사', '기능사'], organization: '한국산업인력공단', examType: 'national', popularity: 5, difficulty: 3 },
      { name: '정보처리산업기사', organization: '한국산업인력공단', examType: 'national', popularity: 4, difficulty: 2 },
      { name: '전자계산기제어산업기사', organization: '한국산업인력공단', examType: 'national' },
      { name: '정보기기운용기능사', organization: '한국산업인력공단', examType: 'national' },
      { name: '컴퓨터시스템응용기술사', organization: '한국산업인력공단', examType: 'national', difficulty: 5 },

      // 네트워크 계열
      { name: '네트워크관리사', levels: ['1급', '2급'], organization: '한국정보통신자격협회', examType: 'private' },
      { name: '정보통신기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '무선설비기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '방송통신기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },

      // 정보보안 계열
      { name: '정보보안기사', organization: '한국산업인력공단', examType: 'national', popularity: 5, difficulty: 4 },
      { name: '정보보안산업기사', organization: '한국산업인력공단', examType: 'national' },
      { name: 'CISA', englishName: 'Certified Information Systems Auditor', organization: 'ISACA', examType: 'international', difficulty: 5 },
      { name: 'CISSP', englishName: 'Certified Information Systems Security Professional', organization: 'ISC2', examType: 'international', difficulty: 5 },
      { name: '개인정보관리사', levels: ['CPPG', 'CPPIS'], organization: '한국개인정보전문가협회', examType: 'private' },

      // 클라우드/가상화
      { name: '클라우드컴퓨팅지도사', organization: '한국클라우드컴퓨팅연구조합', examType: 'private' },
      { name: 'AWS Solutions Architect', levels: ['Associate', 'Professional'], organization: 'Amazon', examType: 'international' },
      { name: 'Azure Administrator', levels: ['Associate', 'Expert'], organization: 'Microsoft', examType: 'international' },
      { name: 'GCP Cloud Engineer', organization: 'Google', examType: 'international' },

      // AI/빅데이터
      { name: '빅데이터분석기사', organization: '한국산업인력공단', examType: 'national', popularity: 5, difficulty: 4 },
      { name: '인공지능지도사', organization: '한국인공지능협회', examType: 'private' },
      { name: '데이터분석전문가(ADP)', organization: '한국데이터산업진흥원', examType: 'private', difficulty: 4 },
      { name: '데이터분석준전문가(ADsP)', organization: '한국데이터산업진흥원', examType: 'private', difficulty: 3 },
      { name: 'SQL개발자(SQLD)', organization: '한국데이터산업진흥원', examType: 'private', popularity: 5 },
      { name: 'SQL전문가(SQLP)', organization: '한국데이터산업진흥원', examType: 'private', difficulty: 5 },

      // 게임/멀티미디어
      { name: '게임기획전문가', organization: '한국산업인력공단', examType: 'national' },
      { name: '게임프로그래밍전문가', organization: '한국산업인력공단', examType: 'national' },
      { name: '멀티미디어콘텐츠제작전문가', organization: '한국산업인력공단', examType: 'national' },
      { name: '컴퓨터그래픽스운용기능사', organization: '한국산업인력공단', examType: 'national' },
      { name: '웹디자인기능사', organization: '한국산업인력공단', examType: 'national' },
    ]
  },

  {
    id: 'business-economy',
    name: '경영/경제/무역',
    description: '경영, 경제, 무역, 유통, 물류 관련 자격증',
    color: 'bg-indigo-100',
    subcategories: ['경영', '경제', '무역', '유통/물류', '품질관리'],
    certifications: [
      // 경영
      { name: '경영지도사', organization: '한국산업인력공단', examType: 'national', difficulty: 5 },
      { name: '기술경영지도사', organization: '한국산업인력공단', examType: 'national' },
      { name: 'ERP정보관리사', levels: ['1급', '2급'], organization: '한국생산성본부', examType: 'private' },
      { name: '경영진단사', organization: '한국경영인증원', examType: 'private' },

      // 경제
      { name: '경제경영연구사', organization: '한국산업인력공단', examType: 'national' },
      { name: '매경TEST', organization: '매일경제신문사', examType: 'private', popularity: 4 },
      { name: 'TESAT', organization: '한국경제신문사', examType: 'private', popularity: 4 },

      // 무역
      { name: '국제무역사', levels: ['1급', '2급'], organization: '한국무역협회', examType: 'private', popularity: 4 },
      { name: '무역영어', levels: ['1급', '2급', '3급'], organization: '대한상공회의소', examType: 'private' },
      { name: '원산지관리사', organization: '한국산업인력공단', examType: 'national' },
      { name: '보세사', organization: '한국관세사회', examType: 'national' },
      { name: '관세사', organization: '한국산업인력공단', examType: 'national', difficulty: 5 },

      // 유통/물류
      { name: '유통관리사', levels: ['1급', '2급', '3급'], organization: '대한상공회의소', examType: 'private', popularity: 4 },
      { name: '물류관리사', organization: '한국산업인력공단', examType: 'national', difficulty: 4 },
      { name: '판매관리사', levels: ['1급', '2급', '3급'], organization: '대한상공회의소', examType: 'private' },

      // 품질관리
      { name: '품질경영기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '품질경영산업기사', organization: '한국산업인력공단', examType: 'national' },
    ]
  },

  {
    id: 'finance-accounting',
    name: '금융/회계/세무',
    description: '은행, 증권, 보험, 회계, 세무 관련 자격증',
    color: 'bg-yellow-100',
    subcategories: ['금융', '증권/투자', '보험', '회계', '세무'],
    certifications: [
      // 금융
      { name: '신용분석사', organization: '한국금융연수원', examType: 'private', popularity: 4 },
      { name: '신용관리사', organization: '한국금융연수원', examType: 'private' },
      { name: '여신심사역', organization: '한국금융연수원', examType: 'private' },
      { name: '자산관리사(FP)', organization: '한국금융연수원', examType: 'private' },
      { name: '외환전문역', levels: ['1종', '2종'], organization: '한국금융연수원', examType: 'private' },

      // 재무설계
      { name: 'CFP', englishName: 'Certified Financial Planner', organization: '한국FPSB', examType: 'international', difficulty: 5 },
      { name: 'AFPK', englishName: 'Associate Financial Planner Korea', organization: '한국FPSB', examType: 'private', difficulty: 3 },

      // 증권/투자
      { name: '투자자산운용사', organization: '한국금융투자협회', examType: 'national', difficulty: 4 },
      { name: '증권투자권유자문인력', organization: '한국금융투자협회', examType: 'private' },
      { name: '파생상품투자권유자문인력', organization: '한국금융투자협회', examType: 'private' },
      { name: '펀드투자권유자문인력', organization: '한국금융투자협회', examType: 'private' },
      { name: '금융투자분석사', organization: '한국금융투자협회', examType: 'national', difficulty: 5 },
      { name: 'CFA', englishName: 'Chartered Financial Analyst', levels: ['Level 1', 'Level 2', 'Level 3'], organization: 'CFA Institute', examType: 'international', difficulty: 5 },

      // 보험
      { name: '손해평가사', organization: '한국산업인력공단', examType: 'national', difficulty: 4 },
      { name: '보험계리사', organization: '금융감독원', examType: 'national', difficulty: 5 },
      { name: '손해사정사', organization: '금융감독원', examType: 'national' },
      { name: '보험중개사', organization: '금융감독원', examType: 'national' },

      // 회계
      { name: '공인회계사', englishName: 'CPA', organization: '금융감독원', examType: 'national', difficulty: 5, popularity: 5 },
      { name: '세무사', englishName: 'CTA', organization: '한국산업인력공단', examType: 'national', difficulty: 5, popularity: 5 },
      { name: '전산회계', levels: ['1급', '2급'], organization: '한국세무사회', examType: 'private', popularity: 4 },
      { name: '전산세무', levels: ['1급', '2급'], organization: '한국세무사회', examType: 'private', popularity: 4 },
      { name: 'FAT', levels: ['1급', '2급'], organization: '한국공인회계사회', examType: 'private' },
      { name: 'TAT', levels: ['1급', '2급'], organization: '한국공인회계사회', examType: 'private' },
      { name: '재경관리사', organization: '삼일회계법인', examType: 'private' },
    ]
  },

  {
    id: 'construction-architecture',
    name: '건설/건축/토목',
    description: '건축, 토목, 조경, 도시계획 관련 자격증',
    color: 'bg-amber-100',
    subcategories: ['건축', '토목', '조경', '도시계획', '안전관리'],
    certifications: [
      // 건축
      { name: '건축기사', levels: ['기사', '산업기사', '기능사'], organization: '한국산업인력공단', examType: 'national', popularity: 5 },
      { name: '건축사', organization: '대한건축사협회', examType: 'national', difficulty: 5 },
      { name: '실내건축기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '건축설비기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },

      // 토목
      { name: '토목기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national', popularity: 5 },
      { name: '측량및지형공간정보기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '콘크리트기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '철도토목기사', organization: '한국산업인력공단', examType: 'national' },

      // 조경
      { name: '조경기사', levels: ['기사', '산업기사', '기능사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '자연생태복원기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },

      // 도시계획
      { name: '도시계획기사', organization: '한국산업인력공단', examType: 'national' },
      { name: '교통기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },

      // 안전관리
      { name: '건설안전기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national', popularity: 5 },
      { name: '산업안전기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national', popularity: 5 },
      { name: '소방설비기사', levels: ['기사-기계', '기사-전기', '산업기사'], organization: '한국산업인력공단', examType: 'national' },
    ]
  },

  {
    id: 'mechanical-electrical',
    name: '기계/전기/전자',
    description: '기계설계, 전기, 전자, 에너지 관련 자격증',
    color: 'bg-gray-100',
    subcategories: ['기계', '전기', '전자', '에너지', '자동차'],
    certifications: [
      // 기계
      { name: '일반기계기사', levels: ['기사', '산업기사', '기능사'], organization: '한국산업인력공단', examType: 'national', popularity: 5 },
      { name: '기계설계기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '메카트로닉스기사', organization: '한국산업인력공단', examType: 'national' },
      { name: '공조냉동기계기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },

      // 전기
      { name: '전기기사', levels: ['기사', '산업기사', '기능사'], organization: '한국산업인력공단', examType: 'national', popularity: 5 },
      { name: '전기공사기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '전기철도기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },

      // 전자
      { name: '전자기사', levels: ['기사', '산업기사', '기능사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '전자계산기기사', organization: '한국산업인력공단', examType: 'national' },
      { name: '반도체설계기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },

      // 에너지
      { name: '에너지관리기사', levels: ['기사', '산업기사', '기능사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '신재생에너지발전설비기사', organization: '한국산업인력공단', examType: 'national' },
      { name: '원자력기사', organization: '한국산업인력공단', examType: 'national' },

      // 자동차
      { name: '자동차정비기사', levels: ['기사', '산업기사', '기능사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '자동차검사기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },
    ]
  },

  {
    id: 'chemical-bio',
    name: '화학/생명/환경',
    description: '화학, 생명과학, 환경, 식품 관련 자격증',
    color: 'bg-green-100',
    subcategories: ['화학', '생명과학', '환경', '식품', '농림'],
    certifications: [
      // 화학
      { name: '화학분석기사', levels: ['기사', '산업기사', '기능사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '화공기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '위험물산업기사', organization: '한국산업인력공단', examType: 'national', popularity: 4 },

      // 생명과학
      { name: '생물공학기사', organization: '한국산업인력공단', examType: 'national' },
      { name: '바이오화학제품제조기사', organization: '한국산업인력공단', examType: 'national' },

      // 환경
      { name: '환경기사', levels: ['대기', '수질', '폐기물', '소음진동', '토양', '자연생태'], organization: '한국산업인력공단', examType: 'national', popularity: 4 },
      { name: '온실가스관리기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '환경측정분석사', organization: '국립환경인재개발원', examType: 'national' },

      // 식품
      { name: '식품기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '영양사', organization: '한국영양사협회', examType: 'national', popularity: 5 },
      { name: '위생사', organization: '한국보건의료인국가시험원', examType: 'national' },
      { name: '조리기능사', levels: ['한식', '양식', '중식', '일식', '복어'], organization: '한국산업인력공단', examType: 'national', popularity: 4 },

      // 농림
      { name: '종자기사', levels: ['기사', '산업기사', '기능사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '시설원예기사', organization: '한국산업인력공단', examType: 'national' },
      { name: '식물보호기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },
    ]
  },

  {
    id: 'healthcare-welfare',
    name: '보건/의료/복지',
    description: '의료, 보건, 복지, 상담 관련 자격증',
    color: 'bg-pink-100',
    subcategories: ['의료기사', '보건', '복지', '상담', '요양보호'],
    certifications: [
      // 의료기사
      { name: '임상병리사', organization: '한국보건의료인국가시험원', examType: 'national', popularity: 5 },
      { name: '방사선사', organization: '한국보건의료인국가시험원', examType: 'national', popularity: 5 },
      { name: '물리치료사', organization: '한국보건의료인국가시험원', examType: 'national', popularity: 5 },
      { name: '작업치료사', organization: '한국보건의료인국가시험원', examType: 'national' },
      { name: '치과기공사', organization: '한국보건의료인국가시험원', examType: 'national' },
      { name: '치과위생사', organization: '한국보건의료인국가시험원', examType: 'national' },
      { name: '안경사', organization: '한국보건의료인국가시험원', examType: 'national' },

      // 보건
      { name: '보건교육사', levels: ['1급', '2급', '3급'], organization: '한국보건의료인국가시험원', examType: 'national' },
      { name: '병원행정사', organization: '대한병원행정관리자협회', examType: 'private' },
      { name: '병원코디네이터', organization: '한국병원코디네이터협회', examType: 'private' },
      { name: '의료관광코디네이터', organization: '한국산업인력공단', examType: 'national' },

      // 복지
      { name: '사회복지사', levels: ['1급', '2급'], organization: '한국사회복지사협회', examType: 'national', popularity: 5, difficulty: 3 },
      { name: '청소년지도사', levels: ['1급', '2급', '3급'], organization: '한국청소년활동진흥원', examType: 'national' },
      { name: '청소년상담사', levels: ['1급', '2급', '3급'], organization: '한국청소년상담복지개발원', examType: 'national' },
      { name: '건강가정사', organization: '한국건강가정진흥원', examType: 'national' },

      // 상담
      { name: '임상심리사', levels: ['1급', '2급'], organization: '한국산업인력공단', examType: 'national', difficulty: 4 },
      { name: '전문상담사', levels: ['1급', '2급'], organization: '한국상담학회', examType: 'private' },
      { name: '직업상담사', levels: ['1급', '2급'], organization: '한국산업인력공단', examType: 'national' },

      // 요양보호
      { name: '요양보호사', organization: '시도지사', examType: 'national', popularity: 5 },
      { name: '간호조무사', organization: '한국보건의료인국가시험원', examType: 'national', popularity: 5 },
    ]
  },

  {
    id: 'education-culture',
    name: '교육/문화/예술',
    description: '교육, 한국어, 외국어, 문화예술 관련 자격증',
    color: 'bg-purple-100',
    subcategories: ['교육', '한국어', '외국어', '문화예술', '스포츠'],
    certifications: [
      // 교육
      { name: '평생교육사', levels: ['1급', '2급', '3급'], organization: '국가평생교육진흥원', examType: 'national' },
      { name: '이러닝지도사', levels: ['1급', '2급'], organization: '한국이러닝협회', examType: 'private' },
      { name: '방과후지도사', levels: ['1급', '2급'], organization: '한국방과후교육진흥원', examType: 'private' },

      // 한국어
      { name: '한국어교육능력검정시험', organization: '국립국어원', examType: 'national' },
      { name: '한국사능력검정', levels: ['심화', '기본'], organization: '국사편찬위원회', examType: 'national', popularity: 5 },
      { name: 'KBS한국어능력시험', organization: 'KBS', examType: 'private' },
      { name: '한국실용글쓰기검정', levels: ['1급', '2급', '3급'], organization: '한국국어능력평가협회', examType: 'private' },

      // 외국어
      { name: 'TOEIC', englishName: 'Test of English for International Communication', organization: 'ETS', examType: 'international', popularity: 5 },
      { name: 'TOEFL', englishName: 'Test of English as a Foreign Language', organization: 'ETS', examType: 'international', popularity: 4 },
      { name: 'IELTS', englishName: 'International English Language Testing System', organization: 'British Council', examType: 'international', popularity: 4 },
      { name: 'TEPS', organization: '서울대학교', examType: 'private', popularity: 3 },
      { name: 'OPIc', englishName: 'Oral Proficiency Interview-computer', organization: 'ACTFL', examType: 'international', popularity: 4 },
      { name: 'HSK', englishName: '汉语水平考试', levels: ['1급', '2급', '3급', '4급', '5급', '6급'], organization: '중국 한반', examType: 'international', popularity: 4 },
      { name: 'JLPT', englishName: '日本語能力試験', levels: ['N1', 'N2', 'N3', 'N4', 'N5'], organization: '일본국제교류기금', examType: 'international', popularity: 4 },
      { name: 'DELF/DALF', organization: '프랑스교육부', examType: 'international' },
      { name: 'DELE', organization: '스페인 세르반테스협회', examType: 'international' },
      { name: 'TestDaF', organization: '독일 TestDaF Institut', examType: 'international' },

      // 문화예술
      { name: '문화예술교육사', levels: ['1급', '2급'], organization: '한국문화예술교육진흥원', examType: 'national' },
      { name: '박물관및미술관준학예사', organization: '국립중앙박물관', examType: 'national' },
      { name: '무대예술전문인', levels: ['1급', '2급', '3급'], organization: '한국산업인력공단', examType: 'national' },

      // 스포츠
      { name: '생활스포츠지도사', levels: ['1급', '2급'], organization: '국민체육진흥공단', examType: 'national' },
      { name: '전문스포츠지도사', levels: ['1급', '2급'], organization: '국민체육진흥공단', examType: 'national' },
      { name: '유소년스포츠지도사', organization: '국민체육진흥공단', examType: 'national' },
      { name: '노인스포츠지도사', organization: '국민체육진흥공단', examType: 'national' },
      { name: '장애인스포츠지도사', levels: ['1급', '2급'], organization: '국민체육진흥공단', examType: 'national' },
    ]
  },

  {
    id: 'law-public',
    name: '법률/공공/행정',
    description: '법무, 행정, 노무, 부동산 관련 자격증',
    color: 'bg-red-100',
    subcategories: ['법무', '행정', '노무', '부동산', '지적재산'],
    certifications: [
      // 법무
      { name: '법무사', organization: '법원행정처', examType: 'national', difficulty: 5 },
      { name: '변리사', organization: '특허청', examType: 'national', difficulty: 5 },

      // 행정
      { name: '행정사', organization: '한국산업인력공단', examType: 'national', difficulty: 3 },
      { name: '행정관리사', levels: ['1급', '2급', '3급'], organization: '한국행정관리협회', examType: 'private' },
      { name: '사무자동화산업기사', organization: '한국산업인력공단', examType: 'national' },
      { name: '컴퓨터활용능력', levels: ['1급', '2급'], organization: '대한상공회의소', examType: 'private', popularity: 5 },
      { name: '워드프로세서', levels: ['단일등급'], organization: '대한상공회의소', examType: 'private', popularity: 4 },
      { name: 'ITQ', levels: ['A급', 'B급', 'C급'], organization: '한국생산성본부', examType: 'private' },

      // 노무
      { name: '공인노무사', organization: '고용노동부', examType: 'national', difficulty: 5 },
      { name: '기업인적자원개발지도사', organization: '한국산업인력공단', examType: 'national' },

      // 부동산
      { name: '공인중개사', organization: '한국산업인력공단', examType: 'national', popularity: 5, difficulty: 4 },
      { name: '감정평가사', organization: '한국산업인력공단', examType: 'national', difficulty: 5 },
      { name: '주택관리사', organization: '한국산업인력공단', examType: 'national', difficulty: 3 },

      // 지적재산
      { name: '지식재산능력시험(IPAT)', organization: '한국발명진흥회', examType: 'private' },
      { name: '특허정보검색사', organization: '한국특허정보원', examType: 'private' },
    ]
  },

  {
    id: 'service-tourism',
    name: '서비스/관광/레저',
    description: '관광, 호텔, 조리, 미용, 패션 관련 자격증',
    color: 'bg-orange-100',
    subcategories: ['관광/호텔', '조리', '미용/패션', '레저/스포츠'],
    certifications: [
      // 관광/호텔
      { name: '관광통역안내사', organization: '한국산업인력공단', examType: 'national', difficulty: 4 },
      { name: '국내여행안내사', organization: '한국산업인력공단', examType: 'national' },
      { name: '호텔경영사', organization: '한국산업인력공단', examType: 'national' },
      { name: '호텔관리사', organization: '한국산업인력공단', examType: 'national' },
      { name: '호텔서비스사', organization: '한국산업인력공단', examType: 'national' },
      { name: '컨벤션기획사', levels: ['1급', '2급'], organization: '한국산업인력공단', examType: 'national' },

      // 조리
      { name: '조리산업기사', levels: ['한식', '양식', '중식', '일식'], organization: '한국산업인력공단', examType: 'national' },
      { name: '조리기능사', levels: ['한식', '양식', '중식', '일식', '복어'], organization: '한국산업인력공단', examType: 'national', popularity: 4 },
      { name: '제과기능사', organization: '한국산업인력공단', examType: 'national', popularity: 4 },
      { name: '제빵기능사', organization: '한국산업인력공단', examType: 'national', popularity: 4 },
      { name: '바리스타', levels: ['1급', '2급'], organization: '한국커피협회', examType: 'private', popularity: 4 },
      { name: '소믈리에', organization: '한국소믈리에협회', examType: 'private' },
      { name: '티소믈리에', organization: '한국티소믈리에협회', examType: 'private' },

      // 미용/패션
      { name: '미용사', levels: ['일반', '피부', '네일', '메이크업'], organization: '한국산업인력공단', examType: 'national', popularity: 4 },
      { name: '이용사', organization: '한국산업인력공단', examType: 'national' },
      { name: '컬러리스트기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '패션디자인산업기사', organization: '한국산업인력공단', examType: 'national' },
      { name: '패션머천다이징산업기사', organization: '한국산업인력공단', examType: 'national' },
      { name: '양장기능사', organization: '한국산업인력공단', examType: 'national' },
      { name: '한복기능사', organization: '한국산업인력공단', examType: 'national' },

      // 레저/스포츠
      { name: '스쿠버다이빙', levels: ['오픈워터', '어드밴스드', '레스큐', '다이브마스터'], organization: 'PADI/SSI', examType: 'international' },
      { name: '요가지도자', levels: ['1급', '2급', '3급'], organization: '한국요가협회', examType: 'private' },
      { name: '필라테스지도자', organization: '한국필라테스협회', examType: 'private' },
    ]
  },

  {
    id: 'safety-security',
    name: '안전/보안/소방',
    description: '산업안전, 소방, 경비, 재난관리 관련 자격증',
    color: 'bg-slate-100',
    subcategories: ['산업안전', '소방', '경비/보안', '재난관리'],
    certifications: [
      // 산업안전
      { name: '산업안전기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national', popularity: 5, difficulty: 3 },
      { name: '산업위생관리기사', levels: ['기사', '산업기사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '가스기사', levels: ['기사', '산업기사', '기능사'], organization: '한국산업인력공단', examType: 'national' },
      { name: '인간공학기사', levels: ['기사', '기술사'], organization: '한국산업인력공단', examType: 'national' },

      // 소방
      { name: '소방설비기사', levels: ['기계', '전기'], organization: '한국산업인력공단', examType: 'national', popularity: 4 },
      { name: '소방설비산업기사', levels: ['기계', '전기'], organization: '한국산업인력공단', examType: 'national' },
      { name: '소방안전관리자', levels: ['1급', '2급', '3급'], organization: '한국소방안전원', examType: 'national' },
      { name: '위험물안전관리자', organization: '한국소방안전원', examType: 'national' },

      // 경비/보안
      { name: '경비지도사', organization: '한국산업인력공단', examType: 'national', difficulty: 4 },
      { name: '신변보호사', organization: '한국경비협회', examType: 'private' },
      { name: '기계경비지도사', organization: '한국산업인력공단', examType: 'national' },

      // 재난관리
      { name: '재난안전관리사', organization: '행정안전부', examType: 'national' },
      { name: '응급구조사', levels: ['1급', '2급'], organization: '한국보건의료인국가시험원', examType: 'national' },
    ]
  },

  {
    id: 'transportation',
    name: '운송/물류/해양',
    description: '육상, 해상, 항공 운송 및 물류 관련 자격증',
    color: 'bg-teal-100',
    subcategories: ['육상운송', '해운/항만', '항공', '물류/유통', '철도'],
    certifications: [
      // 육상운송
      { name: '화물운송종사자격', organization: '한국교통안전공단', examType: 'national' },
      { name: '버스운전자격', organization: '한국교통안전공단', examType: 'national' },
      { name: '택시운전자격', organization: '한국교통안전공단', examType: 'national' },
      { name: '자동차운전기능검정원', organization: '도로교통공단', examType: 'national' },

      // 해운/항만
      { name: '해기사', levels: ['1급', '2급', '3급', '4급', '5급', '6급'], organization: '한국해양수산연수원', examType: 'national' },
      { name: '수상구조사', organization: '해양경찰청', examType: 'national' },
      { name: '잠수기능사', organization: '한국산업인력공단', examType: 'national' },
      { name: '항만물류전문인력', organization: '한국항만연수원', examType: 'private' },

      // 항공
      { name: '항공정비사', organization: '국토교통부', examType: 'national' },
      { name: '항공교통관제사', organization: '국토교통부', examType: 'national' },
      { name: '운항관리사', organization: '국토교통부', examType: 'national' },
      { name: '항공기관사', organization: '국토교통부', examType: 'national' },

      // 물류/유통
      { name: '물류관리사', organization: '한국산업인력공단', examType: 'national', difficulty: 4, popularity: 4 },
      { name: '유통관리사', levels: ['1급', '2급', '3급'], organization: '대한상공회의소', examType: 'private', popularity: 4 },
      { name: '보관하역관리사', organization: '한국산업인력공단', examType: 'national' },

      // 철도
      { name: '철도차량운전면허', levels: ['1종', '2종', '3종'], organization: '국토교통부', examType: 'national' },
      { name: '철도신호기사', organization: '한국산업인력공단', examType: 'national' },
      { name: '철도차량기사', organization: '한국산업인력공단', examType: 'national' },
    ]
  }
];

// 인기 자격증 TOP 30
export const popularCertifications = [
  '토익(TOEIC)',
  '컴퓨터활용능력',
  '한국사능력검정',
  '운전면허',
  '워드프로세서',
  '정보처리기사',
  '공인중개사',
  '사회복지사',
  '요양보호사',
  '전기기사',
  '조리기능사',
  '위험물산업기사',
  '산업안전기사',
  '간호조무사',
  'ITQ',
  '미용사',
  '토플(TOEFL)',
  'HSK',
  'JLPT',
  '유통관리사',
  '물류관리사',
  '무역영어',
  '제과제빵기능사',
  '바리스타',
  'SQLD',
  '빅데이터분석기사',
  '정보보안기사',
  '건축기사',
  '토목기사',
  '소방설비기사'
];

// 난이도별 분류
export const certificationsByDifficulty = {
  beginner: [ // 난이도 1-2
    'ITQ',
    '워드프로세서',
    '컴퓨터활용능력 2급',
    '한국사능력검정 기본',
    '조리기능사',
    '미용사',
    '바리스타 2급',
    '요양보호사',
  ],
  intermediate: [ // 난이도 3
    '정보처리기사',
    '전기기사',
    '산업안전기사',
    '사회복지사 1급',
    'ADsP',
    'SQLD',
    '유통관리사 2급',
    '컴퓨터활용능력 1급'
  ],
  advanced: [ // 난이도 4
    '공인중개사',
    '정보보안기사',
    '빅데이터분석기사',
    'ADP',
    '물류관리사',
    '관광통역안내사',
    '손해평가사',
    '임상심리사'
  ],
  expert: [ // 난이도 5
    '공인회계사(CPA)',
    '세무사',
    '변호사',
    '변리사',
    '법무사',
    '감정평가사',
    'CFA',
    'SQLP',
    '기술사',
    '건축사'
  ]
};

// 취업/진로별 추천 자격증
export const certificationsByCareer = {
  'IT개발자': ['정보처리기사', 'SQLD', 'AWS 자격증', '정보보안기사', '빅데이터분석기사'],
  '공무원': ['컴퓨터활용능력', '워드프로세서', '한국사능력검정', '토익', 'ITQ'],
  '금융권': ['투자자산운용사', 'CFP', 'AFPK', '신용분석사', '여신심사역'],
  '회계/세무': ['공인회계사', '세무사', '전산회계', '전산세무', 'FAT/TAT'],
  '부동산': ['공인중개사', '감정평가사', '주택관리사'],
  '의료/보건': ['간호조무사', '요양보호사', '병원코디네이터', '의료관광코디네이터'],
  '사회복지': ['사회복지사', '청소년지도사', '청소년상담사', '건강가정사'],
  '교육': ['평생교육사', '방과후지도사', '한국어교육능력검정'],
  '무역/물류': ['국제무역사', '무역영어', '물류관리사', '원산지관리사'],
  '관광/호텔': ['관광통역안내사', '호텔경영사', '컨벤션기획사'],
  '조리/제과': ['조리기능사', '제과기능사', '제빵기능사', '바리스타'],
  '미용/패션': ['미용사', '컬러리스트', '패션디자인산업기사'],
  '건설/건축': ['건축기사', '토목기사', '건설안전기사', '조경기사'],
  '전기/기계': ['전기기사', '일반기계기사', '공조냉동기계기사'],
  '환경/안전': ['환경기사', '산업안전기사', '소방설비기사', '위험물산업기사']
};