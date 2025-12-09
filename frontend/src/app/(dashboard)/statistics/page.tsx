'use client';

import { NotionCard, NotionPageHeader, NotionStatCard } from '@/components/ui/NotionCard';
import { BarChart, LineChart, PieChart, TrendingUp, Calendar, Clock, Target, Activity } from 'lucide-react';
import { useState } from 'react';

export default function StatisticsPage() {
  const [timeRange, setTimeRange] = useState('month');
  const [chartType, setChartType] = useState('line');

  const overallStats = {
    totalStudyTime: '152.5h',
    averageDailyTime: '3.2h',
    totalQuestions: 1429,
    correctRate: 78.5,
    longestStreak: 15,
    currentStreak: 7
  };

  const weeklyData = [
    { day: '월', hours: 3.5, questions: 45, accuracy: 82 },
    { day: '화', hours: 2.8, questions: 35, accuracy: 78 },
    { day: '수', hours: 4.2, questions: 52, accuracy: 85 },
    { day: '목', hours: 3.0, questions: 38, accuracy: 75 },
    { day: '금', hours: 3.8, questions: 48, accuracy: 80 },
    { day: '토', hours: 5.5, questions: 68, accuracy: 88 },
    { day: '일', hours: 4.0, questions: 50, accuracy: 83 }
  ];

  const categoryStats = [
    { name: '데이터베이스', percentage: 78, totalTime: 42, questions: 351 },
    { name: '소프트웨어 개발', percentage: 65, totalTime: 35, questions: 247 },
    { name: '소프트웨어 설계', percentage: 82, totalTime: 28, questions: 262 },
    { name: '정보시스템', percentage: 71, totalTime: 25, questions: 199 },
    { name: '프로그래밍', percentage: 88, totalTime: 22.5, questions: 370 }
  ];

  const timeDistribution = [
    { time: '00-06', hours: 5.2, percentage: 3 },
    { time: '06-09', hours: 28.5, percentage: 19 },
    { time: '09-12', hours: 35.2, percentage: 23 },
    { time: '12-15', hours: 22.8, percentage: 15 },
    { time: '15-18', hours: 18.5, percentage: 12 },
    { time: '18-21', hours: 32.3, percentage: 21 },
    { time: '21-24', hours: 10, percentage: 7 }
  ];

  const difficultyStats = [
    { level: '초급', total: 500, solved: 425, accuracy: 92, avgTime: 1.2 },
    { level: '중급', total: 600, solved: 420, accuracy: 78, avgTime: 2.5 },
    { level: '고급', total: 450, solved: 225, accuracy: 65, avgTime: 4.3 },
    { level: '최고급', total: 300, solved: 90, accuracy: 48, avgTime: 6.8 }
  ];

  const monthlyProgress = [
    { month: '8월', questions: 180, hours: 12, accuracy: 68 },
    { month: '9월', questions: 250, hours: 18, accuracy: 72 },
    { month: '10월', questions: 320, hours: 25, accuracy: 75 },
    { month: '11월', questions: 380, hours: 32, accuracy: 78 },
    { month: '12월', questions: 299, hours: 28.5, accuracy: 81 }
  ];

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="통계"
        icon="📊"
        breadcrumbs={[
          { label: '대시보드' },
          { label: '진도' },
          { label: '통계' }
        ]}
      />

      {/* 주요 통계 */}
      <div className="grid grid-cols-1 md:grid-cols-6 gap-4">
        <NotionStatCard
          title="총 학습 시간"
          value={overallStats.totalStudyTime}
          icon={<Clock className="w-5 h-5 text-blue-500" />}
        />
        <NotionStatCard
          title="일 평균"
          value={overallStats.averageDailyTime}
          icon={<Activity className="w-5 h-5 text-green-500" />}
        />
        <NotionStatCard
          title="푼 문제"
          value={overallStats.totalQuestions.toLocaleString()}
          icon={<Target className="w-5 h-5 text-purple-500" />}
        />
        <NotionStatCard
          title="정답률"
          value={`${overallStats.correctRate}%`}
          icon={<TrendingUp className="w-5 h-5 text-yellow-500" />}
        />
        <NotionStatCard
          title="최장 연속"
          value={`${overallStats.longestStreak}일`}
          icon={<Calendar className="w-5 h-5 text-orange-500" />}
        />
        <NotionStatCard
          title="현재 연속"
          value={`${overallStats.currentStreak}일`}
          icon={<Activity className="w-5 h-5 text-red-500" />}
        />
      </div>

      {/* 주간 학습 패턴 */}
      <NotionCard title="주간 학습 패턴" icon={<LineChart className="w-5 h-5" />}>
        <div className="p-6">
          <div className="flex justify-between items-center mb-6">
            <div className="flex gap-2">
              <button
                onClick={() => setTimeRange('week')}
                className={`px-3 py-1 rounded ${
                  timeRange === 'week'
                    ? 'bg-blue-500 text-white'
                    : 'bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                주간
              </button>
              <button
                onClick={() => setTimeRange('month')}
                className={`px-3 py-1 rounded ${
                  timeRange === 'month'
                    ? 'bg-blue-500 text-white'
                    : 'bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                월간
              </button>
              <button
                onClick={() => setTimeRange('year')}
                className={`px-3 py-1 rounded ${
                  timeRange === 'year'
                    ? 'bg-blue-500 text-white'
                    : 'bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                연간
              </button>
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => setChartType('line')}
                className={`p-2 rounded ${
                  chartType === 'line'
                    ? 'bg-gray-200 dark:bg-gray-700'
                    : 'hover:bg-gray-100 dark:hover:bg-gray-800'
                }`}
              >
                <LineChart className="w-4 h-4" />
              </button>
              <button
                onClick={() => setChartType('bar')}
                className={`p-2 rounded ${
                  chartType === 'bar'
                    ? 'bg-gray-200 dark:bg-gray-700'
                    : 'hover:bg-gray-100 dark:hover:bg-gray-800'
                }`}
              >
                <BarChart className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* 차트 영역 (실제로는 Chart.js 또는 Recharts 사용) */}
          <div className="bg-gray-50 dark:bg-gray-900 rounded-lg p-4" style={{ height: '300px' }}>
            <div className="grid grid-cols-7 gap-2 h-full items-end">
              {weeklyData.map((data, index) => (
                <div key={index} className="flex flex-col items-center justify-end h-full">
                  <div className="w-full bg-blue-500 rounded-t" style={{ height: `${(data.hours / 6) * 100}%` }} />
                  <div className="text-xs mt-2">{data.day}</div>
                  <div className="text-xs text-gray-500">{data.hours}h</div>
                </div>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-3 gap-4 mt-4">
            <div className="text-center p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
              <p className="text-sm text-gray-600 dark:text-gray-400">이번 주 총 시간</p>
              <p className="text-2xl font-bold text-blue-600 dark:text-blue-400">26.8h</p>
            </div>
            <div className="text-center p-3 bg-green-50 dark:bg-green-900/20 rounded-lg">
              <p className="text-sm text-gray-600 dark:text-gray-400">이번 주 문제</p>
              <p className="text-2xl font-bold text-green-600 dark:text-green-400">336</p>
            </div>
            <div className="text-center p-3 bg-purple-50 dark:bg-purple-900/20 rounded-lg">
              <p className="text-sm text-gray-600 dark:text-gray-400">이번 주 정답률</p>
              <p className="text-2xl font-bold text-purple-600 dark:text-purple-400">81.6%</p>
            </div>
          </div>
        </div>
      </NotionCard>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 카테고리별 분석 */}
        <NotionCard title="카테고리별 성과" icon={<PieChart className="w-5 h-5" />}>
          <div className="p-6 space-y-4">
            {categoryStats.map((category, index) => (
              <div key={index}>
                <div className="flex items-center justify-between mb-2">
                  <span className="font-medium">{category.name}</span>
                  <div className="flex items-center gap-3 text-sm text-gray-600 dark:text-gray-400">
                    <span>{category.totalTime}h</span>
                    <span>{category.questions}문제</span>
                    <span className="font-medium">{category.percentage}%</span>
                  </div>
                </div>
                <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full ${
                      category.percentage >= 80 ? 'bg-green-500' :
                      category.percentage >= 70 ? 'bg-blue-500' :
                      category.percentage >= 60 ? 'bg-yellow-500' :
                      'bg-red-500'
                    }`}
                    style={{ width: `${category.percentage}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </NotionCard>

        {/* 시간대별 학습 패턴 */}
        <NotionCard title="시간대별 학습 분포" icon={<Clock className="w-5 h-5" />}>
          <div className="p-6">
            <div className="space-y-3">
              {timeDistribution.map((time, index) => (
                <div key={index} className="flex items-center gap-3">
                  <span className="text-sm font-medium w-16">{time.time}시</span>
                  <div className="flex-1 bg-gray-200 dark:bg-gray-700 rounded-full h-6 relative">
                    <div
                      className={`h-6 rounded-full ${
                        time.percentage >= 20 ? 'bg-green-500' :
                        time.percentage >= 15 ? 'bg-blue-500' :
                        time.percentage >= 10 ? 'bg-yellow-500' :
                        'bg-gray-400'
                      }`}
                      style={{ width: `${time.percentage}%` }}
                    />
                    <span className="absolute right-2 top-0 h-6 flex items-center text-xs text-gray-600 dark:text-gray-300">
                      {time.hours}h ({time.percentage}%)
                    </span>
                  </div>
                </div>
              ))}
            </div>
            <div className="mt-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
              <p className="text-sm">
                <span className="font-medium">최고 효율 시간대:</span> 오전 9시-12시
              </p>
              <p className="text-xs text-gray-600 dark:text-gray-400 mt-1">
                이 시간대에 평균 정답률이 85%로 가장 높습니다
              </p>
            </div>
          </div>
        </NotionCard>
      </div>

      {/* 난이도별 통계 */}
      <NotionCard title="난이도별 성과 분석" icon={<Target className="w-5 h-5" />}>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            {difficultyStats.map((level, index) => (
              <div key={index} className="p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
                <h3 className={`font-semibold mb-3 ${
                  level.level === '초급' ? 'text-green-600 dark:text-green-400' :
                  level.level === '중급' ? 'text-blue-600 dark:text-blue-400' :
                  level.level === '고급' ? 'text-purple-600 dark:text-purple-400' :
                  'text-red-600 dark:text-red-400'
                }`}>
                  {level.level}
                </h3>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">풀이:</span>
                    <span className="font-medium">{level.solved}/{level.total}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">정답률:</span>
                    <span className="font-medium">{level.accuracy}%</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">평균 시간:</span>
                    <span className="font-medium">{level.avgTime}분</span>
                  </div>
                </div>
                <div className="mt-3 w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full ${
                      level.level === '초급' ? 'bg-green-500' :
                      level.level === '중급' ? 'bg-blue-500' :
                      level.level === '고급' ? 'bg-purple-500' :
                      'bg-red-500'
                    }`}
                    style={{ width: `${(level.solved / level.total) * 100}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>
      </NotionCard>

      {/* 월별 추이 */}
      <NotionCard title="월별 학습 추이" icon={<TrendingUp className="w-5 h-5" />}>
        <div className="p-6">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b dark:border-gray-700">
                  <th className="text-left py-3 px-4">월</th>
                  <th className="text-center py-3 px-4">문제 수</th>
                  <th className="text-center py-3 px-4">학습 시간</th>
                  <th className="text-center py-3 px-4">정답률</th>
                  <th className="text-center py-3 px-4">성장률</th>
                </tr>
              </thead>
              <tbody>
                {monthlyProgress.map((month, index) => (
                  <tr key={index} className="border-b dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800">
                    <td className="py-3 px-4 font-medium">{month.month}</td>
                    <td className="text-center py-3 px-4">{month.questions}</td>
                    <td className="text-center py-3 px-4">{month.hours}h</td>
                    <td className="text-center py-3 px-4">
                      <span className={`inline-block px-2 py-1 rounded text-xs font-medium ${
                        month.accuracy >= 80 ? 'bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300' :
                        month.accuracy >= 70 ? 'bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300' :
                        'bg-yellow-100 dark:bg-yellow-900 text-yellow-700 dark:text-yellow-300'
                      }`}>
                        {month.accuracy}%
                      </span>
                    </td>
                    <td className="text-center py-3 px-4">
                      <div className="flex items-center justify-center">
                        {index > 0 && (
                          <span className={`flex items-center gap-1 ${
                            month.accuracy > monthlyProgress[index - 1].accuracy
                              ? 'text-green-600 dark:text-green-400'
                              : 'text-red-600 dark:text-red-400'
                          }`}>
                            {month.accuracy > monthlyProgress[index - 1].accuracy ? (
                              <TrendingUp className="w-4 h-4" />
                            ) : (
                              <TrendingUp className="w-4 h-4 rotate-180" />
                            )}
                            {Math.abs(month.accuracy - (index > 0 ? monthlyProgress[index - 1].accuracy : month.accuracy))}%
                          </span>
                        )}
                        {index === 0 && <span className="text-gray-400">-</span>}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </NotionCard>

      {/* 학습 인사이트 */}
      <NotionCard title="AI 학습 인사이트" icon={<Activity className="w-5 h-5" />}>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="p-4 bg-green-50 dark:bg-green-900/20 rounded-lg">
              <h3 className="font-medium text-green-700 dark:text-green-300 mb-2">강점</h3>
              <ul className="space-y-1 text-sm">
                <li>• 오전 시간대 집중력 우수</li>
                <li>• 초급 문제 정답률 92%</li>
                <li>• 꾸준한 일일 학습 유지</li>
              </ul>
            </div>
            <div className="p-4 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
              <h3 className="font-medium text-yellow-700 dark:text-yellow-300 mb-2">개선 필요</h3>
              <ul className="space-y-1 text-sm">
                <li>• 고급 문제 정답률 향상</li>
                <li>• 주중 학습 시간 확보</li>
                <li>• 알고리즘 카테고리 집중</li>
              </ul>
            </div>
            <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
              <h3 className="font-medium text-blue-700 dark:text-blue-300 mb-2">추천 사항</h3>
              <ul className="space-y-1 text-sm">
                <li>• 일일 3문제 고급 도전</li>
                <li>• 취약 시간대 복습 활용</li>
                <li>• 주간 목표 설정</li>
              </ul>
            </div>
          </div>
        </div>
      </NotionCard>
    </div>
  );
}