'use client';

import { useState, useEffect } from 'react';
import { Calendar, Clock, FileText, AlertCircle } from 'lucide-react';
import { getUpcomingExams } from '@/lib/api/certifications';
import type { UpcomingExam } from '@/types/certification';

const EXAM_TYPE_LABELS = {
  written: '필기',
  practical: '실기',
  interview: '면접'
};

export function UpcomingExams() {
  const [exams, setExams] = useState<UpcomingExam[]>([]);
  const [loading, setLoading] = useState(false);
  const [dayRange, setDayRange] = useState(30);

  useEffect(() => {
    loadUpcomingExams();
  }, [dayRange]);

  const loadUpcomingExams = async () => {
    setLoading(true);
    try {
      const data = await getUpcomingExams(dayRange);
      setExams(data.exams);
    } catch (error) {
      console.error('Failed to load upcoming exams:', error);
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('ko-KR', {
      month: 'long',
      day: 'numeric',
      weekday: 'short'
    });
  };

  const getDaysUntilLabel = (days: number) => {
    if (days === 0) return '오늘';
    if (days === 1) return '내일';
    if (days <= 7) return `${days}일 후`;
    if (days <= 30) return `${Math.floor(days / 7)}주 후`;
    return `${Math.floor(days / 30)}개월 후`;
  };

  return (
    <div className="bg-white rounded-lg shadow-lg">
      <div className="p-4 border-b">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold flex items-center gap-2">
            <Clock className="h-5 w-5 text-indigo-600" />
            다가오는 시험 일정
          </h2>
          <select
            value={dayRange}
            onChange={(e) => setDayRange(Number(e.target.value))}
            className="px-3 py-1 text-sm border rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value={30}>30일 이내</option>
            <option value={60}>60일 이내</option>
            <option value={90}>90일 이내</option>
            <option value={180}>6개월 이내</option>
            <option value={365}>1년 이내</option>
          </select>
        </div>
      </div>

      <div className="p-4">
        {loading ? (
          <div className="text-center py-8 text-gray-500">
            시험 일정을 불러오는 중...
          </div>
        ) : exams.length === 0 ? (
          <div className="text-center py-8">
            <AlertCircle className="h-12 w-12 text-gray-300 mx-auto mb-3" />
            <p className="text-gray-500">
              {dayRange}일 이내 예정된 시험이 없습니다.
            </p>
          </div>
        ) : (
          <div className="space-y-4">
            {exams.map((exam, idx) => (
              <div
                key={idx}
                className="p-4 border rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      <FileText className="h-4 w-4 text-gray-500" />
                      <span className="font-medium">{exam.certification_name}</span>
                      <span className="px-2 py-0.5 text-xs bg-blue-100 text-blue-700 rounded">
                        {EXAM_TYPE_LABELS[exam.exam_type]}
                      </span>
                      {exam.round && (
                        <span className="text-sm text-gray-500">
                          {exam.round}회
                        </span>
                      )}
                    </div>

                    <div className="grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <div className="flex items-center gap-1 text-gray-600">
                          <Calendar className="h-3 w-3" />
                          <span>시험일: {formatDate(exam.exam_date)}</span>
                        </div>
                        {exam.is_application_open ? (
                          <div className="flex items-center gap-1 mt-1">
                            <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
                            <span className="text-green-600 text-xs font-medium">
                              접수 중 (~{formatDate(exam.application_end)})
                            </span>
                          </div>
                        ) : (
                          <div className="text-xs text-gray-500 mt-1">
                            접수: {formatDate(exam.application_start)} ~ {formatDate(exam.application_end)}
                          </div>
                        )}
                      </div>

                      <div className="text-right">
                        <div className={`inline-block px-3 py-1 rounded-full text-sm font-medium ${
                          exam.days_until <= 7
                            ? 'bg-red-100 text-red-700'
                            : exam.days_until <= 30
                            ? 'bg-orange-100 text-orange-700'
                            : 'bg-gray-100 text-gray-700'
                        }`}>
                          {getDaysUntilLabel(exam.days_until)}
                        </div>
                        <div className="text-xs text-gray-500 mt-1">
                          발표: {formatDate(exam.result_date)}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}