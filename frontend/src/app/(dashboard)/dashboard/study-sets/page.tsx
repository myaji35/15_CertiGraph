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
  exam_name?: string;
  exam_year?: number;
  exam_round?: number;
  exam_session?: number;
  exam_session_name?: string;
  tags?: string[];
  learning_status: "not_learned" | "learned" | "reset";
  last_studied_at?: string;
}

export default function StudySetsPage() {
  const { getToken } = useAuth();
  const [studySets, setStudySets] = useState<StudySet[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [openDropdown, setOpenDropdown] = useState<string | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);
  const [deleting, setDeleting] = useState<string | null>(null);

  const fetchStudySets = async () => {
    try {
      const token = await getToken();
      if (!token) return;

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/study-sets`,
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

  const updateLearningStatus = async (
    studySetId: string,
    newStatus: "not_learned" | "learned" | "reset"
  ) => {
    try {
      const token = await getToken();
      if (!token) return;

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/study-sets/${studySetId}/learning-status?learning_status=${newStatus}`,
        {
          method: "PATCH",
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (!response.ok) {
        throw new Error("Failed to update learning status");
      }

      // Refresh the list
      await fetchStudySets();
    } catch (err) {
      console.error("Error updating learning status:", err);
    } finally {
      setOpenDropdown(null);
    }
  };

  const deleteStudySet = async (studySetId: string) => {
    try {
      setDeleting(studySetId);
      const token = await getToken();
      if (!token) return;

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/study-sets/${studySetId}`,
        {
          method: "DELETE",
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (!response.ok) {
        throw new Error("Failed to delete study set");
      }

      // Refresh the list
      await fetchStudySets();
    } catch (err) {
      console.error("Error deleting study set:", err);
      alert("삭제 중 오류가 발생했습니다.");
    } finally {
      setDeleting(null);
      setDeleteConfirm(null);
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

  const getLearningStatusButton = (studySet: StudySet) => {
    const isOpen = openDropdown === studySet.id;

    let badge = { text: "미학습", bgClass: "bg-gray-100", textClass: "text-gray-600" };
    switch (studySet.learning_status) {
      case "learned":
        badge = { text: "학습됨", bgClass: "bg-blue-100", textClass: "text-blue-700" };
        break;
      case "reset":
        badge = { text: "초기화", bgClass: "bg-orange-100", textClass: "text-orange-700" };
        break;
    }

    return (
      <div className="relative inline-block">
        <button
          onClick={(e) => {
            e.preventDefault();
            e.stopPropagation();
            setOpenDropdown(isOpen ? null : studySet.id);
          }}
          className={`px-2 py-1 text-xs rounded-full ${badge.bgClass} ${badge.textClass} hover:opacity-80 transition-opacity flex items-center gap-1`}
        >
          {badge.text}
          <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
          </svg>
        </button>

        {isOpen && (
          <div className="absolute left-0 mt-1 w-28 bg-white rounded-md shadow-lg border border-gray-200 z-10">
            <button
              onClick={(e) => {
                e.preventDefault();
                e.stopPropagation();
                updateLearningStatus(studySet.id, "not_learned");
              }}
              className="block w-full text-left px-3 py-2 text-xs text-gray-700 hover:bg-gray-50"
            >
              미학습
            </button>
            <button
              onClick={(e) => {
                e.preventDefault();
                e.stopPropagation();
                updateLearningStatus(studySet.id, "learned");
              }}
              className="block w-full text-left px-3 py-2 text-xs text-blue-700 hover:bg-blue-50"
            >
              학습됨
            </button>
            <button
              onClick={(e) => {
                e.preventDefault();
                e.stopPropagation();
                updateLearningStatus(studySet.id, "reset");
              }}
              className="block w-full text-left px-3 py-2 text-xs text-orange-700 hover:bg-orange-50"
            >
              초기화
            </button>
          </div>
        )}
      </div>
    );
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
        /* Table View */
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  년도
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  회차
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  문제집 제목
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  교시
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  문제 수
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  학습 상태
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  상태
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  작업
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {studySets.map((studySet) => (
                <tr
                  key={studySet.id}
                  onClick={() => window.location.href = `/dashboard/study-sets/${studySet.id}`}
                  className="hover:bg-gray-50 cursor-pointer transition-colors"
                >
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {studySet.exam_year || "-"}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {studySet.exam_round ? `${studySet.exam_round}회` : "-"}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-900">
                    <div className="font-medium">{studySet.exam_name || studySet.name}</div>
                    {studySet.exam_name && studySet.exam_name !== studySet.name && (
                      <div className="text-xs text-gray-500 mt-1">{studySet.name}</div>
                    )}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {studySet.exam_session_name || (studySet.exam_session ? `${studySet.exam_session}교시` : "-")}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {studySet.status === "ready" ? `${studySet.question_count}개` : "-"}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm" onClick={(e) => e.stopPropagation()}>
                    {getLearningStatusButton(studySet)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {getStatusBadge(studySet.status)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm" onClick={(e) => e.stopPropagation()}>
                    {deleteConfirm === studySet.id ? (
                      <div className="flex items-center gap-2">
                        <button
                          onClick={(e) => {
                            e.preventDefault();
                            e.stopPropagation();
                            deleteStudySet(studySet.id);
                          }}
                          disabled={deleting === studySet.id}
                          className="px-2 py-1 text-xs bg-red-600 text-white rounded hover:bg-red-700 disabled:opacity-50"
                        >
                          {deleting === studySet.id ? "삭제 중..." : "확인"}
                        </button>
                        <button
                          onClick={(e) => {
                            e.preventDefault();
                            e.stopPropagation();
                            setDeleteConfirm(null);
                          }}
                          disabled={deleting === studySet.id}
                          className="px-2 py-1 text-xs bg-gray-200 text-gray-700 rounded hover:bg-gray-300 disabled:opacity-50"
                        >
                          취소
                        </button>
                      </div>
                    ) : (
                      <button
                        onClick={(e) => {
                          e.preventDefault();
                          e.stopPropagation();
                          setDeleteConfirm(studySet.id);
                        }}
                        className="text-red-600 hover:text-red-800"
                        title="삭제"
                      >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
