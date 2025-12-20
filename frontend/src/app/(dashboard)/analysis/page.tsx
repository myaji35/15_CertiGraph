'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@clerk/nextjs';
import { NotionCard, NotionPageHeader } from '@/components/ui/NotionCard';
import {
  AlertTriangle,
  TrendingUp,
  Brain,
  Target,
  BarChart3,
  Loader2,
  AlertCircle,
  CheckCircle,
  BookOpen,
} from 'lucide-react';

interface WeakConcept {
  concept: string;
  weakness_score: number;
  wrong_count: number;
  total_count: number;
  accuracy_percent: number;
  related_topics: string[];
}

interface WeakConceptsResponse {
  weak_concepts: WeakConcept[];
  insight: string | null;
  total_questions: number;
  total_correct: number;
  overall_accuracy: number;
}

interface SubjectScore {
  subject_id: string;
  name: string;
  score: number;
  correct_count: number;
  total_count: number;
  is_cutoff: boolean;
  topics: { name: string; score: number; correct: number; total: number }[];
}

interface ExamPrediction {
  predicted_score: number;
  pass_probability: 'high' | 'medium' | 'low' | 'danger' | 'unknown';
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

const probabilityLabels = {
  high: { text: '합격 가능', color: 'text-green-600', bg: 'bg-green-100', borderColor: 'border-green-500' },
  medium: { text: '합격 근접', color: 'text-blue-600', bg: 'bg-blue-100', borderColor: 'border-blue-500' },
  low: { text: '노력 필요', color: 'text-yellow-600', bg: 'bg-yellow-100', borderColor: 'border-yellow-500' },
  danger: { text: '위험', color: 'text-red-600', bg: 'bg-red-100', borderColor: 'border-red-500' },
  unknown: { text: '--', color: 'text-gray-600', bg: 'bg-gray-100', borderColor: 'border-gray-500' },
};

export default function AnalysisPage() {
  const { getToken } = useAuth();
  const [loading, setLoading] = useState(true);
  const [weakConcepts, setWeakConcepts] = useState<WeakConceptsResponse | null>(null);
  const [prediction, setPrediction] = useState<ExamPrediction | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const token = await getToken();
        if (!token) return;

        const [weakRes, predRes] = await Promise.all([
          fetch(`${process.env.NEXT_PUBLIC_API_URL}/v1/analysis/weak-concepts`, {
            headers: { Authorization: `Bearer ${token}` },
          }),
          fetch(`${process.env.NEXT_PUBLIC_API_URL}/v1/analysis/exam-prediction`, {
            headers: { Authorization: `Bearer ${token}` },
          }),
        ]);

        if (weakRes.ok) {
          const data = await weakRes.json();
          setWeakConcepts(data.data);
        }

        if (predRes.ok) {
          const data = await predRes.json();
          setPrediction(data.data);
        }
      } catch (err) {
        console.error('Failed to fetch analysis data:', err);
        setError('데이터를 불러오는 중 오류가 발생했습니다.');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [getToken]);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-12">
        <AlertCircle className="w-12 h-12 text-red-500 mb-4" />
        <p className="text-gray-600">{error}</p>
      </div>
    );
  }

  const hasData = (weakConcepts?.total_questions || 0) > 0;
  const probLabel = prediction ? probabilityLabels[prediction.pass_probability] : probabilityLabels.unknown;

  // Filter strong subjects (accuracy >= 70%)
  const strongSubjects = prediction?.subject_scores?.filter(
    s => s.total_count >= 3 && s.score >= 70
  ) || [];

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="취약점 분석"
        icon="🎯"
        breadcrumbs={[{ label: '홈' }, { label: '취약점 분석' }]}
      />

      {/* No Data State */}
      {!hasData && (
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-8 text-center">
          <BookOpen className="w-16 h-16 text-blue-500 mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-blue-900 mb-2">
            아직 분석할 데이터가 없습니다
          </h3>
          <p className="text-blue-700 mb-4">
            모의고사를 응시하면 취약점 분석 결과를 확인할 수 있습니다.
          </p>
          <a
            href="/dashboard/study-sets"
            className="inline-block px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            학습 세트 보기
          </a>
        </div>
      )}

      {hasData && (
        <>
          {/* Exam Prediction Summary */}
          {prediction && prediction.predicted_score > 0 && (
            <div className={`bg-white rounded-lg border-2 ${probLabel.borderColor} p-6`}>
              <div className="flex items-center justify-between flex-wrap gap-4">
                <div>
                  <h2 className="text-lg font-semibold text-gray-900 mb-3">합격 예측</h2>
                  <div className="flex items-center gap-6">
                    <div>
                      <p className="text-sm text-gray-500">예상 점수</p>
                      <p className="text-3xl font-bold text-gray-900">{prediction.predicted_score}점</p>
                    </div>
                    <div className={`px-6 py-3 rounded-lg ${probLabel.bg}`}>
                      <p className={`text-xl font-bold ${probLabel.color}`}>{probLabel.text}</p>
                    </div>
                    <div>
                      <p className="text-sm text-gray-500">정답률</p>
                      <p className="text-xl font-semibold text-gray-900">
                        {weakConcepts?.overall_accuracy || 0}%
                      </p>
                    </div>
                  </div>
                </div>
                {prediction.cutoff_subjects.length > 0 && (
                  <div className="bg-red-50 px-4 py-3 rounded-lg">
                    <p className="text-sm text-red-600 font-medium flex items-center gap-2">
                      <AlertTriangle className="w-4 h-4" />
                      과락 위험 과목
                    </p>
                    <p className="text-red-700 font-semibold">
                      {prediction.cutoff_subjects.join(', ')}
                    </p>
                  </div>
                )}
              </div>
              {prediction.recommendation && (
                <div className="mt-4 pt-4 border-t border-gray-200">
                  <p className="text-gray-700">{prediction.recommendation}</p>
                </div>
              )}
            </div>
          )}

          {/* AI Insight */}
          {weakConcepts?.insight && (
            <NotionCard title="AI 학습 코치" icon={<Brain className="w-5 h-5 text-purple-500" />}>
              <div className="p-4 bg-purple-50 dark:bg-purple-900/20 rounded-lg">
                <p className="text-purple-900 dark:text-purple-100">{weakConcepts.insight}</p>
              </div>
            </NotionCard>
          )}

          {/* Subject Scores */}
          {prediction?.subject_scores && prediction.subject_scores.length > 0 && (
            <NotionCard title="과목별 성적" icon={<BarChart3 className="w-5 h-5" />}>
              <div className="p-4 space-y-4">
                {prediction.subject_scores.map((subject) => (
                  <div key={subject.subject_id} className="space-y-2">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        {subject.is_cutoff ? (
                          <AlertTriangle className="w-5 h-5 text-red-500" />
                        ) : subject.score >= 60 ? (
                          <CheckCircle className="w-5 h-5 text-green-500" />
                        ) : (
                          <AlertCircle className="w-5 h-5 text-yellow-500" />
                        )}
                        <span className="font-medium">{subject.name}</span>
                        <span className="text-sm text-gray-500">({subject.subject_id})</span>
                      </div>
                      <div className="text-right">
                        <span
                          className={`text-2xl font-bold ${
                            subject.is_cutoff
                              ? 'text-red-600'
                              : subject.score >= 60
                              ? 'text-green-600'
                              : 'text-yellow-600'
                          }`}
                        >
                          {subject.score}%
                        </span>
                        <p className="text-xs text-gray-500">
                          {subject.correct_count}/{subject.total_count}문제
                        </p>
                      </div>
                    </div>
                    <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-3">
                      <div
                        className={`h-3 rounded-full transition-all ${
                          subject.is_cutoff
                            ? 'bg-red-500'
                            : subject.score >= 60
                            ? 'bg-green-500'
                            : 'bg-yellow-500'
                        }`}
                        style={{ width: `${Math.min(subject.score, 100)}%` }}
                      />
                    </div>
                    {/* Topic breakdown */}
                    {subject.topics.length > 0 && (
                      <div className="ml-6 mt-2 space-y-1">
                        {subject.topics.map((topic, idx) => (
                          <div key={idx} className="flex items-center justify-between text-sm">
                            <span className="text-gray-600">{topic.name}</span>
                            <span
                              className={`font-medium ${
                                topic.score < 40
                                  ? 'text-red-600'
                                  : topic.score < 60
                                  ? 'text-yellow-600'
                                  : 'text-green-600'
                              }`}
                            >
                              {topic.score}% ({topic.correct}/{topic.total})
                            </span>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                ))}
                <div className="pt-4 mt-4 border-t border-gray-200 dark:border-gray-700 flex items-center justify-between text-sm">
                  <span className="text-gray-500">
                    합격 기준: 과목별 {prediction.pass_criteria.cutoff_score}점 이상,
                    전체 평균 {prediction.pass_criteria.pass_average}점 이상
                  </span>
                </div>
              </div>
            </NotionCard>
          )}

          {/* Weak Concepts and Strong Areas */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Weak Concepts */}
            <NotionCard
              title="취약 분야"
              icon={<AlertTriangle className="w-5 h-5 text-red-500" />}
            >
              <div className="p-4 space-y-3">
                {weakConcepts?.weak_concepts && weakConcepts.weak_concepts.length > 0 ? (
                  weakConcepts.weak_concepts.map((concept, index) => (
                    <div key={index} className="space-y-2">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <span className="text-lg font-bold text-red-500">#{index + 1}</span>
                          <span className="font-medium">{concept.concept}</span>
                        </div>
                        <div className="text-right">
                          <span className="text-2xl font-bold text-red-600">
                            {concept.accuracy_percent}%
                          </span>
                          <p className="text-xs text-gray-500">정답률</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-4 text-sm text-gray-600 dark:text-gray-400">
                        <span>총 {concept.total_count}문제</span>
                        <span>•</span>
                        <span>오답 {concept.wrong_count}문제</span>
                      </div>
                      <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                        <div
                          className="bg-red-500 h-2 rounded-full"
                          style={{ width: `${concept.accuracy_percent}%` }}
                        />
                      </div>
                      {concept.related_topics.length > 0 && (
                        <div className="flex flex-wrap gap-1 mt-1">
                          {concept.related_topics.map((topic, tidx) => (
                            <span
                              key={tidx}
                              className="text-xs px-2 py-0.5 bg-red-100 text-red-700 rounded"
                            >
                              {topic}
                            </span>
                          ))}
                        </div>
                      )}
                    </div>
                  ))
                ) : (
                  <div className="text-center py-8 text-gray-500">
                    <CheckCircle className="w-12 h-12 mx-auto mb-2 text-green-500" />
                    <p>취약 분야가 없습니다!</p>
                    <p className="text-sm">전체적으로 우수한 성적입니다.</p>
                  </div>
                )}
              </div>
            </NotionCard>

            {/* Strong Areas */}
            <NotionCard
              title="강점 분야"
              icon={<TrendingUp className="w-5 h-5 text-green-500" />}
            >
              <div className="p-4 space-y-3">
                {strongSubjects.length > 0 ? (
                  strongSubjects.map((subject, index) => (
                    <div key={index} className="space-y-2">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <span className="text-lg font-bold text-green-500">#{index + 1}</span>
                          <span className="font-medium">{subject.name}</span>
                        </div>
                        <div className="text-right">
                          <span className="text-2xl font-bold text-green-600">{subject.score}%</span>
                          <p className="text-xs text-gray-500">정답률</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-4 text-sm text-gray-600 dark:text-gray-400">
                        <span>총 {subject.total_count}문제</span>
                        <span>•</span>
                        <span>정답 {subject.correct_count}문제</span>
                      </div>
                      <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                        <div
                          className="bg-green-500 h-2 rounded-full"
                          style={{ width: `${subject.score}%` }}
                        />
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="text-center py-8 text-gray-500">
                    <Target className="w-12 h-12 mx-auto mb-2 text-gray-400" />
                    <p>강점 분야를 파악 중입니다</p>
                    <p className="text-sm">더 많은 문제를 풀어보세요!</p>
                  </div>
                )}
              </div>
            </NotionCard>
          </div>

          {/* Study Stats Summary */}
          <NotionCard title="학습 통계" icon={<BarChart3 className="w-5 h-5" />}>
            <div className="p-4">
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="text-center p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
                  <p className="text-3xl font-bold text-gray-900 dark:text-white">
                    {weakConcepts?.total_questions || 0}
                  </p>
                  <p className="text-sm text-gray-500">총 문제</p>
                </div>
                <div className="text-center p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
                  <p className="text-3xl font-bold text-green-600">
                    {weakConcepts?.total_correct || 0}
                  </p>
                  <p className="text-sm text-gray-500">정답</p>
                </div>
                <div className="text-center p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
                  <p className="text-3xl font-bold text-red-600">
                    {(weakConcepts?.total_questions || 0) - (weakConcepts?.total_correct || 0)}
                  </p>
                  <p className="text-sm text-gray-500">오답</p>
                </div>
                <div className="text-center p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
                  <p className="text-3xl font-bold text-blue-600">
                    {weakConcepts?.overall_accuracy || 0}%
                  </p>
                  <p className="text-sm text-gray-500">정답률</p>
                </div>
              </div>
            </div>
          </NotionCard>
        </>
      )}
    </div>
  );
}
