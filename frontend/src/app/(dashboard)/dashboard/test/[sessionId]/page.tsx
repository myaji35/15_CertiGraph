"use client";

import { useEffect, useState, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import { useAuth } from "@clerk/nextjs";
import QuestionCard from "@/components/test/QuestionCard";
import QuestionNavigator from "@/components/test/QuestionNavigator";

interface Question {
  id: string;
  question_number: number;
  question_text: string;
  options: { number: number; text: string }[];
  passage?: string;
}

interface TestSession {
  session_id: string;
  questions: Question[];
  total_questions: number;
}

export default function TestPage() {
  const params = useParams();
  const router = useRouter();
  const { getToken } = useAuth();

  const sessionId = params.sessionId as string;

  const [session, setSession] = useState<TestSession | null>(null);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [answers, setAnswers] = useState<Map<string, number>>(new Map());
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [startTime] = useState(Date.now());

  // Fetch session data from localStorage (set during test start)
  useEffect(() => {
    const stored = localStorage.getItem(`test_session_${sessionId}`);
    if (stored) {
      setSession(JSON.parse(stored));
      setLoading(false);
    } else {
      setError("테스트 세션을 찾을 수 없습니다.");
      setLoading(false);
    }
  }, [sessionId]);

  const currentQuestion = session?.questions[currentIndex];
  const totalQuestions = session?.total_questions || 0;

  const handleSelectAnswer = useCallback((answer: number) => {
    if (!currentQuestion) return;
    setAnswers((prev) => {
      const next = new Map(prev);
      next.set(currentQuestion.id, answer);
      return next;
    });
  }, [currentQuestion]);

  const handleNavigate = (index: number) => {
    if (index >= 0 && index < totalQuestions) {
      setCurrentIndex(index);
    }
  };

  const handlePrevious = () => handleNavigate(currentIndex - 1);
  const handleNext = () => handleNavigate(currentIndex + 1);

  const handleSubmit = async () => {
    if (!session) return;

    setSubmitting(true);
    try {
      const token = await getToken();
      if (!token) throw new Error("인증이 필요합니다");

      const answersArray = Array.from(answers.entries()).map(([questionId, selected]) => ({
        question_id: questionId,
        selected_option: selected,
      }));

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/api/v1/tests/submit`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            session_id: sessionId,
            answers: answersArray,
          }),
        }
      );

      if (!response.ok) {
        throw new Error("제출에 실패했습니다");
      }

      // Clear session from localStorage
      localStorage.removeItem(`test_session_${sessionId}`);

      // Navigate to results
      router.push(`/dashboard/test/result/${sessionId}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : "오류가 발생했습니다");
      setSubmitting(false);
    }
  };

  // Get answered question numbers
  const answeredQuestions = new Set(
    session?.questions
      .filter((q) => answers.has(q.id))
      .map((q) => q.question_number) || []
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (error || !session || !currentQuestion) {
    return (
      <div className="text-center py-12">
        <p className="text-red-600">{error || "테스트를 로드할 수 없습니다"}</p>
        <button
          onClick={() => router.push("/dashboard")}
          className="mt-4 text-blue-600 hover:underline"
        >
          대시보드로 돌아가기
        </button>
      </div>
    );
  }

  const isLastQuestion = currentIndex === totalQuestions - 1;
  const elapsedTime = Math.floor((Date.now() - startTime) / 1000);
  const minutes = Math.floor(elapsedTime / 60);
  const seconds = elapsedTime % 60;

  return (
    <div className="max-w-5xl mx-auto">
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900">모의고사</h1>
          <p className="text-sm text-gray-500 mt-1">
            {answers.size} / {totalQuestions} 답변 완료
          </p>
        </div>
        <div className="text-right">
          <p className="text-2xl font-mono text-gray-700">
            {String(minutes).padStart(2, "0")}:{String(seconds).padStart(2, "0")}
          </p>
          <p className="text-xs text-gray-500">경과 시간</p>
        </div>
      </div>

      {/* Progress Bar */}
      <div className="mb-6">
        <div className="w-full bg-gray-200 rounded-full h-2">
          <div
            className="bg-blue-600 h-2 rounded-full transition-all duration-300"
            style={{ width: `${((currentIndex + 1) / totalQuestions) * 100}%` }}
          />
        </div>
      </div>

      <div className="flex gap-6">
        {/* Main Content */}
        <div className="flex-1">
          <QuestionCard
            questionNumber={currentIndex + 1}
            totalQuestions={totalQuestions}
            questionText={currentQuestion.question_text}
            options={currentQuestion.options}
            selectedAnswer={answers.get(currentQuestion.id) || null}
            onSelectAnswer={handleSelectAnswer}
          />

          {/* Navigation Buttons */}
          <div className="mt-6 flex justify-between">
            <button
              onClick={handlePrevious}
              disabled={currentIndex === 0}
              className={`px-6 py-2 rounded-lg font-medium transition-colors ${
                currentIndex === 0
                  ? "bg-gray-100 text-gray-400 cursor-not-allowed"
                  : "bg-gray-200 text-gray-700 hover:bg-gray-300"
              }`}
            >
              ← 이전
            </button>

            {isLastQuestion ? (
              <button
                onClick={() => setShowConfirmModal(true)}
                className="px-6 py-2 bg-green-600 text-white rounded-lg font-medium hover:bg-green-700 transition-colors"
              >
                제출하기
              </button>
            ) : (
              <button
                onClick={handleNext}
                className="px-6 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors"
              >
                다음 →
              </button>
            )}
          </div>
        </div>

        {/* Side Panel - Question Navigator */}
        <div className="w-64 flex-shrink-0 hidden lg:block">
          <QuestionNavigator
            totalQuestions={totalQuestions}
            currentQuestion={currentIndex + 1}
            answeredQuestions={answeredQuestions}
            onNavigate={handleNavigate}
          />

          <button
            onClick={() => setShowConfirmModal(true)}
            className="w-full mt-4 px-4 py-3 bg-green-600 text-white rounded-lg font-medium hover:bg-green-700 transition-colors"
          >
            답안 제출하기
          </button>
        </div>
      </div>

      {/* Confirm Modal */}
      {showConfirmModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl max-w-md w-full mx-4 p-6">
            <h2 className="text-xl font-bold text-gray-900 mb-4">답안을 제출하시겠습니까?</h2>
            <p className="text-gray-600 mb-2">
              답변한 문제: {answers.size} / {totalQuestions}
            </p>
            {answers.size < totalQuestions && (
              <p className="text-orange-600 text-sm mb-4">
                ⚠️ {totalQuestions - answers.size}개 문제가 미답변 상태입니다.
              </p>
            )}
            <p className="text-gray-500 text-sm mb-6">
              제출 후에는 답안을 수정할 수 없습니다.
            </p>

            <div className="flex gap-3">
              <button
                onClick={() => setShowConfirmModal(false)}
                className="flex-1 px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-100 transition-colors"
                disabled={submitting}
              >
                취소
              </button>
              <button
                onClick={handleSubmit}
                disabled={submitting}
                className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg font-medium hover:bg-green-700 transition-colors disabled:opacity-50"
              >
                {submitting ? "제출 중..." : "제출하기"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
