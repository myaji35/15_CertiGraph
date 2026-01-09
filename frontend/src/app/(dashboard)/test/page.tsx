'use client';

import { NotionCard, NotionPageHeader, NotionStatCard } from '@/components/ui/NotionCard';
import { FileText, Play, Clock, Trophy, AlertCircle, CheckCircle, X, ChevronRight } from 'lucide-react';
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
  certification_id?: string;
  total_materials: number;
  total_questions: number;
  created_at: string;
}

export default function TestPage() {
  const { getToken, isLoaded, isSignedIn } = useAuth();
  const router = useRouter();
  const [testHistory, setTestHistory] = useState<TestSession[]>([]);
  const [studySets, setStudySets] = useState<StudySet[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [selectedMode, setSelectedMode] = useState<'all' | 'random' | 'timed'>('all');
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
        // Filter only study sets with questions
        const setsWithQuestions = (studySetsData.data || []).filter((s: StudySet) => s.total_questions > 0);
        setStudySets(setsWithQuestions);
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
        router.push(`/dashboard/test/${data.data.session_id}`);
      } else {
        alert('테스트 시작에 실패했습니다.');
      }
    } catch (error) {
      console.error('테스트 시작 실패:', error);
      alert('테스트 시작 중 오류가 발생했습니다.');
    }
  };

  const handleQuickStart = () => {
    if (studySets.length === 0) {
      alert('학습 세트가 없습니다. 먼저 PDF를 업로드해주세요.');
      return;
    }
    setShowModal(true);
  };

  const handleStartExam = (studySetId: string) => {
    setShowModal(false);
    startTest(studySetId, selectedMode);
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
        title="실전 모의고사"
        icon="📝"
        breadcrumbs={[
          { label: '홈' },
          { label: '모의고사' }
        ]}
        actions={
          <button
            onClick={handleQuickStart}
            disabled={studySets.length === 0}
            className="flex items-center gap-2 px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Play className="w-4 h-4" />
            <span>시험 시작</span>
          </button>
        }
      />

      {/* 통계 카드 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <NotionStatCard
          title="응시한 모의고사"
          value={loading ? '-' : stats.totalTests}
          icon={<FileText className="w-5 h-5 text-blue-500" />}
          description={`총 ${studySets.length}개 세트 사용 가능`}
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
      {studySets.length > 0 && (
        <NotionCard title="오늘의 추천 모의고사" icon={<AlertCircle className="w-5 h-5" />}>
          <div className="p-4 bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
            <div className="flex items-start justify-between">
              <div>
                <h3 className="font-semibold text-lg text-gray-900 dark:text-gray-100">
                  {studySets[0].name}
                </h3>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  최신 학습 세트로 실전 감각을 익혀보세요
                </p>
                <div className="flex items-center gap-4 mt-3 text-sm">
                  <span className="flex items-center gap-1">
                    <FileText className="w-4 h-4" />
                    {studySets[0].total_questions}문제
                  </span>
                  <span className="flex items-center gap-1">
                    <Clock className="w-4 h-4" />
                    {Math.ceil(studySets[0].total_questions * 1.5)}분
                  </span>
                  <span className="px-2 py-1 bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300 rounded">
                    실전 모의
                  </span>
                </div>
              </div>
              <button
                onClick={() => startTest(studySets[0].id, 'all')}
                className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
              >
                시작하기
              </button>
            </div>
          </div>
        </NotionCard>
      )}

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
                  className="p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors group"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <h4 className="font-medium text-gray-900 dark:text-gray-100 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                        {studySet.name}
                      </h4>
                      <div className="flex items-center gap-3 mt-2 text-sm text-gray-600 dark:text-gray-400">
                        <span>{studySet.total_questions}문제</span>
                        <span>•</span>
                        <span>{studySet.total_materials}개 자료</span>
                      </div>
                    </div>
                    <button
                      onClick={() => startTest(studySet.id, 'all')}
                      className="px-3 py-1 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors flex items-center gap-1"
                    >
                      시작
                      <ChevronRight className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>
        </NotionCard>

        <NotionCard title="최근 시험 결과" icon={<Trophy className="w-5 h-5" />}>
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
                      className={`flex items-center justify-between p-3 border-l-4 border-${color}-500 bg-${color}-50 dark:bg-${color}-900/20 cursor-pointer hover:opacity-80 transition-opacity rounded-r-lg`}
                      onClick={() => router.push(`/dashboard/test/result/${test.id}`)}
                    >
                      <div>
                        <p className="font-medium">
                          {test.mode === 'all' ? '실전 모의고사' : test.mode === 'random' ? '랜덤 테스트' : '오답 복습'}
                        </p>
                        <p className="text-sm text-gray-600 dark:text-gray-400">
                          {formatDate(test.completed_at || test.started_at)} • {test.total_questions}문제
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
      <NotionCard title="시험 유형 선택" icon={<FileText className="w-5 h-5" />}>
        <div className="p-4 grid grid-cols-2 md:grid-cols-4 gap-4">
          <button
            onClick={() => {
              setSelectedMode('random');
              handleQuickStart();
            }}
            disabled={studySets.length === 0}
            className="p-6 text-center border-2 border-gray-200 dark:border-gray-700 rounded-xl hover:border-blue-500 dark:hover:border-blue-500 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-all disabled:opacity-50 disabled:cursor-not-allowed group"
          >
            <div className="text-3xl mb-3">⚡</div>
            <div className="font-semibold text-lg mb-1">빠른 테스트</div>
            <div className="text-sm text-gray-500 dark:text-gray-400">랜덤 20문제</div>
          </button>
          <button
            onClick={() => router.push('/dashboard/study-sets')}
            className="p-6 text-center border-2 border-gray-200 dark:border-gray-700 rounded-xl hover:border-purple-500 dark:hover:border-purple-500 hover:bg-purple-50 dark:hover:bg-purple-900/20 transition-all group"
          >
            <div className="text-3xl mb-3">📚</div>
            <div className="font-semibold text-lg mb-1">학습 세트</div>
            <div className="text-sm text-gray-500 dark:text-gray-400">세트별 학습</div>
          </button>
          <button
            onClick={() => {
              setSelectedMode('all');
              handleQuickStart();
            }}
            disabled={studySets.length === 0}
            className="p-6 text-center border-2 border-gray-200 dark:border-gray-700 rounded-xl hover:border-green-500 dark:hover:border-green-500 hover:bg-green-50 dark:hover:bg-green-900/20 transition-all disabled:opacity-50 disabled:cursor-not-allowed group"
          >
            <div className="text-3xl mb-3">🎯</div>
            <div className="font-semibold text-lg mb-1">실전 모의</div>
            <div className="text-sm text-gray-500 dark:text-gray-400">전체 문제</div>
          </button>
          <button
            onClick={() => router.push('/dashboard/test/retry')}
            disabled={testHistory.filter(t => t.score && t.score < 100).length === 0}
            className="p-6 text-center border-2 border-gray-200 dark:border-gray-700 rounded-xl hover:border-orange-500 dark:hover:border-orange-500 hover:bg-orange-50 dark:hover:bg-orange-900/20 transition-all disabled:opacity-50 disabled:cursor-not-allowed group"
          >
            <div className="text-3xl mb-3">🔥</div>
            <div className="font-semibold text-lg mb-1">오답 복습</div>
            <div className="text-sm text-gray-500 dark:text-gray-400">틀린 문제만</div>
          </button>
        </div>
      </NotionCard>

      {/* Study Set Selection Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 p-4">
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-xl w-full max-w-2xl max-h-[80vh] overflow-hidden flex flex-col">
            {/* Modal Header */}
            <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-gray-100">
                학습 세트 선택
              </h2>
              <button
                onClick={() => setShowModal(false)}
                className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
              >
                <X className="w-5 h-5 text-gray-500 dark:text-gray-400" />
              </button>
            </div>

            {/* Exam Mode Selection */}
            <div className="p-6 border-b border-gray-200 dark:border-gray-700">
              <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">시험 모드</h3>
              <div className="grid grid-cols-3 gap-3">
                <button
                  onClick={() => setSelectedMode('all')}
                  className={`p-3 text-center border-2 rounded-lg transition-all ${selectedMode === 'all'
                      ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300'
                      : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
                    }`}
                >
                  <div className="font-medium">전체 문제</div>
                  <div className="text-xs text-gray-500 dark:text-gray-400 mt-1">실전 모의</div>
                </button>
                <button
                  onClick={() => setSelectedMode('random')}
                  className={`p-3 text-center border-2 rounded-lg transition-all ${selectedMode === 'random'
                      ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300'
                      : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
                    }`}
                >
                  <div className="font-medium">랜덤 20문제</div>
                  <div className="text-xs text-gray-500 dark:text-gray-400 mt-1">빠른 테스트</div>
                </button>
                <button
                  onClick={() => setSelectedMode('timed')}
                  className={`p-3 text-center border-2 rounded-lg transition-all ${selectedMode === 'timed'
                      ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300'
                      : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
                    }`}
                >
                  <div className="font-medium">시간 제한</div>
                  <div className="text-xs text-gray-500 dark:text-gray-400 mt-1">실전 연습</div>
                </button>
              </div>
            </div>

            {/* Study Sets List */}
            <div className="flex-1 overflow-y-auto p-6">
              <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">학습 세트 목록</h3>
              <div className="space-y-2">
                {studySets.map((studySet) => (
                  <button
                    key={studySet.id}
                    onClick={() => handleStartExam(studySet.id)}
                    className="w-full p-4 text-left border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors group"
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <h4 className="font-medium text-gray-900 dark:text-gray-100 group-hover:text-blue-600 dark:group-hover:text-blue-400">
                          {studySet.name}
                        </h4>
                        <div className="flex items-center gap-3 mt-1 text-sm text-gray-600 dark:text-gray-400">
                          <span>{studySet.total_questions}문제</span>
                          <span>•</span>
                          <span>{studySet.total_materials}개 자료</span>
                          <span>•</span>
                          <span>{formatDate(studySet.created_at)}</span>
                        </div>
                      </div>
                      <ChevronRight className="w-5 h-5 text-gray-400 group-hover:text-blue-600 dark:group-hover:text-blue-400" />
                    </div>
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
