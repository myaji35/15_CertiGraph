'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@clerk/nextjs';
import { useRouter } from 'next/navigation';
import { Plus, Search, Book, FileText, Calendar, TrendingUp, Edit2, Trash2, MoreVertical } from 'lucide-react';

interface StudySet {
  id: string;
  name: string;
  certification_id: string;
  total_materials: number;
  total_questions: number;
  created_at: string;
  learning_status?: string;
  description?: string;
}

export default function MyStudySetsPage() {
  const router = useRouter();
  const { getToken } = useAuth();
  const [studySets, setStudySets] = useState<StudySet[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editName, setEditName] = useState('');
  const [editDescription, setEditDescription] = useState('');

  useEffect(() => {
    fetchStudySets();
  }, []);

  const fetchStudySets = async () => {
    try {
      setLoading(true);
      const token = await getToken();

      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/study-sets`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });

      if (response.ok) {
        const data = await response.json();
        setStudySets(data.data || []);
      } else {
        // Fallback to empty array if API fails
        setStudySets([]);
      }
      setLoading(false);
    } catch (error) {
      console.error('Failed to fetch study sets:', error);
      setStudySets([]);
      setLoading(false);
    }
  };

  const handleEdit = (set: StudySet, e: React.MouseEvent) => {
    e.stopPropagation();
    setEditingId(set.id);
    setEditName(set.name);
    setEditDescription(set.description || '');
  };

  const handleSaveEdit = async (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    try {
      const token = await getToken();

      const formData = new FormData();
      formData.append('name', editName);
      formData.append('description', editDescription);

      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/study-sets/${id}`, {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
        body: formData,
      });

      if (!response.ok) {
        throw new Error('Failed to update study set');
      }

      // Refresh the list
      await fetchStudySets();
      setEditingId(null);
    } catch (error) {
      console.error('Failed to update study set:', error);
      alert('문제집 수정에 실패했습니다.');
    }
  };

  const handleCancelEdit = (e: React.MouseEvent) => {
    e.stopPropagation();
    setEditingId(null);
  };

  const handleDelete = async (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    if (!confirm('이 문제집을 삭제하시겠습니까?')) return;

    try {
      const token = await getToken();

      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/study-sets/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` },
      });

      if (!response.ok) {
        throw new Error('Failed to delete study set');
      }

      // Refresh the list
      await fetchStudySets();
    } catch (error) {
      console.error('Failed to delete study set:', error);
      alert('문제집 삭제에 실패했습니다.');
    }
  };

  const filteredSets = studySets.filter(set =>
    set.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="max-w-7xl mx-auto px-6 py-8">
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-2">
            내 문제집
          </h1>
          <p className="text-gray-600 dark:text-gray-400">
            나만의 문제집을 만들고 학습자료를 추가하세요
          </p>
        </div>
        <button
          onClick={() => router.push('/dashboard/study-sets/new')}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <Plus className="w-5 h-5" />
          새 문제집 만들기
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-1">전체 문제집</p>
              <p className="text-3xl font-bold text-gray-900 dark:text-gray-100">
                {studySets.length}
              </p>
            </div>
            <div className="p-3 bg-blue-100 dark:bg-blue-900/20 rounded-lg">
              <Book className="w-8 h-8 text-blue-600 dark:text-blue-400" />
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-1">총 문제 수</p>
              <p className="text-3xl font-bold text-gray-900 dark:text-gray-100">
                {studySets.reduce((sum, set) => sum + (set.total_questions || 0), 0)}
              </p>
            </div>
            <div className="p-3 bg-green-100 dark:bg-green-900/20 rounded-lg">
              <FileText className="w-8 h-8 text-green-600 dark:text-green-400" />
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-1">학습 완료</p>
              <p className="text-3xl font-bold text-gray-900 dark:text-gray-100">0</p>
            </div>
            <div className="p-3 bg-purple-100 dark:bg-purple-900/20 rounded-lg">
              <TrendingUp className="w-8 h-8 text-purple-600 dark:text-purple-400" />
            </div>
          </div>
        </div>
      </div>

      {/* Search */}
      <div className="mb-6">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="문제집 검색..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
      </div>

      {/* Study Sets Grid */}
      {loading ? (
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600 dark:text-gray-400">로딩 중...</p>
        </div>
      ) : filteredSets.length === 0 ? (
        <div className="text-center py-12 bg-white dark:bg-gray-800 rounded-lg shadow">
          <Book className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h3 className="text-xl font-semibold text-gray-900 dark:text-gray-100 mb-2">
            아직 문제집이 없습니다
          </h3>
          <p className="text-gray-600 dark:text-gray-400">
            상단의 "새 문제집 만들기" 버튼을 눌러 문제집을 만들어보세요
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredSets.map((set) => (
            <div
              key={set.id}
              className="bg-white dark:bg-gray-800 rounded-lg shadow hover:shadow-lg transition-all p-6 relative"
            >
              {/* Edit Mode */}
              {editingId === set.id ? (
                <div className="space-y-4" onClick={(e) => e.stopPropagation()}>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      문제집명
                    </label>
                    <input
                      type="text"
                      value={editName}
                      onChange={(e) => setEditName(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="문제집 이름"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      개요
                    </label>
                    <textarea
                      value={editDescription}
                      onChange={(e) => setEditDescription(e.target.value)}
                      rows={3}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="문제집 설명 (선택사항)"
                    />
                  </div>
                  <div className="flex gap-2">
                    <button
                      onClick={(e) => handleSaveEdit(set.id, e)}
                      className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm"
                    >
                      저장
                    </button>
                    <button
                      onClick={handleCancelEdit}
                      className="flex-1 px-4 py-2 border border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors text-sm"
                    >
                      취소
                    </button>
                  </div>
                </div>
              ) : (
                <>
                  {/* View Mode */}
                  <div
                    onClick={() => router.push(`/dashboard/study-sets/${set.id}`)}
                    className="cursor-pointer"
                  >
                    <div className="flex items-start justify-between mb-4">
                      <div className="p-3 bg-blue-100 dark:bg-blue-900/20 rounded-lg">
                        <Book className="w-6 h-6 text-blue-600 dark:text-blue-400" />
                      </div>
                      <div className="flex items-center gap-2">
                        {set.learning_status === 'in_progress' && (
                          <span className="px-2 py-1 bg-yellow-100 dark:bg-yellow-900/20 text-yellow-800 dark:text-yellow-400 text-xs rounded-full">
                            학습 중
                          </span>
                        )}
                      </div>
                    </div>

                    <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2">
                      {set.name}
                    </h3>

                    {set.description && (
                      <p className="text-sm text-gray-600 dark:text-gray-400 mb-4 line-clamp-2">
                        {set.description}
                      </p>
                    )}

                    <div className="flex items-center gap-4 text-sm text-gray-600 dark:text-gray-400 mb-4">
                      <div className="flex items-center gap-1">
                        <FileText className="w-4 h-4" />
                        <span>학습자료 {set.total_materials || 0}개</span>
                      </div>
                      <div className="flex items-center gap-1">
                        <span>문제 {set.total_questions || 0}개</span>
                      </div>
                    </div>

                    <div className="flex items-center gap-2 text-sm text-gray-500 dark:text-gray-500">
                      <Calendar className="w-4 h-4" />
                      <span>{new Date(set.created_at).toLocaleDateString('ko-KR')}</span>
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div className="flex items-center gap-2 mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
                    <button
                      onClick={(e) => handleEdit(set, e)}
                      className="flex items-center gap-1 px-3 py-1.5 text-sm text-blue-600 dark:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
                    >
                      <Edit2 className="w-4 h-4" />
                      수정
                    </button>
                    <button
                      onClick={(e) => handleDelete(set.id, e)}
                      className="flex items-center gap-1 px-3 py-1.5 text-sm text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                    >
                      <Trash2 className="w-4 h-4" />
                      삭제
                    </button>
                  </div>
                </>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
