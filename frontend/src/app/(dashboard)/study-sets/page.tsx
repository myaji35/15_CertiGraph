'use client';

import { NotionCard, NotionPageHeader, NotionEmptyState } from '@/components/ui/NotionCard';
import { BookOpen, Plus, Clock, Brain, Target, TrendingUp } from 'lucide-react';
import { useState } from 'react';

export default function StudySetsPage() {
  const [studySets] = useState([
    {
      id: 1,
      title: "정보처리기사 실기 - 데이터베이스",
      questions: 85,
      completed: 45,
      lastStudied: "2시간 전",
      difficulty: "중급",
      accuracy: 78
    },
    {
      id: 2,
      title: "정보처리기사 실기 - 소프트웨어 설계",
      questions: 120,
      completed: 30,
      lastStudied: "1일 전",
      difficulty: "고급",
      accuracy: 65
    },
    {
      id: 3,
      title: "정보처리기사 필기 - 데이터통신",
      questions: 200,
      completed: 180,
      lastStudied: "3일 전",
      difficulty: "초급",
      accuracy: 92
    }
  ]);

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="학습 세트"
        icon="📚"
        breadcrumbs={[
          { label: '홈' },
          { label: '학습 세트' }
        ]}
        actions={
          <button className="flex items-center gap-2 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors">
            <Plus className="w-4 h-4" />
            <span>새 학습 세트</span>
          </button>
        }
      />

      {/* 통계 카드 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <NotionCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-100 dark:bg-blue-900 rounded-lg">
              <BookOpen className="w-5 h-5 text-blue-600 dark:text-blue-400" />
            </div>
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400">전체 학습 세트</p>
              <p className="text-2xl font-bold">{studySets.length}</p>
            </div>
          </div>
        </NotionCard>

        <NotionCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-green-100 dark:bg-green-900 rounded-lg">
              <Target className="w-5 h-5 text-green-600 dark:text-green-400" />
            </div>
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400">완료한 문제</p>
              <p className="text-2xl font-bold">255</p>
            </div>
          </div>
        </NotionCard>

        <NotionCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-purple-100 dark:bg-purple-900 rounded-lg">
              <Brain className="w-5 h-5 text-purple-600 dark:text-purple-400" />
            </div>
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400">평균 정답률</p>
              <p className="text-2xl font-bold">78%</p>
            </div>
          </div>
        </NotionCard>

        <NotionCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-orange-100 dark:bg-orange-900 rounded-lg">
              <Clock className="w-5 h-5 text-orange-600 dark:text-orange-400" />
            </div>
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400">학습 시간</p>
              <p className="text-2xl font-bold">24시간</p>
            </div>
          </div>
        </NotionCard>
      </div>

      {/* 학습 세트 목록 */}
      <NotionCard title="내 학습 세트" icon={<BookOpen className="w-5 h-5" />}>
        {studySets.length > 0 ? (
          <div className="space-y-3 p-4">
            {studySets.map((set) => (
              <div
                key={set.id}
                className="p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer transition-colors"
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <h3 className="font-semibold text-gray-900 dark:text-gray-100">
                      {set.title}
                    </h3>
                    <div className="flex items-center gap-4 mt-2 text-sm text-gray-600 dark:text-gray-400">
                      <span className="flex items-center gap-1">
                        <Clock className="w-3 h-3" />
                        {set.lastStudied}
                      </span>
                      <span>난이도: {set.difficulty}</span>
                      <span>정답률: {set.accuracy}%</span>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-lg font-semibold text-blue-600 dark:text-blue-400">
                      {set.completed}/{set.questions}
                    </div>
                    <div className="text-xs text-gray-500">문제 완료</div>
                    <div className="mt-2 w-32 bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                      <div
                        className="bg-blue-500 h-2 rounded-full"
                        style={{ width: `${(set.completed / set.questions) * 100}%` }}
                      />
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <NotionEmptyState
            icon={<BookOpen className="w-12 h-12 text-gray-400" />}
            title="학습 세트가 없습니다"
            description="첫 번째 학습 세트를 만들어 시작해보세요"
            action={{
              label: "학습 세트 만들기",
              onClick: () => console.log("Create study set")
            }}
          />
        )}
      </NotionCard>

      {/* 추천 학습 세트 */}
      <NotionCard title="추천 학습 세트" icon={<TrendingUp className="w-5 h-5" />}>
        <div className="p-4 grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="p-3 border border-gray-200 dark:border-gray-700 rounded-lg">
            <h4 className="font-medium">정보처리기사 필기 총정리</h4>
            <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">500문제 • 인기</p>
          </div>
          <div className="p-3 border border-gray-200 dark:border-gray-700 rounded-lg">
            <h4 className="font-medium">SQL 마스터 과정</h4>
            <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">200문제 • 추천</p>
          </div>
        </div>
      </NotionCard>
    </div>
  );
}