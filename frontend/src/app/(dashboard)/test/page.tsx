'use client';

import { NotionCard, NotionPageHeader, NotionStatCard } from '@/components/ui/NotionCard';
import { FileText, Play, Clock, Trophy, AlertCircle, CheckCircle } from 'lucide-react';
import { useState, useEffect } from 'react';
import { useAuth } from '@clerk/nextjs';
import { useRouter } from 'next/navigation';

interface TestSession {
  id: string;
  study_set_id: string;
  mode: string;
  status: string;
  total_questions: number;
  score: number | null;
  started_at: string;
  completed_at: string | null;
}

interface StudySet {
  id: string;
  name: string;
  certification_name: string;
  total_questions: number;
}

export default function TestPage() {
  const { getToken, isLoaded, isSignedIn } = useAuth();
  const router = useRouter();
  const [testHistory, setTestHistory] = useState<TestSession[]>([]);
  const [studySets, setStudySets] = useState<StudySet[]>([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    totalTests: 0,
    avgScore: 0,
    totalTime: 0,
    passRate: 0
  });

  useEffect(() => {
    if (isLoaded && isSignedIn) {
      fetchData();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isLoaded, isSignedIn]);

  const fetchData = async () => {
    try {
      setLoading(true);
      const token = await getToken();

      // 테스트 히스토리 가져오기
      const historyResponse = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/tests/history?limit=10`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      // 학습 세트 목록 가져오기
      const studySetsResponse = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/study-sets`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (historyResponse.ok) {
        const historyData = await historyResponse.json();
        setTestHistory(historyData.data || []);

        // 통계 계산
        const completed = (historyData.data || []).filter((t: TestSession) => t.status === 'completed');
        const avgScore = completed.length > 0
          ? completed.reduce((sum: number, t: TestSession) => sum + (t.score || 0), 0) / completed.length
          : 0;

        setStats({
          totalTests: completed.length,
          avgScore: Math.round(avgScore),
          totalTime: completed.length * 60, // 임시: 테스트당 60분 가정
          passRate: avgScore >= 60 ? Math.min(Math.round(avgScore * 1.2), 95) : Math.round(avgScore * 0.8)
        });
      }

      if (studySetsResponse.ok) {
        const studySetsData = await studySetsResponse.json();
        setStudySets(studySetsData.data || []);
      }
    } catch (error) {
      console.error('데이터 가져오기 실패:', error);
    } finally {
      setLoading(false);
    }
  };

  const startTest = async (studySetId: string, mode: string = 'all') => {
    try {
      const token = await getToken();
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/tests/start`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          study_set_id: studySetId,
          mode: mode,
          shuffle_options: true,
        }),
      });

      if (response.ok) {
        const data = await response.json();
        router.push(`/test/${data.data.session_id}`);
      } else {
        alert('테스트 시작에 실패했습니다.');
      }
    } catch (error) {
      console.error('테스트 시작 실패:', error);
      alert('테스트 시작 중 오류가 발생했습니다.');
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffInMs = now.getTime() - date.getTime();
    const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24));

    if (diffInDays === 0) return '오늘';
    if (diffInDays === 1) return '어제';
    if (diffInDays < 7) return `${diffInDays}일 전`;
    if (diffInDays < 30) return `${Math.floor(diffInDays / 7)}주 전`;
    return `${Math.floor(diffInDays / 30)}개월 전`;
  };

  const getScoreColor = (score: number) => {
    if (score >= 80) return 'green';
    if (score >= 60) return 'yellow';
    return 'red';
  };

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
          value={loading ? '-' : stats.totalTests}
          icon={<FileText className="w-5 h-5 text-blue-500" />}
          description={`총 ${studySets.length}개 중`}
        />
        <NotionStatCard
          title="평균 점수"
          value={loading ? '-' : `${stats.avgScore}%`}
          icon={<Trophy className="w-5 h-5 text-yellow-500" />}
          trend={stats.avgScore > 0 ? { value: 5, isUp: stats.avgScore >= 60 } : undefined}
        />
        <NotionStatCard
          title="총 학습 시간"
          value={loading ? '-' : `${(stats.totalTime / 60).toFixed(1)}h`}
          icon={<Clock className="w-5 h-5 text-purple-500" />}
        />
        <NotionStatCard
          title="합격 예상률"
          value={loading ? '-' : `${stats.passRate}%`}
          icon={<CheckCircle className="w-5 h-5 text-green-500" />}
          trend={stats.passRate > 0 ? { value: 12, isUp: stats.passRate >= 60 } : undefined}
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
        <NotionCard title="사용 가능한 학습 세트" icon={<FileText className="w-5 h-5" />}>
          <div className="space-y-3 p-4">
            {loading ? (
              <div className="text-center py-8 text-gray-500">로딩 중...</div>
            ) : studySets.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                아직 학습 세트가 없습니다.
                <br />
                <span className="text-sm">PDF를 업로드하여 학습 세트를 만들어보세요!</span>
              </div>
            ) : (
              studySets.slice(0, 5).map((studySet) => (
                <div
                  key={studySet.id}
                  className="p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer transition-colors"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <h4 className="font-medium text-gray-900 dark:text-gray-100">
                        {studySet.name}
                      </h4>
                      <div className="flex items-center gap-3 mt-2 text-sm text-gray-600 dark:text-gray-400">
                        <span>{studySet.total_questions}문제</span>
                        <span>•</span>
                        <span>{studySet.certification_name}</span>
                      </div>
                    </div>
                    <button
                      onClick={() => startTest(studySet.id, 'all')}
                      className="px-3 py-1 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
                    >
                      시작
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>
        </NotionCard>

        <NotionCard title="시험 결과 히스토리" icon={<Trophy className="w-5 h-5" />}>
          <div className="p-4">
            {loading ? (
              <div className="text-center py-8 text-gray-500">로딩 중...</div>
            ) : testHistory.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                아직 응시한 테스트가 없습니다.
              </div>
            ) : (
              <div className="space-y-3">
                {testHistory.slice(0, 5).map((test) => {
                  const score = test.score || 0;
                  const color = getScoreColor(score);
                  return (
                    <div
                      key={test.id}
                      className={`flex items-center justify-between p-3 border-l-4 border-${color}-500 bg-${color}-50 dark:bg-${color}-900/20 cursor-pointer hover:opacity-80 transition-opacity`}
                      onClick={() => router.push(`/test/result/${test.id}`)}
                    >
                      <div>
                        <p className="font-medium">
                          테스트 ({test.mode === 'all' ? '전체' : test.mode === 'random' ? '랜덤' : '오답'})
                        </p>
                        <p className="text-sm text-gray-600 dark:text-gray-400">
                          {formatDate(test.completed_at || test.started_at)}
                        </p>
                      </div>
                      <span className={`text-lg font-bold text-${color}-600 dark:text-${color}-400`}>
                        {score}점
                      </span>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </NotionCard>
      </div>

      {/* 시험 유형별 카테고리 */}
      <NotionCard title="시험 유형별 선택" icon={<FileText className="w-5 h-5" />}>
        <div className="p-4 grid grid-cols-2 md:grid-cols-4 gap-4">
          <button
            onClick={() => {
              if (studySets.length > 0) {
                startTest(studySets[0].id, 'random');
              } else {
                alert('학습 세트가 없습니다. 먼저 PDF를 업로드해주세요.');
              }
            }}
            disabled={studySets.length === 0}
            className="p-4 text-center border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <div className="text-2xl mb-2">⚡</div>
            <div className="font-medium">빠른 테스트</div>
            <div className="text-sm text-gray-500">랜덤 20문제</div>
          </button>
          <button
            onClick={() => router.push('/shuffle')}
            className="p-4 text-center border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
          >
            <div className="text-2xl mb-2">📚</div>
            <div className="font-medium">단원별</div>
            <div className="text-sm text-gray-500">선택 학습</div>
          </button>
          <button
            onClick={() => {
              if (studySets.length > 0) {
                startTest(studySets[0].id, 'all');
              } else {
                alert('학습 세트가 없습니다. 먼저 PDF를 업로드해주세요.');
              }
            }}
            disabled={studySets.length === 0}
            className="p-4 text-center border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <div className="text-2xl mb-2">🎯</div>
            <div className="font-medium">실전 모의</div>
            <div className="text-sm text-gray-500">전체 문제</div>
          </button>
          <button
            onClick={() => router.push('/test/retry')}
            disabled={testHistory.filter(t => t.score && t.score < 100).length === 0}
            className="p-4 text-center border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <div className="text-2xl mb-2">🔥</div>
            <div className="font-medium">오답 복습</div>
            <div className="text-sm text-gray-500">틀린 문제만</div>
          </button>
        </div>
      </NotionCard>
    </div>
  );
}