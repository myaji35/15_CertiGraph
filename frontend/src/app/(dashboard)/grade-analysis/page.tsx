'use client';

import { NotionCard, NotionPageHeader, NotionStatCard } from '@/components/ui/NotionCard';
import { BarChart3, TrendingUp, TrendingDown, FileText } from 'lucide-react';

export default function GradeAnalysisPage() {
  const weeklyReport = [
    { week: '1주차', score: 65, tests: 3 },
    { week: '2주차', score: 72, tests: 4 },
    { week: '3주차', score: 68, tests: 3 },
    { week: '4주차', score: 78, tests: 5 }
  ];

  const monthlyReport = [
    { month: '10월', avg: 68, highest: 85, lowest: 52, total: 12 },
    { month: '11월', avg: 74, highest: 92, lowest: 58, total: 15 },
    { month: '12월', avg: 71, highest: 88, lowest: 55, total: 8 }
  ];

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="성적 분석"
        icon="📈"
        breadcrumbs={[
          { label: '홈' },
          { label: '학습 분석' },
          { label: '성적 분석' }
        ]}
      />

      {/* 성적 요약 통계 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <NotionStatCard
          title="평균 점수"
          value="71.5"
          description="최근 30일"
          icon={<BarChart3 className="w-5 h-5 text-blue-500" />}
          trend={{ value: 3.5, isUp: true }}
        />
        <NotionStatCard
          title="최고 점수"
          value="92"
          description="11월 15일"
          icon={<TrendingUp className="w-5 h-5 text-green-500" />}
        />
        <NotionStatCard
          title="최저 점수"
          value="52"
          description="10월 8일"
          icon={<TrendingDown className="w-5 h-5 text-red-500" />}
        />
        <NotionStatCard
          title="응시 횟수"
          value="35"
          description="총 모의고사"
          icon={<FileText className="w-5 h-5 text-purple-500" />}
        />
      </div>

      {/* 주간 리포트 */}
      <NotionCard title="주간 리포트" icon={<BarChart3 className="w-5 h-5" />}>
        <div className="p-6">
          <div className="space-y-4">
            {weeklyReport.map((week, index) => (
              <div key={index} className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="font-medium">{week.week}</span>
                  <div className="flex items-center gap-4">
                    <span className="text-sm text-gray-600 dark:text-gray-400">
                      {week.tests}회 응시
                    </span>
                    <span className="text-lg font-bold">{week.score}점</span>
                  </div>
                </div>
                <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full ${
                      week.score >= 70 ? 'bg-green-500' : 'bg-yellow-500'
                    }`}
                    style={{ width: `${week.score}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
          <div className="mt-6 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
            <h4 className="font-semibold text-blue-900 dark:text-blue-100 mb-2">
              📊 주간 분석
            </h4>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              4주차에 가장 높은 점수를 기록했습니다. 꾸준한 상승 추세를 보이고 있어요!
              지속적인 학습으로 목표 점수 80점에 근접하고 있습니다.
            </p>
          </div>
        </div>
      </NotionCard>

      {/* 월간 리포트 */}
      <NotionCard title="월간 리포트" icon={<FileText className="w-5 h-5" />}>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {monthlyReport.map((month, index) => (
              <div
                key={index}
                className="p-4 border border-gray-200 dark:border-gray-700 rounded-lg"
              >
                <h4 className="font-semibold text-lg mb-3">{month.month}</h4>
                <div className="space-y-2">
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-600 dark:text-gray-400">평균</span>
                    <span className="font-bold text-xl">{month.avg}점</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-600 dark:text-gray-400">최고</span>
                    <span className="text-green-600 font-medium">{month.highest}점</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-600 dark:text-gray-400">최저</span>
                    <span className="text-red-600 font-medium">{month.lowest}점</span>
                  </div>
                  <div className="pt-2 border-t border-gray-200 dark:border-gray-700">
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-600 dark:text-gray-400">응시</span>
                      <span className="font-medium">{month.total}회</span>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </NotionCard>

      {/* 과목별 성적 분포 */}
      <NotionCard title="과목별 성적 분포" icon={<BarChart3 className="w-5 h-5" />}>
        <div className="p-6">
          <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
            {[
              { subject: '소프트웨어 설계', score: 78, color: 'blue' },
              { subject: '소프트웨어 개발', score: 65, color: 'green' },
              { subject: '데이터베이스', score: 82, color: 'purple' },
              { subject: '프로그래밍', score: 71, color: 'orange' },
              { subject: '정보시스템', score: 69, color: 'pink' }
            ].map((subject, index) => (
              <div key={index} className="text-center">
                <div className={`w-16 h-16 mx-auto mb-2 rounded-full bg-${subject.color}-100 dark:bg-${subject.color}-900 flex items-center justify-center`}>
                  <span className="text-xl font-bold">{subject.score}</span>
                </div>
                <p className="text-sm font-medium">{subject.subject}</p>
              </div>
            ))}
          </div>
        </div>
      </NotionCard>

      {/* AI 피드백 */}
      <NotionCard title="AI 성적 분석 피드백" icon={<TrendingUp className="w-5 h-5" />}>
        <div className="p-6 space-y-4">
          <div className="p-4 bg-green-50 dark:bg-green-900/20 rounded-lg">
            <h4 className="font-semibold text-green-900 dark:text-green-100 mb-2">
              💪 강점 분야
            </h4>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              데이터베이스 분야에서 우수한 성적을 보이고 있습니다.
              특히 SQL 쿼리와 정규화 이론에서 높은 이해도를 보여주고 있어요.
            </p>
          </div>
          <div className="p-4 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
            <h4 className="font-semibold text-yellow-900 dark:text-yellow-100 mb-2">
              📚 개선 필요 분야
            </h4>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              소프트웨어 개발 분야의 점수가 상대적으로 낮습니다.
              디자인 패턴과 테스트 케이스 작성 부분을 집중 학습하는 것을 추천합니다.
            </p>
          </div>
          <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
            <h4 className="font-semibold text-blue-900 dark:text-blue-100 mb-2">
              🎯 다음 목표
            </h4>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              현재 평균 71.5점에서 80점으로 향상시키기 위해
              일일 30문제씩 꾸준히 학습하면 2주 내에 목표 달성이 가능합니다.
            </p>
          </div>
        </div>
      </NotionCard>
    </div>
  );
}