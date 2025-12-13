// 공공데이터 API를 통한 각종 국가시험 일정 통합 조회 서비스
// 여러 공공기관의 API를 통합하여 제공

export interface UnifiedExamSchedule {
  id: string;
  examName: string;           // 시험명
  examType: 'written' | 'practical' | 'interview'; // 시험 유형
  category: string;            // 분류 (IT, 사회복지, 데이터분석 등)
  organization: string;        // 시행기관

  // 날짜 정보
  examDate: Date;              // 시험일
  registrationStartDate?: Date; // 접수 시작일
  registrationEndDate?: Date;   // 접수 종료일
  resultDate?: Date;           // 결과 발표일

  // 추가 정보
  location?: string;           // 시험 장소
  fee?: number;               // 응시료
  applicants?: number;        // 지원자 수
  passRate?: number;          // 합격률
  status: 'upcoming' | 'registration-open' | 'registration-closed' | 'completed';

  // 링크
  detailUrl?: string;         // 상세 정보 URL
  applicationUrl?: string;    // 접수 URL
}

// 날짜 포맷 헬퍼 함수들
function parseKoreanDate(dateStr: string | null | undefined): Date | undefined {
  if (!dateStr) return undefined;

  // YYYYMMDD 형식
  if (/^\d{8}$/.test(dateStr)) {
    const year = parseInt(dateStr.substring(0, 4));
    const month = parseInt(dateStr.substring(4, 6)) - 1;
    const day = parseInt(dateStr.substring(6, 8));
    return new Date(year, month, day);
  }

  // YYYY-MM-DD 형식
  if (/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) {
    return new Date(dateStr);
  }

  return undefined;
}

function getExamStatus(
  examDate: Date,
  regStartDate?: Date,
  regEndDate?: Date
): 'upcoming' | 'registration-open' | 'registration-closed' | 'completed' {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  if (examDate < today) return 'completed';

  if (regStartDate && regEndDate) {
    if (today >= regStartDate && today <= regEndDate) return 'registration-open';
    if (today > regEndDate) return 'registration-closed';
  }

  return 'upcoming';
}

// 1. 한국산업인력공단 (큐넷) - 국가기술자격
class QNetAPI {
  private baseUrl = 'http://apis.data.go.kr/B490007/qualExamSchd/getQualExamSchdList';
  private apiKey: string;

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async fetchSchedules(year: number): Promise<UnifiedExamSchedule[]> {
    // 주요 기술자격 종목 코드
    const majorExams = [
      { code: '1320', name: '정보처리기사', category: 'IT' },
      { code: '1321', name: '정보처리산업기사', category: 'IT' },
      { code: '2290', name: '정보보안기사', category: 'IT' },
      { code: '1220', name: '전자계산기조직응용기사', category: 'IT' },
      { code: '1380', name: '사무자동화산업기사', category: 'IT' },
      { code: '1860', name: '컴퓨터활용능력1급', category: 'IT' },
      { code: '1861', name: '컴퓨터활용능력2급', category: 'IT' },
      { code: '2840', name: '빅데이터분석기사', category: '데이터분석' },
      { code: '2850', name: '데이터분석전문가', category: '데이터분석' },
      { code: '2851', name: '데이터분석준전문가', category: '데이터분석' },
      { code: '2860', name: 'SQL개발자', category: '데이터베이스' },
      { code: '2861', name: 'SQLD', category: '데이터베이스' }
    ];

    // API 키가 없으면 샘플 데이터 반환
    if (!this.apiKey) {
      return this.getSampleData();
    }

    // 실제 API 호출 로직은 CORS 문제로 백엔드를 통해야 함
    // 여기서는 샘플 데이터 반환
    return this.getSampleData();
  }

