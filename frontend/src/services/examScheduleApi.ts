// 공공데이터포털 API를 통한 국가기술자격 시험일정 데이터 조회
// API 문서: https://www.data.go.kr/data/15077904/openapi.do

interface ExamScheduleAPIResponse {
  response: {
    header: {
      resultCode: string;
      resultMsg: string;
    };
    body: {
      items: {
        item: ExamScheduleItem[] | ExamScheduleItem;
      };
      numOfRows: number;
      pageNo: number;
      totalCount: number;
    };
  };
}

interface ExamScheduleItem {
  implYy: string;           // 시행년도
  implSeq: string;          // 시행회차
  qualgbCd: string;         // 자격구분코드
  qualgbNm: string;         // 자격구분명
  description: string;      // 설명
  docRegStartDt: string;    // 필기원서접수시작일자
  docRegEndDt: string;      // 필기원서접수종료일자
  docExamStartDt: string;   // 필기시험시작일자
  docExamEndDt: string;     // 필기시험종료일자
  docPassDt: string;        // 필기합격(예정)자발표일자
  pracRegStartDt: string;   // 실기원서접수시작일자
  pracRegEndDt: string;     // 실기원서접수종료일자
  pracExamStartDt: string;  // 실기시험시작일자
  pracExamEndDt: string;    // 실기시험종료일자
  pracPassDt: string;       // 최종합격자발표일자
}

// 큐넷 (한국산업인력공단) API
interface QNetExamSchedule {
  jmcd: string;             // 종목코드
  jmfldnm: string;          // 종목명
  qualgbnm: string;         // 자격구분명
  implYy: string;           // 시행년도
  implSeq: string;          // 시행회차
  docregstartdt: string;    // 필기접수시작일
  docregenddt: string;      // 필기접수종료일
  docexamstartdt: string;   // 필기시험시작일
  docexamenddt: string;     // 필기시험종료일
  docpassdt: string;        // 필기합격발표일
  pracregstartdt?: string;  // 실기접수시작일
  pracregenddt?: string;    // 실기접수종료일
  pracexamstartdt?: string; // 실기시험시작일
  pracexamenddt?: string;   // 실기시험종료일
  pracpassdt?: string;      // 최종합격발표일
}

// API 키는 환경변수에 저장
const API_KEY = process.env.NEXT_PUBLIC_DATA_GO_KR_API_KEY || '';
const QNET_API_URL = 'http://apis.data.go.kr/B490007/qualExamSchd/getQualExamSchdList';

// XML을 JSON으로 파싱하는 헬퍼 함수
async function parseXMLResponse(xmlText: string): Promise<any> {
  // 브라우저 환경에서 DOMParser 사용
  if (typeof window !== 'undefined') {
    const parser = new DOMParser();
    const xmlDoc = parser.parseFromString(xmlText, 'text/xml');

    const parseNode = (node: Element): any => {
      const obj: any = {};

      // 텍스트 노드만 있는 경우
      if (node.children.length === 0) {
        return node.textContent;
      }

      // 자식 노드들 파싱
      Array.from(node.children).forEach(child => {
        const tagName = child.tagName;
        const parsed = parseNode(child);

        if (obj[tagName]) {
          // 이미 같은 태그가 있으면 배열로 변환
          if (!Array.isArray(obj[tagName])) {
            obj[tagName] = [obj[tagName]];
          }
          obj[tagName].push(parsed);
        } else {
          obj[tagName] = parsed;
        }
      });

      return obj;
    };

    return parseNode(xmlDoc.documentElement);
  }

  // 서버 환경에서는 간단한 정규식 파싱
  const items: any[] = [];
  const itemMatches = xmlText.matchAll(/<item>(.*?)<\/item>/gs);

  for (const match of itemMatches) {
    const itemXml = match[1];
    const item: any = {};

    const fields = [
      'implYy', 'implSeq', 'qualgbCd', 'qualgbNm', 'description',
      'docRegStartDt', 'docRegEndDt', 'docExamStartDt', 'docExamEndDt', 'docPassDt',
      'pracRegStartDt', 'pracRegEndDt', 'pracExamStartDt', 'pracExamEndDt', 'pracPassDt'
    ];

    fields.forEach(field => {
      const regex = new RegExp(`<${field}>(.*?)<\/${field}>`, 's');
      const fieldMatch = itemXml.match(regex);
      if (fieldMatch) {
        item[field] = fieldMatch[1].trim();
      }
    });

    if (Object.keys(item).length > 0) {
      items.push(item);
    }
  }

  return { response: { body: { items: { item: items } } } };
}

