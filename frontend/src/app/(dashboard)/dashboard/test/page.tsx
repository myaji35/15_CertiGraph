"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@clerk/nextjs";
import Link from "next/link";

interface TestSession {
  id: string;
  study_set_id: string;
  study_set_name: string;
  mode: string;
  score: number;
  total_questions: number;
  percentage: number;
  started_at: string;
  completed_at: string | null;
  status: "in_progress" | "completed" | "abandoned";
}

export default function TestHistoryPage() {
  const { getToken } = useAuth();
  const [sessions, setSessions] = useState<TestSession[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchHistory = async () => {
      try {
        const token = await getToken();
        if (!token) return;

        const response = await fetch(
          `${process.env.NEXT_PUBLIC_API_URL}/tests/history`,
          {
            headers: { Authorization: `Bearer ${token}` },
          }
        );

        if (!response.ok) {
          throw new Error("테스트 기록을 불러오는데 실패했습니다");
        }

        const data = await response.json();
        setSessions(data.data || []);
      } catch (err) {
        setError(err instanceof Error ? err.message : "오류가 발생했습니다");
      } finally {
        setLoading(false);
      }
    };

    fetchHistory();
  }, [getToken]);

  const getModeLabel = (mode: string) => {
    switch (mode) {
      case "full":
        return "전체 문제";
      case "random":
        return "랜덤 문제";
      case "wrong_only":
        return "오답 문제";
      default:
        return mode;
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
      </div>
    );
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">모의고사 기록</h1>
        <p className="text-gray-600 mt-1">응시한 모의고사 결과를 확인하세요</p>
      </div>

      {sessions.length === 0 ? (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center">
          <div className="text-gray-400 mb-4">
            <svg className="w-16 h-16 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={1.5}
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
              />
            </svg>
          </div>
          <h3 className="text-lg font-semibold text-gray-900 mb-2">아직 모의고사를 응시하지 않았습니다</h3>
          <p className="text-gray-600 mb-6">학습 세트에서 모의고사를 시작해보세요.</p>
          <Link
            href="/dashboard/study-sets"
            className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            학습 세트 보기
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </Link>
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    학습 세트
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    모드
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    점수
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    상태
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    응시일
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">

                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {sessions.map((session) => (
                  <tr key={session.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="font-medium text-gray-900">{session.study_set_name}</span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="text-sm text-gray-600">{getModeLabel(session.mode)}</span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {session.status === "completed" ? (
                        <div>
                          <span
                            className={`text-lg font-bold ${
                              session.percentage >= 60 ? "text-green-600" : "text-red-600"
                            }`}
                          >
                            {session.percentage}%
                          </span>
                          <span className="text-sm text-gray-500 ml-2">
                            ({session.score}/{session.total_questions})
                          </span>
                        </div>
                      ) : (
                        <span className="text-gray-400">--</span>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {session.status === "completed" ? (
                        <span className="px-2 py-1 text-xs bg-green-100 text-green-700 rounded-full">
                          완료
                        </span>
                      ) : session.status === "in_progress" ? (
                        <span className="px-2 py-1 text-xs bg-yellow-100 text-yellow-700 rounded-full">
                          진행 중
                        </span>
                      ) : (
                        <span className="px-2 py-1 text-xs bg-gray-100 text-gray-700 rounded-full">
                          중단됨
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="text-sm text-gray-600">
                        {new Date(session.completed_at || session.started_at).toLocaleDateString("ko-KR", {
                          year: "numeric",
                          month: "short",
                          day: "numeric",
                          hour: "2-digit",
                          minute: "2-digit",
                        })}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right">
                      {session.status === "completed" ? (
                        <Link
                          href={`/dashboard/test/result/${session.id}`}
                          className="text-blue-600 hover:underline text-sm"
                        >
                          결과 보기
                        </Link>
                      ) : session.status === "in_progress" ? (
                        <Link
                          href={`/dashboard/test/${session.id}`}
                          className="text-blue-600 hover:underline text-sm"
                        >
                          계속하기
                        </Link>
                      ) : null}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