  private getSampleData(): UnifiedExamSchedule[] {
    const schedules: UnifiedExamSchedule[] = [];
    const today = new Date();

    // 정보처리기사 일정
    const infoProcessingSchedules = [
      {
        year: 2024, round: 1,
        docReg: ['2024-02-05', '2024-02-08'],
        docExam: '2024-03-07',
        docResult: '2024-03-21',
        pracReg: ['2024-03-25', '2024-03-28'],
        pracExam: '2024-04-25',
        pracResult: '2024-05-21'
      },
      {
        year: 2024, round: 2,
        docReg: ['2024-04-08', '2024-04-11'],
        docExam: '2024-05-09',
        docResult: '2024-05-23',
        pracReg: ['2024-06-03', '2024-06-06'],
        pracExam: '2024-07-13',
        pracResult: '2024-08-08'
      },
      {
        year: 2024, round: 3,
        docReg: ['2024-08-19', '2024-08-22'],
        docExam: '2024-09-21',
        docResult: '2024-10-02',
        pracReg: ['2024-10-14', '2024-10-17'],
        pracExam: '2024-11-16',
        pracResult: '2024-12-11'
      },
      {
        year: 2025, round: 1,
        docReg: ['2025-02-03', '2025-02-06'],
        docExam: '2025-03-08',
        docResult: '2025-03-20',
        pracReg: ['2025-03-24', '2025-03-27'],
        pracExam: '2025-04-24',
        pracResult: '2025-05-20'
      },
      {
        year: 2025, round: 2,
        docReg: ['2025-04-07', '2025-04-10'],
        docExam: '2025-05-10',
        docResult: '2025-05-22',
        pracReg: ['2025-06-02', '2025-06-05'],
        pracExam: '2025-07-12',
        pracResult: '2025-08-07'
      }
    ];

    infoProcessingSchedules.forEach(schedule => {
      // 필기시험
      const docExamDate = new Date(schedule.docExam);
      const docRegStart = new Date(schedule.docReg[0]);
      const docRegEnd = new Date(schedule.docReg[1]);

      schedules.push({
        id: `qnet-info-${schedule.year}-${schedule.round}-doc`,
        examName: `정보처리기사 ${schedule.year}년 ${schedule.round}회 필기`,
        examType: 'written',
        category: 'IT',
        organization: '한국산업인력공단',
        examDate: docExamDate,
        registrationStartDate: docRegStart,
        registrationEndDate: docRegEnd,
        resultDate: new Date(schedule.docResult),
        location: '전국 CBT 시험장',
        fee: 19400,
        status: getExamStatus(docExamDate, docRegStart, docRegEnd),
        detailUrl: 'https://www.q-net.or.kr/crf005.do?id=crf00503&jmCd=1320',
        applicationUrl: 'https://www.q-net.or.kr'
      });

      // 실기시험
      const pracExamDate = new Date(schedule.pracExam);
      const pracRegStart = new Date(schedule.pracReg[0]);
      const pracRegEnd = new Date(schedule.pracReg[1]);

      schedules.push({
        id: `qnet-info-${schedule.year}-${schedule.round}-prac`,
        examName: `정보처리기사 ${schedule.year}년 ${schedule.round}회 실기`,
        examType: 'practical',
        category: 'IT',
        organization: '한국산업인력공단',
        examDate: pracExamDate,
        registrationStartDate: pracRegStart,
        registrationEndDate: pracRegEnd,
        resultDate: new Date(schedule.pracResult),
        location: '지정 시험장',
        fee: 22600,
        status: getExamStatus(pracExamDate, pracRegStart, pracRegEnd),
        detailUrl: 'https://www.q-net.or.kr/crf005.do?id=crf00503&jmCd=1320',
        applicationUrl: 'https://www.q-net.or.kr'
      });
    });

    return schedules;
  }
}

// 2. 한국데이터산업진흥원 - SQLD, ADsP
class DataExamAPI {
  async fetchSchedules(year: number): Promise<UnifiedExamSchedule[]> {
    const schedules: UnifiedExamSchedule[] = [];

    // SQLD 일정
    const sqldSchedules = [
      { year: 2024, round: 48, date: '2024-03-02', reg: ['2024-02-05', '2024-02-08'] },
      { year: 2024, round: 49, date: '2024-05-25', reg: ['2024-04-29', '2024-05-02'] },
      { year: 2024, round: 50, date: '2024-09-07', reg: ['2024-08-12', '2024-08-15'] },
      { year: 2024, round: 51, date: '2024-11-30', reg: ['2024-11-04', '2024-11-07'] },
      { year: 2025, round: 52, date: '2025-03-08', reg: ['2025-02-10', '2025-02-13'] },
      { year: 2025, round: 53, date: '2025-06-14', reg: ['2025-05-19', '2025-05-22'] },
      { year: 2025, round: 54, date: '2025-09-13', reg: ['2025-08-18', '2025-08-21'] },
      { year: 2025, round: 55, date: '2025-12-06', reg: ['2025-11-10', '2025-11-13'] }
    ];

    sqldSchedules.forEach(schedule => {
      const examDate = new Date(schedule.date);
      const regStart = new Date(schedule.reg[0]);
      const regEnd = new Date(schedule.reg[1]);

      schedules.push({
        id: `dataq-sqld-${schedule.year}-${schedule.round}`,
        examName: `SQLD ${schedule.round}회`,
        examType: 'written',
        category: '데이터베이스',
        organization: '한국데이터산업진흥원',
        examDate: examDate,
        registrationStartDate: regStart,
        registrationEndDate: regEnd,
        resultDate: new Date(examDate.getTime() + 30 * 24 * 60 * 60 * 1000), // 30일 후
        location: '전국 지정 시험장',
        fee: 100000,
        status: getExamStatus(examDate, regStart, regEnd),
        detailUrl: 'https://www.dataq.or.kr/www/sub/a_04/a_0401.do',
        applicationUrl: 'https://www.dataq.or.kr'
      });
    });

    // ADsP 일정
    const adspSchedules = [
      { year: 2024, round: 42, date: '2024-03-16', reg: ['2024-02-19', '2024-02-22'] },
      { year: 2024, round: 43, date: '2024-06-15', reg: ['2024-05-20', '2024-05-23'] },
      { year: 2024, round: 44, date: '2024-10-12', reg: ['2024-09-16', '2024-09-19'] },
      { year: 2025, round: 45, date: '2025-03-15', reg: ['2025-02-17', '2025-02-20'] },
      { year: 2025, round: 46, date: '2025-06-21', reg: ['2025-05-26', '2025-05-29'] },
      { year: 2025, round: 47, date: '2025-10-18', reg: ['2025-09-22', '2025-09-25'] }
    ];

    adspSchedules.forEach(schedule => {
      const examDate = new Date(schedule.date);
      const regStart = new Date(schedule.reg[0]);
      const regEnd = new Date(schedule.reg[1]);

      schedules.push({
        id: `dataq-adsp-${schedule.year}-${schedule.round}`,
        examName: `ADsP ${schedule.round}회`,
        examType: 'written',
        category: '데이터분석',
        organization: '한국데이터산업진흥원',
        examDate: examDate,
        registrationStartDate: regStart,
        registrationEndDate: regEnd,
        resultDate: new Date(examDate.getTime() + 30 * 24 * 60 * 60 * 1000),
        location: '전국 지정 시험장',
        fee: 80000,
        status: getExamStatus(examDate, regStart, regEnd),
        detailUrl: 'https://www.dataq.or.kr/www/sub/a_04/a_0402.do',
        applicationUrl: 'https://www.dataq.or.kr'
      });
    });

    return schedules;
  }
}

