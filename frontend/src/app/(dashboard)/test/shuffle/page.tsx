'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@clerk/nextjs';
import { useRouter } from 'next/navigation';
import { Shuffle, BookOpen, ChevronRight } from 'lucide-react';

interface StudySet {
  id: string;
  name: string;
  total_questions: number;
  total_materials: number;
  created_at: string;
}

export default function ShufflePracticePage() {
  const router = useRouter();
  const { getToken } = useAuth();
  const [studySets, setStudySets] = useState<StudySet[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStudySets();
  }, []);

  const fetchStudySets = async () => {
    try {
      setLoading(true);
      const token = await getToken();
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/study-sets`,
        {
          headers: { 'Authorization': `Bearer ${token}` },
        }
      );

      if (response.ok) {
        const data = await response.json();
        setStudySets(data.data || []);
      }
    } catch (error) {
      console.error('Failed to fetch study sets:', error);
    } finally {
      setLoading(false);
    }
  };

  const startShuffleTest = async (studySetId: string) => {
    try {
      const token = await getToken();

      // Create test session
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/tests/start`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            study_set_id: studySetId,
            mode: 'random',
            question_count: 30,
            shuffle_options: true,
          }),
        }
      );

      if (!response.ok) {
        throw new Error('Failed to start test');
      }

      const data = await response.json();
      router.push(`/test/${data.data.session_id}`);
    } catch (error) {
      console.error('Failed to start test:', error);
      alert('시험 시작에 실패했습니다.');
    }
  };

  if (loading) {
    return (
      <div className="max-w-5xl mx-auto px-6 py-8">
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600 dark:text-gray-400">로딩 중...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-5xl mx-auto px-6 py-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center gap-3 mb-4">
          <div className="p-3 bg-purple-100 dark:bg-purple-900/20 rounded-lg">
            <Shuffle className="w-6 h-6 text-purple-600 dark:text-purple-400" />
          </div>
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-gray-100">
              섞어풀기
            </h1>
            <p className="text-gray-600 dark:text-gray-400 mt-1">
              문제 순서를 랜덤으로 섞어서 풀어보세요
            </p>
          </div>
        </div>
      </div>

      {/* Study Sets List */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
          문제집 선택
        </h2>

        {studySets.length === 0 ? (
          <div className="text-center py-12">
            <BookOpen className="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-600 dark:text-gray-400 mb-4">
              아직 문제집이 없습니다.
            </p>
            <button
              onClick={() => router.push('/study-sets')}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              문제집 만들기
            </button>
          </div>
        ) : (
          <div className="space-y-3">
            {studySets.map((studySet) => (
              <div
                key={studySet.id}
                className="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors"
              >
                <div className="flex-1">
                  <h3 className="font-medium text-gray-900 dark:text-gray-100 mb-1">
                    {studySet.name}
                  </h3>
                  <div className="flex items-center gap-3 text-sm text-gray-600 dark:text-gray-400">
                    <span>문제 {studySet.total_questions}개</span>
                    <span>•</span>
                    <span>자료 {studySet.total_materials}개</span>
                  </div>
                </div>
                <button
                  onClick={() => startShuffleTest(studySet.id)}
                  disabled={studySet.total_questions === 0}
                  className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed"
                >
                  <Shuffle className="w-4 h-4" />
                  <span>시작하기</span>
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
