"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@clerk/nextjs";
import Link from "next/link";

interface SubjectScore {
  subject_id: string;
  name: string;
  score: number;
  correct_count: number;
  total_count: number;
  is_cutoff: boolean;
  topics: {
    name: string;
    score: number;
    correct: number;
    total: number;
  }[];
}

interface ExamPrediction {
  predicted_score: number;
  pass_probability: "high" | "medium" | "low" | "danger" | "unknown";
  is_passing: boolean;
  cutoff_subjects: string[];
  subject_scores: SubjectScore[];
  recommendation: string;
  total_questions: number;
  total_correct: number;
  pass_criteria: {
    cutoff_score: number;
    pass_average: number;
  };
}

interface WeakConcept {
  topic: string;
  subject: string;
  correct_rate: number;
  total_attempts: number;
  priority: "high" | "medium" | "low";
}

interface WeaknessAnalysis {
  weak_concepts: WeakConcept[];
  recommendations: string[];
  overall_accuracy: number;
  total_questions_attempted: number;
}

const probabilityConfig = {
  high: {
    color: "text-green-600",
    bgColor: "bg-green-100",
    borderColor: "border-green-500",
    label: "합격 가능성 높음",
    icon: "🎯",
  },
  medium: {
    color: "text-blue-600",
    bgColor: "bg-blue-100",
    borderColor: "border-blue-500",
    label: "합격 가능성 보통",
    icon: "📈",
  },
  low: {
    color: "text-yellow-600",
    bgColor: "bg-yellow-100",
    borderColor: "border-yellow-500",
    label: "합격 가능성 낮음",
    icon: "⚠️",
  },
  danger: {
    color: "text-red-600",
    bgColor: "bg-red-100",
    borderColor: "border-red-500",
    label: "합격 위험",
    icon: "🚨",
  },
  unknown: {
    color: "text-gray-600",
    bgColor: "bg-gray-100",
    borderColor: "border-gray-500",
    label: "데이터 부족",
    icon: "❓",
  },
};

