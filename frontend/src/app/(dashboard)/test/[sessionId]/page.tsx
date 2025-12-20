'use client';

import { useState, useEffect, useMemo } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useAuth } from '@clerk/nextjs';
import {
  ChevronLeft,
  ChevronRight,
  Clock,
  Send,
  AlertCircle,
  Loader2,
  Grid,
  X,
} from 'lucide-react';

interface QuestionOption {
  number: number;
  text: string;
}

interface Question {
  id: string;
  question_number: number;
  question_text: string;
  options: QuestionOption[];
  passage?: string;
}

interface TestSession {
  session_id: string;
  questions: Question[];
  total_questions: number;
  time_limit_minutes: number | null;
}

interface Answer {
  question_id: string;
  selected_option: number | null;
}

export default function TestSessionPage() {
  const params = useParams();
  const router = useRouter();
  const { getToken } = useAuth();

  const sessionId = params.sessionId as string;

  const [session, setSession] = useState<TestSession | null>(null);
  const [answers, setAnswers] = useState<Answer[]>([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showNavGrid, setShowNavGrid] = useState(false);
  const [startTime] = useState(Date.now());
  const [elapsedTime, setElapsedTime] = useState(0);

  // Load session data
  useEffect(() => {
    const loadSession = async () => {
      try {
        // Try to get from sessionStorage first
        const stored = sessionStorage.getItem('testSession');
        if (stored) {
          const data = JSON.parse(stored);
          if (data.session_id === sessionId) {
            setSession(data);
            setAnswers(
              data.questions.map((q: Question) => ({
                question_id: q.id,
                selected_option: null,
              }))
            );
            setLoading(false);
            return;
          }
        }

        // If not in sessionStorage, redirect to test page
        router.push('/dashboard/test');
      } catch (err) {
        console.error('Failed to load session:', err);
        setError('세션 데이터를 불러오는데 실패했습니다.');
        setLoading(false);
      }
    };

    loadSession();
  }, [sessionId, router]);

  // Timer
  useEffect(() => {
    const interval = setInterval(() => {
      setElapsedTime(Math.floor((Date.now() - startTime) / 1000));
    }, 1000);

    return () => clearInterval(interval);
  }, [startTime]);

  const formatTime = (seconds: number) => {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    if (h > 0) {
      return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    }
    return `${m}:${s.toString().padStart(2, '0')}`;
  };

  const currentQuestion = useMemo(() => {
    return session?.questions[currentIndex];
  }, [session, currentIndex]);

  const answeredCount = useMemo(() => {
    return answers.filter((a) => a.selected_option !== null).length;
  }, [answers]);

  const handleSelectOption = (optionNumber: number) => {
    setAnswers((prev) =>
      prev.map((a, i) =>
        i === currentIndex ? { ...a, selected_option: optionNumber } : a
      )
    );
  };

  const handleNext = () => {
    if (session && currentIndex < session.questions.length - 1) {
      setCurrentIndex((prev) => prev + 1);
    }
  };

  const handlePrev = () => {
    if (currentIndex > 0) {
      setCurrentIndex((prev) => prev - 1);
    }
  };

  const handleNavigate = (index: number) => {
    setCurrentIndex(index);
    setShowNavGrid(false);
  };

  const handleSubmit = async () => {
    const unanswered = answers.filter((a) => a.selected_option === null).length;
    if (unanswered > 0) {
      const confirmed = confirm(
        `아직 ${unanswered}개 문제에 답하지 않았습니다.\n그래도 제출하시겠습니까?`
      );
      if (!confirmed) return;
    } else {
      const confirmed = confirm('답안을 제출하시겠습니까?');
      if (!confirmed) return;
    }

    try {
      setSubmitting(true);
      const token = await getToken();

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/v1/tests/submit`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            session_id: sessionId,
            answers: answers.filter((a) => a.selected_option !== null),
          }),
        }
      );

      if (!response.ok) {
        throw new Error('제출에 실패했습니다.');
      }

      // Clear session storage
      sessionStorage.removeItem('testSession');

      // Navigate to result page
      router.push(`/dashboard/test/result/${sessionId}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : '오류가 발생했습니다.');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  if (error || !session || !currentQuestion) {
    return (
      <div className="max-w-2xl mx-auto py-12 text-center">
        <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
        <h2 className="text-xl font-semibold text-gray-900 mb-2">오류 발생</h2>
        <p className="text-gray-600 mb-4">{error || '세션을 찾을 수 없습니다.'}</p>
        <button
          onClick={() => router.push('/dashboard/test')}
          className="text-blue-600 hover:underline"
        >
          돌아가기
        </button>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto">
      {/* Header */}
      <div className="bg-white rounded-lg border border-gray-200 p-4 mb-4 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="text-lg font-semibold">
            {currentIndex + 1} / {session.total_questions}
          </div>
          <div className="w-48 bg-gray-200 rounded-full h-2">
            <div
              className="bg-blue-600 h-2 rounded-full transition-all"
              style={{
                width: `${((currentIndex + 1) / session.total_questions) * 100}%`,
              }}
            />
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2 text-gray-600">
            <Clock className="w-4 h-4" />
            <span className="font-mono">{formatTime(elapsedTime)}</span>
          </div>

          <button
            onClick={() => setShowNavGrid(true)}
            className="flex items-center gap-2 px-3 py-1 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
          >
            <Grid className="w-4 h-4" />
            <span className="text-sm">문제 목록</span>
          </button>

          <button
            onClick={handleSubmit}
            disabled={submitting}
            className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:bg-gray-300"
          >
            {submitting ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <Send className="w-4 h-4" />
            )}
            제출 ({answeredCount}/{session.total_questions})
          </button>
        </div>
      </div>

      {/* Question Card */}
      <div className="bg-white rounded-lg border border-gray-200 p-6 mb-4">
        {/* Passage (if exists) */}
        {currentQuestion.passage && (
          <div className="mb-6 p-4 bg-gray-50 rounded-lg border-l-4 border-blue-400">
            <p className="text-sm text-gray-600 mb-2 font-medium">[지문]</p>
            <p className="text-gray-800 whitespace-pre-wrap">
              {currentQuestion.passage}
            </p>
          </div>
        )}

        {/* Question */}
        <div className="mb-6">
          <div className="flex items-start gap-3">
            <span className="flex-shrink-0 w-8 h-8 bg-blue-100 text-blue-600 rounded-full text-sm font-bold flex items-center justify-center">
              {currentQuestion.question_number}
            </span>
            <p className="text-lg text-gray-900 leading-relaxed">
              {currentQuestion.question_text}
            </p>
          </div>
        </div>

        {/* Options */}
        <div className="space-y-3">
          {currentQuestion.options.map((option) => {
            const isSelected =
              answers[currentIndex]?.selected_option === option.number;

            return (
              <button
                key={option.number}
                onClick={() => handleSelectOption(option.number)}
                className={`w-full text-left p-4 rounded-lg border-2 transition-all ${
                  isSelected
                    ? 'border-blue-500 bg-blue-50'
                    : 'border-gray-200 hover:border-blue-300 hover:bg-gray-50'
                }`}
              >
                <div className="flex items-start gap-3">
                  <span
                    className={`flex-shrink-0 w-6 h-6 rounded-full text-sm font-medium flex items-center justify-center ${
                      isSelected
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-200 text-gray-600'
                    }`}
                  >
                    {option.number}
                  </span>
                  <span className="text-gray-800">{option.text}</span>
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Navigation */}
      <div className="flex items-center justify-between">
        <button
          onClick={handlePrev}
          disabled={currentIndex === 0}
          className="flex items-center gap-2 px-4 py-2 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <ChevronLeft className="w-4 h-4" />
          이전
        </button>

        <div className="flex gap-1">
          {session.questions.slice(
            Math.max(0, currentIndex - 2),
            Math.min(session.questions.length, currentIndex + 3)
          ).map((_, i) => {
            const actualIndex = Math.max(0, currentIndex - 2) + i;
            const isAnswered = answers[actualIndex]?.selected_option !== null;
            const isCurrent = actualIndex === currentIndex;

            return (
              <button
                key={actualIndex}
                onClick={() => setCurrentIndex(actualIndex)}
                className={`w-8 h-8 rounded-lg text-sm font-medium transition-colors ${
                  isCurrent
                    ? 'bg-blue-600 text-white'
                    : isAnswered
                    ? 'bg-green-100 text-green-700 hover:bg-green-200'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {actualIndex + 1}
              </button>
            );
          })}
        </div>

        <button
          onClick={handleNext}
          disabled={currentIndex === session.questions.length - 1}
          className="flex items-center gap-2 px-4 py-2 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          다음
          <ChevronRight className="w-4 h-4" />
        </button>
      </div>

      {/* Navigation Grid Modal */}
      {showNavGrid && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-lg w-full mx-4 max-h-[80vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold">문제 목록</h3>
              <button
                onClick={() => setShowNavGrid(false)}
                className="p-1 hover:bg-gray-100 rounded"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="grid grid-cols-10 gap-2 mb-4">
              {session.questions.map((_, i) => {
                const isAnswered = answers[i]?.selected_option !== null;
                const isCurrent = i === currentIndex;

                return (
                  <button
                    key={i}
                    onClick={() => handleNavigate(i)}
                    className={`w-8 h-8 rounded text-sm font-medium transition-colors ${
                      isCurrent
                        ? 'bg-blue-600 text-white'
                        : isAnswered
                        ? 'bg-green-500 text-white'
                        : 'bg-gray-200 text-gray-600 hover:bg-gray-300'
                    }`}
                  >
                    {i + 1}
                  </button>
                );
              })}
            </div>

            <div className="flex items-center gap-4 text-sm text-gray-600">
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 bg-green-500 rounded" />
                <span>답변 완료 ({answeredCount})</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 bg-gray-200 rounded" />
                <span>미답변 ({session.total_questions - answeredCount})</span>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
