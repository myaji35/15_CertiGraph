'use client';

import { NotionCard, NotionPageHeader, NotionStatCard } from '@/components/ui/NotionCard';
import { Target, TrendingUp, Award, Calendar } from 'lucide-react';

export default function ProgressPage() {
  const subjects = [
    { name: "소프트웨어 설계", total: 150, completed: 120, percentage: 80 },
    { name: "소프트웨어 개발", total: 200, completed: 140, percentage: 70 },
    { name: "데이터베이스 구축", total: 180, completed: 162, percentage: 90 },
    { name: "프로그래밍 언어", total: 120, completed: 96, percentage: 80 },
    { name: "정보시스템 구축", total: 100, completed: 55, percentage: 55 }
  ];

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="진도율"
        icon="📊"
        breadcrumbs={[
          { label: '홈' },
          { label: '학습 분석' },
          { label: '진도율' }
        ]}
      />

      {/* 전체 진도 요약 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <NotionStatCard
          title="전체 진도율"
          value="73%"
          icon={<Target className="w-5 h-5 text-blue-500" />}
          trend={{ value: 8, isUp: true }}
        />
        <NotionStatCard
          title="완료한 문제"
          value="573"
          description="전체 750문제 중"
          icon={<Award className="w-5 h-5 text-green-500" />}
        />
        <NotionStatCard
          title="학습 일수"
          value="28일"
          icon={<Calendar className="w-5 h-5 text-purple-500" />}
        />
        <NotionStatCard
          title="일일 평균"
          value="20.5"
          description="문제/일"
          icon={<TrendingUp className="w-5 h-5 text-orange-500" />}
        />
      </div>

      {/* 과목별 진도율 */}
      <NotionCard title="과목별 진도율" icon={<Target className="w-5 h-5" />}>
        <div className="p-6 space-y-4">
          {subjects.map((subject, index) => (
            <div key={index} className="space-y-2">
              <div className="flex items-center justify-between">
                <h4 className="font-medium">{subject.name}</h4>
                <div className="text-sm text-gray-600 dark:text-gray-400">
                  <span className="font-medium">{subject.completed}</span>/{subject.total}문제
                </div>
              </div>
              <div className="relative">
                <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-3">
                  <div
                    className={`h-3 rounded-full transition-all duration-500 ${
                      subject.percentage >= 80
                        ? 'bg-green-500'
                        : subject.percentage >= 60
                        ? 'bg-yellow-500'
                        : 'bg-red-500'
                    }`}
                    style={{ width: `${subject.percentage}%` }}
                  />
                </div>
                <span className="absolute right-0 -top-6 text-sm font-bold">
                  {subject.percentage}%
                </span>
              </div>
            </div>
          ))}
        </div>
      </NotionCard>

      {/* 주간 학습 패턴 */}
      <NotionCard title="주간 학습 패턴" icon={<Calendar className="w-5 h-5" />}>
        <div className="p-6">
          <div className="grid grid-cols-7 gap-4">
            {['월', '화', '수', '목', '금', '토', '일'].map((day, index) => {
              const studyHours = [2.5, 3, 1.5, 4, 3.5, 5, 2];
              const isToday = index === 4;
              return (
                <div
                  key={day}
                  className={`text-center p-3 rounded-lg ${
                    isToday
                      ? 'bg-blue-100 dark:bg-blue-900'
                      : 'bg-gray-50 dark:bg-gray-800'
                  }`}
                >
                  <p className="text-sm font-medium mb-2">{day}</p>
                  <p className="text-2xl font-bold">
                    {studyHours[index]}
                  </p>
                  <p className="text-xs text-gray-500">시간</p>
                </div>
              );
            })}
          </div>
        </div>
      </NotionCard>

      {/* 목표 달성률 */}
      <NotionCard title="이번 주 목표" icon={<Award className="w-5 h-5" />}>
        <div className="p-6">
          <div className="space-y-4">
            <div className="flex items-center justify-between p-4 bg-green-50 dark:bg-green-900/20 rounded-lg">
              <div className="flex items-center gap-3">
                <span className="text-2xl">✅</span>
                <div>
                  <p className="font-medium">일일 20문제 풀기</p>
                  <p className="text-sm text-gray-600 dark:text-gray-400">5/7일 달성</p>
                </div>
              </div>
              <span className="text-green-600 font-bold">71%</span>
            </div>
            <div className="flex items-center justify-between p-4 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
              <div className="flex items-center gap-3">
                <span className="text-2xl">⏳</span>
                <div>
                  <p className="font-medium">주간 모의고사 응시</p>
                  <p className="text-sm text-gray-600 dark:text-gray-400">1/2회 완료</p>
                </div>
              </div>
              <span className="text-yellow-600 font-bold">50%</span>
            </div>
            <div className="flex items-center justify-between p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
              <div className="flex items-center gap-3">
                <span className="text-2xl">📚</span>
                <div>
                  <p className="font-medium">취약 분야 복습</p>
                  <p className="text-sm text-gray-600 dark:text-gray-400">3/5개 완료</p>
                </div>
              </div>
              <span className="text-blue-600 font-bold">60%</span>
            </div>
          </div>
        </div>
      </NotionCard>
    </div>
  );
}