export async function fetchExamSchedules(year?: number): Promise<ExamScheduleItem[]> {
  if (!API_KEY) {
    console.warn('공공데이터포털 API 키가 설정되지 않았습니다. 샘플 데이터를 사용합니다.');
    return getSampleExamSchedules();
  }

  try {
    const currentYear = year || new Date().getFullYear();
    const params = new URLSearchParams({
      serviceKey: API_KEY,
      numOfRows: '100',
      pageNo: '1',
      dataFormat: 'xml',
      implYy: currentYear.toString()
    });

    const response = await fetch(`${QNET_API_URL}?${params}`, {
      method: 'GET',
      headers: {
        'Accept': 'application/xml'
      }
    });

    if (!response.ok) {
      throw new Error(`API 호출 실패: ${response.status}`);
    }

    const xmlText = await response.text();
    const data = await parseXMLResponse(xmlText);

    const items = data?.response?.body?.items?.item;
    if (!items) {
      return [];
    }

    // 배열이 아닌 경우 배열로 변환
    const itemArray = Array.isArray(items) ? items : [items];

    return itemArray;
  } catch (error) {
    console.error('시험 일정 API 호출 실패:', error);
    return getSampleExamSchedules();
  }
}

// 여러 년도의 데이터를 한번에 가져오기
export async function fetchMultiYearExamSchedules(startYear: number, endYear: number): Promise<ExamScheduleItem[]> {
  const promises: Promise<ExamScheduleItem[]>[] = [];

  for (let year = startYear; year <= endYear; year++) {
    promises.push(fetchExamSchedules(year));
  }

  const results = await Promise.all(promises);
  return results.flat();
}

// 특정 자격증 시험 일정만 필터링
export function filterExamsByQualification(
  exams: ExamScheduleItem[],
  qualifications: string[]
): ExamScheduleItem[] {
  return exams.filter(exam =>
    qualifications.some(qual =>
      exam.description?.includes(qual) ||
      exam.qualgbNm?.includes(qual)
    )
  );
}

// 날짜 문자열을 Date 객체로 변환
export function parseExamDate(dateStr: string | undefined | null): Date | null {
  if (!dateStr || dateStr.length !== 8) return null;

  const year = parseInt(dateStr.substring(0, 4));
  const month = parseInt(dateStr.substring(4, 6)) - 1;
  const day = parseInt(dateStr.substring(6, 8));

  return new Date(year, month, day);
}

// 샘플 데이터 (API 키가 없을 때 사용)
function getSampleExamSchedules(): ExamScheduleItem[] {
  return [
    {
      implYy: '2024',
      implSeq: '1',
      qualgbCd: 'T',
      qualgbNm: '국가기술자격',
      description: '정보처리기사',
      docRegStartDt: '20240205',
      docRegEndDt: '20240208',
      docExamStartDt: '20240307',
      docExamEndDt: '20240307',
      docPassDt: '20240321',
      pracRegStartDt: '20240325',
      pracRegEndDt: '20240328',
      pracExamStartDt: '20240425',
      pracExamEndDt: '20240509',
      pracPassDt: '20240521'
    },
    {
      implYy: '2024',
      implSeq: '2',
      qualgbCd: 'T',
      qualgbNm: '국가기술자격',
      description: '정보처리기사',
      docRegStartDt: '20240408',
      docRegEndDt: '20240411',
      docExamStartDt: '20240509',
      docExamEndDt: '20240509',
      docPassDt: '20240523',
      pracRegStartDt: '20240603',
      pracRegEndDt: '20240606',
      pracExamStartDt: '20240713',
      pracExamEndDt: '20240727',
      pracPassDt: '20240808'
    },
    {
      implYy: '2024',
      implSeq: '3',
      qualgbCd: 'T',
      qualgbNm: '국가기술자격',
      description: '정보처리기사',
      docRegStartDt: '20240819',
      docRegEndDt: '20240822',
      docExamStartDt: '20240921',
      docExamEndDt: '20240921',
      docPassDt: '20241002',
      pracRegStartDt: '20241014',
      pracRegEndDt: '20241017',
      pracExamStartDt: '20241116',
      pracExamEndDt: '20241130',
      pracPassDt: '20241211'
    }
  ];
}

