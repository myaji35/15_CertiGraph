'use client';

import { NotionCard, NotionPageHeader, NotionStatCard } from '@/components/ui/NotionCard';
import { Code, CheckCircle, XCircle, BookOpen, Target, Clock, AlertCircle } from 'lucide-react';
import { useState } from 'react';

export default function SoftwareDevStudyPage() {
  const [selectedDifficulty, setSelectedDifficulty] = useState('all');

  const topics = [
    { name: '개발 방법론', progress: 75, total: 80, weak: false },
    { name: '소프트웨어 테스팅', progress: 60, total: 100, weak: true },
    { name: '형상 관리', progress: 82, total: 60, weak: false },
    { name: '디버깅 기법', progress: 45, total: 70, weak: true },
    { name: '빌드 및 배포', progress: 90, total: 50, weak: false },
    { name: '코드 리뷰', progress: 70, total: 40, weak: false }
  ];

  const problemHistory = [
    { date: '2024-12-08', solved: 25, correct: 20, time: '45분' },
    { date: '2024-12-07', solved: 30, correct: 24, time: '52분' },
    { date: '2024-12-06', solved: 20, correct: 18, time: '35분' },
    { date: '2024-12-05', solved: 35, correct: 28, time: '61분' },
    { date: '2024-12-04', solved: 15, correct: 12, time: '28분' }
  ];

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="소프트웨어 개발"
        icon="🔨"
        breadcrumbs={[
          { label: '대시보드' },
          { label: '학습' },
          { label: '소프트웨어 개발' }
        ]}
      />

      {/* 학습 통계 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <NotionStatCard
          title="전체 진도"
          value="65%"
          icon={<Code className="w-5 h-5 text-green-500" />}
          trend={{ value: 7, isUp: true }}
        />
        <NotionStatCard
          title="완료 문제"
          value="247"
          description="총 380문제"
          icon={<BookOpen className="w-5 h-5 text-blue-500" />}
        />
        <NotionStatCard
          title="정답률"
          value="75%"
          icon={<Target className="w-5 h-5 text-purple-500" />}
          trend={{ value: -2, isUp: false }}
        />
        <NotionStatCard
          title="연속 학습"
          value="12일"
          icon={<Clock className="w-5 h-5 text-orange-500" />}
        />
      </div>

      {/* 주제별 진도 */}
      <NotionCard title="주제별 진도 현황" icon={<BookOpen className="w-5 h-5" />}>
        <div className="p-6 space-y-4">
          {topics.map((topic, index) => (
            <div key={index} className="space-y-2">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="font-medium">{topic.name}</span>
                  {topic.weak && (
                    <span className="px-2 py-1 text-xs bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300 rounded">
                      취약
                    </span>
                  )}
                </div>
                <span className="text-sm text-gray-600 dark:text-gray-400">
                  {Math.floor((topic.progress / topic.total) * 100)}% ({topic.progress}/{topic.total})
                </span>
              </div>
              <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-3">
                <div
                  className={`h-3 rounded-full ${
                    topic.weak ? 'bg-red-500' : 'bg-green-500'
                  }`}
                  style={{ width: `${(topic.progress / topic.total) * 100}%` }}
                />
              </div>
            </div>
          ))}
        </div>
      </NotionCard>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 난이도별 문제 */}
        <NotionCard title="난이도별 문제 풀이" icon={<Target className="w-5 h-5" />}>
          <div className="p-6">
            <div className="flex gap-2 mb-4">
              {['all', 'easy', 'medium', 'hard'].map((level) => (
                <button
                  key={level}
                  onClick={() => setSelectedDifficulty(level)}
                  className={`px-3 py-1 rounded text-sm ${
                    selectedDifficulty === level
                      ? 'bg-blue-500 text-white'
                      : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300'
                  }`}
                >
                  {level === 'all' ? '전체' : level === 'easy' ? '초급' : level === 'medium' ? '중급' : '고급'}
                </button>
              ))}
            </div>
            <div className="space-y-3">
              <div className="flex items-center justify-between p-3 bg-green-50 dark:bg-green-900/20 rounded-lg">
                <span className="text-sm font-medium">초급 문제</span>
                <div className="flex items-center gap-2">
                  <span className="text-sm">85/100</span>
                  <CheckCircle className="w-4 h-4 text-green-500" />
                </div>
              </div>
              <div className="flex items-center justify-between p-3 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
                <span className="text-sm font-medium">중급 문제</span>
                <div className="flex items-center gap-2">
                  <span className="text-sm">120/180</span>
                  <AlertCircle className="w-4 h-4 text-yellow-500" />
                </div>
              </div>
              <div className="flex items-center justify-between p-3 bg-red-50 dark:bg-red-900/20 rounded-lg">
                <span className="text-sm font-medium">고급 문제</span>
                <div className="flex items-center gap-2">
                  <span className="text-sm">42/100</span>
                  <XCircle className="w-4 h-4 text-red-500" />
                </div>
              </div>
            </div>
            <button className="mt-4 w-full px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600">
              난이도별 학습 시작
            </button>
          </div>
        </NotionCard>

        {/* 학습 히스토리 */}
        <NotionCard title="최근 학습 기록" icon={<Clock className="w-5 h-5" />}>
          <div className="p-6">
            <div className="space-y-3">
              {problemHistory.map((history, index) => (
                <div
                  key={index}
                  className="flex items-center justify-between p-3 border border-gray-200 dark:border-gray-700 rounded-lg"
                >
                  <div>
                    <p className="font-medium text-sm">{history.date}</p>
                    <p className="text-xs text-gray-600 dark:text-gray-400">
                      {history.time} 학습
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="font-medium">
                      {history.correct}/{history.solved}
                    </p>
                    <p className="text-xs text-gray-600 dark:text-gray-400">
                      정답률 {Math.round((history.correct / history.solved) * 100)}%
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </NotionCard>
      </div>

      {/* 오답 노트 */}
      <NotionCard title="오답 노트" icon={<XCircle className="w-5 h-5" />}>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 bg-red-50 dark:bg-red-900/20 rounded-lg">
              <h3 className="font-semibold mb-3">자주 틀리는 유형</h3>
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm">테스트 케이스 설계</span>
                  <span className="text-sm text-red-600 dark:text-red-400">12회</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm">V모델 개념</span>
                  <span className="text-sm text-red-600 dark:text-red-400">8회</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm">Git 명령어</span>
                  <span className="text-sm text-red-600 dark:text-red-400">6회</span>
                </div>
              </div>
            </div>
            <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
              <h3 className="font-semibold mb-3">복습 필요 문제</h3>
              <div className="space-y-2 text-sm">
                <p className="line-clamp-2">• 블랙박스 테스팅과 화이트박스 테스팅의 차이점은?</p>
                <p className="line-clamp-2">• CI/CD 파이프라인의 구성 요소를 설명하시오.</p>
                <p className="line-clamp-2">• 애자일 방법론의 핵심 원칙 4가지는?</p>
              </div>
              <button className="mt-3 px-3 py-1 bg-blue-500 text-white text-sm rounded hover:bg-blue-600">
                오답 복습하기
              </button>
            </div>
          </div>
        </div>
      </NotionCard>
    </div>
  );
}