'use client';

import { useState, useEffect } from 'react';
import { ChevronLeft, ChevronRight, Calendar, Clock, MapPin, Users, AlertCircle, CheckCircle, XCircle, BookOpen, Award, Target } from 'lucide-react';

interface ExamDate {
  id: string;
  title: string;
  date: Date;
  type: 'written' | 'practical' | 'interview';
  category: string;
  location?: string;
  registrationDeadline?: Date;
  resultDate?: Date;
  status: 'upcoming' | 'registration-open' | 'registration-closed' | 'completed';
  applicants?: number;
  passRate?: number;
}

// API에서 실제 시험 일정 데이터를 가져오는 함수
const fetchExamDates = async (): Promise<ExamDate[]> => {
  try {
    const response = await fetch('/api/exam-schedules');
    if (!response.ok) {
      throw new Error('Failed to fetch exam schedules');
    }
    const result = await response.json();

    // API 응답 확인
    if (!result.success || !result.data) {
      throw new Error('Invalid API response');
    }

    // API 데이터를 ExamDate 형식으로 변환
    const exams: ExamDate[] = result.data.map((item: any) => ({
      id: item.id,
      title: item.examName,
      date: new Date(item.examDate),
      type: item.examType === 'practical' ? 'practical' : item.examType === 'interview' ? 'interview' : 'written',
      category: item.category,
      location: item.location || '전국 시험장',
      registrationDeadline: item.registrationEndDate ? new Date(item.registrationEndDate) : undefined,
      resultDate: item.resultDate ? new Date(item.resultDate) : undefined,
      status: getExamStatusFromDate(new Date(item.examDate), item.registrationEndDate ? new Date(item.registrationEndDate) : null),
      applicants: item.applicants,
      passRate: item.passRate
    }));

    // 디버깅용 로그
    console.log('Loaded exam data:', exams.filter(e => e.category === '사회복지'));
    console.log('Total exams loaded:', exams.length);

    return exams;
  } catch (error) {
    console.error('Error fetching exam schedules:', error);
    return getFallbackExamDates();
  }
};

