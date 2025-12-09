'use client';

import { NotionCard, NotionPageHeader, NotionStatCard } from '@/components/ui/NotionCard';
import { Database, Play, BookOpen, Target, Clock, TrendingUp, AlertCircle } from 'lucide-react';
import { useState } from 'react';

export default function DatabaseStudyPage() {
  const [selectedTopic, setSelectedTopic] = useState<string>('');

  const topics = [
    { id: 'sql-basic', name: 'SQL 기본', progress: 85, problems: 120 },
    { id: 'normalization', name: '정규화', progress: 72, problems: 80 },
    { id: 'transaction', name: '트랜잭션', progress: 90, problems: 60 },
    { id: 'index', name: '인덱싱', progress: 65, problems: 90 },
    { id: 'modeling', name: '데이터 모델링', progress: 78, problems: 110 },
    { id: 'security', name: '보안', progress: 55, problems: 50 }
  ];

  const recentProblems = [
    { id: 1, question: 'SELECT 문에서 DISTINCT의 역할은?', correct: true, difficulty: '초급' },
    { id: 2, question: '제3정규형의 조건을 설명하시오.', correct: false, difficulty: '중급' },
    { id: 3, question: 'ACID 속성 중 Isolation의 의미는?', correct: true, difficulty: '고급' },
    { id: 4, question: 'B-Tree 인덱스의 특징은?', correct: false, difficulty: '고급' },
    { id: 5, question: 'LEFT JOIN과 INNER JOIN의 차이는?', correct: true, difficulty: '초급' }
  ];

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="데이터베이스 구축"
        icon="🗄️"
        breadcrumbs={[
          { label: '대시보드' },
          { label: '학습' },
          { label: '데이터베이스 구축' }
        ]}
      />

      {/* 학습 통계 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <NotionStatCard
          title="전체 진도"
          value="78%"
          icon={<Database className="w-5 h-5 text-blue-500" />}
          trend={{ value: 5, isUp: true }}
        />
        <NotionStatCard
          title="완료 문제"
          value="351"
          description="총 450문제"
          icon={<BookOpen className="w-5 h-5 text-green-500" />}
        />
        <NotionStatCard
          title="정답률"
          value="82%"
          icon={<Target className="w-5 h-5 text-purple-500" />}
          trend={{ value: 3, isUp: true }}
        />
        <NotionStatCard
          title="학습 시간"
          value="24.5h"
          description="이번 달"
          icon={<Clock className="w-5 h-5 text-orange-500" />}
        />
      </div>

      {/* 주제별 학습 */}
      <NotionCard title="주제별 학습" icon={<BookOpen className="w-5 h-5" />}>
        <div className="p-6 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {topics.map((topic) => (
            <div
              key={topic.id}
              onClick={() => setSelectedTopic(topic.id)}
              className={`p-4 border-2 rounded-lg cursor-pointer transition-all ${
                selectedTopic === topic.id
                  ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                  : 'border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800'
              }`}
            >
              <h3 className="font-semibold mb-2">{topic.name}</h3>
              <div className="text-sm text-gray-600 dark:text-gray-400 mb-2">
                {topic.problems}문제
              </div>
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span>진도율</span>
                  <span className="font-medium">{topic.progress}%</span>
                </div>
                <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                  <div
                    className="bg-blue-500 h-2 rounded-full"
                    style={{ width: `${topic.progress}%` }}
                  />
                </div>
              </div>
              <button className="mt-3 w-full px-3 py-2 bg-blue-500 text-white text-sm rounded hover:bg-blue-600">
                학습 시작
              </button>
            </div>
          ))}
        </div>
      </NotionCard>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 오늘의 학습 목표 */}
        <NotionCard title="오늘의 학습 목표" icon={<Target className="w-5 h-5" />}>
          <div className="p-6 space-y-4">
            <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
              <div className="flex items-center justify-between mb-3">
                <h3 className="font-semibold">SQL 고급 문법</h3>
                <span className="text-sm text-blue-600 dark:text-blue-400">12/30 완료</span>
              </div>
              <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                <div className="bg-blue-500 h-2 rounded-full" style={{ width: '40%' }} />
              </div>
            </div>
            <div className="space-y-2">
              <label className="flex items-center gap-2">
                <input type="checkbox" className="rounded" defaultChecked />
                <span className="text-sm">서브쿼리 10문제</span>
              </label>
              <label className="flex items-center gap-2">
                <input type="checkbox" className="rounded" defaultChecked />
                <span className="text-sm">조인 연습 15문제</span>
              </label>
              <label className="flex items-center gap-2">
                <input type="checkbox" className="rounded" />
                <span className="text-sm">윈도우 함수 5문제</span>
              </label>
            </div>
            <button className="w-full px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 flex items-center justify-center gap-2">
              <Play className="w-4 h-4" />
              이어서 학습하기
            </button>
          </div>
        </NotionCard>

        {/* 최근 학습 기록 */}
        <NotionCard title="최근 학습 기록" icon={<Clock className="w-5 h-5" />}>
          <div className="p-6 space-y-3">
            {recentProblems.map((problem) => (
              <div
                key={problem.id}
                className="flex items-center justify-between p-3 border border-gray-200 dark:border-gray-700 rounded-lg"
              >
                <div className="flex-1">
                  <p className="text-sm font-medium">{problem.question}</p>
                  <span className={`text-xs px-2 py-1 rounded mt-1 inline-block ${
                    problem.difficulty === '초급'
                      ? 'bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300'
                      : problem.difficulty === '중급'
                      ? 'bg-yellow-100 dark:bg-yellow-900 text-yellow-700 dark:text-yellow-300'
                      : 'bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300'
                  }`}>
                    {problem.difficulty}
                  </span>
                </div>
                <div className="ml-4">
                  {problem.correct ? (
                    <span className="text-green-500">✓</span>
                  ) : (
                    <span className="text-red-500">✗</span>
                  )}
                </div>
              </div>
            ))}
          </div>
        </NotionCard>
      </div>

      {/* AI 학습 추천 */}
      <NotionCard title="AI 학습 추천" icon={<TrendingUp className="w-5 h-5" />}>
        <div className="p-6">
          <div className="p-4 bg-gradient-to-r from-purple-500 to-pink-500 rounded-lg text-white">
            <AlertCircle className="w-6 h-6 mb-2" />
            <h3 className="text-lg font-semibold mb-2">취약 분야 발견</h3>
            <p className="mb-3">
              최근 학습 결과 분석 결과, <strong>정규화</strong>와 <strong>인덱싱</strong> 분야의
              정답률이 낮습니다. 집중 학습을 추천합니다.
            </p>
            <button className="px-4 py-2 bg-white text-purple-600 rounded-lg hover:bg-gray-100">
              취약 분야 집중 학습 시작
            </button>
          </div>
        </div>
      </NotionCard>
    </div>
  );
}