'use client';

import { NotionCard, NotionPageHeader, NotionStatCard } from '@/components/ui/NotionCard';
import { Terminal, Code2, Cpu, Zap, Brain, Bug, PlayCircle, ChevronRight } from 'lucide-react';
import { useState } from 'react';

export default function ProgrammingStudyPage() {
  const [selectedLanguage, setSelectedLanguage] = useState('Java');
  const [activeAlgorithm, setActiveAlgorithm] = useState('');

  const languages = [
    { name: 'Java', icon: '☕', progress: 92, problems: 150, strong: true },
    { name: 'Python', icon: '🐍', progress: 85, problems: 120, strong: true },
    { name: 'C++', icon: '⚡', progress: 70, problems: 100, strong: false },
    { name: 'JavaScript', icon: '🌐', progress: 78, problems: 80, strong: false },
    { name: 'SQL', icon: '🗄️', progress: 88, problems: 90, strong: true }
  ];

  const algorithmTopics = [
    { id: 'sorting', name: '정렬 알고리즘', mastery: 95, problems: 45, lastPracticed: '오늘' },
    { id: 'searching', name: '탐색 알고리즘', mastery: 88, problems: 35, lastPracticed: '어제' },
    { id: 'dp', name: '동적 계획법', mastery: 65, problems: 60, lastPracticed: '3일 전' },
    { id: 'graph', name: '그래프', mastery: 72, problems: 55, lastPracticed: '2일 전' },
    { id: 'greedy', name: '그리디', mastery: 80, problems: 40, lastPracticed: '오늘' },
    { id: 'tree', name: '트리', mastery: 75, problems: 50, lastPracticed: '1주 전' }
  ];

  const codeProblems = [
    {
      id: 1,
      title: '배열 회전',
      difficulty: '초급',
      category: '배열',
      solved: true,
      timeSpent: '15분',
      accuracy: 100
    },
    {
      id: 2,
      title: '최단 경로 찾기',
      difficulty: '고급',
      category: '그래프',
      solved: false,
      timeSpent: '45분',
      accuracy: 60
    },
    {
      id: 3,
      title: '문자열 압축',
      difficulty: '중급',
      category: '문자열',
      solved: true,
      timeSpent: '25분',
      accuracy: 85
    },
    {
      id: 4,
      title: '이진 트리 순회',
      difficulty: '중급',
      category: '트리',
      solved: true,
      timeSpent: '20분',
      accuracy: 90
    }
  ];

  const dataStructures = [
    { name: '배열/리스트', understanding: 95, implementation: 90 },
    { name: '스택/큐', understanding: 92, implementation: 88 },
    { name: '해시 테이블', understanding: 85, implementation: 78 },
    { name: '힙', understanding: 70, implementation: 65 },
    { name: '트라이', understanding: 60, implementation: 55 }
  ];

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="프로그래밍 언어 활용"
        icon="💻"
        breadcrumbs={[
          { label: '대시보드' },
          { label: '학습' },
          { label: '프로그래밍 언어 활용' }
        ]}
      />

      {/* 학습 통계 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <NotionStatCard
          title="전체 진도"
          value="88%"
          icon={<Terminal className="w-5 h-5 text-pink-500" />}
          trend={{ value: 3, isUp: true }}
        />
        <NotionStatCard
          title="완료 문제"
          value="370"
          description="총 420문제"
          icon={<Code2 className="w-5 h-5 text-blue-500" />}
        />
        <NotionStatCard
          title="알고리즘 마스터리"
          value="79%"
          icon={<Brain className="w-5 h-5 text-purple-500" />}
        />
        <NotionStatCard
          title="코딩 속도"
          value="24분"
          description="평균 문제당"
          icon={<Zap className="w-5 h-5 text-yellow-500" />}
          trend={{ value: -3, isUp: true }}
        />
      </div>

      {/* 언어별 숙련도 */}
      <NotionCard title="프로그래밍 언어별 숙련도" icon={<Terminal className="w-5 h-5" />}>
        <div className="p-6">
          <div className="flex gap-2 mb-6 flex-wrap">
            {languages.map((lang) => (
              <button
                key={lang.name}
                onClick={() => setSelectedLanguage(lang.name)}
                className={`px-4 py-2 rounded-lg flex items-center gap-2 transition-all ${
                  selectedLanguage === lang.name
                    ? 'bg-pink-500 text-white'
                    : 'bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                <span className="text-lg">{lang.icon}</span>
                <span className="font-medium">{lang.name}</span>
              </button>
            ))}
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            {languages.map((lang) => (
              <div
                key={lang.name}
                className={`p-4 rounded-lg border-2 ${
                  lang.strong
                    ? 'border-green-500 bg-green-50 dark:bg-green-900/20'
                    : 'border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800'
                }`}
              >
                <div className="text-center mb-3">
                  <div className="text-2xl mb-1">{lang.icon}</div>
                  <h4 className="font-semibold">{lang.name}</h4>
                </div>
                <div className="space-y-2">
                  <div className="text-center">
                    <div className="text-2xl font-bold">{lang.progress}%</div>
                    <p className="text-xs text-gray-500">{lang.problems}문제 완료</p>
                  </div>
                  <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                    <div
                      className={`h-2 rounded-full ${
                        lang.strong ? 'bg-green-500' : 'bg-blue-500'
                      }`}
                      style={{ width: `${lang.progress}%` }}
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </NotionCard>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 알고리즘 학습 */}
        <NotionCard title="알고리즘 카테고리" icon={<Brain className="w-5 h-5" />}>
          <div className="p-6 space-y-3">
            {algorithmTopics.map((topic) => (
              <div
                key={topic.id}
                onClick={() => setActiveAlgorithm(topic.id)}
                className={`p-3 rounded-lg border cursor-pointer transition-all ${
                  activeAlgorithm === topic.id
                    ? 'border-purple-500 bg-purple-50 dark:bg-purple-900/20'
                    : 'border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800'
                }`}
              >
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <span className="font-medium">{topic.name}</span>
                    <span className="text-xs text-gray-500">({topic.lastPracticed})</span>
                  </div>
                  <span className="text-sm font-medium">{topic.mastery}%</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="flex-1 bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                    <div
                      className={`h-2 rounded-full ${
                        topic.mastery >= 80 ? 'bg-green-500' :
                        topic.mastery >= 60 ? 'bg-yellow-500' :
                        'bg-red-500'
                      }`}
                      style={{ width: `${topic.mastery}%` }}
                    />
                  </div>
                  <span className="text-xs text-gray-500">{topic.problems}문제</span>
                </div>
              </div>
            ))}
            <button className="w-full mt-4 px-4 py-2 bg-purple-500 text-white rounded-lg hover:bg-purple-600 flex items-center justify-center gap-2">
              <PlayCircle className="w-4 h-4" />
              알고리즘 문제 풀기
            </button>
          </div>
        </NotionCard>

        {/* 자료구조 이해도 */}
        <NotionCard title="자료구조 이해도" icon={<Cpu className="w-5 h-5" />}>
          <div className="p-6 space-y-3">
            {dataStructures.map((ds, index) => (
              <div key={index} className="space-y-2">
                <div className="font-medium text-sm">{ds.name}</div>
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <div className="flex justify-between text-xs text-gray-600 dark:text-gray-400 mb-1">
                      <span>개념 이해</span>
                      <span>{ds.understanding}%</span>
                    </div>
                    <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-1.5">
                      <div
                        className="bg-blue-500 h-1.5 rounded-full"
                        style={{ width: `${ds.understanding}%` }}
                      />
                    </div>
                  </div>
                  <div>
                    <div className="flex justify-between text-xs text-gray-600 dark:text-gray-400 mb-1">
                      <span>구현 능력</span>
                      <span>{ds.implementation}%</span>
                    </div>
                    <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-1.5">
                      <div
                        className="bg-green-500 h-1.5 rounded-full"
                        style={{ width: `${ds.implementation}%` }}
                      />
                    </div>
                  </div>
                </div>
              </div>
            ))}
            <div className="pt-4 border-t dark:border-gray-700">
              <div className="flex items-center justify-between mb-2">
                <span className="font-medium">종합 점수</span>
                <span className="text-lg font-bold text-purple-600 dark:text-purple-400">83%</span>
              </div>
              <p className="text-xs text-gray-600 dark:text-gray-400">
                코딩 테스트 수준: 중상급
              </p>
            </div>
          </div>
        </NotionCard>
      </div>

      {/* 최근 코딩 문제 */}
      <NotionCard title="최근 풀이 문제" icon={<Bug className="w-5 h-5" />}>
        <div className="p-6">
          <div className="space-y-3">
            {codeProblems.map((problem) => (
              <div
                key={problem.id}
                className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-800 rounded-lg"
              >
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    <h3 className="font-medium">{problem.title}</h3>
                    <span className={`text-xs px-2 py-1 rounded ${
                      problem.difficulty === '초급'
                        ? 'bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300'
                        : problem.difficulty === '중급'
                        ? 'bg-yellow-100 dark:bg-yellow-900 text-yellow-700 dark:text-yellow-300'
                        : 'bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300'
                    }`}>
                      {problem.difficulty}
                    </span>
                    <span className="text-xs px-2 py-1 bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300 rounded">
                      {problem.category}
                    </span>
                  </div>
                  <div className="flex items-center gap-4 text-xs text-gray-600 dark:text-gray-400">
                    <span>소요시간: {problem.timeSpent}</span>
                    <span>정확도: {problem.accuracy}%</span>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  {problem.solved ? (
                    <div className="text-green-500">
                      <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                      </svg>
                    </div>
                  ) : (
                    <div className="text-yellow-500">
                      <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm0-2a6 6 0 100-12 6 6 0 000 12z" clipRule="evenodd" />
                      </svg>
                    </div>
                  )}
                  <ChevronRight className="w-4 h-4 text-gray-400" />
                </div>
              </div>
            ))}
          </div>
          <div className="mt-6 p-4 bg-gradient-to-r from-pink-500 to-purple-600 rounded-lg text-white">
            <h3 className="text-lg font-semibold mb-2">일일 코딩 챌린지</h3>
            <p className="text-sm mb-3">
              오늘의 도전: 동적 계획법을 활용한 최적화 문제
            </p>
            <div className="flex items-center gap-4 text-sm mb-3">
              <span>난이도: ⭐⭐⭐⭐</span>
              <span>예상 시간: 40분</span>
              <span>보상: 150XP</span>
            </div>
            <button className="px-4 py-2 bg-white text-purple-600 rounded-lg hover:bg-gray-100">
              도전하기
            </button>
          </div>
        </div>
      </NotionCard>
    </div>
  );
}