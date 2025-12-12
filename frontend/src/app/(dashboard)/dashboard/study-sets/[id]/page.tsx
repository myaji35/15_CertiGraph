"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useAuth } from "@clerk/nextjs";
import Link from "next/link";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
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

interface Question {
  id: string;
  question_number: number;
  question_text: string;
  options: string[];
  correct_answer: number;
  explanation?: string;
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
  const [questions, setQuestions] = useState<Question[]>([]);
  const [loadingQuestions, setLoadingQuestions] = useState(false);
  const [loadingLogs, setLoadingLogs] = useState<string[]>([]);

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
          `${process.env.NEXT_PUBLIC_API_URL}/study-sets/${studySetId}`,
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
          `${process.env.NEXT_PUBLIC_API_URL}/study-sets/${studySetId}/status`,
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

  // Fetch questions when study set is ready
  useEffect(() => {
    const fetchQuestions = async () => {
      if (!studySet || studySet.status !== "ready" || studySet.question_count === 0) {
        return;
      }

      setLoadingQuestions(true);
      try {
        const token = await getToken();
        if (!token) {
          console.error("No auth token available");
          return;
        }

        console.log("Fetching questions for study set:", studySetId);
        const url = `${process.env.NEXT_PUBLIC_API_URL}/study-sets/${studySetId}/questions`;
        console.log("Request URL:", url);

        const response = await fetch(url, {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        });

        console.log("Response status:", response.status);

        if (response.ok) {
          const data = await response.json();
          console.log("Questions data:", data);
          setQuestions(data.data || []);
        } else {
          const errorData = await response.text();
          console.error("Failed to fetch questions. Status:", response.status, "Error:", errorData);
        }
      } catch (err) {
        console.error("Failed to fetch questions:", err);
      } finally {
        setLoadingQuestions(false);
      }
    };

    fetchQuestions();
  }, [studySet?.status, studySet?.question_count, studySetId, getToken]);

