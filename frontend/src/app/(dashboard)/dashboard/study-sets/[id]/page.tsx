"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useAuth } from "@clerk/nextjs";
import Link from "next/link";
import TestStartModal from "@/components/test/TestStartModal";

interface StudySet {
  id: string;
  name: string;
  status: "uploading" | "parsing" | "processing" | "ready" | "failed";
  question_count: number;
  created_at: string;
  is_cached: boolean;
}

interface ProcessingStatus {
  status: string;
  progress: number;
  current_step: string | null;
  is_cached: boolean;
}

export default function StudySetDetailPage() {
  const params = useParams();
  const router = useRouter();
  const { getToken } = useAuth();
  const [studySet, setStudySet] = useState<StudySet | null>(null);
  const [processingStatus, setProcessingStatus] = useState<ProcessingStatus | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [showTestModal, setShowTestModal] = useState(false);
  const [startingTest, setStartingTest] = useState(false);

  const studySetId = params.id as string;

  useEffect(() => {
    const fetchStudySet = async () => {
      try {
        const token = await getToken();
        if (!token) {
          router.push("/sign-in");
          return;
        }

        const response = await fetch(
          `${process.env.NEXT_PUBLIC_API_URL}/api/v1/study-sets/${studySetId}`,
          {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          }
        );

        if (!response.ok) {
          if (response.status === 404) {
            setError("학습 세트를 찾을 수 없습니다.");
            return;
          }
          throw new Error("Failed to fetch study set");
        }

        const data = await response.json();
        setStudySet(data.data);
      } catch (err) {
        setError(err instanceof Error ? err.message : "오류가 발생했습니다");
      }
    };

    fetchStudySet();
  }, [studySetId, getToken, router]);

  // Poll for status updates while processing
  useEffect(() => {
    if (!studySet || studySet.status === "ready" || studySet.status === "failed") {
      return;
    }

    const pollStatus = async () => {
      try {
        const token = await getToken();
        if (!token) return;

        const response = await fetch(
          `${process.env.NEXT_PUBLIC_API_URL}/api/v1/study-sets/${studySetId}/status`,
          {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          }
        );

        if (response.ok) {
          const data = await response.json();
          setProcessingStatus(data.data);

          // Update study set status if completed
          if (data.data.status === "ready" || data.data.status === "failed") {
            setStudySet((prev) =>
              prev ? { ...prev, status: data.data.status } : null
            );
          }
        }
      } catch (err) {
        console.error("Failed to poll status:", err);
      }
    };

    // Initial fetch
    pollStatus();

    // Poll every 2 seconds
    const interval = setInterval(pollStatus, 2000);

    return () => clearInterval(interval);
  }, [studySet?.status, studySetId, getToken]);

  const handleStartTest = async (mode: string, count?: number) => {
    if (!studySet) return;

    setStartingTest(true);
    try {
      const token = await getToken();
      if (!token) throw new Error("인증이 필요합니다");

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/api/v1/tests/start`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            study_set_id: studySet.id,
            mode: mode,
            question_count: count,
          }),
        }
      );

      if (!response.ok) {
        throw new Error("테스트 시작에 실패했습니다");
      }

      const data = await response.json();
      const session = data.data;

      // Store session data in localStorage for the test page
      localStorage.setItem(
        `test_session_${session.session_id}`,
        JSON.stringify(session)
      );

      // Navigate to test page
      router.push(`/dashboard/test/${session.session_id}`);
    } catch (err) {
      alert(err instanceof Error ? err.message : "오류가 발생했습니다");
      setStartingTest(false);
    }
  };

  if (error) {
    return (
      <div className="text-center py-12">
        <div className="text-red-500 mb-4">
          <svg className="mx-auto w-16 h-16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
            />
          </svg>
        </div>
        <h2 className="text-xl font-bold text-gray-900 mb-2">오류</h2>
        <p className="text-gray-600 mb-4">{error}</p>
        <Link
          href="/dashboard/study-sets"
          className="text-blue-600 hover:underline"
        >
          학습 세트 목록으로 돌아가기
        </Link>
      </div>
    );
  }

  if (!studySet) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  const isProcessing = ["uploading", "parsing", "processing"].includes(studySet.status);

  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <Link
          href="/dashboard/study-sets"
          className="text-sm text-gray-500 hover:text-gray-700 mb-2 inline-flex items-center gap-1"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
          학습 세트 목록
        </Link>
        <h1 className="text-2xl font-bold text-gray-900">{studySet.name}</h1>
        <p className="text-sm text-gray-500 mt-1">
          {new Date(studySet.created_at).toLocaleDateString("ko-KR", {
            year: "numeric",
            month: "long",
            day: "numeric",
          })}
        </p>
      </div>

      {/* Processing Status */}
      {isProcessing && processingStatus && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
            <span className="font-medium text-gray-900">
              {processingStatus.current_step || "처리 중..."}
            </span>
          </div>

          {/* Progress Bar */}
          <div className="w-full bg-gray-200 rounded-full h-3 mb-2">
            <div
              className="bg-blue-600 h-3 rounded-full transition-all duration-500"
              style={{ width: `${processingStatus.progress}%` }}
            />
          </div>
          <p className="text-sm text-gray-500 text-right">{processingStatus.progress}%</p>

          {processingStatus.is_cached && (
            <p className="text-sm text-green-600 mt-2">
              ✨ 이전에 분석된 문서입니다. 빠르게 처리됩니다!
            </p>
          )}
        </div>
      )}

      {/* Failed Status */}
      {studySet.status === "failed" && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-6 mb-6">
          <div className="flex items-center gap-3 text-red-700">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
              />
            </svg>
            <span className="font-medium">처리 중 오류가 발생했습니다</span>
          </div>
          <p className="text-red-600 mt-2 text-sm">
            PDF 파일을 분석하는 중 오류가 발생했습니다. 다른 파일로 다시 시도해주세요.
          </p>
        </div>
      )}

      {/* Ready Status - Show Actions */}
      {studySet.status === "ready" && (
        <>
          {/* Stats */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
              <p className="text-sm text-gray-500">총 문제 수</p>
              <p className="text-3xl font-bold text-gray-900">{studySet.question_count}</p>
            </div>
            <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
              <p className="text-sm text-gray-500">정답률</p>
              <p className="text-3xl font-bold text-gray-900">--%</p>
            </div>
            <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
              <p className="text-sm text-gray-500">학습 진도</p>
              <p className="text-3xl font-bold text-gray-900">0%</p>
            </div>
          </div>

          {/* Actions */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <button
              className="flex items-center justify-center gap-3 bg-blue-600 text-white p-6 rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              disabled={studySet.question_count === 0}
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"
                />
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              <span className="font-medium">학습 시작</span>
            </button>
            <button
              onClick={() => setShowTestModal(true)}
              className="flex items-center justify-center gap-3 bg-green-600 text-white p-6 rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              disabled={studySet.question_count === 0 || startingTest}
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                />
              </svg>
              <span className="font-medium">
                {startingTest ? "시작 중..." : "모의고사"}
              </span>
            </button>
          </div>
        </>
      )}

      {/* Test Start Modal */}
      {showTestModal && studySet && (
        <TestStartModal
          studySetName={studySet.name}
          questionCount={studySet.question_count}
          hasWrongQuestions={false} // TODO: Check from API
          onStart={handleStartTest}
          onClose={() => setShowTestModal(false)}
        />
      )}
    </div>
  );
}
