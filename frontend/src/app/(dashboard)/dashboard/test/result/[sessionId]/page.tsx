"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useAuth } from "@clerk/nextjs";
import Link from "next/link";

interface QuestionResult {
  id: string;
  question_number: number;
  question_text: string;
  options: { number: number; text: string }[];
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
        if (!token) {
          router.push("/sign-in");
          return;
        }

        const response = await fetch(
          `${process.env.NEXT_PUBLIC_API_URL}/tests/${sessionId}/result`,
          {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          }
        );

        if (!response.ok) {
          throw new Error("결과를 불러올 수 없습니다");
        }

        const data = await response.json();
        setResult(data.data);
      } catch (err) {
        setError(err instanceof Error ? err.message : "오류가 발생했습니다");
      } finally {
        setLoading(false);
      }
    };

    fetchResult();
  }, [sessionId, getToken, router]);

  const toggleQuestion = (questionId: string) => {
    setExpandedQuestions((prev) => {
      const next = new Set(prev);
      if (next.has(questionId)) {
        next.delete(questionId);
      } else {
        next.add(questionId);
      }
      return next;
    });
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}분 ${secs}초`;
  };

  const getGradeBadge = (percentage: number) => {
    if (percentage >= 80) {
      return { text: "우수", color: "bg-green-100 text-green-700" };
    } else if (percentage >= 60) {
      return { text: "양호", color: "bg-yellow-100 text-yellow-700" };
    } else {
      return { text: "노력필요", color: "bg-red-100 text-red-700" };
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (error || !result) {
    return (
      <div className="text-center py-12">
        <p className="text-red-600">{error || "결과를 로드할 수 없습니다"}</p>
        <Link href="/dashboard" className="mt-4 text-blue-600 hover:underline block">
          대시보드로 돌아가기
        </Link>
      </div>
    );
  }

  const grade = getGradeBadge(result.percentage);
  const wrongQuestions = result.questions.filter((q) => !q.is_correct);

  return (
    <div className="max-w-4xl mx-auto">
      {/* Result Summary */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-8 mb-8">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">시험 결과</h1>

          <div className="mt-6 mb-4">
            <span className="text-6xl font-bold text-blue-600">{result.score}</span>
            <span className="text-3xl text-gray-400"> / {result.total}</span>
          </div>

          <div className="flex items-center justify-center gap-4 mb-6">
            <span className="text-2xl font-medium text-gray-700">
              {result.percentage}%
            </span>
            <span className={`px-3 py-1 rounded-full text-sm font-medium ${grade.color}`}>
              {grade.text}
            </span>
          </div>

          <p className="text-gray-500">소요 시간: {formatTime(result.time_taken_seconds)}</p>
        </div>

        {/* Action Buttons */}
        <div className="mt-8 flex flex-wrap justify-center gap-4">
          <Link
            href="/dashboard"
            className="px-6 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-100 transition-colors"
          >
            대시보드로
          </Link>
          {wrongQuestions.length > 0 && (
            <button
              onClick={() => {
                // TODO: Start new test with wrong questions only
                alert("오답 다시 풀기 기능은 준비 중입니다");
              }}
              className="px-6 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 transition-colors"
            >
              오답만 다시 풀기 ({wrongQuestions.length}문제)
            </button>
          )}
        </div>
      </div>

      {/* Question Review */}
      <div className="space-y-4">
        <h2 className="text-xl font-bold text-gray-900 mb-4">문제별 결과</h2>

        {result.questions.map((question) => {
          const isExpanded = expandedQuestions.has(question.id);
          const circleNumbers = ["①", "②", "③", "④", "⑤"];

          return (
            <div
              key={question.id}
              className={`bg-white rounded-lg shadow-sm border overflow-hidden ${
                question.is_correct ? "border-green-200" : "border-red-200"
              }`}
            >
              {/* Question Header */}
              <button
                onClick={() => toggleQuestion(question.id)}
                className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-center gap-4">
                  <span
                    className={`w-8 h-8 rounded-full flex items-center justify-center text-white ${
                      question.is_correct ? "bg-green-500" : "bg-red-500"
                    }`}
                  >
                    {question.is_correct ? "✓" : "✗"}
                  </span>
                  <span className="font-medium text-gray-900">
                    문제 {question.question_number}
                  </span>
                </div>
                <svg
                  className={`w-5 h-5 text-gray-400 transition-transform ${
                    isExpanded ? "rotate-180" : ""
                  }`}
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                </svg>
              </button>

              {/* Expanded Content */}
              {isExpanded && (
                <div className="px-6 pb-6 border-t border-gray-100">
                  <p className="mt-4 text-gray-900 whitespace-pre-wrap">
                    {question.question_text}
                  </p>

                  <div className="mt-4 space-y-2">
                    {question.options.map((option) => {
                      const isCorrect = option.number === question.correct_answer;
                      const isSelected = option.number === question.selected_answer;
                      const isWrongSelected = isSelected && !isCorrect;

                      return (
                        <div
                          key={option.number}
                          className={`p-3 rounded-lg flex items-start gap-3 ${
                            isCorrect
                              ? "bg-green-50 border border-green-200"
                              : isWrongSelected
                              ? "bg-red-50 border border-red-200"
                              : "bg-gray-50"
                          }`}
                        >
                          <span
                            className={`font-medium ${
                              isCorrect
                                ? "text-green-600"
                                : isWrongSelected
                                ? "text-red-600"
                                : "text-gray-500"
                            }`}
                          >
                            {circleNumbers[option.number - 1]}
                          </span>
                          <span
                            className={`flex-1 ${
                              isCorrect
                                ? "text-green-700"
                                : isWrongSelected
                                ? "text-red-700"
                                : "text-gray-600"
                            }`}
                          >
                            {option.text}
                          </span>
                          {isCorrect && (
                            <span className="text-green-600 text-sm font-medium">정답</span>
                          )}
                          {isWrongSelected && (
                            <span className="text-red-600 text-sm font-medium">선택</span>
                          )}
                        </div>
                      );
                    })}
                  </div>

                  {question.explanation && (
                    <div className="mt-4 p-4 bg-blue-50 rounded-lg">
                      <p className="text-sm font-medium text-blue-700 mb-1">해설</p>
                      <p className="text-blue-900">{question.explanation}</p>
                    </div>
                  )}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