// API 데이터를 캘린더용 포맷으로 변환
export interface CalendarExamData {
  id: string;
  title: string;
  date: Date;
  type: 'written' | 'practical' | 'registration';
  category: string;
  status: 'upcoming' | 'registration-open' | 'registration-closed' | 'completed';
  description?: string;
  registrationDeadline?: Date;
  resultDate?: Date;
}

export function convertToCalendarFormat(examData: ExamScheduleItem[]): CalendarExamData[] {
  const calendarData: CalendarExamData[] = [];
  const today = new Date();

  examData.forEach(exam => {
    // 필기 접수
    if (exam.docRegStartDt && exam.docRegEndDt) {
      const regStart = parseExamDate(exam.docRegStartDt);
      const regEnd = parseExamDate(exam.docRegEndDt);

      if (regStart) {
        calendarData.push({
          id: `${exam.implYy}-${exam.implSeq}-doc-reg`,
          title: `${exam.description || exam.qualgbNm} ${exam.implSeq}회 필기접수 시작`,
          date: regStart,
          type: 'registration',
          category: exam.qualgbNm,
          status: getStatus(regStart, today),
          registrationDeadline: regEnd || undefined
        });
      }
    }

    // 필기 시험
    if (exam.docExamStartDt) {
      const examDate = parseExamDate(exam.docExamStartDt);
      if (examDate) {
        calendarData.push({
          id: `${exam.implYy}-${exam.implSeq}-doc-exam`,
          title: `${exam.description || exam.qualgbNm} ${exam.implSeq}회 필기시험`,
          date: examDate,
          type: 'written',
          category: exam.qualgbNm,
          status: getStatus(examDate, today),
          resultDate: parseExamDate(exam.docPassDt) || undefined
        });
      }
    }

    // 실기 접수
    if (exam.pracRegStartDt && exam.pracRegEndDt) {
      const regStart = parseExamDate(exam.pracRegStartDt);
      const regEnd = parseExamDate(exam.pracRegEndDt);

      if (regStart) {
        calendarData.push({
          id: `${exam.implYy}-${exam.implSeq}-prac-reg`,
          title: `${exam.description || exam.qualgbNm} ${exam.implSeq}회 실기접수 시작`,
          date: regStart,
          type: 'registration',
          category: exam.qualgbNm,
          status: getStatus(regStart, today),
          registrationDeadline: regEnd || undefined
        });
      }
    }

    // 실기 시험
    if (exam.pracExamStartDt) {
      const examDate = parseExamDate(exam.pracExamStartDt);
      if (examDate) {
        calendarData.push({
          id: `${exam.implYy}-${exam.implSeq}-prac-exam`,
          title: `${exam.description || exam.qualgbNm} ${exam.implSeq}회 실기시험`,
          date: examDate,
          type: 'practical',
          category: exam.qualgbNm,
          status: getStatus(examDate, today),
          resultDate: parseExamDate(exam.pracPassDt) || undefined
        });
      }
    }
  });

  return calendarData;
}

function getStatus(date: Date, today: Date): 'upcoming' | 'registration-open' | 'registration-closed' | 'completed' {
  if (date < today) return 'completed';

  const daysUntil = Math.floor((date.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));

  if (daysUntil <= 7) return 'registration-open';
  if (daysUntil <= 30) return 'registration-closed';

  return 'upcoming';
}