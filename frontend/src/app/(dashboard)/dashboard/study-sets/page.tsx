"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@clerk/nextjs";
import Link from "next/link";

interface StudySet {
  id: string;
  name: string;
  status: "uploading" | "parsing" | "processing" | "ready" | "failed";
  question_count: number;
  created_at: string;
  is_cached: boolean;
}

export default function StudySetsPage() {
  const { getToken } = useAuth();
  const [studySets, setStudySets] = useState<StudySet[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchStudySets = async () => {
    try {
      const token = await getToken();
      if (!token) return;

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/api/v1/study-sets`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (!response.ok) {
        throw new Error("Failed to fetch study sets");
      }

      const data = await response.json();
      setStudySets(data.data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "오류가 발생했습니다");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStudySets();
  }, [getToken]);

  // Refresh periodically to update processing status
  useEffect(() => {
    const hasProcessing = studySets.some((s) =>
      ["uploading", "parsing", "processing"].includes(s.status)
    );

    if (!hasProcessing) return;

    const interval = setInterval(fetchStudySets, 5000);
    return () => clearInterval(interval);
  }, [studySets]);

  const getStatusBadge = (status: StudySet["status"]) => {
    switch (status) {
      case "ready":
        return <span className="px-2 py-1 text-xs rounded-full bg-green-100 text-green-700">사용 가능</span>;
      case "parsing":
      case "processing":
      case "uploading":
        return (
          <span className="px-2 py-1 text-xs rounded-full bg-yellow-100 text-yellow-700 flex items-center gap-1">
            <span className="animate-pulse">●</span> 분석 중
          </span>
        );
      case "failed":
        return <span className="px-2 py-1 text-xs rounded-full bg-red-100 text-red-700">오류</span>;
      default:
        return null;
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <p className="text-red-600">{error}</p>
        <button
          onClick={() => {
            setError(null);
            setLoading(true);
            fetchStudySets();
          }}
          className="mt-4 text-blue-600 hover:underline"
        >
          다시 시도
        </button>
      </div>
    );
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">학습 세트</h1>
        <Link
          href="/dashboard/study-sets/new"
          className="inline-flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          새 학습 세트
        </Link>
      </div>

      {studySets.length === 0 ? (
        <div className="text-center py-12">
          <svg
            className="mx-auto w-16 h-16 text-gray-300"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
            />
          </svg>
          <h3 className="mt-4 text-lg font-medium text-gray-900">학습 세트가 없습니다</h3>
          <p className="mt-2 text-gray-600">
            첫 번째 PDF를 업로드하여 학습을 시작해보세요!
          </p>
          <Link
            href="/dashboard/study-sets/new"
            className="inline-block mt-4 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
          >
            PDF 업로드하기
          </Link>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {studySets.map((studySet) => (
            <Link
              key={studySet.id}
              href={`/dashboard/study-sets/${studySet.id}`}
              className="block bg-white p-6 rounded-lg shadow-sm border border-gray-200 hover:border-blue-300 hover:shadow-md transition-all"
            >
              <div className="flex justify-between items-start">
                <h3 className="font-medium text-gray-900 flex-1 pr-2">{studySet.name}</h3>
                {getStatusBadge(studySet.status)}
              </div>

              <p className="mt-2 text-sm text-gray-500">
                {studySet.status === "ready"
                  ? `${studySet.question_count}개 문제`
                  : "처리 중..."}
              </p>

              <div className="mt-4 pt-4 border-t border-gray-100 flex justify-between items-center text-xs text-gray-400">
                <span>
                  {new Date(studySet.created_at).toLocaleDateString("ko-KR", {
                    month: "short",
                    day: "numeric",
                  })}
                </span>
                {studySet.is_cached && (
                  <span className="text-green-600" title="캐시된 결과 사용">
                    ⚡ 빠른 처리
                  </span>
                )}
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
