'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useAuth } from '@clerk/nextjs';
import Link from 'next/link';
import {
  Trophy,
  Clock,
  CheckCircle,
  XCircle,
  RotateCcw,
  ArrowLeft,
  Loader2,
  AlertCircle,
  ChevronDown,
  ChevronUp,
} from 'lucide-react';

interface QuestionOption {
  number: number;
  text: string;
}

interface QuestionResult {
  id: string;
  question_number: number;
  question_text: string;
  options: QuestionOption[];
  correct_answer: number;
  selected_answer: number | null;
  is_correct: boolean;
  explanation: string | null;
}

interface TestResult {
  session_id: string;
  score: number;
  total: number;
  percentage: number;
  time_taken_seconds: number;
  completed_at: string;
  questions: QuestionResult[];
}

export default function TestResultPage() {
  const params = useParams();
  const router = useRouter();
  const { getToken } = useAuth();

  const sessionId = params.sessionId as string;

  const [result, setResult] = useState<TestResult | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [expandedQuestions, setExpandedQuestions] = useState<Set<string>>(new Set());

  useEffect(() => {
    const fetchResult = async () => {
      try {
        const token = await getToken();
        if (!token) return;

        const response = await fetch(
          `${process.env.NEXT_PUBLIC_API_URL}/v1/tests/${sessionId}/result`,
          {
            headers: { Authorization: `Bearer ${token}` },
          }
        );

        if (!response.ok) {
          throw new Error('결과를 불러오는데 실패했습니다.');
        }

        const data = await response.json();
        setResult(data.data);
      } catch (err) {
        console.error('Failed to fetch result:', err);
        setError(err instanceof Error ? err.message : '오류가 발생했습니다.');
      } finally {
        setLoading(false);
      }
    };

    fetchResult();
  }, [sessionId, getToken]);

  const formatTime = (seconds: number) => {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    if (h > 0) {
      return `${h}시간 ${m}분 ${s}초`;
    }
    return `${m}분 ${s}초`;
  };

  const getGradeBadge = (percentage: number) => {
    if (percentage >= 80) {
      return {
        label: '우수',
        color: 'bg-green-100 text-green-700 border-green-200',
      };
    } else if (percentage >= 60) {
      return {
        label: '양호',
        color: 'bg-yellow-100 text-yellow-700 border-yellow-200',
      };
    } else {
      return {
        label: '노력 필요',
        color: 'bg-red-100 text-red-700 border-red-200',
      };
    }
  };

  const toggleQuestion = (id: string) => {
    setExpandedQuestions((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  const expandAll = () => {
    if (!result) return;
    setExpandedQuestions(new Set(result.questions.map((q) => q.id)));
  };

  const collapseAll = () => {
    setExpandedQuestions(new Set());
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  if (error || !result) {
    return (
      <div className="max-w-2xl mx-auto py-12 text-center">
        <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
        <h2 className="text-xl font-semibold text-gray-900 mb-2">오류 발생</h2>
        <p className="text-gray-600 mb-4">{error || '결과를 찾을 수 없습니다.'}</p>
        <Link
          href="/dashboard/test"
          className="text-blue-600 hover:underline"
        >
          돌아가기
        </Link>
      </div>
    );
  }

  const grade = getGradeBadge(result.percentage);
  const wrongQuestions = result.questions.filter((q) => !q.is_correct);

  return (
    <div className="max-w-4xl mx-auto">
      {/* Back button */}
      <Link
        href="/dashboard/test"
        className="inline-flex items-center gap-2 text-gray-500 hover:text-gray-700 mb-4 transition-colors"
      >
        <ArrowLeft className="w-4 h-4" />
        모의고사로 돌아가기
      </Link>

      {/* Result Summary */}
      <div className="bg-white rounded-lg border border-gray-200 p-8 mb-6 text-center">
        <Trophy
          className={`w-16 h-16 mx-auto mb-4 ${
            result.percentage >= 80
              ? 'text-yellow-500'
              : result.percentage >= 60
              ? 'text-gray-400'
              : 'text-gray-300'
          }`}
        />

        <div className="text-5xl font-bold text-gray-900 mb-2">
          {result.score} / {result.total}
        </div>

        <div className="text-2xl text-gray-600 mb-4">
          {result.percentage}%
        </div>

        <div
          className={`inline-block px-4 py-2 rounded-full border ${grade.color} font-medium`}
        >
          {grade.label}
        </div>

        <div className="flex items-center justify-center gap-6 mt-6 text-gray-600">
          <div className="flex items-center gap-2">
            <Clock className="w-5 h-5" />
            <span>{formatTime(result.time_taken_seconds)}</span>
          </div>
          <div className="flex items-center gap-2">
            <CheckCircle className="w-5 h-5 text-green-500" />
            <span>정답 {result.score}개</span>
          </div>
          <div className="flex items-center gap-2">
            <XCircle className="w-5 h-5 text-red-500" />
            <span>오답 {result.total - result.score}개</span>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center justify-center gap-4 mt-8">
          <Link
            href={`/dashboard/test?study_set_id=${sessionId}`}
            className="inline-flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <RotateCcw className="w-4 h-4" />
            다시 풀기
          </Link>

          {wrongQuestions.length > 0 && (
            <button
              onClick={() => {
                // TODO: Start wrong-only test
                alert('오답 복습 기능은 준비 중입니다.');
              }}
              className="inline-flex items-center gap-2 px-6 py-3 bg-red-100 text-red-700 rounded-lg hover:bg-red-200 transition-colors"
            >
              <XCircle className="w-4 h-4" />
              오답만 다시 풀기 ({wrongQuestions.length}문제)
            </button>
          )}
        </div>
      </div>

      {/* Question Review */}
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-gray-900">문제 리뷰</h2>
          <div className="flex gap-2">
            <button
              onClick={expandAll}
              className="text-sm text-blue-600 hover:underline"
            >
              모두 펼치기
            </button>
            <span className="text-gray-300">|</span>
            <button
              onClick={collapseAll}
              className="text-sm text-blue-600 hover:underline"
            >
              모두 접기
            </button>
          </div>
        </div>

        <div className="space-y-4">
          {result.questions.map((question) => {
            const isExpanded = expandedQuestions.has(question.id);

            return (
              <div
                key={question.id}
                className={`border rounded-lg overflow-hidden ${
                  question.is_correct ? 'border-green-200' : 'border-red-200'
                }`}
              >
                {/* Question Header */}
                <button
                  onClick={() => toggleQuestion(question.id)}
                  className={`w-full flex items-center justify-between p-4 text-left ${
                    question.is_correct ? 'bg-green-50' : 'bg-red-50'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    {question.is_correct ? (
                      <CheckCircle className="w-5 h-5 text-green-500" />
                    ) : (
                      <XCircle className="w-5 h-5 text-red-500" />
                    )}
                    <span className="font-medium">
                      문제 {question.question_number}
                    </span>
                    {!question.is_correct && (
                      <span className="text-sm text-red-600">
                        (선택: {question.selected_answer || '미선택'} → 정답:{' '}
                        {question.correct_answer})
                      </span>
                    )}
                  </div>
                  {isExpanded ? (
                    <ChevronUp className="w-5 h-5 text-gray-400" />
                  ) : (
                    <ChevronDown className="w-5 h-5 text-gray-400" />
                  )}
                </button>

                {/* Question Content */}
                {isExpanded && (
                  <div className="p-4 border-t border-gray-100">
                    <p className="text-gray-900 mb-4">{question.question_text}</p>

                    <div className="space-y-2 mb-4">
                      {question.options.map((option) => {
                        const isCorrect = option.number === question.correct_answer;
                        const isSelected = option.number === question.selected_answer;
                        const isWrongSelection = isSelected && !isCorrect;

                        return (
                          <div
                            key={option.number}
                            className={`p-3 rounded-lg ${
                              isCorrect
                                ? 'bg-green-100 border border-green-300'
                                : isWrongSelection
                                ? 'bg-red-100 border border-red-300'
                                : 'bg-gray-50'
                            }`}
                          >
                            <div className="flex items-start gap-2">
                              <span
                                className={`flex-shrink-0 w-6 h-6 rounded-full text-sm font-medium flex items-center justify-center ${
                                  isCorrect
                                    ? 'bg-green-500 text-white'
                                    : isWrongSelection
                                    ? 'bg-red-500 text-white'
                                    : 'bg-gray-300 text-gray-600'
                                }`}
                              >
                                {option.number}
                              </span>
                              <span className="text-gray-800">{option.text}</span>
                              {isCorrect && (
                                <span className="ml-auto text-green-600 text-sm font-medium">
                                  정답
                                </span>
                              )}
                              {isWrongSelection && (
                                <span className="ml-auto text-red-600 text-sm font-medium">
                                  오답
                                </span>
                              )}
                            </div>
                          </div>
                        );
                      })}
                    </div>

                    {question.explanation && (
                      <div className="p-4 bg-blue-50 rounded-lg border-l-4 border-blue-400">
                        <p className="text-sm font-medium text-blue-800 mb-1">
                          해설
                        </p>
                        <p className="text-gray-700">{question.explanation}</p>
                      </div>
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
