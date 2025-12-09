'use client';

import { NotionCard, NotionPageHeader, NotionStatCard } from '@/components/ui/NotionCard';
import { Target, AlertTriangle, TrendingDown, TrendingUp, BookOpen, Brain, CheckCircle, XCircle } from 'lucide-react';
import { useState } from 'react';

export default function WeakPointsPage() {
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [timeRange, setTimeRange] = useState('week');

  const weaknessStats = {
    totalWeak: 47,
    improved: 12,
    worsened: 5,
    new: 8,
    criticalWeak: 15
  };

  const weakCategories = [
    {
      id: 'database',
      name: '데이터베이스',
      weakCount: 15,
      avgScore: 42,
      trend: -5,
      topics: [
        { name: 'B-Tree 인덱스', score: 35, attempts: 24, lastAttempt: '2일 전' },
        { name: '트랜잭션 격리 수준', score: 38, attempts: 18, lastAttempt: '오늘' },
        { name: '정규화 3NF/BCNF', score: 45, attempts: 15, lastAttempt: '3일 전' },
        { name: 'NoSQL 개념', score: 48, attempts: 12, lastAttempt: '1주 전' }
      ]
    },
    {
      id: 'algorithm',
      name: '알고리즘',
      weakCount: 18,
      avgScore: 38,
      trend: -8,
      topics: [
        { name: '동적 계획법', score: 30, attempts: 30, lastAttempt: '오늘' },
        { name: '그래프 탐색', score: 35, attempts: 25, lastAttempt: '어제' },
        { name: '그리디 알고리즘', score: 42, attempts: 20, lastAttempt: '3일 전' },
        { name: '분할 정복', score: 45, attempts: 18, lastAttempt: '5일 전' }
      ]
    },
    {
      id: 'network',
      name: '네트워크',
      weakCount: 10,
      avgScore: 50,
      trend: 3,
      topics: [
        { name: 'OSI 7계층', score: 45, attempts: 15, lastAttempt: '2일 전' },
        { name: 'TCP/UDP', score: 48, attempts: 12, lastAttempt: '4일 전' },
        { name: '라우팅 프로토콜', score: 52, attempts: 10, lastAttempt: '1주 전' },
        { name: 'HTTP/HTTPS', score: 55, attempts: 8, lastAttempt: '오늘' }
      ]
    },
    {
      id: 'security',
      name: '보안',
      weakCount: 4,
      avgScore: 55,
      trend: 5,
      topics: [
        { name: '암호화 알고리즘', score: 50, attempts: 10, lastAttempt: '3일 전' },
        { name: '접근 제어', score: 55, attempts: 8, lastAttempt: '5일 전' },
        { name: 'PKI', score: 58, attempts: 6, lastAttempt: '1주 전' }
      ]
    }
  ];

  const mistakePatterns = [
    {
      type: '개념 혼동',
      frequency: 45,
      examples: ['INNER JOIN vs OUTER JOIN', 'Stack vs Queue', 'TCP vs UDP'],
      recommendation: '유사 개념 비교 학습'
    },
    {
      type: '계산 실수',
      frequency: 32,
      examples: ['시간 복잡도 계산', '정규화 판별', '네트워크 서브넷 계산'],
      recommendation: '단계별 풀이 연습'
    },
    {
      type: '문제 해석 오류',
      frequency: 28,
      examples: ['요구사항 누락', '조건 간과', '출력 형식 실수'],
      recommendation: '문제 재독해 습관화'
    },
    {
      type: '시간 부족',
      frequency: 25,
      examples: ['복잡한 알고리즘 문제', '긴 지문 문제', 'SQL 작성'],
      recommendation: '시간 배분 전략 수립'
    }
  ];

  const selectedCategoryData = selectedCategory === 'all'
    ? weakCategories
    : weakCategories.filter(cat => cat.id === selectedCategory);

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="취약점 분석"
        icon="🎯"
        breadcrumbs={[
          { label: '대시보드' },
          { label: '학습' },
          { label: '취약점 분석' }
        ]}
      />

      {/* 통계 카드 */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        <NotionStatCard
          title="전체 취약점"
          value={weaknessStats.totalWeak.toString()}
          icon={<Target className="w-5 h-5 text-red-500" />}
          trend={{ value: 3, isUp: false }}
        />
        <NotionStatCard
          title="개선됨"
          value={weaknessStats.improved.toString()}
          icon={<TrendingUp className="w-5 h-5 text-green-500" />}
        />
        <NotionStatCard
          title="악화됨"
          value={weaknessStats.worsened.toString()}
          icon={<TrendingDown className="w-5 h-5 text-orange-500" />}
        />
        <NotionStatCard
          title="신규 발견"
          value={weaknessStats.new.toString()}
          icon={<AlertTriangle className="w-5 h-5 text-yellow-500" />}
        />
        <NotionStatCard
          title="위험 수준"
          value={weaknessStats.criticalWeak.toString()}
          description="긴급 학습 필요"
          icon={<AlertTriangle className="w-5 h-5 text-red-600" />}
        />
      </div>

      {/* 카테고리 필터 */}
      <NotionCard title="취약 분야별 현황" icon={<Target className="w-5 h-5" />}>
        <div className="p-6">
          <div className="flex gap-2 mb-6">
            <button
              onClick={() => setSelectedCategory('all')}
              className={`px-4 py-2 rounded-lg ${
                selectedCategory === 'all'
                  ? 'bg-red-500 text-white'
                  : 'bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600'
              }`}
            >
              전체
            </button>
            {weakCategories.map(cat => (
              <button
                key={cat.id}
                onClick={() => setSelectedCategory(cat.id)}
                className={`px-4 py-2 rounded-lg ${
                  selectedCategory === cat.id
                    ? 'bg-red-500 text-white'
                    : 'bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                {cat.name} ({cat.weakCount})
              </button>
            ))}
          </div>

          <div className="space-y-4">
            {selectedCategoryData.map(category => (
              <div key={category.id} className="border border-gray-200 dark:border-gray-700 rounded-lg p-4">
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h3 className="text-lg font-semibold">{category.name}</h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400">
                      취약 항목 {category.weakCount}개 • 평균 정답률 {category.avgScore}%
                    </p>
                  </div>
                  <div className={`flex items-center gap-2 ${
                    category.trend > 0 ? 'text-green-500' : 'text-red-500'
                  }`}>
                    {category.trend > 0 ? <TrendingUp className="w-4 h-4" /> : <TrendingDown className="w-4 h-4" />}
                    <span className="font-medium">{Math.abs(category.trend)}%</span>
                  </div>
                </div>

                <div className="space-y-3">
                  {category.topics.map((topic, index) => (
                    <div key={index} className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
                      <div className="flex-1">
                        <div className="flex items-center justify-between mb-2">
                          <span className="font-medium">{topic.name}</span>
                          <span className="text-sm text-gray-500">시도 {topic.attempts}회</span>
                        </div>
                        <div className="flex items-center gap-4">
                          <div className="flex-1 bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                            <div
                              className={`h-2 rounded-full ${
                                topic.score < 40 ? 'bg-red-500' :
                                topic.score < 60 ? 'bg-yellow-500' :
                                'bg-green-500'
                              }`}
                              style={{ width: `${topic.score}%` }}
                            />
                          </div>
                          <span className="text-sm font-medium">{topic.score}%</span>
                        </div>
                        <p className="text-xs text-gray-500 mt-1">마지막 학습: {topic.lastAttempt}</p>
                      </div>
                      <button className="ml-4 px-3 py-1 bg-red-500 text-white text-sm rounded hover:bg-red-600">
                        집중 학습
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>
      </NotionCard>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 실수 패턴 분석 */}
        <NotionCard title="실수 패턴 분석" icon={<Brain className="w-5 h-5" />}>
          <div className="p-6 space-y-4">
            {mistakePatterns.map((pattern, index) => (
              <div key={index} className="p-4 border border-gray-200 dark:border-gray-700 rounded-lg">
                <div className="flex items-center justify-between mb-2">
                  <h3 className="font-medium">{pattern.type}</h3>
                  <span className="text-sm font-medium text-red-600 dark:text-red-400">
                    {pattern.frequency}%
                  </span>
                </div>
                <div className="mb-3">
                  <p className="text-xs text-gray-600 dark:text-gray-400 mb-1">주요 사례:</p>
                  <div className="flex flex-wrap gap-1">
                    {pattern.examples.map((example, i) => (
                      <span
                        key={i}
                        className="text-xs px-2 py-1 bg-gray-100 dark:bg-gray-700 rounded"
                      >
                        {example}
                      </span>
                    ))}
                  </div>
                </div>
                <div className="p-2 bg-blue-50 dark:bg-blue-900/20 rounded">
                  <p className="text-xs text-blue-700 dark:text-blue-300">
                    💡 추천: {pattern.recommendation}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </NotionCard>

        {/* 학습 처방전 */}
        <NotionCard title="맞춤형 학습 처방" icon={<BookOpen className="w-5 h-5" />}>
          <div className="p-6">
            <div className="space-y-4">
              <div className="p-4 bg-red-50 dark:bg-red-900/20 rounded-lg">
                <div className="flex items-center gap-2 mb-2">
                  <AlertTriangle className="w-5 h-5 text-red-500" />
                  <h3 className="font-semibold text-red-700 dark:text-red-300">긴급 학습 필요</h3>
                </div>
                <ul className="space-y-2">
                  <li className="flex items-center gap-2 text-sm">
                    <XCircle className="w-4 h-4 text-red-500" />
                    <span>동적 계획법 - 30% 정답률</span>
                  </li>
                  <li className="flex items-center gap-2 text-sm">
                    <XCircle className="w-4 h-4 text-red-500" />
                    <span>B-Tree 인덱스 - 35% 정답률</span>
                  </li>
                  <li className="flex items-center gap-2 text-sm">
                    <XCircle className="w-4 h-4 text-red-500" />
                    <span>그래프 탐색 - 35% 정답률</span>
                  </li>
                </ul>
                <button className="mt-3 w-full px-3 py-2 bg-red-500 text-white rounded hover:bg-red-600">
                  긴급 학습 시작
                </button>
              </div>

              <div className="p-4 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
                <div className="flex items-center gap-2 mb-2">
                  <Target className="w-5 h-5 text-yellow-500" />
                  <h3 className="font-semibold text-yellow-700 dark:text-yellow-300">집중 개선 대상</h3>
                </div>
                <ul className="space-y-2">
                  <li className="flex items-center gap-2 text-sm">
                    <AlertTriangle className="w-4 h-4 text-yellow-500" />
                    <span>트랜잭션 격리 수준 - 38% 정답률</span>
                  </li>
                  <li className="flex items-center gap-2 text-sm">
                    <AlertTriangle className="w-4 h-4 text-yellow-500" />
                    <span>그리디 알고리즘 - 42% 정답률</span>
                  </li>
                </ul>
                <button className="mt-3 w-full px-3 py-2 bg-yellow-500 text-white rounded hover:bg-yellow-600">
                  집중 학습 계획 생성
                </button>
              </div>

              <div className="p-4 bg-green-50 dark:bg-green-900/20 rounded-lg">
                <div className="flex items-center gap-2 mb-2">
                  <CheckCircle className="w-5 h-5 text-green-500" />
                  <h3 className="font-semibold text-green-700 dark:text-green-300">개선 중인 영역</h3>
                </div>
                <ul className="space-y-2">
                  <li className="flex items-center gap-2 text-sm">
                    <TrendingUp className="w-4 h-4 text-green-500" />
                    <span>HTTP/HTTPS - 55% (+5%)</span>
                  </li>
                  <li className="flex items-center gap-2 text-sm">
                    <TrendingUp className="w-4 h-4 text-green-500" />
                    <span>접근 제어 - 55% (+3%)</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </NotionCard>
      </div>

      {/* 시간대별 분석 */}
      <NotionCard title="시간대별 취약점 변화" icon={<TrendingUp className="w-5 h-5" />}>
        <div className="p-6">
          <div className="flex gap-2 mb-4">
            {['day', 'week', 'month', 'all'].map(range => (
              <button
                key={range}
                onClick={() => setTimeRange(range)}
                className={`px-3 py-1 rounded ${
                  timeRange === range
                    ? 'bg-blue-500 text-white'
                    : 'bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                {range === 'day' ? '일간' :
                 range === 'week' ? '주간' :
                 range === 'month' ? '월간' : '전체'}
              </button>
            ))}
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="p-4 bg-gradient-to-br from-green-50 to-green-100 dark:from-green-900/20 dark:to-green-800/20 rounded-lg">
              <h3 className="font-medium mb-2">최근 개선된 취약점</h3>
              <ul className="space-y-2">
                <li className="text-sm flex items-center gap-2">
                  <TrendingUp className="w-3 h-3 text-green-500" />
                  정규화 개념 (+15%)
                </li>
                <li className="text-sm flex items-center gap-2">
                  <TrendingUp className="w-3 h-3 text-green-500" />
                  스택/큐 구현 (+12%)
                </li>
                <li className="text-sm flex items-center gap-2">
                  <TrendingUp className="w-3 h-3 text-green-500" />
                  JOIN 연산 (+10%)
                </li>
              </ul>
            </div>

            <div className="p-4 bg-gradient-to-br from-red-50 to-red-100 dark:from-red-900/20 dark:to-red-800/20 rounded-lg">
              <h3 className="font-medium mb-2">악화된 영역</h3>
              <ul className="space-y-2">
                <li className="text-sm flex items-center gap-2">
                  <TrendingDown className="w-3 h-3 text-red-500" />
                  동적 계획법 (-8%)
                </li>
                <li className="text-sm flex items-center gap-2">
                  <TrendingDown className="w-3 h-3 text-red-500" />
                  그래프 탐색 (-5%)
                </li>
              </ul>
            </div>

            <div className="p-4 bg-gradient-to-br from-yellow-50 to-yellow-100 dark:from-yellow-900/20 dark:to-yellow-800/20 rounded-lg">
              <h3 className="font-medium mb-2">새로 발견된 취약점</h3>
              <ul className="space-y-2">
                <li className="text-sm flex items-center gap-2">
                  <AlertTriangle className="w-3 h-3 text-yellow-500" />
                  분산 시스템
                </li>
                <li className="text-sm flex items-center gap-2">
                  <AlertTriangle className="w-3 h-3 text-yellow-500" />
                  마이크로서비스
                </li>
                <li className="text-sm flex items-center gap-2">
                  <AlertTriangle className="w-3 h-3 text-yellow-500" />
                  Docker/K8s
                </li>
              </ul>
            </div>
          </div>
        </div>
      </NotionCard>
    </div>
  );
}