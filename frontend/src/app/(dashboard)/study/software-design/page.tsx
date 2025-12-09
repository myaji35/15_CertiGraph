'use client';

import { NotionCard, NotionPageHeader, NotionStatCard } from '@/components/ui/NotionCard';
import { Settings, Layers, GitBranch, BookOpen, Target, Trophy, Brain } from 'lucide-react';
import { useState } from 'react';

export default function SoftwareDesignStudyPage() {
  const [selectedPattern, setSelectedPattern] = useState<string | null>(null);

  const designPatterns = [
    { name: 'Singleton', category: '생성', mastery: 90, examples: 12 },
    { name: 'Factory', category: '생성', mastery: 75, examples: 8 },
    { name: 'Observer', category: '행동', mastery: 60, examples: 6 },
    { name: 'Strategy', category: '행동', mastery: 85, examples: 10 },
    { name: 'Adapter', category: '구조', mastery: 70, examples: 7 },
    { name: 'Decorator', category: '구조', mastery: 45, examples: 5 }
  ];

  const umlDiagrams = [
    { type: '클래스 다이어그램', completed: 18, total: 20, accuracy: 85 },
    { type: '시퀀스 다이어그램', completed: 12, total: 15, accuracy: 78 },
    { type: '유스케이스 다이어그램', completed: 8, total: 10, accuracy: 90 },
    { type: '액티비티 다이어그램', completed: 5, total: 8, accuracy: 72 }
  ];

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="소프트웨어 설계"
        icon="🏗️"
        breadcrumbs={[
          { label: '대시보드' },
          { label: '학습' },
          { label: '소프트웨어 설계' }
        ]}
      />

      {/* 학습 통계 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <NotionStatCard
          title="전체 진도"
          value="82%"
          icon={<Settings className="w-5 h-5 text-purple-500" />}
          trend={{ value: 4, isUp: true }}
        />
        <NotionStatCard
          title="완료 문제"
          value="262"
          description="총 320문제"
          icon={<BookOpen className="w-5 h-5 text-blue-500" />}
        />
        <NotionStatCard
          title="패턴 마스터"
          value="15"
          description="총 23 패턴"
          icon={<Brain className="w-5 h-5 text-green-500" />}
        />
        <NotionStatCard
          title="이번 주 학습"
          value="12.5h"
          icon={<Trophy className="w-5 h-5 text-orange-500" />}
        />
      </div>

      {/* 디자인 패턴 */}
      <NotionCard title="디자인 패턴 학습" icon={<Layers className="w-5 h-5" />}>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {designPatterns.map((pattern, index) => (
              <div
                key={index}
                onClick={() => setSelectedPattern(pattern.name)}
                className={`p-4 border-2 rounded-lg cursor-pointer transition-all ${
                  selectedPattern === pattern.name
                    ? 'border-purple-500 bg-purple-50 dark:bg-purple-900/20'
                    : 'border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800'
                }`}
              >
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <h3 className="font-semibold">{pattern.name}</h3>
                    <span className={`text-xs px-2 py-1 rounded mt-1 inline-block ${
                      pattern.category === '생성'
                        ? 'bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300'
                        : pattern.category === '행동'
                        ? 'bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300'
                        : 'bg-purple-100 dark:bg-purple-900 text-purple-700 dark:text-purple-300'
                    }`}>
                      {pattern.category}
                    </span>
                  </div>
                  <span className="text-xs text-gray-500">{pattern.examples} 예제</span>
                </div>
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span>숙련도</span>
                    <span className={`font-medium ${
                      pattern.mastery >= 80 ? 'text-green-600 dark:text-green-400' :
                      pattern.mastery >= 60 ? 'text-yellow-600 dark:text-yellow-400' :
                      'text-red-600 dark:text-red-400'
                    }`}>
                      {pattern.mastery}%
                    </span>
                  </div>
                  <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                    <div
                      className={`h-2 rounded-full ${
                        pattern.mastery >= 80 ? 'bg-green-500' :
                        pattern.mastery >= 60 ? 'bg-yellow-500' :
                        'bg-red-500'
                      }`}
                      style={{ width: `${pattern.mastery}%` }}
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </NotionCard>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* UML 다이어그램 */}
        <NotionCard title="UML 다이어그램" icon={<GitBranch className="w-5 h-5" />}>
          <div className="p-6 space-y-4">
            {umlDiagrams.map((diagram, index) => (
              <div key={index} className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="font-medium text-sm">{diagram.type}</span>
                  <div className="flex items-center gap-2 text-sm">
                    <span className="text-gray-600 dark:text-gray-400">
                      {diagram.completed}/{diagram.total}
                    </span>
                    <span className={`font-medium ${
                      diagram.accuracy >= 80 ? 'text-green-600 dark:text-green-400' :
                      diagram.accuracy >= 60 ? 'text-yellow-600 dark:text-yellow-400' :
                      'text-red-600 dark:text-red-400'
                    }`}>
                      {diagram.accuracy}% 정확도
                    </span>
                  </div>
                </div>
                <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                  <div
                    className="bg-purple-500 h-2 rounded-full"
                    style={{ width: `${(diagram.completed / diagram.total) * 100}%` }}
                  />
                </div>
              </div>
            ))}
            <button className="mt-4 w-full px-4 py-2 bg-purple-500 text-white rounded-lg hover:bg-purple-600">
              UML 연습 문제
            </button>
          </div>
        </NotionCard>

        {/* 아키텍처 패턴 */}
        <NotionCard title="아키텍처 패턴" icon={<Target className="w-5 h-5" />}>
          <div className="p-6">
            <div className="space-y-3">
              <div className="p-3 border border-gray-200 dark:border-gray-700 rounded-lg">
                <div className="flex items-center justify-between mb-2">
                  <span className="font-medium">MVC 패턴</span>
                  <span className="text-sm text-green-600 dark:text-green-400">마스터</span>
                </div>
                <p className="text-xs text-gray-600 dark:text-gray-400">
                  Model-View-Controller 구조 이해 완료
                </p>
              </div>
              <div className="p-3 border border-gray-200 dark:border-gray-700 rounded-lg">
                <div className="flex items-center justify-between mb-2">
                  <span className="font-medium">마이크로서비스</span>
                  <span className="text-sm text-yellow-600 dark:text-yellow-400">학습중</span>
                </div>
                <p className="text-xs text-gray-600 dark:text-gray-400">
                  분산 시스템 설계 원칙 학습 필요
                </p>
              </div>
              <div className="p-3 border border-gray-200 dark:border-gray-700 rounded-lg">
                <div className="flex items-center justify-between mb-2">
                  <span className="font-medium">계층형 아키텍처</span>
                  <span className="text-sm text-green-600 dark:text-green-400">완료</span>
                </div>
                <p className="text-xs text-gray-600 dark:text-gray-400">
                  3-tier, n-tier 구조 이해 완료
                </p>
              </div>
              <div className="p-3 border border-gray-200 dark:border-gray-700 rounded-lg">
                <div className="flex items-center justify-between mb-2">
                  <span className="font-medium">이벤트 기반</span>
                  <span className="text-sm text-red-600 dark:text-red-400">미학습</span>
                </div>
                <p className="text-xs text-gray-600 dark:text-gray-400">
                  Event-driven architecture 학습 예정
                </p>
              </div>
            </div>
          </div>
        </NotionCard>
      </div>

      {/* 실전 문제 */}
      <NotionCard title="실전 설계 문제" icon={<BookOpen className="w-5 h-5" />}>
        <div className="p-6">
          <div className="p-4 bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg text-white">
            <h3 className="text-lg font-semibold mb-2">오늘의 설계 챌린지</h3>
            <p className="mb-4">
              온라인 쇼핑몰 시스템의 클래스 다이어그램을 설계하고,
              주요 디자인 패턴을 적용해보세요.
            </p>
            <div className="flex items-center gap-4 text-sm mb-4">
              <span>난이도: ⭐⭐⭐⭐</span>
              <span>예상 시간: 30분</span>
              <span>보상: 100XP</span>
            </div>
            <button className="px-4 py-2 bg-white text-blue-600 rounded-lg hover:bg-gray-100">
              도전하기
            </button>
          </div>
        </div>
      </NotionCard>
    </div>
  );
}