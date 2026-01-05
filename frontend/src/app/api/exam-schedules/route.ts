import { NextRequest, NextResponse } from 'next/server';

// 공공데이터포털 API를 통한 실제 시험일정 데이터 조회
export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const requestYear = searchParams.get('year');
  const category = searchParams.get('category') || 'all';

  const API_KEY = process.env.NEXT_PUBLIC_DATA_GO_KR_API_KEY;

  if (!API_KEY) {
    console.warn('공공데이터포털 API 키가 설정되지 않아 샘플 데이터를 반환합니다.');
    const currentYear = new Date().getFullYear();
    const years = requestYear
      ? [requestYear]
      : [currentYear - 1, currentYear, currentYear + 1, currentYear + 2].map(y => y.toString());

    const sampleData = years.flatMap(y => getSampleData(y));

    return NextResponse.json({
      success: true,
      data: sampleData,
      count: sampleData.length,
      isSample: true
    });
  }

  try {
    // 요청된 연도가 있으면 해당 연도만, 없으면 현재 연도 기준 -1년 ~ +2년
    const currentYear = new Date().getFullYear();
    const years = requestYear
      ? [requestYear]
      : [currentYear - 1, currentYear, currentYear + 1, currentYear + 2].map(y => y.toString());

    const allYearData = await Promise.all(
      years.map(async (year) => {
        const [qnetData, dataqData, socialData, otherData] = await Promise.all([
          fetchQNetData(API_KEY, year),
          fetchDataQData(year),
          fetchSocialWorkerData(year),
          fetchOtherCertData(year)
        ]);
        return [...qnetData, ...dataqData, ...socialData, ...otherData];
      })
    );

    // 모든 연도 데이터 통합
    const allSchedules = allYearData.flat();

    // 카테고리 필터링
    const filteredSchedules = category === 'all'
      ? allSchedules
      : allSchedules.filter(exam => exam.category === category);

    // 날짜순 정렬
    filteredSchedules.sort((a, b) =>
      new Date(a.examDate).getTime() - new Date(b.examDate).getTime()
    );

    return NextResponse.json({
      success: true,
      data: filteredSchedules,
      count: filteredSchedules.length
    });

  } catch (error) {
    console.error('API 호출 실패:', error);

    // 에러 발생시 샘플 데이터 반환
    const fallbackYear = requestYear || new Date().getFullYear().toString();
    const sampleData = getSampleData(fallbackYear);

    return NextResponse.json({
      success: true,
      data: sampleData,
      count: sampleData.length,
      message: 'API 호출 실패로 샘플 데이터를 반환합니다.'
    });
  }
}

