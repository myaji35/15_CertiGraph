"use client";

import { useEffect, useState } from "react";
import { useAuth, useUser } from "@clerk/nextjs";
import Link from "next/link";

interface DashboardStats {
  study_set_count: number;
  total_questions: number;
  test_count: number;
  avg_accuracy: number;
  recent_activity: {
    session_id: string;
    study_set_name: string;
    score: number;
    total: number;
    percentage: number;
    completed_at: string;
  }[];
  has_data: boolean;
}

interface ExamPrediction {
  predicted_score: number;
  pass_probability: "high" | "medium" | "low" | "danger" | "unknown";
  is_passing: boolean;
  cutoff_subjects: string[];
}

const probabilityLabels = {
  high: { text: "합격 가능", color: "text-green-600", bg: "bg-green-100" },
  medium: { text: "합격 근접", color: "text-blue-600", bg: "bg-blue-100" },
  low: { text: "노력 필요", color: "text-yellow-600", bg: "bg-yellow-100" },
  danger: { text: "위험", color: "text-red-600", bg: "bg-red-100" },
  unknown: { text: "--", color: "text-gray-600", bg: "bg-gray-100" },
};

export default function DashboardPage() {
  const { getToken } = useAuth();
  const { user } = useUser();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [prediction, setPrediction] = useState<ExamPrediction | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const token = await getToken();
        if (!token) return;

        const [statsRes, predictionRes] = await Promise.all([
          fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/analysis/dashboard`, {
            headers: { Authorization: `Bearer ${token}` },
          }),
          fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/analysis/exam-prediction`, {
            headers: { Authorization: `Bearer ${token}` },
          }),
        ]);

        if (statsRes.ok) {
          const data = await statsRes.json();
          setStats(data.data);
        }

        if (predictionRes.ok) {
          const data = await predictionRes.json();
          setPrediction(data.data);
        }
      } catch (err) {
        console.error("Failed to fetch dashboard data:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [getToken]);

  const userName = user?.firstName || user?.emailAddresses?.[0]?.emailAddress?.split("@")[0] || "사용자";
  const probLabel = prediction ? probabilityLabels[prediction.pass_probability] : probabilityLabels.unknown;

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">
        {userName}님, 환영합니다!
      </h1>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-100">
          <p className="text-sm text-gray-500">총 학습 문제</p>
          <p className="text-3xl font-bold text-gray-900">{stats?.total_questions || 0}</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-100">
          <p className="text-sm text-gray-500">평균 정답률</p>
          <p className="text-3xl font-bold text-gray-900">
            {stats?.avg_accuracy ? `${stats.avg_accuracy}%` : "--%"}
          </p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-100">
          <p className="text-sm text-gray-500">학습 세트</p>
          <p className="text-3xl font-bold text-gray-900">{stats?.study_set_count || 0}개</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-100">
          <p className="text-sm text-gray-500">모의고사 응시</p>
          <p className="text-3xl font-bold text-gray-900">{stats?.test_count || 0}회</p>
        </div>
      </div>

      {/* Exam Prediction Summary */}
      {prediction && prediction.predicted_score > 0 && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-8">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold text-gray-900 mb-2">합격 예측</h2>
              <div className="flex items-center gap-4">
                <div>
                  <p className="text-sm text-gray-500">예상 점수</p>
                  <p className="text-2xl font-bold text-gray-900">{prediction.predicted_score}점</p>
                </div>
                <div className={`px-4 py-2 rounded-lg ${probLabel.bg}`}>
                  <p className={`text-lg font-semibold ${probLabel.color}`}>{probLabel.text}</p>
                </div>
              </div>
            </div>
            {prediction.cutoff_subjects.length > 0 && (
              <div className="text-right">
                <p className="text-sm text-red-600 font-medium">과락 위험 과목</p>
                <p className="text-red-700">{prediction.cutoff_subjects.join(", ")}</p>
              </div>
            )}
            <Link
              href="/dashboard/analysis"
              className="text-blue-600 hover:underline text-sm"
            >
              상세 보기 →
            </Link>
          </div>
        </div>
      )}

      {/* Recent Activity */}
      {stats?.recent_activity && stats.recent_activity.length > 0 ? (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-8">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">최근 학습 활동</h2>
          <div className="space-y-3">
            {stats.recent_activity.map((activity) => (
              <Link
                key={activity.session_id}
                href={`/dashboard/test/result/${activity.session_id}`}
                className="flex items-center justify-between p-3 rounded-lg border border-gray-100 hover:bg-gray-50 transition-colors"
              >
                <div>
                  <p className="font-medium text-gray-900">{activity.study_set_name}</p>
                  <p className="text-sm text-gray-500">
                    {new Date(activity.completed_at).toLocaleDateString("ko-KR", {
                      month: "short",
                      day: "numeric",
                      hour: "2-digit",
                      minute: "2-digit",
                    })}
                  </p>
                </div>
                <div className="text-right">
                  <p
                    className={`text-lg font-bold ${
                      activity.percentage >= 60 ? "text-green-600" : "text-red-600"
                    }`}
                  >
                    {activity.percentage}%
                  </p>
                  <p className="text-sm text-gray-500">
                    {activity.score}/{activity.total}
                  </p>
                </div>
              </Link>
            ))}
          </div>
        </div>
      ) : null}

      {/* Onboarding - Show when no data */}
      {!stats?.has_data && (
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-6">
          <h2 className="text-lg font-semibold text-blue-900 mb-2">
            첫 번째 PDF를 업로드하고 학습을 시작해보세요!
          </h2>
          <p className="text-blue-700 mb-4">
            사회복지사 1급 기출문제 PDF를 업로드하면 AI가 자동으로 문제를 분석합니다.
          </p>
          <Link
            href="/dashboard/study-sets/new"
            className="inline-block bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
          >
            PDF 업로드하기
          </Link>
        </div>
      )}

      {/* Quick Actions */}
      {stats?.has_data && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Link
            href="/dashboard/study-sets/new"
            className="flex items-center gap-3 p-4 bg-white rounded-lg shadow-sm border border-gray-200 hover:bg-gray-50 transition-colors"
          >
            <div className="p-2 bg-blue-100 rounded-lg">
              <svg className="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
              </svg>
            </div>
            <div>
              <p className="font-medium text-gray-900">새 PDF 업로드</p>
              <p className="text-sm text-gray-500">기출문제 추가</p>
            </div>
          </Link>
          <Link
            href="/dashboard/study-sets"
            className="flex items-center gap-3 p-4 bg-white rounded-lg shadow-sm border border-gray-200 hover:bg-gray-50 transition-colors"
          >
            <div className="p-2 bg-green-100 rounded-lg">
              <svg className="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
            </div>
            <div>
              <p className="font-medium text-gray-900">모의고사 응시</p>
              <p className="text-sm text-gray-500">실력 점검하기</p>
            </div>
          </Link>
          <Link
            href="/dashboard/analysis"
            className="flex items-center gap-3 p-4 bg-white rounded-lg shadow-sm border border-gray-200 hover:bg-gray-50 transition-colors"
          >
            <div className="p-2 bg-purple-100 rounded-lg">
              <svg className="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
              </svg>
            </div>
            <div>
              <p className="font-medium text-gray-900">취약점 분석</p>
              <p className="text-sm text-gray-500">과목별 성적 확인</p>
            </div>
          </Link>
        </div>
      )}
    </div>
  );
}