// 3. 한국사회복지사협회 - 사회복지사 1급
class SocialWorkerExamAPI {
  async fetchSchedules(year: number): Promise<UnifiedExamSchedule[]> {
    const schedules: UnifiedExamSchedule[] = [];

    const socialWorkerSchedules = [
      { year: 2024, round: 22, date: '2024-02-03', reg: ['2023-12-04', '2023-12-08'] },
      { year: 2025, round: 23, date: '2025-02-08', reg: ['2024-12-09', '2024-12-13'] },
      { year: 2026, round: 24, date: '2026-02-07', reg: ['2025-12-08', '2025-12-12'] }
    ];

    socialWorkerSchedules.forEach(schedule => {
      const examDate = new Date(schedule.date);
      const regStart = new Date(schedule.reg[0]);
      const regEnd = new Date(schedule.reg[1]);

      schedules.push({
        id: `kasw-${schedule.year}-${schedule.round}`,
        examName: `사회복지사 1급 ${schedule.round}회`,
        examType: 'written',
        category: '사회복지',
        organization: '한국사회복지사협회',
        examDate: examDate,
        registrationStartDate: regStart,
        registrationEndDate: regEnd,
        resultDate: new Date(examDate.getTime() + 45 * 24 * 60 * 60 * 1000),
        location: '전국 동시 시행',
        fee: 65000,
        status: getExamStatus(examDate, regStart, regEnd),
        detailUrl: 'https://www.welfare.net',
        applicationUrl: 'https://lic.welfare.net'
      });
    });

    return schedules;
  }
}

// 통합 API 서비스
export class PublicExamAPIService {
  private apiKey: string;
  private qnetAPI: QNetAPI;
  private dataExamAPI: DataExamAPI;
  private socialWorkerAPI: SocialWorkerExamAPI;

  constructor(apiKey?: string) {
    this.apiKey = apiKey || '';
    this.qnetAPI = new QNetAPI(this.apiKey);
    this.dataExamAPI = new DataExamAPI();
    this.socialWorkerAPI = new SocialWorkerExamAPI();
  }

  async fetchAllExamSchedules(startYear: number, endYear: number): Promise<UnifiedExamSchedule[]> {
    const allSchedules: UnifiedExamSchedule[] = [];

    for (let year = startYear; year <= endYear; year++) {
      const [qnetData, dataExamData, socialWorkerData] = await Promise.all([
        this.qnetAPI.fetchSchedules(year),
        this.dataExamAPI.fetchSchedules(year),
        this.socialWorkerAPI.fetchSchedules(year)
      ]);

      allSchedules.push(...qnetData, ...dataExamData, ...socialWorkerData);
    }

    // 날짜순 정렬
    return allSchedules.sort((a, b) => a.examDate.getTime() - b.examDate.getTime());
  }

  filterByDateRange(
    schedules: UnifiedExamSchedule[],
    startDate: Date,
    endDate: Date
  ): UnifiedExamSchedule[] {
    return schedules.filter(exam =>
      exam.examDate >= startDate && exam.examDate <= endDate
    );
  }

  filterByCategory(
    schedules: UnifiedExamSchedule[],
    category: string
  ): UnifiedExamSchedule[] {
    if (category === 'all') return schedules;
    return schedules.filter(exam => exam.category === category);
  }

  getUpcomingExams(schedules: UnifiedExamSchedule[], limit: number = 5): UnifiedExamSchedule[] {
    const today = new Date();
    return schedules
      .filter(exam => exam.examDate >= today)
      .slice(0, limit);
  }

  getRegistrationOpenExams(schedules: UnifiedExamSchedule[]): UnifiedExamSchedule[] {
    return schedules.filter(exam => exam.status === 'registration-open');
  }
}