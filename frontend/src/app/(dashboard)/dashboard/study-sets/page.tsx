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

interface GroupedStudySets {
  examName: string;
  years: {
    year: number;
    rounds: {
      round: number;
      studySets: StudySet[];
    }[];
  }[];
}

export default function StudySetsPage() {
  const { getToken } = useAuth();
  const [studySets, setStudySets] = useState<StudySet[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [viewMode, setViewMode] = useState<"grid" | "grouped">("grouped");
  const [openDropdown, setOpenDropdown] = useState<string | null>(null);

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

  const updateLearningStatus = async (
    studySetId: string,
    newStatus: "not_learned" | "learned" | "reset"
  ) => {
    try {
      const token = await getToken();
      if (!token) return;

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/api/v1/study-sets/${studySetId}/learning-status?learning_status=${newStatus}`,
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

  // Group study sets by exam hierarchy
  const groupedStudySets = (): GroupedStudySets[] => {
    const groups: { [examName: string]: GroupedStudySets } = {};
    const ungrouped: StudySet[] = [];

    studySets.forEach((set) => {
      if (!set.exam_name) {
        ungrouped.push(set);
        return;
      }

      if (!groups[set.exam_name]) {
        groups[set.exam_name] = {
          examName: set.exam_name,
          years: [],
        };
      }

      const group = groups[set.exam_name];
      const year = set.exam_year || 0;
      let yearGroup = group.years.find((y) => y.year === year);

      if (!yearGroup) {
        yearGroup = { year, rounds: [] };
        group.years.push(yearGroup);
      }

      const round = set.exam_round || 0;
      let roundGroup = yearGroup.rounds.find((r) => r.round === round);

      if (!roundGroup) {
        roundGroup = { round, studySets: [] };
        yearGroup.rounds.push(roundGroup);
      }

      roundGroup.studySets.push(set);
    });

    // Sort years and rounds in descending order
    Object.values(groups).forEach((group) => {
      group.years.sort((a, b) => b.year - a.year);
      group.years.forEach((year) => {
        year.rounds.sort((a, b) => b.round - a.round);
        // Sort study sets by session within each round
        year.rounds.forEach((round) => {
          round.studySets.sort((a, b) => (a.exam_session || 0) - (b.exam_session || 0));
        });
      });
    });

    const result = Object.values(groups);

    // Add ungrouped items as separate group if exists
    if (ungrouped.length > 0) {
      result.push({
        examName: "기타",
        years: [{
          year: 0,
          rounds: [{
            round: 0,
            studySets: ungrouped,
          }],
        }],
      });
    }

    return result;
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
        <div className="flex items-center gap-3">
          {/* View Toggle */}
          <div className="flex items-center gap-1 bg-gray-100 rounded-lg p-1">
            <button
              onClick={() => setViewMode("grouped")}
              className={`px-3 py-1.5 text-sm rounded-md transition-colors ${
                viewMode === "grouped"
                  ? "bg-white text-gray-900 shadow-sm"
                  : "text-gray-600 hover:text-gray-900"
              }`}
            >
              그룹
            </button>
            <button
              onClick={() => setViewMode("grid")}
              className={`px-3 py-1.5 text-sm rounded-md transition-colors ${
                viewMode === "grid"
                  ? "bg-white text-gray-900 shadow-sm"
                  : "text-gray-600 hover:text-gray-900"
              }`}
            >
              전체
            </button>
          </div>

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
      ) : viewMode === "grid" ? (
        /* Grid View - Original Layout */
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {studySets.map((studySet) => (
            <Link
              key={studySet.id}
              href={`/dashboard/study-sets/${studySet.id}`}
              className="block bg-white p-6 rounded-lg shadow-sm border border-gray-200 hover:border-blue-300 hover:shadow-md transition-all"
            >
              <div className="flex justify-between items-start mb-2">
                <h3 className="font-medium text-gray-900 flex-1 pr-2">{studySet.name}</h3>
                {getStatusBadge(studySet.status)}
              </div>

              <div className="flex gap-1 mb-2">
                {getLearningStatusButton(studySet)}
              </div>

              {studySet.exam_name && (
                <div className="mt-2 flex flex-wrap gap-1">
                  <span className="text-xs px-2 py-0.5 bg-blue-50 text-blue-700 rounded">
                    {studySet.exam_name}
                  </span>
                  {studySet.exam_year && (
                    <span className="text-xs px-2 py-0.5 bg-gray-100 text-gray-700 rounded">
                      {studySet.exam_year}년
                    </span>
                  )}
                  {studySet.exam_round && (
                    <span className="text-xs px-2 py-0.5 bg-gray-100 text-gray-700 rounded">
                      {studySet.exam_round}차
                    </span>
                  )}
                </div>
              )}

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
      ) : (
        /* Grouped View - Hierarchical by Exam/Year/Round/Session */
        <div className="space-y-6">
          {groupedStudySets().map((examGroup) => (
            <div key={examGroup.examName} className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
              {/* Exam Name Header */}
              <div className="bg-gradient-to-r from-blue-500 to-blue-600 px-6 py-4">
                <h2 className="text-xl font-bold text-white">{examGroup.examName}</h2>
              </div>

              {/* Years */}
              <div className="divide-y divide-gray-200">
                {examGroup.years.map((yearGroup) => (
                  <div key={yearGroup.year} className="p-6">
                    {yearGroup.year > 0 && (
                      <h3 className="text-lg font-semibold text-gray-900 mb-4">
                        {yearGroup.year}년
                      </h3>
                    )}

                    {/* Rounds */}
                    <div className="space-y-4">
                      {yearGroup.rounds.map((roundGroup) => (
                        <div key={roundGroup.round}>
                          {roundGroup.round > 0 && (
                            <div className="flex items-center gap-2 mb-3">
                              <span className="text-sm font-medium text-gray-700">
                                제{roundGroup.round}회
                              </span>
                              <div className="flex-1 h-px bg-gray-200"></div>
                            </div>
                          )}

                          {/* Study Sets */}
                          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                            {roundGroup.studySets.map((studySet) => (
                              <Link
                                key={studySet.id}
                                href={`/dashboard/study-sets/${studySet.id}`}
                                className="block p-4 rounded-lg border border-gray-200 hover:border-blue-300 hover:bg-blue-50 transition-all"
                              >
                                <div className="flex justify-between items-start mb-2">
                                  <div className="flex-1">
                                    {studySet.exam_session_name ? (
                                      <h4 className="font-medium text-gray-900 text-sm">
                                        {studySet.exam_session_name}
                                      </h4>
                                    ) : studySet.exam_session ? (
                                      <h4 className="font-medium text-gray-900 text-sm">
                                        {studySet.exam_session}교시
                                      </h4>
                                    ) : (
                                      <h4 className="font-medium text-gray-900 text-sm line-clamp-1">
                                        {studySet.name}
                                      </h4>
                                    )}
                                  </div>
                                  {getStatusBadge(studySet.status)}
                                </div>

                                <div className="mb-2">
                                  {getLearningStatusButton(studySet)}
                                </div>

                                <p className="text-xs text-gray-500">
                                  {studySet.status === "ready"
                                    ? `${studySet.question_count}개 문제`
                                    : "처리 중..."}
                                </p>

                                {studySet.tags && studySet.tags.length > 0 && (
                                  <div className="mt-2 flex flex-wrap gap-1">
                                    {studySet.tags.slice(0, 2).map((tag, i) => (
                                      <span
                                        key={i}
                                        className="text-xs px-1.5 py-0.5 bg-gray-100 text-gray-600 rounded"
                                      >
                                        {tag}
                                      </span>
                                    ))}
                                  </div>
                                )}
                              </Link>
                            ))}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
