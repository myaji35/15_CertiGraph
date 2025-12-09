'use client';

import { NotionCard, NotionPageHeader } from '@/components/ui/NotionCard';
import { Play, Clock, AlertCircle, BookOpen } from 'lucide-react';
import { useState } from 'react';

export default function ExamPage() {
  const [selectedExam, setSelectedExam] = useState<string | null>(null);

  const examTypes = [
    {
      id: 'quick',
      title: '빠른 시험',
      description: '10분 안에 끝나는 간단한 테스트',
      duration: 10,
      questions: 20,
      icon: '⚡',
      color: 'blue'
    },
    {
      id: 'standard',
      title: '표준 모의고사',
      description: '실제 시험과 동일한 형식',
      duration: 120,
      questions: 100,
      icon: '📝',
      color: 'green'
    },
    {
      id: 'custom',
      title: '맞춤형 시험',
      description: '취약 분야 집중 테스트',
      duration: 60,
      questions: 50,
      icon: '🎯',
      color: 'purple'
    },
    {
      id: 'review',
      title: '오답 복습',
      description: '틀린 문제만 다시 풀기',
      duration: 30,
      questions: 25,
      icon: '🔄',
      color: 'orange'
    }
  ];

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="시험"
        icon="✏️"
        breadcrumbs={[
          { label: '홈' },
          { label: '시험' }
        ]}
      />

      {/* 시험 유형 선택 */}
      <NotionCard title="시험 유형 선택" icon={<BookOpen className="w-5 h-5" />}>
        <div className="p-6 grid grid-cols-1 md:grid-cols-2 gap-4">
          {examTypes.map((exam) => (
            <div
              key={exam.id}
              onClick={() => setSelectedExam(exam.id)}
              className={`p-6 border-2 rounded-xl cursor-pointer transition-all ${
                selectedExam === exam.id
                  ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                  : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
              }`}
            >
              <div className="flex items-start gap-4">
                <div className="text-3xl">{exam.icon}</div>
                <div className="flex-1">
                  <h3 className="font-semibold text-lg">{exam.title}</h3>
                  <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                    {exam.description}
                  </p>
                  <div className="flex items-center gap-4 mt-3 text-sm">
                    <span className="flex items-center gap-1">
                      <Clock className="w-4 h-4" />
                      {exam.duration}분
                    </span>
                    <span className="flex items-center gap-1">
                      <BookOpen className="w-4 h-4" />
                      {exam.questions}문제
                    </span>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </NotionCard>

      {/* 시험 설정 */}
      {selectedExam && (
        <NotionCard title="시험 설정" icon={<AlertCircle className="w-5 h-5" />}>
          <div className="p-6 space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                과목 선택
              </label>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                {['소프트웨어 설계', '소프트웨어 개발', '데이터베이스', '프로그래밍', '정보시스템', '전체'].map(
                  (subject) => (
                    <label key={subject} className="flex items-center gap-2">
                      <input
                        type="checkbox"
                        className="rounded border-gray-300"
                        defaultChecked={subject === '전체'}
                      />
                      <span className="text-sm">{subject}</span>
                    </label>
                  )
                )}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                난이도
              </label>
              <div className="flex gap-3">
                {['쉬움', '보통', '어려움', '랜덤'].map((level) => (
                  <button
                    key={level}
                    className={`px-4 py-2 rounded-lg border ${
                      level === '보통'
                        ? 'bg-blue-500 text-white border-blue-500'
                        : 'bg-white dark:bg-gray-800 border-gray-300 dark:border-gray-600'
                    }`}
                  >
                    {level}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                시험 옵션
              </label>
              <div className="space-y-2">
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded border-gray-300" defaultChecked />
                  <span className="text-sm">시간 제한 적용</span>
                </label>
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded border-gray-300" defaultChecked />
                  <span className="text-sm">답안 순서 무작위 배치</span>
                </label>
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded border-gray-300" />
                  <span className="text-sm">즉시 정답 확인</span>
                </label>
              </div>
            </div>

            <div className="pt-4 border-t border-gray-200 dark:border-gray-700">
              <button className="w-full md:w-auto px-8 py-3 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors flex items-center justify-center gap-2">
                <Play className="w-5 h-5" />
                <span className="font-medium">시험 시작하기</span>
              </button>
            </div>
          </div>
        </NotionCard>
      )}

      {/* 최근 시험 기록 */}
      <NotionCard title="최근 시험 기록" icon={<Clock className="w-5 h-5" />}>
        <div className="p-6">
          <div className="space-y-3">
            <div className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
              <div>
                <p className="font-medium">표준 모의고사</p>
                <p className="text-sm text-gray-600 dark:text-gray-400">2시간 전</p>
              </div>
              <div className="text-right">
                <p className="text-2xl font-bold text-blue-600">78점</p>
                <p className="text-xs text-gray-500">100문제 / 120분</p>
              </div>
            </div>
            <div className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
              <div>
                <p className="font-medium">빠른 시험</p>
                <p className="text-sm text-gray-600 dark:text-gray-400">어제</p>
              </div>
              <div className="text-right">
                <p className="text-2xl font-bold text-green-600">85점</p>
                <p className="text-xs text-gray-500">20문제 / 10분</p>
              </div>
            </div>
            <div className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
              <div>
                <p className="font-medium">맞춤형 시험</p>
                <p className="text-sm text-gray-600 dark:text-gray-400">3일 전</p>
              </div>
              <div className="text-right">
                <p className="text-2xl font-bold text-yellow-600">62점</p>
                <p className="text-xs text-gray-500">50문제 / 60분</p>
              </div>
            </div>
          </div>
        </div>
      </NotionCard>
    </div>
  );
}