export default function AnalysisPage() {
  const { getToken } = useAuth();
  const [prediction, setPrediction] = useState<ExamPrediction | null>(null);
  const [weakness, setWeakness] = useState<WeaknessAnalysis | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchAnalysis = async () => {
      try {
        const token = await getToken();
        if (!token) return;

        // Fetch both analyses in parallel
        const [predictionRes, weaknessRes] = await Promise.all([
          fetch(`${process.env.NEXT_PUBLIC_API_URL}/analysis/exam-prediction`, {
            headers: { Authorization: `Bearer ${token}` },
          }),
          fetch(`${process.env.NEXT_PUBLIC_API_URL}/analysis/weak-concepts`, {
            headers: { Authorization: `Bearer ${token}` },
          }),
        ]);

        if (predictionRes.ok) {
          const predData = await predictionRes.json();
          setPrediction(predData.data);
        }

        if (weaknessRes.ok) {
          const weakData = await weaknessRes.json();
          setWeakness(weakData.data);
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : "분석 데이터를 불러오는데 실패했습니다");
      } finally {
        setLoading(false);
      }
    };

    fetchAnalysis();
  }, [getToken]);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">분석 데이터를 불러오는 중...</p>
        </div>
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

  const probConfig = prediction ? probabilityConfig[prediction.pass_probability] : probabilityConfig.unknown;

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">학습 분석</h1>
        <p className="text-gray-600 mt-1">시험 합격 예측 및 취약 영역 분석</p>
      </div>

      {/* No Data State */}
      {prediction && prediction.total_questions === 0 ? (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center">
          <div className="text-gray-400 mb-4">
            <svg className="w-16 h-16 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={1.5}
                d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
              />
            </svg>
          </div>
          <h3 className="text-lg font-semibold text-gray-900 mb-2">분석할 데이터가 없습니다</h3>
          <p className="text-gray-600 mb-6">
            모의고사를 응시하면 합격 예측과 취약 영역 분석을 받을 수 있습니다.
          </p>
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
        <>
          {/* Pass Prediction Card */}
          {prediction && (
            <div className={`bg-white rounded-lg shadow-sm border-l-4 ${probConfig.borderColor} p-6`}>
              <div className="flex items-start justify-between">
                <div>
                  <h2 className="text-lg font-semibold text-gray-900 mb-1">합격 예측</h2>
                  <div className="flex items-center gap-3">
                    <span className="text-4xl">{probConfig.icon}</span>
                    <div>
                      <p className={`text-2xl font-bold ${probConfig.color}`}>{probConfig.label}</p>
                      <p className="text-gray-600">
                        예상 점수: <span className="font-semibold">{prediction.predicted_score}점</span>
                        <span className="text-sm text-gray-500 ml-2">
                          (합격선: {prediction.pass_criteria.pass_average}점)
                        </span>
                      </p>
                    </div>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-sm text-gray-500">풀이 문제</p>
                  <p className="text-xl font-semibold">
                    {prediction.total_correct} / {prediction.total_questions}
                  </p>
                </div>
              </div>

              {/* Recommendation */}
              <div className="mt-4 p-3 bg-gray-50 rounded-lg">
                <p className="text-sm text-gray-700">{prediction.recommendation}</p>
              </div>
            </div>
          )}

          {/* Cutoff Warning */}
          {prediction && prediction.cutoff_subjects.length > 0 && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4">
              <div className="flex items-center gap-2 text-red-700 mb-2">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                  />
                </svg>
                <span className="font-semibold">과락 위험 과목</span>
              </div>
              <p className="text-red-600">
                다음 과목이 과락 기준({prediction.pass_criteria.cutoff_score}점) 미만입니다:
                <span className="font-semibold ml-2">
                  {prediction.cutoff_subjects.join(", ")}
                </span>
              </p>
            </div>
          )}

          {/* Subject Scores */}
          {prediction && prediction.subject_scores.length > 0 && (
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">과목별 성적</h2>
              <div className="space-y-4">
                {prediction.subject_scores.map((subject) => (
                  <div
                    key={subject.subject_id}
                    className={`p-4 rounded-lg border ${
                      subject.is_cutoff ? "border-red-300 bg-red-50" : "border-gray-200"
                    }`}
                  >
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-2">
                        <span className="font-medium text-gray-900">{subject.subject_id}</span>
                        <span className="text-gray-600">{subject.name}</span>
                        {subject.is_cutoff && (
                          <span className="px-2 py-0.5 text-xs bg-red-100 text-red-700 rounded-full">
                            과락 위험
                          </span>
                        )}
                      </div>
                      <div className="text-right">
                        <span
                          className={`text-xl font-bold ${
                            subject.is_cutoff ? "text-red-600" : subject.score >= 60 ? "text-green-600" : "text-yellow-600"
                          }`}
                        >
                          {subject.score}점
                        </span>
                        <span className="text-sm text-gray-500 ml-2">
                          ({subject.correct_count}/{subject.total_count})
                        </span>
                      </div>
                    </div>

                    {/* Progress Bar */}
                    <div className="w-full bg-gray-200 rounded-full h-2 mb-3">
                      <div
                        className={`h-2 rounded-full transition-all ${
                          subject.is_cutoff
                            ? "bg-red-500"
                            : subject.score >= 60
                            ? "bg-green-500"
                            : "bg-yellow-500"
                        }`}
                        style={{ width: `${Math.min(subject.score, 100)}%` }}
                      />
                    </div>

                    {/* Topic Breakdown */}
                    {subject.topics.length > 0 && (
                      <div className="grid grid-cols-2 md:grid-cols-3 gap-2 mt-3">
                        {subject.topics.map((topic) => (
                          <div
                            key={topic.name}
                            className={`text-xs p-2 rounded ${
                              topic.score < 40
                                ? "bg-red-100 text-red-700"
                                : topic.score < 60
                                ? "bg-yellow-100 text-yellow-700"
                                : "bg-green-100 text-green-700"
                            }`}
                          >
                            <span className="font-medium">{topic.name}</span>
                            <span className="ml-1">({topic.score}%)</span>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Weak Concepts */}
          {weakness && weakness.weak_concepts.length > 0 && (
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">취약 영역</h2>
              <div className="space-y-3">
                {weakness.weak_concepts.map((concept, idx) => (
                  <div
                    key={idx}
                    className="flex items-center justify-between p-3 rounded-lg border border-gray-200"
                  >
                    <div>
                      <span
                        className={`inline-block px-2 py-0.5 text-xs rounded-full mr-2 ${
                          concept.priority === "high"
                            ? "bg-red-100 text-red-700"
                            : concept.priority === "medium"
                            ? "bg-yellow-100 text-yellow-700"
                            : "bg-blue-100 text-blue-700"
                        }`}
                      >
                        {concept.priority === "high" ? "긴급" : concept.priority === "medium" ? "중요" : "보통"}
                      </span>
                      <span className="font-medium text-gray-900">{concept.topic}</span>
                      <span className="text-gray-500 text-sm ml-2">({concept.subject})</span>
                    </div>
                    <div className="text-right">
                      <span
                        className={`font-semibold ${
                          concept.correct_rate < 40 ? "text-red-600" : "text-yellow-600"
                        }`}
                      >
                        {concept.correct_rate.toFixed(0)}%
                      </span>
                      <span className="text-gray-500 text-sm ml-1">
                        ({concept.total_attempts}문제)
                      </span>
                    </div>
                  </div>
                ))}
              </div>

              {/* Recommendations */}
              {weakness.recommendations.length > 0 && (
                <div className="mt-4 p-4 bg-blue-50 rounded-lg">
                  <h3 className="font-medium text-blue-900 mb-2">학습 추천</h3>
                  <ul className="space-y-1">
                    {weakness.recommendations.map((rec, idx) => (
                      <li key={idx} className="text-sm text-blue-800 flex items-start gap-2">
                        <span>•</span>
                        <span>{rec}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          )}

          {/* Study Progress Summary */}
          {weakness && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
                <h3 className="text-sm text-gray-500 mb-1">전체 정답률</h3>
                <p className="text-3xl font-bold text-gray-900">
                  {weakness.overall_accuracy.toFixed(1)}%
                </p>
              </div>
              <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
                <h3 className="text-sm text-gray-500 mb-1">풀이 문제 수</h3>
                <p className="text-3xl font-bold text-gray-900">
                  {weakness.total_questions_attempted}문제
                </p>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}
