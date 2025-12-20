'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { useAuth } from '@clerk/nextjs';
import {
  ArrowLeft,
  Book,
  Clock,
  Calendar,
  Play,
  FileText,
  CheckCircle,
  AlertCircle,
  Loader2,
  Trash2,
} from 'lucide-react';

interface StudySet {
  id: string;
  name: string;
  status: 'parsing' | 'processing' | 'ready' | 'failed';
  progress: number;
  current_step: string;
  question_count: number;
  created_at: string;
  exam_name?: string;
  exam_year?: number;
  exam_round?: number;
}

interface Question {
  id: string;
  question_number: number;
  question_text: string;
  options: { number: number; text: string }[];
  correct_answer: number;
  explanation?: string;
  subject?: string;
}

export default function StudySetDetailPage() {
  const params = useParams();
  const router = useRouter();
  const { getToken } = useAuth();
  const [studySet, setStudySet] = useState<StudySet | null>(null);
  const [questions, setQuestions] = useState<Question[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);

  const fetchStudySet = useCallback(async () => {
    try {
      const token = await getToken();
      if (!token) return;

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/v1/study-sets/${params.id}`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (!response.ok) {
        throw new Error('학습 세트를 불러오는데 실패했습니다.');
      }

      const data = await response.json();
      setStudySet(data.data);
      return data.data;
    } catch (err) {
      setError(err instanceof Error ? err.message : '오류가 발생했습니다.');
      return null;
    } finally {
      setLoading(false);
    }
  }, [params.id, getToken]);

  const fetchQuestions = useCallback(async () => {
    try {
      const token = await getToken();
      if (!token) return;

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/v1/study-sets/${params.id}/questions`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (response.ok) {
        const data = await response.json();
        setQuestions(data.data || []);
      }
    } catch (err) {
      console.error('Failed to fetch questions:', err);
    }
  }, [params.id, getToken]);

  // Initial fetch
  useEffect(() => {
    fetchStudySet();
  }, [fetchStudySet]);

  // Poll for status updates while processing
  useEffect(() => {
    if (!studySet) return;
    if (studySet.status === 'parsing' || studySet.status === 'processing') {
      const interval = setInterval(async () => {
        const updated = await fetchStudySet();
        if (updated && updated.status === 'ready') {
          fetchQuestions();
          clearInterval(interval);
        }
      }, 2000);

      return () => clearInterval(interval);
    } else if (studySet.status === 'ready') {
      fetchQuestions();
    }
  }, [studySet?.status, fetchStudySet, fetchQuestions]);

  const handleDelete = async () => {
    if (!confirm('정말로 이 학습 세트를 삭제하시겠습니까?')) return;

    try {
      setDeleting(true);
      const token = await getToken();

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/v1/study-sets/${params.id}`,
        {
          method: 'DELETE',
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (response.ok) {
        router.push('/dashboard/study-sets');
      } else {
        throw new Error('삭제에 실패했습니다.');
      }
    } catch (err) {
      alert(err instanceof Error ? err.message : '오류가 발생했습니다.');
    } finally {
      setDeleting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  if (error || !studySet) {
    return (
      <div className="max-w-2xl mx-auto py-12 text-center">
        <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
        <h2 className="text-xl font-semibold text-gray-900 mb-2">오류 발생</h2>
        <p className="text-gray-600 mb-4">{error || '학습 세트를 찾을 수 없습니다.'}</p>
        <Link
          href="/dashboard/study-sets"
          className="text-blue-600 hover:underline"
        >
          목록으로 돌아가기
        </Link>
      </div>
    );
  }

  const isProcessing = studySet.status === 'parsing' || studySet.status === 'processing';
  const isFailed = studySet.status === 'failed';
  const isReady = studySet.status === 'ready';

  return (
    <div className="max-w-4xl mx-auto">
      {/* Header */}
      <div className="mb-6">
        <Link
          href="/dashboard/study-sets"
          className="inline-flex items-center gap-2 text-gray-500 hover:text-gray-700 mb-4 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          목록으로
        </Link>
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">{studySet.name}</h1>
            <p className="mt-1 text-gray-600">
              {studySet.exam_year && `${studySet.exam_year}년`}
              {studySet.exam_round && ` 제${studySet.exam_round}회`}
              {studySet.exam_name && ` ${studySet.exam_name}`}
            </p>
          </div>
          <button
            onClick={handleDelete}
            disabled={deleting}
            className="p-2 text-gray-400 hover:text-red-600 transition-colors"
            title="삭제"
          >
            <Trash2 className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Processing Status */}
      {isProcessing && (
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-6">
          <div className="flex items-center gap-3 mb-4">
            <Loader2 className="w-6 h-6 text-blue-600 animate-spin" />
            <div>
              <h3 className="font-semibold text-blue-900">문제 추출 중...</h3>
              <p className="text-sm text-blue-700">{studySet.current_step}</p>
            </div>
          </div>
          <div className="w-full bg-blue-200 rounded-full h-2">
            <div
              className="bg-blue-600 h-2 rounded-full transition-all duration-500"
              style={{ width: `${studySet.progress}%` }}
            />
          </div>
          <p className="text-right text-sm text-blue-600 mt-1">{studySet.progress}%</p>
        </div>
      )}

      {/* Failed Status */}
      {isFailed && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-6 mb-6">
          <div className="flex items-center gap-3">
            <AlertCircle className="w-6 h-6 text-red-600" />
            <div>
              <h3 className="font-semibold text-red-900">처리 실패</h3>
              <p className="text-sm text-red-700">{studySet.current_step}</p>
            </div>
          </div>
        </div>
      )}

      {/* Ready Status */}
      {isReady && (
        <div className="bg-green-50 border border-green-200 rounded-lg p-6 mb-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <CheckCircle className="w-6 h-6 text-green-600" />
              <div>
                <h3 className="font-semibold text-green-900">처리 완료</h3>
                <p className="text-sm text-green-700">
                  총 {studySet.question_count}개의 문제가 추출되었습니다.
                </p>
              </div>
            </div>
            <Link
              href={`/dashboard/test?study_set_id=${studySet.id}`}
              className="inline-flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
            >
              <Play className="w-4 h-4" />
              모의고사 시작
            </Link>
          </div>
        </div>
      )}

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <div className="flex items-center gap-2 text-gray-500 mb-1">
            <FileText className="w-4 h-4" />
            <span className="text-sm">문제 수</span>
          </div>
          <p className="text-2xl font-bold text-gray-900">
            {studySet.question_count}
          </p>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <div className="flex items-center gap-2 text-gray-500 mb-1">
            <Clock className="w-4 h-4" />
            <span className="text-sm">예상 시간</span>
          </div>
          <p className="text-2xl font-bold text-gray-900">
            {Math.ceil(studySet.question_count * 1.5)}분
          </p>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <div className="flex items-center gap-2 text-gray-500 mb-1">
            <Calendar className="w-4 h-4" />
            <span className="text-sm">생성일</span>
          </div>
          <p className="text-sm font-medium text-gray-900">
            {new Date(studySet.created_at).toLocaleDateString('ko-KR')}
          </p>
        </div>
      </div>

      {/* Questions Preview */}
      {isReady && questions.length > 0 && (
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">
            문제 미리보기
          </h2>
          <div className="space-y-4">
            {questions.slice(0, 5).map((q) => (
              <div
                key={q.id}
                className="border-b border-gray-100 pb-4 last:border-0"
              >
                <div className="flex items-start gap-3">
                  <span className="flex-shrink-0 w-6 h-6 bg-blue-100 text-blue-600 rounded-full text-sm font-medium flex items-center justify-center">
                    {q.question_number}
                  </span>
                  <div className="flex-1">
                    <p className="text-gray-900 mb-2">{q.question_text}</p>
                    <div className="grid grid-cols-1 gap-1">
                      {q.options.map((opt) => (
                        <div
                          key={opt.number}
                          className={`text-sm px-2 py-1 rounded ${
                            opt.number === q.correct_answer
                              ? 'bg-green-50 text-green-700'
                              : 'text-gray-600'
                          }`}
                        >
                          {opt.number}. {opt.text}
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
          {questions.length > 5 && (
            <p className="text-sm text-gray-500 text-center mt-4">
              외 {questions.length - 5}개 문제 더 있음
            </p>
          )}
        </div>
      )}
    </div>
  );
}