  const handleStartLearning = async () => {
    if (!studySet) return;

    setStartingTest(true);
    setLoadingLogs([]);

    const addLog = (message: string) => {
      setLoadingLogs(prev => [...prev, message]);
    };

    // Clear any previous session data
    const storedKeys = Object.keys(localStorage);
    storedKeys.forEach(key => {
      if (key.startsWith('test_session_')) {
        localStorage.removeItem(key);
      }
    });

    try {
      const token = await getToken();
      if (!token) throw new Error("인증이 필요합니다");

      addLog("🔄 새로운 학습 세션을 준비합니다...");
      addLog("✨ 이전 학습 기록이 있어도 처음부터 다시 시작합니다");

      // If no questions exist, trigger PDF parsing first
      if (studySet.question_count === 0) {
        // Call parse endpoint
        const parseResponse = await fetch(
          `${process.env.NEXT_PUBLIC_API_URL}/study-sets/${studySet.id}/parse`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${token}`,
            },
          }
        );

        if (!parseResponse.ok) {
          throw new Error("PDF 파싱 시작에 실패했습니다");
        }

        // Wait for parsing to complete by polling status
        let isComplete = false;
        while (!isComplete) {
          await new Promise((resolve) => setTimeout(resolve, 2000)); // Wait 2 seconds

          const statusResponse = await fetch(
            `${process.env.NEXT_PUBLIC_API_URL}/study-sets/${studySet.id}/status`,
            {
              headers: {
                Authorization: `Bearer ${token}`,
              },
            }
          );

          if (statusResponse.ok) {
            const statusData = await statusResponse.json();
            setProcessingStatus(statusData.data);

            if (statusData.data.status === "ready") {
              isComplete = true;
              // Refresh study set data to get question count
              const refreshResponse = await fetch(
                `${process.env.NEXT_PUBLIC_API_URL}/study-sets/${studySet.id}`,
                {
                  headers: {
                    Authorization: `Bearer ${token}`,
                  },
                }
              );
              if (refreshResponse.ok) {
                const refreshData = await refreshResponse.json();
                setStudySet(refreshData.data);
                // Reload page to fetch questions
                window.location.reload();
              }
            } else if (statusData.data.status === "failed") {
              throw new Error("PDF 파싱에 실패했습니다");
            }
          }
        }
      } else {
        // Start learning mode with all questions
        addLog(`📚 ${studySet.question_count}개의 문제를 준비합니다...`);

        // Simulate loading each question for better UX
        for (let i = 1; i <= Math.min(studySet.question_count, 5); i++) {
          await new Promise(resolve => setTimeout(resolve, 100));
          addLog(`✓ ${i}번 문제 로딩`);
        }
        if (studySet.question_count > 5) {
          addLog(`✓ ...나머지 ${studySet.question_count - 5}개 문제 로딩`);
        }

        addLog("🔀 보기 순서를 섞습니다...");
        await new Promise(resolve => setTimeout(resolve, 300));
        addLog("🚀 학습 세션을 시작합니다...");

        const response = await fetch(
          `${process.env.NEXT_PUBLIC_API_URL}/tests/start`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${token}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              study_set_id: studySet.id,
              mode: "all",
              question_count: studySet.question_count,
              shuffle_options: true, // 보기 섞기 활성화
            }),
          }
        );

        if (!response.ok) {
          throw new Error("학습 시작에 실패했습니다");
        }

        const data = await response.json();
        const session = data.data;

        addLog("✅ 학습 세션 준비 완료!");

        // Store session data in localStorage for the learning page
        localStorage.setItem(
          `test_session_${session.session_id}`,
          JSON.stringify(session)
        );

        // Navigate to learning/test page
        router.push(`/dashboard/test/${session.session_id}`);
      }
    } catch (err) {
      addLog(`❌ 오류: ${err instanceof Error ? err.message : "알 수 없는 오류"}`);
      alert(err instanceof Error ? err.message : "오류가 발생했습니다");
      setStartingTest(false);
      // Clear logs after a delay
      setTimeout(() => setLoadingLogs([]), 3000);
    }
  };

  const handleStartTest = async (mode: string, count?: number, shuffleOptions?: boolean) => {
    if (!studySet) return;

    setStartingTest(true);
    try {
      const token = await getToken();
      if (!token) throw new Error("인증이 필요합니다");

      // Now start the test
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/tests/start`,
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
            shuffle_options: shuffleOptions || false,
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

          {/* Loading Logs */}
          {loadingLogs.length > 0 && (
            <div className="mb-6 bg-gray-50 border border-gray-200 rounded-lg p-4">
              <div className="space-y-2">
                {loadingLogs.map((log, index) => (
                  <div
                    key={index}
                    className="text-sm text-gray-700 font-mono animate-fade-in"
                  >
                    {log}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Actions */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <button
              onClick={handleStartLearning}
              className="flex items-center justify-center gap-3 bg-blue-600 text-white p-6 rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              disabled={startingTest}
            >
              {startingTest ? (
                <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-white"></div>
              ) : (
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
              )}
              <span className="font-medium">
                {startingTest ? "새 세션 시작 중..." : questions.length > 0 ? "다시 학습하기" : "학습 시작"}
              </span>
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

          {/* Questions List */}
          {questions.length > 0 && (
            <div className="mt-8">
              <h2 className="text-xl font-bold text-gray-900 mb-4">학습 문제 목록</h2>
              <div className="space-y-4">
                {loadingQuestions ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                  </div>
                ) : (
                  questions.map((question) => (
                    <div
                      key={question.id}
                      className="bg-white p-6 rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow"
                    >
                      <div className="flex items-start gap-4">
                        <div className="flex-shrink-0 w-8 h-8 bg-blue-100 text-blue-700 rounded-full flex items-center justify-center font-bold text-sm">
                          {question.question_number}
                        </div>
                        <div className="flex-1">
                          <div className="text-gray-900 leading-relaxed prose prose-sm max-w-none">
                            <ReactMarkdown
                              remarkPlugins={[remarkGfm]}
                              components={{
                                table: ({ node, ...props }) => (
                                  <table className="min-w-full border-collapse border border-gray-300 my-2 text-sm" {...props} />
                                ),
                                thead: ({ node, ...props }) => (
                                  <thead className="bg-gray-100" {...props} />
                                ),
                                tbody: ({ node, ...props }) => (
                                  <tbody {...props} />
                                ),
                                tr: ({ node, ...props }) => (
                                  <tr className="border-b border-gray-300" {...props} />
                                ),
                                th: ({ node, ...props }) => (
                                  <th className="border border-gray-300 px-2 py-1 text-left font-semibold" {...props} />
                                ),
                                td: ({ node, ...props }) => (
                                  <td className="border border-gray-300 px-2 py-1" {...props} />
                                ),
                              }}
                            >
                              {question.question_text}
                            </ReactMarkdown>
                          </div>
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          )}
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
