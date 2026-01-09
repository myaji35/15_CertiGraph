'use client';

import { useState, useEffect } from 'react';
import { ChevronLeft, ChevronRight, Calendar, Clock, FileText } from 'lucide-react';
import { getMonthlyCalendar } from '@/lib/api/certifications';
import type { MonthlyCalendar } from '@/types/certification';

const WEEKDAYS = ['일', '월', '화', '수', '목', '금', '토'];
const MONTHS = [
  '1월', '2월', '3월', '4월', '5월', '6월',
  '7월', '8월', '9월', '10월', '11월', '12월'
];

const EXAM_TYPE_LABELS = {
  written: '필기',
  practical: '실기',
  interview: '면접'
};

export function CalendarView() {
  const today = new Date();
  const [currentYear, setCurrentYear] = useState(today.getFullYear());
  const [currentMonth, setCurrentMonth] = useState(today.getMonth() + 1);
  const [calendarData, setCalendarData] = useState<MonthlyCalendar | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadCalendarData();
  }, [currentYear, currentMonth]);

  const loadCalendarData = async () => {
    setLoading(true);
    try {
      const data = await getMonthlyCalendar(currentYear, currentMonth);
      console.log(`[Calendar Debug] Loaded data for ${currentYear}/${currentMonth}:`, data);
      console.log('[Calendar Debug] Calendar object:', data.calendar);
      console.log('[Calendar Debug] Day 17 data:', data.calendar?.['17']);
      setCalendarData(data);
    } catch (error) {
      console.error('Failed to load calendar:', error);
    } finally {
      setLoading(false);
    }
  };

  const handlePreviousMonth = () => {
    if (currentMonth === 1) {
      setCurrentMonth(12);
      setCurrentYear(currentYear - 1);
    } else {
      setCurrentMonth(currentMonth - 1);
    }
  };

  const handleNextMonth = () => {
    if (currentMonth === 12) {
      setCurrentMonth(1);
      setCurrentYear(currentYear + 1);
    } else {
      setCurrentMonth(currentMonth + 1);
    }
  };

  const getDaysInMonth = (year: number, month: number) => {
    return new Date(year, month, 0).getDate();
  };

  const getFirstDayOfMonth = (year: number, month: number) => {
    return new Date(year, month - 1, 1).getDay();
  };

  const renderCalendarDays = () => {
    const daysInMonth = getDaysInMonth(currentYear, currentMonth);
    const firstDay = getFirstDayOfMonth(currentYear, currentMonth);
    const days = [];

    // Empty cells for days before month starts
    for (let i = 0; i < firstDay; i++) {
      days.push(
        <div key={`empty-${i}`} className="h-32 border-r border-b bg-gray-50" />
      );
    }

    // Days of the month
    for (let day = 1; day <= daysInMonth; day++) {
      const exams = calendarData?.calendar[day.toString()] || [];
      if (day === 17 && currentYear === 2026 && currentMonth === 1) {
        console.log(`[Calendar Debug] Rendering day ${day}:`, {
          examsCount: exams.length,
          exams: exams,
          calendarDataExists: !!calendarData,
          calendarObjectKeys: calendarData?.calendar ? Object.keys(calendarData.calendar) : 'null'
        });
      }
      const isToday =
        currentYear === today.getFullYear() &&
        currentMonth === today.getMonth() + 1 &&
        day === today.getDate();

      days.push(
        <div
          key={day}
          className={`h-32 border-r border-b p-2 ${
            isToday ? 'bg-blue-50' : ''
          } hover:bg-gray-50 transition-colors`}
        >
          <div className={`text-sm font-medium mb-1 ${
            isToday ? 'text-blue-600' : 'text-gray-900'
          }`}>
            {day}
          </div>
          <div className="space-y-1">
            {exams.slice(0, 3).map((exam, idx) => (
              <div
                key={idx}
                className="text-xs p-1 rounded bg-indigo-100 text-indigo-700 truncate"
                title={`${exam.certification_name} - ${EXAM_TYPE_LABELS[exam.exam_type as keyof typeof EXAM_TYPE_LABELS]} ${exam.round}회`}
              >
                <span className="font-medium">{exam.certification_name}</span>
              </div>
            ))}
            {exams.length > 3 && (
              <div className="text-xs text-gray-500">
                +{exams.length - 3}개 더보기
              </div>
            )}
          </div>
        </div>
      );
    }

    return days;
  };

  return (
    <div className="bg-white rounded-lg shadow-lg">
      {/* Calendar Header */}
      <div className="p-4 border-b flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={handlePreviousMonth}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ChevronLeft className="h-5 w-5" />
          </button>
          <h2 className="text-xl font-semibold">
            {currentYear}년 {MONTHS[currentMonth - 1]}
          </h2>
          <button
            onClick={handleNextMonth}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ChevronRight className="h-5 w-5" />
          </button>
        </div>
        <div className="flex items-center gap-2 text-sm text-gray-600">
          <Calendar className="h-4 w-4" />
          <span>자격증 시험 일정</span>
        </div>
      </div>

      {/* Calendar Grid */}
      {loading ? (
        <div className="p-8 text-center text-gray-500">
          달력 데이터를 불러오는 중...
        </div>
      ) : (
        <div>
          {/* Weekday Headers */}
          <div className="grid grid-cols-7 border-b">
            {WEEKDAYS.map((day, idx) => (
              <div
                key={day}
                className={`p-2 text-center text-sm font-medium ${
                  idx === 0 ? 'text-red-600' : idx === 6 ? 'text-blue-600' : 'text-gray-700'
                }`}
              >
                {day}
              </div>
            ))}
          </div>

          {/* Calendar Days */}
          <div className="grid grid-cols-7">
            {renderCalendarDays()}
          </div>
        </div>
      )}

      {/* Legend */}
      <div className="p-4 border-t bg-gray-50">
        <div className="flex items-center gap-6 text-xs">
          <div className="flex items-center gap-2">
            <FileText className="h-4 w-4 text-indigo-600" />
            <span>시험 일정</span>
          </div>
          <div className="flex items-center gap-2">
            <Clock className="h-4 w-4 text-gray-500" />
            <span>클릭하여 상세 정보 확인</span>
          </div>
        </div>
      </div>
    </div>
  );
}