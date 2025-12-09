'use client';

import { NotionCard, NotionPageHeader, NotionStatCard } from '@/components/ui/NotionCard';
import { Trophy, Target, TrendingUp, Clock, Star, Award, BookOpen, Calendar } from 'lucide-react';
import { useState } from 'react';

export default function DashboardCertificationsPage() {
  const [selectedCert, setSelectedCert] = useState('정보처리기사');

  const certificationStats = {
    '정보처리기사': {
      progress: 78,
      studyDays: 45,
      totalQuestions: 2500,
      completedQuestions: 1950,
      weakPoints: ['소프트웨어 개발', '데이터베이스 설계'],
      strongPoints: ['프로그래밍 언어', '정보시스템'],
      nextExam: '2024-12-07',
      estimatedScore: 75,
      targetScore: 80
    },
    'SQLD': {
      progress: 42,
      studyDays: 12,
      totalQuestions: 800,
      completedQuestions: 336,
      weakPoints: ['SQL 활용', '데이터 모델링'],
      strongPoints: ['SQL 기본'],
      nextExam: '2025-01-11',
      estimatedScore: 55,
      targetScore: 70
    },
    'ADsP': {
      progress: 15,
      studyDays: 5,
      totalQuestions: 1200,
      completedQuestions: 180,
      weakPoints: ['통계 분석', 'R 프로그래밍'],
      strongPoints: ['데이터 분석 기획'],
      nextExam: '2025-01-25',
      estimatedScore: 40,
      targetScore: 60
    }
  };

  const certList = [
    { name: '정보처리기사', icon: '💻', level: '중급', category: 'IT' },
    { name: 'SQLD', icon: '🗄️', level: '초급', category: '데이터' },
    { name: 'ADsP', icon: '📊', level: '초급', category: '데이터' }
  ];

  const selectedStats = certificationStats[selectedCert as keyof typeof certificationStats];

  const achievements = [
    { name: '첫 모의고사 완료', icon: '🎯', date: '2024-11-15', points: 100 },
    { name: '7일 연속 학습', icon: '🔥', date: '2024-11-20', points: 250 },
    { name: '1000문제 돌파', icon: '💯', date: '2024-11-25', points: 500 },
    { name: '취약 분야 극복', icon: '💪', date: '2024-12-01', points: 300 }
  ];

  const studyPlan = [
    { week: '1주차', topic: '소프트웨어 설계', progress: 90, status: 'completed' },
    { week: '2주차', topic: '소프트웨어 개발', progress: 75, status: 'in-progress' },
    { week: '3주차', topic: '데이터베이스', progress: 60, status: 'in-progress' },
    { week: '4주차', topic: '프로그래밍 언어', progress: 30, status: 'upcoming' },
    { week: '5주차', topic: '정보시스템', progress: 0, status: 'upcoming' }
  ];

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="자격증 관리"
        icon="🏆"
        breadcrumbs={[
          { label: '대시보드' },
          { label: '자격증 관리' }
        ]}
      />

      {/* 자격증 선택 */}
      <NotionCard title="내 자격증" icon={<Trophy className="w-5 h-5" />}>
        <div className="p-4 grid grid-cols-1 md:grid-cols-3 gap-4">
          {certList.map((cert) => (
            <button
              key={cert.name}
              onClick={() => setSelectedCert(cert.name)}
              className={`p-4 border-2 rounded-lg transition-all ${
                selectedCert === cert.name
                  ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                  : 'border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800'
              }`}
            >
              <div className="text-3xl mb-2">{cert.icon}</div>
              <h3 className="font-semibold">{cert.name}</h3>
              <div className="flex items-center justify-center gap-2 mt-2">
                <span className="text-xs px-2 py-1 bg-gray-100 dark:bg-gray-700 rounded">
                  {cert.level}
                </span>
                <span className="text-xs px-2 py-1 bg-gray-100 dark:bg-gray-700 rounded">
                  {cert.category}
                </span>
              </div>
            </button>
          ))}
        </div>
      </NotionCard>

      {/* 자격증 통계 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <NotionStatCard
          title="학습 진도"
          value={`${selectedStats.progress}%`}
          icon={<Target className="w-5 h-5 text-blue-500" />}
          trend={{ value: 5, isUp: true }}
        />
        <NotionStatCard
          title="학습 일수"
          value={`${selectedStats.studyDays}일`}
          icon={<Calendar className="w-5 h-5 text-green-500" />}
        />
        <NotionStatCard
          title="예상 점수"
          value={`${selectedStats.estimatedScore}점`}
          description={`목표: ${selectedStats.targetScore}점`}
          icon={<TrendingUp className="w-5 h-5 text-purple-500" />}
        />
        <NotionStatCard
          title="문제 풀이"
          value={`${selectedStats.completedQuestions}`}
          description={`전체 ${selectedStats.totalQuestions}문제`}
          icon={<BookOpen className="w-5 h-5 text-orange-500" />}
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 학습 계획 */}
        <NotionCard title="주간 학습 계획" icon={<Calendar className="w-5 h-5" />}>
          <div className="p-4 space-y-3">
            {studyPlan.map((plan) => (
              <div key={plan.week} className="space-y-2">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <span className={`text-sm font-medium ${
                      plan.status === 'completed'
                        ? 'text-green-600 dark:text-green-400'
                        : plan.status === 'in-progress'
                        ? 'text-blue-600 dark:text-blue-400'
                        : 'text-gray-500'
                    }`}>
                      {plan.week}
                    </span>
                    <span className="font-medium">{plan.topic}</span>
                  </div>
                  <span className="text-sm font-medium">{plan.progress}%</span>
                </div>
                <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full ${
                      plan.status === 'completed'
                        ? 'bg-green-500'
                        : plan.status === 'in-progress'
                        ? 'bg-blue-500'
                        : 'bg-gray-300'
                    }`}
                    style={{ width: `${plan.progress}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </NotionCard>

        {/* 강약점 분석 */}
        <NotionCard title="강약점 분석" icon={<Target className="w-5 h-5" />}>
          <div className="p-4 space-y-4">
            <div>
              <h4 className="font-medium text-green-600 dark:text-green-400 mb-3 flex items-center gap-2">
                <Star className="w-4 h-4" />
                강점 분야
              </h4>
              <div className="space-y-2">
                {selectedStats.strongPoints.map((point) => (
                  <div
                    key={point}
                    className="p-3 bg-green-50 dark:bg-green-900/20 rounded-lg"
                  >
                    <div className="flex items-center justify-between">
                      <span className="font-medium">{point}</span>
                      <span className="text-sm text-green-600 dark:text-green-400">우수</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
            <div>
              <h4 className="font-medium text-red-600 dark:text-red-400 mb-3 flex items-center gap-2">
                <Target className="w-4 h-4" />
                취약 분야
              </h4>
              <div className="space-y-2">
                {selectedStats.weakPoints.map((point) => (
                  <div
                    key={point}
                    className="p-3 bg-red-50 dark:bg-red-900/20 rounded-lg"
                  >
                    <div className="flex items-center justify-between">
                      <span className="font-medium">{point}</span>
                      <button className="text-xs px-2 py-1 bg-red-500 text-white rounded hover:bg-red-600">
                        집중 학습
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </NotionCard>
      </div>

      {/* 성취 및 배지 */}
      <NotionCard title="성취 및 배지" icon={<Award className="w-5 h-5" />}>
        <div className="p-4">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {achievements.map((achievement) => (
              <div
                key={achievement.name}
                className="text-center p-4 bg-gradient-to-br from-yellow-50 to-orange-50 dark:from-yellow-900/20 dark:to-orange-900/20 rounded-lg"
              >
                <div className="text-3xl mb-2">{achievement.icon}</div>
                <h4 className="font-medium text-sm">{achievement.name}</h4>
                <p className="text-xs text-gray-600 dark:text-gray-400 mt-1">
                  {achievement.date}
                </p>
                <div className="mt-2 text-xs font-bold text-orange-600 dark:text-orange-400">
                  +{achievement.points}점
                </div>
              </div>
            ))}
          </div>
          <div className="mt-6 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
            <div className="flex items-center justify-between">
              <div>
                <h4 className="font-medium">다음 목표</h4>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  모의고사 80점 이상 달성하기
                </p>
              </div>
              <div className="text-right">
                <div className="text-2xl font-bold text-blue-600 dark:text-blue-400">
                  500점
                </div>
                <p className="text-xs text-gray-500">보상 포인트</p>
              </div>
            </div>
          </div>
        </div>
      </NotionCard>

      {/* 시험 일정 알림 */}
      <NotionCard title="시험 D-Day" icon={<Clock className="w-5 h-5" />}>
        <div className="p-4">
          <div className="p-6 bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg text-white text-center">
            <h3 className="text-2xl font-bold mb-2">{selectedCert}</h3>
            <div className="text-5xl font-bold my-4">
              D-{Math.ceil((new Date(selectedStats.nextExam).getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24))}
            </div>
            <p className="text-lg">{selectedStats.nextExam}</p>
            <div className="mt-4 grid grid-cols-3 gap-4 text-sm">
              <div>
                <p className="text-blue-100">현재 점수</p>
                <p className="text-xl font-bold">{selectedStats.estimatedScore}점</p>
              </div>
              <div>
                <p className="text-blue-100">목표 점수</p>
                <p className="text-xl font-bold">{selectedStats.targetScore}점</p>
              </div>
              <div>
                <p className="text-blue-100">남은 문제</p>
                <p className="text-xl font-bold">{selectedStats.totalQuestions - selectedStats.completedQuestions}</p>
              </div>
            </div>
            <button className="mt-6 px-6 py-3 bg-white text-purple-600 font-medium rounded-lg hover:bg-gray-100">
              모의고사 시작하기
            </button>
          </div>
        </div>
      </NotionCard>
    </div>
  );
}