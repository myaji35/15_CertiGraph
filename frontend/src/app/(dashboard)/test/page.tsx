'use client';

import { NotionCard, NotionPageHeader, NotionStatCard } from '@/components/ui/NotionCard';
import { FileText, Play, Clock, Trophy, AlertCircle, CheckCircle } from 'lucide-react';
import { useState } from 'react';

export default function TestPage() {
  const [mockExams] = useState([
    {
      id: 1,
      title: "2024년 정보처리기사 실기 모의고사 #1",
      questions: 100,
      duration: 180,
      difficulty: "실전",
      attempts: 2,
      bestScore: 78
    },
    {
      id: 2,
      title: "2024년 정보처리기사 필기 모의고사 #3",
      questions: 100,
      duration: 120,
      difficulty: "중급",
      attempts: 0,
      bestScore: null
    },
    {
      id: 3,
      title: "데이터베이스 집중 모의고사",
      questions: 50,
      duration: 60,
      difficulty: "고급",
      attempts: 1,
      bestScore: 84
    }
  ]);

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="모의고사"
        icon="📝"
        breadcrumbs={[
          { label: '홈' },
          { label: '모의고사' }
        ]}
        actions={
          <button className="flex items-center gap-2 px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors">
            <Play className="w-4 h-4" />
            <span>빠른 시험 시작</span>
          </button>
        }
      />

      {/* 통계 카드 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <NotionStatCard
          title="응시한 모의고사"
          value={5}
          icon={<FileText className="w-5 h-5 text-blue-500" />}
          description="총 10개 중"
        />
        <NotionStatCard
          title="평균 점수"
          value="72%"
          icon={<Trophy className="w-5 h-5 text-yellow-500" />}
          trend={{ value: 5, isUp: true }}
        />
        <NotionStatCard
          title="총 학습 시간"
          value="8.5h"
          icon={<Clock className="w-5 h-5 text-purple-500" />}
        />
        <NotionStatCard
          title="합격 예상률"
          value="65%"
          icon={<CheckCircle className="w-5 h-5 text-green-500" />}
          trend={{ value: 12, isUp: true }}
        />
      </div>

      {/* 추천 모의고사 */}
      <NotionCard title="오늘의 추천 모의고사" icon={<AlertCircle className="w-5 h-5" />}>
        <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
          <div className="flex items-start justify-between">
            <div>
              <h3 className="font-semibold text-lg text-gray-900 dark:text-gray-100">
                취약 분야 집중 모의고사
              </h3>
              <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                최근 학습 데이터 기반으로 취약한 부분을 집중 테스트합니다
              </p>
              <div className="flex items-center gap-4 mt-3 text-sm">
                <span className="flex items-center gap-1">
                  <FileText className="w-4 h-4" />
                  30문제
                </span>
                <span className="flex items-center gap-1">
                  <Clock className="w-4 h-4" />
                  45분
                </span>
                <span className="px-2 py-1 bg-orange-100 dark:bg-orange-900 text-orange-700 dark:text-orange-300 rounded">
                  맞춤형
                </span>
              </div>
            </div>
            <button className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors">
              시작하기
            </button>
          </div>
        </div>
      </NotionCard>

      {/* 모의고사 목록 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <NotionCard title="최신 모의고사" icon={<FileText className="w-5 h-5" />}>
          <div className="space-y-3 p-4">
            {mockExams.map((exam) => (
              <div
                key={exam.id}
                className="p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer transition-colors"
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <h4 className="font-medium text-gray-900 dark:text-gray-100">
                      {exam.title}
                    </h4>
                    <div className="flex items-center gap-3 mt-2 text-sm text-gray-600 dark:text-gray-400">
                      <span>{exam.questions}문제</span>
                      <span>•</span>
                      <span>{exam.duration}분</span>
                      <span>•</span>
                      <span>{exam.difficulty}</span>
                    </div>
                    {exam.attempts > 0 && (
                      <div className="mt-2 text-sm">
                        <span className="text-gray-500">최고 점수: </span>
                        <span className="font-medium text-blue-600 dark:text-blue-400">
                          {exam.bestScore}점
                        </span>
                      </div>
                    )}
                  </div>
                  <button className="px-3 py-1 bg-gray-100 dark:bg-gray-700 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors">
                    {exam.attempts > 0 ? '재응시' : '시작'}
                  </button>
                </div>
              </div>
            ))}
          </div>
        </NotionCard>

        <NotionCard title="시험 결과 히스토리" icon={<Trophy className="w-5 h-5" />}>
          <div className="p-4">
            <div className="space-y-3">
              <div className="flex items-center justify-between p-3 border-l-4 border-green-500 bg-green-50 dark:bg-green-900/20">
                <div>
                  <p className="font-medium">필기 모의고사 #2</p>
                  <p className="text-sm text-gray-600 dark:text-gray-400">2일 전</p>
                </div>
                <span className="text-lg font-bold text-green-600 dark:text-green-400">85점</span>
              </div>
              <div className="flex items-center justify-between p-3 border-l-4 border-yellow-500 bg-yellow-50 dark:bg-yellow-900/20">
                <div>
                  <p className="font-medium">실기 모의고사 #1</p>
                  <p className="text-sm text-gray-600 dark:text-gray-400">5일 전</p>
                </div>
                <span className="text-lg font-bold text-yellow-600 dark:text-yellow-400">72점</span>
              </div>
              <div className="flex items-center justify-between p-3 border-l-4 border-red-500 bg-red-50 dark:bg-red-900/20">
                <div>
                  <p className="font-medium">종합 모의고사</p>
                  <p className="text-sm text-gray-600 dark:text-gray-400">1주 전</p>
                </div>
                <span className="text-lg font-bold text-red-600 dark:text-red-400">58점</span>
              </div>
            </div>
          </div>
        </NotionCard>
      </div>

      {/* 시험 유형별 카테고리 */}
      <NotionCard title="시험 유형별 선택" icon={<FileText className="w-5 h-5" />}>
        <div className="p-4 grid grid-cols-2 md:grid-cols-4 gap-4">
          <button className="p-4 text-center border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors">
            <div className="text-2xl mb-2">⚡</div>
            <div className="font-medium">빠른 테스트</div>
            <div className="text-sm text-gray-500">10분 / 20문제</div>
          </button>
          <button className="p-4 text-center border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors">
            <div className="text-2xl mb-2">📚</div>
            <div className="font-medium">단원별</div>
            <div className="text-sm text-gray-500">선택 학습</div>
          </button>
          <button className="p-4 text-center border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors">
            <div className="text-2xl mb-2">🎯</div>
            <div className="font-medium">실전 모의</div>
            <div className="text-sm text-gray-500">실제 시험 형식</div>
          </button>
          <button className="p-4 text-center border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors">
            <div className="text-2xl mb-2">🔥</div>
            <div className="font-medium">오답 복습</div>
            <div className="text-sm text-gray-500">틀린 문제만</div>
          </button>
        </div>
      </NotionCard>
    </div>
  );
}