// 날짜 기반으로 시험 상태 판단
function getExamStatusFromDate(examDate: Date, registrationEndDate: Date | null): 'upcoming' | 'registration-open' | 'registration-closed' | 'completed' {
  const today = new Date();

  if (examDate < today) return 'completed';

  if (registrationEndDate) {
    if (registrationEndDate >= today) return 'registration-open';
    if (registrationEndDate < today && examDate > today) return 'registration-closed';
  }

  const daysUntil = Math.floor((examDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
  if (daysUntil <= 30) return 'registration-closed';

  return 'upcoming';
}

// 오프라인 폴백 데이터 (API 실패 시 사용)
const getFallbackExamDates = (): ExamDate[] => {
  const today = new Date();
  const exams: ExamDate[] = [];

  // 정보처리기사 시험 일정 (실제 2024-2026년 일정 기반)
  const infoProcessingDates = [
    // 2023년 (과거 데이터)
    { year: 2023, round: 3, written: new Date(2023, 8, 23), practical: new Date(2023, 10, 18), registration: new Date(2023, 7, 21) },
    { year: 2023, round: 4, written: new Date(2023, 10, 11), practical: new Date(2023, 11, 23), registration: new Date(2023, 9, 16) },
    // 2024년
    { year: 2024, round: 1, written: new Date(2024, 2, 7), practical: new Date(2024, 4, 25), registration: new Date(2024, 1, 5) },
    { year: 2024, round: 2, written: new Date(2024, 4, 9), practical: new Date(2024, 6, 13), registration: new Date(2024, 3, 8) },
    { year: 2024, round: 3, written: new Date(2024, 8, 21), practical: new Date(2024, 10, 16), registration: new Date(2024, 7, 19) },
    // 2025년
    { year: 2025, round: 1, written: new Date(2025, 2, 8), practical: new Date(2025, 4, 24), registration: new Date(2025, 1, 3) },
    { year: 2025, round: 2, written: new Date(2025, 4, 10), practical: new Date(2025, 6, 12), registration: new Date(2025, 3, 7) },
    { year: 2025, round: 3, written: new Date(2025, 8, 20), practical: new Date(2025, 10, 15), registration: new Date(2025, 7, 18) },
    // 2026년
    { year: 2026, round: 1, written: new Date(2026, 2, 7), practical: new Date(2026, 4, 23), registration: new Date(2026, 1, 2) },
    { year: 2026, round: 2, written: new Date(2026, 4, 9), practical: new Date(2026, 6, 11), registration: new Date(2026, 3, 6) },
  ];

  // SQLD 시험 일정
  const sqldDates = [
    { year: 2023, round: 46, date: new Date(2023, 8, 2), registration: new Date(2023, 7, 7) },
    { year: 2023, round: 47, date: new Date(2023, 11, 2), registration: new Date(2023, 10, 6) },
    { year: 2024, round: 48, date: new Date(2024, 2, 2), registration: new Date(2024, 1, 5) },
    { year: 2024, round: 49, date: new Date(2024, 4, 25), registration: new Date(2024, 3, 29) },
    { year: 2024, round: 50, date: new Date(2024, 8, 7), registration: new Date(2024, 7, 12) },
    { year: 2024, round: 51, date: new Date(2024, 10, 30), registration: new Date(2024, 10, 4) },
    { year: 2025, round: 52, date: new Date(2025, 2, 8), registration: new Date(2025, 1, 10) },
    { year: 2025, round: 53, date: new Date(2025, 5, 14), registration: new Date(2025, 4, 19) },
    { year: 2025, round: 54, date: new Date(2025, 8, 13), registration: new Date(2025, 7, 18) },
    { year: 2025, round: 55, date: new Date(2025, 11, 6), registration: new Date(2025, 10, 10) },
    { year: 2026, round: 56, date: new Date(2026, 2, 14), registration: new Date(2026, 1, 16) },
    { year: 2026, round: 57, date: new Date(2026, 5, 13), registration: new Date(2026, 4, 18) },
  ];

  // 사회복지사 1급 시험 일정
  const socialWorkerDates = [
    { year: 2023, round: 21, date: new Date(2023, 1, 11), registration: new Date(2022, 11, 12) },
    { year: 2024, round: 22, date: new Date(2024, 1, 3), registration: new Date(2023, 11, 4) },
    { year: 2025, round: 23, date: new Date(2025, 1, 8), registration: new Date(2024, 11, 9) },
    { year: 2026, round: 24, date: new Date(2026, 1, 7), registration: new Date(2025, 11, 8) },
  ];

  // 정보처리기사 데이터 추가
  infoProcessingDates.forEach(exam => {
    // 필기시험
    exams.push({
      id: `info-written-${exam.year}-${exam.round}`,
      title: `정보처리기사 ${exam.year}년 ${exam.round}회 필기`,
      date: exam.written,
      type: 'written',
      category: '정보처리',
      location: '전국 CBT 시험장',
      registrationDeadline: exam.registration,
      resultDate: new Date(exam.written.getTime() + 14 * 24 * 60 * 60 * 1000),
      status: getExamStatus(exam.written, exam.registration),
      applicants: Math.floor(Math.random() * 5000) + 10000,
      passRate: 45 + Math.random() * 15,
    });

    // 실기시험
    exams.push({
      id: `info-practical-${exam.year}-${exam.round}`,
      title: `정보처리기사 ${exam.year}년 ${exam.round}회 실기`,
      date: exam.practical,
      type: 'practical',
      category: '정보처리',
      location: '지정 시험장',
      registrationDeadline: new Date(exam.practical.getTime() - 30 * 24 * 60 * 60 * 1000),
      resultDate: new Date(exam.practical.getTime() + 28 * 24 * 60 * 60 * 1000),
      status: getExamStatus(exam.practical, new Date(exam.practical.getTime() - 30 * 24 * 60 * 60 * 1000)),
      applicants: Math.floor(Math.random() * 3000) + 7000,
      passRate: 20 + Math.random() * 10,
    });
  });

  // SQLD 데이터 추가
  sqldDates.forEach(exam => {
    exams.push({
      id: `sqld-${exam.year}-${exam.round}`,
      title: `SQLD ${exam.round}회`,
      date: exam.date,
      type: 'written',
      category: '데이터베이스',
      location: '전국 지정 시험장',
      registrationDeadline: exam.registration,
      resultDate: new Date(exam.date.getTime() + 28 * 24 * 60 * 60 * 1000),
      status: getExamStatus(exam.date, exam.registration),
      applicants: Math.floor(Math.random() * 3000) + 5000,
      passRate: 40 + Math.random() * 20,
    });
  });

  // 사회복지사 데이터 추가
  socialWorkerDates.forEach(exam => {
    exams.push({
      id: `social-${exam.year}-${exam.round}`,
      title: `사회복지사 1급 ${exam.round}회`,
      date: exam.date,
      type: 'written',
      category: '사회복지',
      location: '전국 동시 시행',
      registrationDeadline: exam.registration,
      resultDate: new Date(exam.date.getTime() + 42 * 24 * 60 * 60 * 1000),
      status: getExamStatus(exam.date, exam.registration),
      applicants: Math.floor(Math.random() * 10000) + 20000,
      passRate: 35 + Math.random() * 15,
    });
  });

  // ADsP, ADP 시험 일정 추가
  const adspDates = [
    { year: 2024, round: 42, date: new Date(2024, 2, 16), registration: new Date(2024, 1, 19) },
    { year: 2024, round: 43, date: new Date(2024, 5, 15), registration: new Date(2024, 4, 20) },
    { year: 2024, round: 44, date: new Date(2024, 9, 12), registration: new Date(2024, 8, 16) },
    { year: 2025, round: 45, date: new Date(2025, 2, 15), registration: new Date(2025, 1, 17) },
    { year: 2025, round: 46, date: new Date(2025, 5, 21), registration: new Date(2025, 4, 26) },
    { year: 2025, round: 47, date: new Date(2025, 9, 18), registration: new Date(2025, 8, 22) },
  ];

  adspDates.forEach(exam => {
    exams.push({
      id: `adsp-${exam.year}-${exam.round}`,
      title: `ADsP ${exam.round}회`,
      date: exam.date,
      type: 'written',
      category: '데이터분석',
      location: '전국 지정 시험장',
      registrationDeadline: exam.registration,
      resultDate: new Date(exam.date.getTime() + 28 * 24 * 60 * 60 * 1000),
      status: getExamStatus(exam.date, exam.registration),
      applicants: Math.floor(Math.random() * 2000) + 3000,
      passRate: 35 + Math.random() * 15,
    });
  });

  return exams.filter(exam => {
    const oneYearAgo = new Date(today);
    oneYearAgo.setFullYear(today.getFullYear() - 1);
    const twoYearsLater = new Date(today);
    twoYearsLater.setFullYear(today.getFullYear() + 2);
    return exam.date >= oneYearAgo && exam.date <= twoYearsLater;
  });
};

function getExamStatus(examDate: Date, registrationDeadline: Date): 'upcoming' | 'registration-open' | 'registration-closed' | 'completed' {
  const today = new Date();
  if (examDate < today) return 'completed';
  if (registrationDeadline > today) return 'upcoming';
  if (registrationDeadline <= today && examDate > today) return 'registration-closed';

  // 접수 기간 (보통 1주일)
  const registrationStart = new Date(registrationDeadline);
  registrationStart.setDate(registrationStart.getDate() - 7);
  if (today >= registrationStart && today <= registrationDeadline) return 'registration-open';

  return 'upcoming';
}

export default function CertificationsPage() {
  const [currentDate, setCurrentDate] = useState(new Date());
  const [selectedDate, setSelectedDate] = useState<Date | null>(null);
  const [examDates, setExamDates] = useState<ExamDate[]>([]);
  const [viewMode, setViewMode] = useState<'month' | 'year'>('month');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // API에서 실제 데이터 가져오기
    const loadExamDates = async () => {
      setIsLoading(true);
      try {
        const dates = await fetchExamDates();
        setExamDates(dates);
      } finally {
        setIsLoading(false);
      }
    };
    loadExamDates();
  }, []);

  const getDaysInMonth = (date: Date) => {
    return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
  };

  const getFirstDayOfMonth = (date: Date) => {
    return new Date(date.getFullYear(), date.getMonth(), 1).getDay();
  };

  const navigateMonth = (direction: number) => {
    setCurrentDate(prev => {
      const newDate = new Date(prev);
      newDate.setMonth(prev.getMonth() + direction);
      return newDate;
    });
  };

  const navigateYear = (direction: number) => {
    setCurrentDate(prev => {
      const newDate = new Date(prev);
      newDate.setFullYear(prev.getFullYear() + direction);
      return newDate;
    });
  };

  const getExamsForDate = (date: Date) => {
    return examDates.filter(exam => {
      const matchesDate = exam.date.getFullYear() === date.getFullYear() &&
        exam.date.getMonth() === date.getMonth() &&
        exam.date.getDate() === date.getDate();
      const matchesCategory = selectedCategory === 'all' || exam.category === selectedCategory;
      return matchesDate && matchesCategory;
    });
  };

  const getExamsForMonth = (year: number, month: number) => {
    return examDates.filter(exam => {
      const matchesMonth = exam.date.getFullYear() === year && exam.date.getMonth() === month;
      const matchesCategory = selectedCategory === 'all' || exam.category === selectedCategory;
      return matchesMonth && matchesCategory;
    });
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'upcoming': return 'bg-blue-100 text-blue-800';
      case 'registration-open': return 'bg-green-100 text-green-800';
      case 'registration-closed': return 'bg-yellow-100 text-yellow-800';
      case 'completed': return 'bg-gray-100 text-gray-600';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'upcoming': return <Clock className="w-4 h-4" />;
      case 'registration-open': return <CheckCircle className="w-4 h-4" />;
      case 'registration-closed': return <AlertCircle className="w-4 h-4" />;
      case 'completed': return <XCircle className="w-4 h-4" />;
      default: return null;
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'upcoming': return '접수 예정';
      case 'registration-open': return '접수 중';
      case 'registration-closed': return '접수 마감';
      case 'completed': return '시행 완료';
      default: return status;
    }
  };

  const monthNames = ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];
  const dayNames = ['일', '월', '화', '수', '목', '금', '토'];

  const categories = [
    { value: 'all', label: '전체', color: 'bg-gray-100' },
    { value: 'IT', label: 'IT/정보처리', color: 'bg-blue-100' },
    { value: '데이터분석', label: '데이터분석', color: 'bg-purple-100' },
    { value: '사회복지', label: '사회복지', color: 'bg-pink-100' },
    { value: '금융', label: '금융', color: 'bg-yellow-100' },
    { value: '경제', label: '경제', color: 'bg-indigo-100' },
    { value: '세무회계', label: '세무/회계', color: 'bg-amber-100' }
  ];

  const renderMonthView = () => {
    const daysInMonth = getDaysInMonth(currentDate);
    const firstDay = getFirstDayOfMonth(currentDate);
    const days = [];

    // 빈 날짜 채우기
    for (let i = 0; i < firstDay; i++) {
      days.push(<div key={`empty-${i}`} className="h-32 bg-gray-50"></div>);
    }

    // 날짜 렌더링
    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(currentDate.getFullYear(), currentDate.getMonth(), day);
      const exams = getExamsForDate(date);
      const isToday =
        date.getFullYear() === new Date().getFullYear() &&
        date.getMonth() === new Date().getMonth() &&
        date.getDate() === new Date().getDate();
      const isSelected =
        selectedDate &&
        date.getFullYear() === selectedDate.getFullYear() &&
        date.getMonth() === selectedDate.getMonth() &&
        date.getDate() === selectedDate.getDate();

      days.push(
        <div
          key={day}
          className={`border border-gray-200 p-2 h-32 overflow-hidden cursor-pointer transition-all hover:bg-gray-50 ${
            isToday ? 'bg-blue-50 ring-2 ring-blue-400' : ''
          } ${isSelected ? 'ring-2 ring-blue-500' : ''}`}
          onClick={() => setSelectedDate(date)}
        >
          <div className={`text-sm font-semibold mb-1 ${isToday ? 'text-blue-600' : 'text-gray-700'}`}>
            {day}
          </div>
          <div className="space-y-1">
            {exams.slice(0, 3).map((exam) => (
              <div
                key={exam.id}
                className={`text-xs p-1 rounded truncate ${
                  exam.type === 'practical' ? 'bg-purple-100 text-purple-700' :
                  exam.category === '정보처리' || exam.category === 'IT' ? 'bg-blue-100 text-blue-700' :
                  exam.category === '데이터베이스' ? 'bg-green-100 text-green-700' :
                  exam.category === '데이터분석' ? 'bg-purple-100 text-purple-700' :
                  exam.category === '사회복지' ? 'bg-pink-100 text-pink-700' :
                  exam.category === '금융' ? 'bg-yellow-100 text-yellow-700' :
                  exam.category === '경제' ? 'bg-indigo-100 text-indigo-700' :
                  exam.category === '세무회계' ? 'bg-amber-100 text-amber-700' :
                  'bg-orange-100 text-orange-700'
                }`}
                title={exam.title}
              >
                {exam.title.replace(/\d{4}년 /, '')}
              </div>
            ))}
            {exams.length > 3 && (
              <div className="text-xs text-gray-500">+{exams.length - 3} more</div>
            )}
          </div>
        </div>
      );
    }

    return days;
  };

  const renderYearView = () => {
    const months = [];
    for (let month = 0; month < 12; month++) {
      const monthExams = getExamsForMonth(currentDate.getFullYear(), month);
      const isCurrentMonth =
        new Date().getFullYear() === currentDate.getFullYear() &&
        new Date().getMonth() === month;

      months.push(
        <div
          key={month}
          className={`border border-gray-200 p-3 cursor-pointer hover:bg-gray-50 transition-all ${
            isCurrentMonth ? 'bg-blue-50 ring-2 ring-blue-400' : ''
          }`}
          onClick={() => {
            setCurrentDate(new Date(currentDate.getFullYear(), month, 1));
            setViewMode('month');
          }}
        >
          <div className="font-semibold text-sm mb-2">{monthNames[month]}</div>
          <div className="space-y-1">
            <div className="text-xs text-gray-600">
              시험 {monthExams.length}건
            </div>
            {monthExams.length > 0 && (
              <div className="flex flex-wrap gap-1 mt-1">
                {Array.from(new Set(monthExams.map(e => e.category))).map(cat => (
                  <span
                    key={cat}
                    className={`text-xs px-1 py-0.5 rounded ${
                      cat === '정보처리' ? 'bg-blue-100 text-blue-700' :
                      cat === '데이터베이스' ? 'bg-green-100 text-green-700' :
                      cat === '데이터분석' ? 'bg-purple-100 text-purple-700' :
                      'bg-orange-100 text-orange-700'
                    }`}
                  >
                    {cat}
                  </span>
                ))}
              </div>
            )}
          </div>
        </div>
      );
    }
    return months;
  };

  const selectedExams = selectedDate ? getExamsForDate(selectedDate) : [];
  const upcomingExams = examDates
    .filter(exam => exam.status === 'registration-open' || exam.status === 'upcoming')
    .filter(exam => selectedCategory === 'all' || exam.category === selectedCategory)
    .sort((a, b) => a.date.getTime() - b.date.getTime())
    .slice(0, 5);

  return (
    <div className="max-w-7xl mx-auto">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900 mb-2">자격증 시험 일정</h1>
        <p className="text-gray-600">최근 1년 및 향후 2년간의 주요 자격증 시험 일정을 확인하세요</p>
      </div>

      {isLoading ? (
        <div className="flex justify-center items-center min-h-[400px]">
          <div className="text-center">
            <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
            <p className="mt-4 text-gray-600">시험 일정을 불러오는 중...</p>
          </div>
        </div>
      ) : (
        <>

      {/* 카테고리 필터 */}
      <div className="mb-4 flex gap-2">
        {categories.map(cat => (
          <button
            key={cat.value}
            onClick={() => setSelectedCategory(cat.value)}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
              selectedCategory === cat.value
                ? 'bg-blue-500 text-white'
                : 'bg-gray-100 hover:bg-gray-200 text-gray-700'
            }`}
          >
            {cat.label}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* 캘린더 */}
        <div className="lg:col-span-2">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="flex items-center justify-between p-4 border-b border-gray-200">
              <div className="flex items-center gap-4">
                <button
                  onClick={() => viewMode === 'month' ? navigateMonth(-1) : navigateYear(-1)}
                  className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                >
                  <ChevronLeft className="w-5 h-5" />
                </button>
                <h2 className="text-xl font-semibold">
                  {viewMode === 'month'
                    ? `${currentDate.getFullYear()}년 ${monthNames[currentDate.getMonth()]}`
                    : `${currentDate.getFullYear()}년`
                  }
                </h2>
                <button
                  onClick={() => viewMode === 'month' ? navigateMonth(1) : navigateYear(1)}
                  className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                >
                  <ChevronRight className="w-5 h-5" />
                </button>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setCurrentDate(new Date())}
                  className="px-3 py-1.5 text-sm bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
                >
                  오늘
                </button>
                <div className="flex bg-gray-100 rounded-lg p-1">
                  <button
                    onClick={() => setViewMode('month')}
                    className={`px-3 py-1 text-sm rounded transition-colors ${
                      viewMode === 'month' ? 'bg-white shadow-sm' : 'hover:bg-gray-200'
                    }`}
                  >
                    월별
                  </button>
                  <button
                    onClick={() => setViewMode('year')}
                    className={`px-3 py-1 text-sm rounded transition-colors ${
                      viewMode === 'year' ? 'bg-white shadow-sm' : 'hover:bg-gray-200'
                    }`}
                  >
                    연간
                  </button>
                </div>
              </div>
            </div>

            <div className="p-4">
              {viewMode === 'month' ? (
                <>
                  <div className="grid grid-cols-7 gap-px mb-2">
                    {dayNames.map(day => (
                      <div key={day} className="text-center text-sm font-semibold text-gray-600 py-2">
                        {day}
                      </div>
                    ))}
                  </div>
                  <div className="grid grid-cols-7 gap-px bg-gray-200">
                    {renderMonthView()}
                  </div>
                </>
              ) : (
                <div className="grid grid-cols-4 gap-2">
                  {renderYearView()}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* 사이드바 */}
        <div className="space-y-6">
          {/* 다가오는 시험 */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
              <Calendar className="w-5 h-5 text-blue-500" />
              다가오는 시험
            </h3>
            <div className="space-y-3">
              {upcomingExams.map(exam => (
                <div key={exam.id} className="p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors cursor-pointer"
                     onClick={() => setSelectedDate(exam.date)}>
                  <div className="flex items-start justify-between mb-1">
                    <h4 className="font-medium text-sm">{exam.title.replace(/\d{4}년 /, '')}</h4>
                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${getStatusColor(exam.status)}`}>
                      {getStatusText(exam.status)}
                    </span>
                  </div>
                  <div className="text-xs text-gray-600">
                    {exam.date.toLocaleDateString('ko-KR', { month: 'long', day: 'numeric' })}
                    {exam.registrationDeadline && exam.status === 'upcoming' && (
                      <span className="block mt-1">
                        접수: {exam.registrationDeadline.toLocaleDateString('ko-KR')}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* 선택된 날짜의 시험 정보 */}
          {selectedDate && selectedExams.length > 0 && (
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
              <h3 className="text-lg font-semibold mb-4">
                {selectedDate.getFullYear()}년 {monthNames[selectedDate.getMonth()]} {selectedDate.getDate()}일
              </h3>
              <div className="space-y-3">
                {selectedExams.map(exam => (
                  <div key={exam.id} className="border border-gray-200 rounded-lg p-3">
                    <div className="flex items-start justify-between mb-2">
                      <h4 className="font-semibold text-sm">{exam.title.replace(/\d{4}년 /, '')}</h4>
                      <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${getStatusColor(exam.status)}`}>
                        {getStatusText(exam.status)}
                      </span>
                    </div>
                    <div className="space-y-1 text-xs text-gray-600">
                      {exam.location && (
                        <div className="flex items-center gap-1">
                          <MapPin className="w-3 h-3" />
                          {exam.location}
                        </div>
                      )}
                      {exam.applicants && exam.status === 'completed' && (
                        <div className="flex items-center gap-1">
                          <Users className="w-3 h-3" />
                          지원자 {exam.applicants.toLocaleString()}명
                        </div>
                      )}
                      {exam.passRate && exam.status === 'completed' && (
                        <div>합격률: {exam.passRate.toFixed(1)}%</div>
                      )}
                      {exam.registrationDeadline && exam.status !== 'completed' && (
                        <div>접수마감: {exam.registrationDeadline.toLocaleDateString('ko-KR')}</div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* 범례 */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <h3 className="text-sm font-semibold mb-3">범례</h3>
            <div className="space-y-2 text-sm">
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 bg-blue-100 rounded"></div>
                <span>정보처리</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 bg-green-100 rounded"></div>
                <span>데이터베이스</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 bg-orange-100 rounded"></div>
                <span>사회복지</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 bg-purple-100 rounded"></div>
                <span>데이터분석/실기</span>
              </div>
            </div>
            <div className="mt-3 pt-3 border-t border-gray-200 space-y-2 text-sm">
              <div className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-blue-600" />
                <span>접수 예정</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle className="w-4 h-4 text-green-600" />
                <span>접수 중</span>
              </div>
              <div className="flex items-center gap-2">
                <AlertCircle className="w-4 h-4 text-yellow-600" />
                <span>접수 마감</span>
              </div>
              <div className="flex items-center gap-2">
                <XCircle className="w-4 h-4 text-gray-600" />
                <span>시행 완료</span>
              </div>
            </div>
          </div>
        </div>
      </div>
      </>
      )}
    </div>
  );
}