// 1. 한국산업인력공단 (큐넷) API - 국가기술자격
async function fetchQNetData(apiKey: string, year: string) {
  const baseUrl = 'http://apis.data.go.kr/B490007/qualExamSchd/getQualExamSchdList';

  // 주요 기술자격증 목록 (확장됨)
  const examList = [
    // IT/컴퓨터
    { jmcd: '1320', name: '정보처리기사', category: 'IT' },
    { jmcd: '1321', name: '정보처리산업기사', category: 'IT' },
    { jmcd: '2290', name: '정보보안기사', category: 'IT' },
    { jmcd: '2291', name: '정보보안산업기사', category: 'IT' },
    { jmcd: '1220', name: '전자계산기조직응용기사', category: 'IT' },
    { jmcd: '1860', name: '컴퓨터활용능력1급', category: 'IT' },
    { jmcd: '1861', name: '컴퓨터활용능력2급', category: 'IT' },
    { jmcd: '1380', name: '사무자동화산업기사', category: 'IT' },
    { jmcd: '2840', name: '빅데이터분석기사', category: '데이터분석' },
    { jmcd: '7910', name: '네트워크관리사1급', category: 'IT' },
    { jmcd: '7920', name: '네트워크관리사2급', category: 'IT' },

    // 전기/전자
    { jmcd: '1610', name: '전기기사', category: '전기' },
    { jmcd: '1611', name: '전기산업기사', category: '전기' },
    { jmcd: '1620', name: '전기공사기사', category: '전기' },
    { jmcd: '1630', name: '전자기사', category: '전자' },
    { jmcd: '1631', name: '전자산업기사', category: '전자' },

    // 건축/토목
    { jmcd: '1340', name: '건축기사', category: '건축' },
    { jmcd: '1341', name: '건축산업기사', category: '건축' },
    { jmcd: '1350', name: '토목기사', category: '토목' },
    { jmcd: '1351', name: '토목산업기사', category: '토목' },
    { jmcd: '1360', name: '조경기사', category: '건축' },

    // 기계
    { jmcd: '1420', name: '일반기계기사', category: '기계' },
    { jmcd: '1430', name: '기계설계기사', category: '기계' },
    { jmcd: '1440', name: '메카트로닉스기사', category: '기계' },

    // 화학/환경
    { jmcd: '1520', name: '화공기사', category: '화학' },
    { jmcd: '1530', name: '위험물산업기사', category: '화학' },
    { jmcd: '1540', name: '환경기사', category: '환경' },
    { jmcd: '1541', name: '대기환경기사', category: '환경' },
    { jmcd: '1542', name: '수질환경기사', category: '환경' },
    { jmcd: '1543', name: '폐기물처리기사', category: '환경' },

    // 산업안전
    { jmcd: '1810', name: '산업안전기사', category: '안전' },
    { jmcd: '1811', name: '산업안전산업기사', category: '안전' },
    { jmcd: '1820', name: '산업위생관리기사', category: '안전' },
    { jmcd: '1830', name: '소방설비기사(기계)', category: '안전' },
    { jmcd: '1831', name: '소방설비기사(전기)', category: '안전' },

    // 경영/사무
    { jmcd: '2130', name: '물류관리사', category: '경영' },
    { jmcd: '2140', name: '유통관리사1급', category: '경영' },
    { jmcd: '2141', name: '유통관리사2급', category: '경영' },
    { jmcd: '2150', name: '품질경영기사', category: '경영' },
    { jmcd: '2160', name: '경영지도사', category: '경영' }
  ];

  const schedules: any[] = [];

  // 각 자격증별로 데이터 조회 (병렬 처리)
  const promises = examList.map(async (exam) => {
    try {
      const params = new URLSearchParams({
        serviceKey: apiKey,
        numOfRows: '10',
        pageNo: '1',
        dataFormat: 'json',
        implYy: year,
        qualgbCd: 'T', // 국가기술자격
        jmCd: exam.jmcd
      });

      const response = await fetch(`${baseUrl}?${params}`, {
        headers: {
          'Accept': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        const items = data?.response?.body?.items?.item;

        if (items) {
          const itemArray = Array.isArray(items) ? items : [items];
          return itemArray.map((item: any) => ({
            ...item,
            examName: exam.name,
            category: exam.category
          }));
        }
      }
    } catch (error) {
      console.error(`${exam.name} 데이터 조회 실패:`, error);
    }
    return [];
  });

  const results = await Promise.all(promises);
  return results.flat();
}

// 2. 한국데이터산업진흥원 - 데이터 자격증
async function fetchDataQData(year: string) {
  // 실제 데이터 (2024-2026년)
  const examSchedules = [
    // SQLD
    { year: 2024, round: 48, name: 'SQLD', date: '2024-03-02', reg: ['2024-02-05', '2024-02-08'] },
    { year: 2024, round: 49, name: 'SQLD', date: '2024-05-25', reg: ['2024-04-29', '2024-05-02'] },
    { year: 2024, round: 50, name: 'SQLD', date: '2024-09-07', reg: ['2024-08-12', '2024-08-15'] },
    { year: 2024, round: 51, name: 'SQLD', date: '2024-11-30', reg: ['2024-11-04', '2024-11-07'] },
    { year: 2025, round: 52, name: 'SQLD', date: '2025-03-08', reg: ['2025-02-10', '2025-02-13'] },
    { year: 2025, round: 53, name: 'SQLD', date: '2025-06-14', reg: ['2025-05-19', '2025-05-22'] },
    { year: 2025, round: 54, name: 'SQLD', date: '2025-09-13', reg: ['2025-08-18', '2025-08-21'] },
    { year: 2025, round: 55, name: 'SQLD', date: '2025-12-06', reg: ['2025-11-10', '2025-11-13'] },
    { year: 2026, round: 56, name: 'SQLD', date: '2026-03-14', reg: ['2026-02-16', '2026-02-19'] },
    { year: 2026, round: 57, name: 'SQLD', date: '2026-06-13', reg: ['2026-05-18', '2026-05-21'] },

    // SQLP
    { year: 2024, round: 33, name: 'SQLP', date: '2024-04-06', reg: ['2024-03-11', '2024-03-14'] },
    { year: 2024, round: 34, name: 'SQLP', date: '2024-10-05', reg: ['2024-09-09', '2024-09-12'] },
    { year: 2025, round: 35, name: 'SQLP', date: '2025-04-05', reg: ['2025-03-10', '2025-03-13'] },
    { year: 2025, round: 36, name: 'SQLP', date: '2025-10-04', reg: ['2025-09-08', '2025-09-11'] },

    // ADsP
    { year: 2024, round: 42, name: 'ADsP', date: '2024-03-16', reg: ['2024-02-19', '2024-02-22'] },
    { year: 2024, round: 43, name: 'ADsP', date: '2024-06-15', reg: ['2024-05-20', '2024-05-23'] },
    { year: 2024, round: 44, name: 'ADsP', date: '2024-10-12', reg: ['2024-09-16', '2024-09-19'] },
    { year: 2025, round: 45, name: 'ADsP', date: '2025-03-15', reg: ['2025-02-17', '2025-02-20'] },
    { year: 2025, round: 46, name: 'ADsP', date: '2025-06-21', reg: ['2025-05-26', '2025-05-29'] },
    { year: 2025, round: 47, name: 'ADsP', date: '2025-10-18', reg: ['2025-09-22', '2025-09-25'] },

    // ADP
    { year: 2024, round: 26, name: 'ADP', date: '2024-04-20', reg: ['2024-03-25', '2024-03-28'] },
    { year: 2024, round: 27, name: 'ADP', date: '2024-10-19', reg: ['2024-09-23', '2024-09-26'] },
    { year: 2025, round: 28, name: 'ADP', date: '2025-04-19', reg: ['2025-03-24', '2025-03-27'] },
    { year: 2025, round: 29, name: 'ADP', date: '2025-10-25', reg: ['2025-09-29', '2025-10-02'] },

    // DAP
    { year: 2024, round: 3, name: 'DAP', date: '2024-06-08', reg: ['2024-05-13', '2024-05-16'] },
    { year: 2024, round: 4, name: 'DAP', date: '2024-11-16', reg: ['2024-10-21', '2024-10-24'] },
    { year: 2025, round: 5, name: 'DAP', date: '2025-06-07', reg: ['2025-05-12', '2025-05-15'] },
    { year: 2025, round: 6, name: 'DAP', date: '2025-11-15', reg: ['2025-10-20', '2025-10-23'] }
  ];

  return examSchedules
    .filter(exam => exam.year.toString() === year)
    .map(exam => ({
      id: `dataq-${exam.name.toLowerCase()}-${exam.year}-${exam.round}`,
      examName: `${exam.name} ${exam.round}회`,
      examType: 'written',
      category: '데이터분석',
      organization: '한국데이터산업진흥원',
      examDate: exam.date,
      registrationStartDate: exam.reg[0],
      registrationEndDate: exam.reg[1],
      resultDate: new Date(new Date(exam.date).getTime() + 30 * 24 * 60 * 60 * 1000).toISOString(),
      location: '전국 지정 시험장',
      fee: exam.name === 'SQLP' || exam.name === 'ADP' ? 150000 : exam.name === 'DAP' ? 200000 : 100000,
      status: getExamStatus(new Date(exam.date), new Date(exam.reg[0]), new Date(exam.reg[1])),
      detailUrl: 'https://www.dataq.or.kr',
      applicationUrl: 'https://www.dataq.or.kr'
    }));
}

// 3. 한국사회복지사협회 - 사회복지사
async function fetchSocialWorkerData(year: string) {
  const examSchedules = [
    { year: 2024, round: 22, date: '2024-02-03', reg: ['2023-12-04', '2023-12-08'] },
    { year: 2025, round: 23, date: '2025-02-08', reg: ['2024-12-09', '2024-12-13'] },
    { year: 2026, round: 24, date: '2026-01-17', reg: ['2025-12-01', '2025-12-05'] }
  ];

  return examSchedules
    .filter(exam => exam.year.toString() === year)
    .map(exam => ({
      id: `kasw-${exam.year}-${exam.round}`,
      examName: `사회복지사 1급 ${exam.round}회`,
      examType: 'written',
      category: '사회복지',
      organization: '한국사회복지사협회',
      examDate: exam.date,
      registrationStartDate: exam.reg[0],
      registrationEndDate: exam.reg[1],
      resultDate: new Date(new Date(exam.date).getTime() + 45 * 24 * 60 * 60 * 1000).toISOString(),
      location: '전국 동시 시행',
      fee: 65000,
      status: getExamStatus(new Date(exam.date), new Date(exam.reg[0]), new Date(exam.reg[1])),
      detailUrl: 'https://www.welfare.net',
      applicationUrl: 'https://lic.welfare.net'
    }));
}

// 4. 기타 주요 자격증
async function fetchOtherCertData(year: string) {
  const otherExams = [
    // 한국금융연수원 - 금융자격증
    { name: 'CFP', round: '1회', date: '2024-05-18', reg: ['2024-04-01', '2024-04-10'], category: '금융', org: '한국금융연수원' },
    { name: 'CFP', round: '2회', date: '2024-11-16', reg: ['2024-10-01', '2024-10-10'], category: '금융', org: '한국금융연수원' },
    { name: 'AFPK', round: '1회', date: '2024-03-23', reg: ['2024-02-05', '2024-02-14'], category: '금융', org: '한국금융연수원' },
    { name: 'AFPK', round: '2회', date: '2024-06-22', reg: ['2024-05-06', '2024-05-15'], category: '금융', org: '한국금융연수원' },
    { name: 'AFPK', round: '3회', date: '2024-09-28', reg: ['2024-08-05', '2024-08-14'], category: '금융', org: '한국금융연수원' },
    { name: 'AFPK', round: '4회', date: '2024-12-14', reg: ['2024-11-04', '2024-11-13'], category: '금융', org: '한국금융연수원' },

    // 매경TEST
    { name: '매경TEST', round: '87회', date: '2024-02-24', reg: ['2024-01-29', '2024-02-13'], category: '경제', org: '매일경제' },
    { name: '매경TEST', round: '88회', date: '2024-05-11', reg: ['2024-04-15', '2024-04-30'], category: '경제', org: '매일경제' },
    { name: '매경TEST', round: '89회', date: '2024-08-03', reg: ['2024-07-08', '2024-07-23'], category: '경제', org: '매일경제' },
    { name: '매경TEST', round: '90회', date: '2024-10-26', reg: ['2024-09-30', '2024-10-15'], category: '경제', org: '매일경제' },

    // TESAT
    { name: 'TESAT', round: '91회', date: '2024-02-17', reg: ['2024-01-22', '2024-02-05'], category: '경제', org: '한국경제' },
    { name: 'TESAT', round: '92회', date: '2024-05-18', reg: ['2024-04-22', '2024-05-06'], category: '경제', org: '한국경제' },
    { name: 'TESAT', round: '93회', date: '2024-08-24', reg: ['2024-07-29', '2024-08-12'], category: '경제', org: '한국경제' },
    { name: 'TESAT', round: '94회', date: '2024-11-23', reg: ['2024-10-28', '2024-11-11'], category: '경제', org: '한국경제' },

    // 한국사능력검정
    { name: '한국사능력검정', round: '68회', date: '2024-02-10', reg: ['2024-01-15', '2024-01-19'], category: '역사', org: '국사편찬위원회' },
    { name: '한국사능력검정', round: '69회', date: '2024-04-13', reg: ['2024-03-18', '2024-03-22'], category: '역사', org: '국사편찬위원회' },
    { name: '한국사능력검정', round: '70회', date: '2024-06-08', reg: ['2024-05-13', '2024-05-17'], category: '역사', org: '국사편찬위원회' },
    { name: '한국사능력검정', round: '71회', date: '2024-08-10', reg: ['2024-07-15', '2024-07-19'], category: '역사', org: '국사편찬위원회' },
    { name: '한국사능력검정', round: '72회', date: '2024-10-26', reg: ['2024-09-30', '2024-10-04'], category: '역사', org: '국사편찬위원회' },

    // 공인중개사
    { name: '공인중개사', round: '34회', date: '2024-10-26', reg: ['2024-08-05', '2024-08-09'], category: '부동산', org: '한국산업인력공단' },
    { name: '공인중개사', round: '35회', date: '2025-10-25', reg: ['2025-08-04', '2025-08-08'], category: '부동산', org: '한국산업인력공단' },

    // 세무사
    { name: '세무사 1차', round: '61회', date: '2024-04-27', reg: ['2024-03-11', '2024-03-15'], category: '세무회계', org: '한국산업인력공단' },
    { name: '세무사 2차', round: '61회', date: '2024-07-27', reg: ['2024-06-10', '2024-06-14'], category: '세무회계', org: '한국산업인력공단' },
    { name: '세무사 1차', round: '62회', date: '2025-04-26', reg: ['2025-03-10', '2025-03-14'], category: '세무회계', org: '한국산업인력공단' },
    { name: '세무사 2차', round: '62회', date: '2025-07-26', reg: ['2025-06-09', '2025-06-13'], category: '세무회계', org: '한국산업인력공단' },

    // 공인회계사
    { name: '공인회계사 1차', round: '59회', date: '2024-03-02', reg: ['2024-01-15', '2024-01-19'], category: '세무회계', org: '금융감독원' },
    { name: '공인회계사 2차', round: '59회', date: '2024-06-28', reg: ['2024-05-13', '2024-05-17'], category: '세무회계', org: '금융감독원' },
    { name: '공인회계사 1차', round: '60회', date: '2025-03-01', reg: ['2025-01-13', '2025-01-17'], category: '세무회계', org: '금융감독원' },
    { name: '공인회계사 2차', round: '60회', date: '2025-06-27', reg: ['2025-05-12', '2025-05-16'], category: '세무회계', org: '금융감독원' },

    // 행정사
    { name: '행정사 1차', round: '34회', date: '2024-05-25', reg: ['2024-04-08', '2024-04-12'], category: '행정', org: '한국산업인력공단' },
    { name: '행정사 2차', round: '34회', date: '2024-09-28', reg: ['2024-08-12', '2024-08-16'], category: '행정', org: '한국산업인력공단' },
    { name: '행정사 1차', round: '35회', date: '2025-05-24', reg: ['2025-04-07', '2025-04-11'], category: '행정', org: '한국산업인력공단' },
    { name: '행정사 2차', round: '35회', date: '2025-09-27', reg: ['2025-08-11', '2025-08-15'], category: '행정', org: '한국산업인력공단' },

    // 손해평가사
    { name: '손해평가사 1차', round: '10회', date: '2024-05-11', reg: ['2024-03-25', '2024-03-29'], category: '보험', org: '한국산업인력공단' },
    { name: '손해평가사 2차', round: '10회', date: '2024-09-07', reg: ['2024-07-22', '2024-07-26'], category: '보험', org: '한국산업인력공단' },
    { name: '손해평가사 1차', round: '11회', date: '2025-05-10', reg: ['2025-03-24', '2025-03-28'], category: '보험', org: '한국산업인력공단' },
    { name: '손해평가사 2차', round: '11회', date: '2025-09-06', reg: ['2025-07-21', '2025-07-25'], category: '보험', org: '한국산업인력공단' }
  ];

  return otherExams
    .filter(exam => {
      const examYear = new Date(exam.date).getFullYear().toString();
      return examYear === year;
    })
    .map(exam => ({
      id: `other-${exam.name.replace(/\s+/g, '-')}-${exam.round}`,
      examName: `${exam.name} ${exam.round}`,
      examType: exam.name.includes('2차') ? 'practical' : 'written',
      category: exam.category,
      organization: exam.org,
      examDate: exam.date,
      registrationStartDate: exam.reg[0],
      registrationEndDate: exam.reg[1],
      resultDate: new Date(new Date(exam.date).getTime() + 30 * 24 * 60 * 60 * 1000).toISOString(),
      location: '전국 지정 시험장',
      fee: getFeeByExam(exam.name),
      status: getExamStatus(new Date(exam.date), new Date(exam.reg[0]), new Date(exam.reg[1])),
      detailUrl: getDetailUrlByOrg(exam.org),
      applicationUrl: getDetailUrlByOrg(exam.org)
    }));
}

function getFeeByExam(examName: string): number {
  const fees: { [key: string]: number } = {
    'CFP': 300000,
    'AFPK': 150000,
    '매경TEST': 30000,
    'TESAT': 33000,
    '한국사능력검정': 22000,
    '공인중개사': 30500,
    '세무사 1차': 30000,
    '세무사 2차': 35000,
    '공인회계사 1차': 35000,
    '공인회계사 2차': 40000,
    '행정사 1차': 20000,
    '행정사 2차': 25000,
    '손해평가사 1차': 25000,
    '손해평가사 2차': 30000
  };

  for (const [key, value] of Object.entries(fees)) {
    if (examName.includes(key)) {
      return value;
    }
  }
  return 50000; // 기본값
}

function getDetailUrlByOrg(org: string): string {
  const urls: { [key: string]: string } = {
    '한국산업인력공단': 'https://www.q-net.or.kr',
    '한국금융연수원': 'https://www.kbi.or.kr',
    '매일경제': 'https://www.mk.co.kr/mkt',
    '한국경제': 'https://www.tesat.or.kr',
    '국사편찬위원회': 'http://www.historyexam.go.kr',
    '금융감독원': 'https://www.fss.or.kr'
  };

  return urls[org] || 'https://www.q-net.or.kr';
}

function getExamStatus(
  examDate: Date,
  regStartDate: Date,
  regEndDate: Date
): 'upcoming' | 'registration-open' | 'registration-closed' | 'completed' {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  if (examDate < today) return 'completed';
  if (today >= regStartDate && today <= regEndDate) return 'registration-open';
  if (today > regEndDate && examDate > today) return 'registration-closed';

  return 'upcoming';
}

// 샘플 데이터 (API 실패시 백업용)
function getSampleData(year: string) {
  return [
    {
      id: `sample-1-${year}`,
      examName: '정보처리기사 1회 필기',
      examType: 'written',
      category: 'IT',
      organization: '한국산업인력공단',
      examDate: `${year}-03-07`,
      registrationStartDate: `${year}-02-05`,
      registrationEndDate: `${year}-02-08`,
      resultDate: `${year}-03-21`,
      location: '전국 CBT 시험장',
      fee: 19400,
      status: 'upcoming',
      detailUrl: 'https://www.q-net.or.kr',
      applicationUrl: 'https://www.q-net.or.kr'
    }
  ];
}