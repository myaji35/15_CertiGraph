'use client';

import { NotionCard, NotionPageHeader } from '@/components/ui/NotionCard';
import { AlertTriangle, TrendingDown, TrendingUp, Brain, Target, BarChart3 } from 'lucide-react';

export default function AnalysisPage() {
  const weakTopics = [
    { topic: "SQL 쿼리 최적화", score: 35, questions: 15, incorrect: 10 },
    { topic: "정규화 이론", score: 42, questions: 20, incorrect: 12 },
    { topic: "인덱싱 전략", score: 48, questions: 18, incorrect: 9 },
    { topic: "트랜잭션 관리", score: 55, questions: 25, incorrect: 11 },
    { topic: "데이터베이스 설계", score: 58, questions: 30, incorrect: 13 }
  ];

  const strongTopics = [
    { topic: "자료구조", score: 92, questions: 40, correct: 37 },
    { topic: "알고리즘 기초", score: 88, questions: 35, correct: 31 },
    { topic: "프로그래밍 언어", score: 85, questions: 45, correct: 38 }
  ];

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="취약점 분석"
        icon="🎯"
        breadcrumbs={[
          { label: '홈' },
          { label: '취약점 분석' }
        ]}
      />

      {/* Knowledge Graph 시각화 (Placeholder) */}
      <NotionCard title="Knowledge Graph 분석" icon={<Brain className="w-5 h-5" />}>
        <div className="p-6 bg-gradient-to-br from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20 rounded-lg">
          <div className="h-64 flex items-center justify-center text-gray-500">
            <div className="text-center">
              <Brain className="w-16 h-16 mx-auto mb-4 text-blue-500" />
              <p className="text-lg font-medium">지식 그래프 분석 중...</p>
              <p className="text-sm mt-2">개념 간 연결 관계를 분석하여 취약점을 파악합니다</p>
            </div>
          </div>
        </div>
      </NotionCard>

      {/* 취약 분야 TOP 5 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <NotionCard
          title="취약 분야 TOP 5"
          icon={<AlertTriangle className="w-5 h-5 text-red-500" />}
        >
          <div className="p-4 space-y-3">
            {weakTopics.map((topic, index) => (
              <div key={index} className="space-y-2">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="text-lg font-bold text-red-500">#{index + 1}</span>
                    <span className="font-medium">{topic.topic}</span>
                  </div>
                  <div className="text-right">
                    <span className="text-2xl font-bold text-red-600">{topic.score}%</span>
                    <p className="text-xs text-gray-500">정답률</p>
                  </div>
                </div>
                <div className="flex items-center gap-4 text-sm text-gray-600 dark:text-gray-400">
                  <span>총 {topic.questions}문제</span>
                  <span>•</span>
                  <span>오답 {topic.incorrect}문제</span>
                </div>
                <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                  <div
                    className="bg-red-500 h-2 rounded-full"
                    style={{ width: `${topic.score}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </NotionCard>

        <NotionCard
          title="강점 분야"
          icon={<TrendingUp className="w-5 h-5 text-green-500" />}
        >
          <div className="p-4 space-y-3">
            {strongTopics.map((topic, index) => (
              <div key={index} className="space-y-2">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="text-lg font-bold text-green-500">#{index + 1}</span>
                    <span className="font-medium">{topic.topic}</span>
                  </div>
                  <div className="text-right">
                    <span className="text-2xl font-bold text-green-600">{topic.score}%</span>
                    <p className="text-xs text-gray-500">정답률</p>
                  </div>
                </div>
                <div className="flex items-center gap-4 text-sm text-gray-600 dark:text-gray-400">
                  <span>총 {topic.questions}문제</span>
                  <span>•</span>
                  <span>정답 {topic.correct}문제</span>
                </div>
                <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                  <div
                    className="bg-green-500 h-2 rounded-full"
                    style={{ width: `${topic.score}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </NotionCard>
      </div>

      {/* 추천 학습 경로 */}
      <NotionCard title="AI 추천 학습 경로" icon={<Target className="w-5 h-5" />}>
        <div className="p-4">
          <div className="space-y-4">
            <div className="flex items-start gap-4 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
              <div className="flex-shrink-0 w-8 h-8 bg-blue-500 text-white rounded-full flex items-center justify-center font-bold">
                1
              </div>
              <div className="flex-1">
                <h4 className="font-semibold">SQL 기초 다지기</h4>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  SELECT, JOIN, 서브쿼리 등 기본 문법을 복습하세요
                </p>
                <div className="flex items-center gap-2 mt-2">
                  <span className="text-xs px-2 py-1 bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300 rounded">
                    긴급
                  </span>
                  <span className="text-xs text-gray-500">예상 학습 시간: 3시간</span>
                </div>
              </div>
            </div>

            <div className="flex items-start gap-4 p-4 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
              <div className="flex-shrink-0 w-8 h-8 bg-yellow-500 text-white rounded-full flex items-center justify-center font-bold">
                2
              </div>
              <div className="flex-1">
                <h4 className="font-semibold">정규화 이론 학습</h4>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  1NF부터 BCNF까지 단계별로 이해하고 실습하세요
                </p>
                <div className="flex items-center gap-2 mt-2">
                  <span className="text-xs px-2 py-1 bg-yellow-100 dark:bg-yellow-900 text-yellow-700 dark:text-yellow-300 rounded">
                    중요
                  </span>
                  <span className="text-xs text-gray-500">예상 학습 시간: 2시간</span>
                </div>
              </div>
            </div>

            <div className="flex items-start gap-4 p-4 bg-green-50 dark:bg-green-900/20 rounded-lg">
              <div className="flex-shrink-0 w-8 h-8 bg-green-500 text-white rounded-full flex items-center justify-center font-bold">
                3
              </div>
              <div className="flex-1">
                <h4 className="font-semibold">인덱싱 전략 심화</h4>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  복합 인덱스, 커버링 인덱스 등 고급 개념을 학습하세요
                </p>
                <div className="flex items-center gap-2 mt-2">
                  <span className="text-xs px-2 py-1 bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300 rounded">
                    보통
                  </span>
                  <span className="text-xs text-gray-500">예상 학습 시간: 1.5시간</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </NotionCard>

      {/* 학습 성과 트렌드 */}
      <NotionCard title="학습 성과 트렌드" icon={<BarChart3 className="w-5 h-5" />}>
        <div className="p-4">
          <div className="grid grid-cols-7 gap-2">
            {['월', '화', '수', '목', '금', '토', '일'].map((day, index) => {
              const heights = [40, 55, 70, 65, 80, 85, 75];
              return (
                <div key={day} className="text-center">
                  <div className="h-32 flex items-end justify-center mb-2">
                    <div
                      className="w-full bg-blue-500 rounded-t"
                      style={{ height: `${heights[index]}%` }}
                    />
                  </div>
                  <span className="text-xs text-gray-600 dark:text-gray-400">{day}</span>
                </div>
              );
            })}
          </div>
          <div className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700 flex items-center justify-between">
            <div className="text-sm">
              <span className="text-gray-600 dark:text-gray-400">주간 평균: </span>
              <span className="font-semibold">68%</span>
            </div>
            <div className="flex items-center gap-1 text-green-500">
              <TrendingUp className="w-4 h-4" />
              <span className="text-sm font-medium">+12%</span>
            </div>
          </div>
        </div>
      </NotionCard>
    </div>
  );
}