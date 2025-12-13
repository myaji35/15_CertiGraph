'use client';

import { useState, useEffect } from 'react';
import { useUser, useAuth } from '@clerk/nextjs';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Search, Plus, Book, Calendar, TrendingUp, FileText, Trash2, Edit, Play } from 'lucide-react';

interface StudySet {
  id: string;
  name: string;
  created_at: string;
  question_count: number;
  status: string;
  learning_status?: string;
  last_studied_at?: string;
  exam_name?: string;
  exam_year?: number;
  exam_round?: number;
  exam_session?: number;
  exam_session_name?: string;
  tags?: string[];
  is_cached?: boolean;
}

export default function MyStudySetsPage() {
  const { user, isLoaded } = useUser();
  const { getToken } = useAuth();
  const router = useRouter();
  const [studySets, setStudySets] = useState<StudySet[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    if (isLoaded && !user) {
      router.push('/sign-in');
      return;
    }

    if (user) {
      fetchMyStudySets();
    }
  }, [user, isLoaded, router]);

  const fetchMyStudySets = async () => {
    try {
      setLoading(true);
      const token = await getToken();
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/v1/study-sets`, {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      console.log('Study sets response status:', response.status);

      if (response.ok) {
        const data = await response.json();
        console.log('Study sets data:', data);
        console.log('Study sets array:', data.data);
        setStudySets(data.data || []);
      } else {
        console.error('Failed to fetch study sets:', response.status, await response.text());
      }
    } catch (error) {
      console.error('Failed to fetch study sets:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredStudySets = studySets.filter(set =>
    set.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (!isLoaded || !user) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div>
        {/* 검색 */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6 mb-8">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="text"
              placeholder="문제집 검색..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        {/* 통계 카드 */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
          <StatCard
            icon={<Book className="w-5 h-5" />}
            label="전체 문제집"
            value={studySets.length}
            color="blue"
          />
          <StatCard
            icon={<FileText className="w-5 h-5" />}
            label="총 문제 수"
            value={studySets.reduce((sum, set) => sum + (set.question_count || 0), 0)}
            color="green"
          />
          <StatCard
            icon={<TrendingUp className="w-5 h-5" />}
            label="학습 완료"
            value={studySets.filter(set => set.learning_status === 'learned').length}
            color="purple"
          />
        </div>

        {/* 문제집 목록 */}
        {loading ? (
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          </div>
        ) : filteredStudySets.length === 0 ? (
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-12 text-center">
            <Book className="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-gray-900 dark:text-gray-100 mb-2">
              {searchTerm ? '검색 결과가 없습니다' : '아직 문제집이 없습니다'}
            </h3>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              {searchTerm
                ? '다른 검색어를 시도해보세요'
                : 'PDF를 업로드하여 첫 번째 문제집을 만들어보세요'}
            </p>
            {!searchTerm && (
              <Link
                href="/admin/study-sets"
                className="inline-flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                <Plus className="w-5 h-5" />
                문제집 만들기
              </Link>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredStudySets.map((set) => (
              <StudySetCard key={set.id} studySet={set} onUpdate={fetchMyStudySets} />
            ))}
          </div>
        )}
    </div>
  );
}

function StudySetCard({ studySet, onUpdate }: { studySet: StudySet; onUpdate: () => void }) {
  const router = useRouter();
  const isLearned = studySet.learning_status === 'learned';
  const isNotLearned = studySet.learning_status === 'not_learned';

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm hover:shadow-md transition-all">
      {/* 썸네일 */}
      <div className="h-32 bg-gradient-to-br from-blue-500 to-purple-600 rounded-t-lg flex items-center justify-center relative">
        <Book className="w-12 h-12 text-white" />
        {isLearned && (
          <div className="absolute top-2 right-2 px-2 py-1 bg-green-500 text-white text-xs rounded-full font-semibold">
            학습 완료
          </div>
        )}
      </div>

      {/* 콘텐츠 */}
      <div className="p-6">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2 line-clamp-2">
          {studySet.name}
        </h3>

        <div className="space-y-2 text-sm text-gray-600 dark:text-gray-400 mb-4">
          <div className="flex items-center gap-2">
            <FileText className="w-4 h-4" />
            <span>{studySet.question_count || 0}문제</span>
          </div>
          <div className="flex items-center gap-2">
            <Calendar className="w-4 h-4" />
            <span>{new Date(studySet.created_at).toLocaleDateString('ko-KR')}</span>
          </div>
          {studySet.last_studied_at && (
            <div className="flex items-center gap-2">
              <Play className="w-4 h-4" />
              <span>
                마지막 학습: {new Date(studySet.last_studied_at).toLocaleDateString('ko-KR')}
              </span>
            </div>
          )}
        </div>

        {/* 액션 버튼 */}
        <div className="flex gap-2">
          <Link
            href={`/dashboard/study-sets/${studySet.id}`}
            className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm font-medium"
          >
            <Play className="w-4 h-4" />
            학습하기
          </Link>
          <button
            onClick={() => router.push(`/dashboard/study-sets/${studySet.id}/edit`)}
            className="p-2 text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
            title="수정"
          >
            <Edit className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
}

function StatCard({ icon, label, value, color }: any) {
  const colorClasses = {
    blue: 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400',
    green: 'bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400',
    purple: 'bg-purple-50 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400',
  }[color];

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg p-4 flex items-center gap-3 shadow-sm">
      <div className={`p-2 rounded-lg ${colorClasses}`}>{icon}</div>
      <div>
        <p className="text-sm text-gray-500 dark:text-gray-400">{label}</p>
        <p className="text-lg font-semibold text-gray-900 dark:text-gray-100">{value}</p>
      </div>
    </div>
  );
}
