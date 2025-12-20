'use client';

import { useState, useEffect, Suspense } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import { useAuth } from '@clerk/nextjs';
import Link from 'next/link';
import {
  FileText,
  Play,
  Clock,
  Trophy,
  AlertCircle,
  Loader2,
  ArrowLeft,
  Shuffle,
  Target,
  RotateCcw,
} from 'lucide-react';

interface StudySet {
  id: string;
  name: string;
  question_count: number;
  status: string;
}

interface TestSession {
  id: string;
  study_set_id: string;
  study_set_name: string;
  score: number;
  total_questions: number;
  percentage: number;
  started_at: string;
  completed_at: string;
  mode: string;
}

type TestMode = 'all' | 'random' | 'wrong_only';

function TestPageContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const { getToken } = useAuth();

  const studySetId = searchParams.get('study_set_id');

  const [studySet, setStudySet] = useState<StudySet | null>(null);
  const [testHistory, setTestHistory] = useState<TestSession[]>([]);
  const [loading, setLoading] = useState(true);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Test options
  const [selectedMode, setSelectedMode] = useState<TestMode>('all');
  const [questionCount, setQuestionCount] = useState(20);
  const [shuffleOptions, setShuffleOptions] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const token = await getToken();
        if (!token) return;

        // Fetch study set if ID provided
        if (studySetId) {
          const response = await fetch(
            `${process.env.NEXT_PUBLIC_API_URL}/v1/study-sets/${studySetId}`,
            { headers: { Authorization: `Bearer ${token}` } }
          );
          if (response.ok) {
            const data = await response.json();
            setStudySet(data.data);
          }
        }

        // Fetch test history
        const historyUrl = studySetId
          ? `${process.env.NEXT_PUBLIC_API_URL}/v1/tests/history?study_set_id=${studySetId}`
          : `${process.env.NEXT_PUBLIC_API_URL}/v1/tests/history`;

        const historyResponse = await fetch(historyUrl, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (historyResponse.ok) {
          const data = await historyResponse.json();
          setTestHistory(data.data || []);
        }
      } catch (err) {
        console.error('Failed to fetch data:', err);
        setError('데이터를 불러오는데 실패했습니다.');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [studySetId, getToken]);

  const handleStartTest = async () => {
    if (!studySetId) return;

    try {
      setStarting(true);
      const token = await getToken();

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/v1/tests/start`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            study_set_id: studySetId,
            mode: selectedMode,
            question_count: selectedMode === 'random' ? questionCount : null,
            shuffle_options: shuffleOptions,
          }),
        }
      );

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error?.message || '테스트 시작에 실패했습니다.');
      }

      const data = await response.json();
      // Store session data in sessionStorage for the test page
      sessionStorage.setItem('testSession', JSON.stringify(data.data));
      router.push(`/dashboard/test/${data.data.session_id}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : '오류가 발생했습니다.');
    } finally {
      setStarting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  // If no study set ID, show study set selection
  if (!studySetId) {
    return (
      <div className="max-w-4xl mx-auto">
        <h1 className="text-2xl font-bold text-gray-900 mb-6">모의고사</h1>

        {/* Test History */}
        <div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <Trophy className="w-5 h-5 text-yellow-500" />
            최근 시험 결과
          </h2>
          {testHistory.length === 0 ? (
            <p className="text-gray-500 text-center py-8">
              아직 응시한 시험이 없습니다.
            </p>
          ) : (
            <div className="space-y-3">
              {testHistory.slice(0, 5).map((session) => (
                <Link
                  key={session.id}
                  href={`/dashboard/test/result/${session.id}`}
                  className="flex items-center justify-between p-4 rounded-lg border border-gray-100 hover:bg-gray-50 transition-colors"
                >
                  <div>
                    <p className="font-medium text-gray-900">
                      {session.study_set_name}
                    </p>
                    <p className="text-sm text-gray-500">
                      {new Date(session.completed_at).toLocaleDateString('ko-KR')}
                    </p>
                  </div>
                  <div
                    className={`text-lg font-bold ${
                      session.percentage >= 80
                        ? 'text-green-600'
                        : session.percentage >= 60
                        ? 'text-yellow-600'
                        : 'text-red-600'
                    }`}
                  >
                    {session.score}/{session.total_questions} ({session.percentage}%)
                  </div>
                </Link>
              ))}
            </div>
          )}
        </div>

        {/* Prompt to select study set */}
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 text-center">
          <AlertCircle className="w-12 h-12 text-blue-500 mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-blue-900 mb-2">
            학습 세트를 선택하세요
          </h3>
          <p className="text-blue-700 mb-4">
            모의고사를 시작하려면 먼저 학습 세트를 선택해야 합니다.
          </p>
          <Link
            href="/dashboard/study-sets"
            className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <FileText className="w-4 h-4" />
            학습 세트 목록
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto">
      {/* Back button */}
      <Link
        href={`/dashboard/study-sets/${studySetId}`}
        className="inline-flex items-center gap-2 text-gray-500 hover:text-gray-700 mb-4 transition-colors"
      >
        <ArrowLeft className="w-4 h-4" />
        학습 세트로 돌아가기
      </Link>

      {/* Header */}
      <div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
        <h1 className="text-2xl font-bold text-gray-900 mb-2">
          {studySet?.name || '모의고사'}
        </h1>
        <p className="text-gray-600">
          총 {studySet?.question_count || 0}개 문제
        </p>
      </div>

      {/* Test Options */}
      <div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">
          시험 옵션 설정
        </h2>

        {/* Mode Selection */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            출제 모드
          </label>
          <div className="grid grid-cols-1 gap-3">
            <button
              onClick={() => setSelectedMode('all')}
              className={`flex items-center gap-3 p-4 rounded-lg border-2 transition-colors ${
                selectedMode === 'all'
                  ? 'border-blue-500 bg-blue-50'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <Target className="w-5 h-5 text-blue-600" />
              <div className="text-left">
                <p className="font-medium">전체 문제</p>
                <p className="text-sm text-gray-500">
                  모든 문제를 순서대로 풀기
                </p>
              </div>
            </button>

            <button
              onClick={() => setSelectedMode('random')}
              className={`flex items-center gap-3 p-4 rounded-lg border-2 transition-colors ${
                selectedMode === 'random'
                  ? 'border-blue-500 bg-blue-50'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <Shuffle className="w-5 h-5 text-purple-600" />
              <div className="text-left">
                <p className="font-medium">랜덤 출제</p>
                <p className="text-sm text-gray-500">
                  무작위로 선택된 문제 풀기
                </p>
              </div>
            </button>

            <button
              onClick={() => setSelectedMode('wrong_only')}
              className={`flex items-center gap-3 p-4 rounded-lg border-2 transition-colors ${
                selectedMode === 'wrong_only'
                  ? 'border-blue-500 bg-blue-50'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <RotateCcw className="w-5 h-5 text-red-600" />
              <div className="text-left">
                <p className="font-medium">오답 복습</p>
                <p className="text-sm text-gray-500">
                  이전에 틀린 문제만 다시 풀기
                </p>
              </div>
            </button>
          </div>
        </div>

        {/* Question Count (for random mode) */}
        {selectedMode === 'random' && (
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              문제 수
            </label>
            <div className="flex gap-2">
              {[10, 20, 30, 50].map((count) => (
                <button
                  key={count}
                  onClick={() => setQuestionCount(count)}
                  className={`px-4 py-2 rounded-lg border-2 transition-colors ${
                    questionCount === count
                      ? 'border-blue-500 bg-blue-50 text-blue-700'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  {count}문제
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Shuffle Options */}
        <div className="mb-6">
          <label className="flex items-center gap-3 cursor-pointer">
            <input
              type="checkbox"
              checked={shuffleOptions}
              onChange={(e) => setShuffleOptions(e.target.checked)}
              className="w-5 h-5 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
            />
            <div>
              <p className="font-medium text-gray-900">보기 순서 섞기</p>
              <p className="text-sm text-gray-500">
                매번 다른 순서로 보기가 표시됩니다
              </p>
            </div>
          </label>
        </div>

        {/* Error Message */}
        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
            {error}
          </div>
        )}

        {/* Start Button */}
        <button
          onClick={handleStartTest}
          disabled={starting || !studySet || studySet.status !== 'ready'}
          className="w-full flex items-center justify-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
        >
          {starting ? (
            <>
              <Loader2 className="w-5 h-5 animate-spin" />
              시작 중...
            </>
          ) : (
            <>
              <Play className="w-5 h-5" />
              시험 시작
            </>
          )}
        </button>
      </div>

      {/* Test History for this study set */}
      {testHistory.length > 0 && (
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <Clock className="w-5 h-5 text-gray-500" />
            이전 시험 결과
          </h2>
          <div className="space-y-3">
            {testHistory.slice(0, 5).map((session) => (
              <Link
                key={session.id}
                href={`/dashboard/test/result/${session.id}`}
                className="flex items-center justify-between p-4 rounded-lg border border-gray-100 hover:bg-gray-50 transition-colors"
              >
                <div>
                  <p className="text-sm text-gray-500">
                    {new Date(session.completed_at).toLocaleDateString('ko-KR', {
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </p>
                </div>
                <div
                  className={`text-lg font-bold ${
                    session.percentage >= 80
                      ? 'text-green-600'
                      : session.percentage >= 60
                      ? 'text-yellow-600'
                      : 'text-red-600'
                  }`}
                >
                  {session.percentage}%
                </div>
              </Link>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

export default function TestPage() {
  return (
    <Suspense
      fallback={
        <div className="flex items-center justify-center py-12">
          <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
        </div>
      }
    >
      <TestPageContent />
    </Suspense>
  );
}
