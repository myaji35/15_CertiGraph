'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { Plus, Search, Filter, Edit, Trash2, Eye, MoreVertical, FileText, Calendar, Users } from 'lucide-react';

interface StudySet {
  id: string;
  title: string;
  description: string;
  questionCount: number;
  createdAt: string;
  updatedAt: string;
  author: string;
  views: number;
  tests: number;
  status: 'published' | 'draft' | 'archived';
}

export default function AdminStudySets() {
  const [studySets, setStudySets] = useState<StudySet[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [selectedItems, setSelectedItems] = useState<Set<string>>(new Set());

  useEffect(() => {
    // TODO: API에서 실제 데이터 가져오기
    setStudySets([
      {
        id: '1',
        title: '2024 사회복지사 1급 기출문제',
        description: '최신 기출문제 모음집',
        questionCount: 120,
        createdAt: '2024-01-15',
        updatedAt: '2024-01-20',
        author: '관리자',
        views: 1234,
        tests: 89,
        status: 'published'
      },
      {
        id: '2',
        title: '정신건강론 핵심요약',
        description: '주요 개념 정리 및 문제',
        questionCount: 85,
        createdAt: '2024-01-10',
        updatedAt: '2024-01-18',
        author: '김교수',
        views: 987,
        tests: 67,
        status: 'published'
      },
      {
        id: '3',
        title: '사회복지정책론 모의고사',
        description: '실전 모의고사 5회분',
        questionCount: 200,
        createdAt: '2024-01-05',
        updatedAt: '2024-01-12',
        author: '이강사',
        views: 756,
        tests: 45,
        status: 'draft'
      },
    ]);
  }, []);

  const handleDelete = (id: string) => {
    if (confirm('정말로 이 문제집을 삭제하시겠습니까?')) {
      setStudySets(studySets.filter(set => set.id !== id));
      // TODO: API 호출하여 실제 삭제
    }
  };

  const handleBulkDelete = () => {
    if (selectedItems.size === 0) {
      alert('삭제할 항목을 선택해주세요.');
      return;
    }
    if (confirm(`선택한 ${selectedItems.size}개 항목을 삭제하시겠습니까?`)) {
      setStudySets(studySets.filter(set => !selectedItems.has(set.id)));
      setSelectedItems(new Set());
      // TODO: API 호출하여 실제 삭제
    }
  };

  const filteredStudySets = studySets.filter(set => {
    const matchesSearch = set.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         set.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesFilter = filterStatus === 'all' || set.status === filterStatus;
    return matchesSearch && matchesFilter;
  });

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold text-gray-900">문제집 관리</h1>
        <Link
          href="/admin/study-sets/new"
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <Plus className="w-5 h-5" />
          새 문제집 추가
        </Link>
      </div>

      {/* 검색 및 필터 */}
      <div className="bg-white rounded-lg shadow p-4 mb-6">
        <div className="flex gap-4 items-center">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="text"
              placeholder="문제집 검색..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">모든 상태</option>
            <option value="published">게시됨</option>
            <option value="draft">임시저장</option>
            <option value="archived">보관됨</option>
          </select>
          {selectedItems.size > 0 && (
            <button
              onClick={handleBulkDelete}
              className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
            >
              선택 삭제 ({selectedItems.size})
            </button>
          )}
        </div>
      </div>

      {/* 문제집 테이블 */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left">
                <input
                  type="checkbox"
                  onChange={(e) => {
                    if (e.target.checked) {
                      setSelectedItems(new Set(filteredStudySets.map(s => s.id)));
                    } else {
                      setSelectedItems(new Set());
                    }
                  }}
                  checked={selectedItems.size === filteredStudySets.length && filteredStudySets.length > 0}
                />
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                문제집
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                문제 수
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                작성자
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                통계
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                상태
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                수정일
              </th>
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                작업
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {filteredStudySets.map((set) => (
              <tr key={set.id} className="hover:bg-gray-50">
                <td className="px-6 py-4">
                  <input
                    type="checkbox"
                    checked={selectedItems.has(set.id)}
                    onChange={(e) => {
                      const newSelected = new Set(selectedItems);
                      if (e.target.checked) {
                        newSelected.add(set.id);
                      } else {
                        newSelected.delete(set.id);
                      }
                      setSelectedItems(newSelected);
                    }}
                  />
                </td>
                <td className="px-6 py-4">
                  <div>
                    <div className="text-sm font-medium text-gray-900">{set.title}</div>
                    <div className="text-sm text-gray-500">{set.description}</div>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-1 text-sm text-gray-900">
                    <FileText className="w-4 h-4 text-gray-400" />
                    {set.questionCount}
                  </div>
                </td>
                <td className="px-6 py-4 text-sm text-gray-900">
                  {set.author}
                </td>
                <td className="px-6 py-4">
                  <div className="text-sm text-gray-900">
                    <div className="flex items-center gap-1">
                      <Eye className="w-4 h-4 text-gray-400" />
                      {set.views}
                    </div>
                    <div className="flex items-center gap-1">
                      <Users className="w-4 h-4 text-gray-400" />
                      {set.tests}
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <StatusBadge status={set.status} />
                </td>
                <td className="px-6 py-4 text-sm text-gray-500">
                  {set.updatedAt}
                </td>
                <td className="px-6 py-4 text-right">
                  <div className="flex items-center justify-end gap-2">
                    <Link
                      href={`/admin/study-sets/${set.id}/edit`}
                      className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                      title="수정"
                    >
                      <Edit className="w-4 h-4" />
                    </Link>
                    <button
                      onClick={() => handleDelete(set.id)}
                      className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                      title="삭제"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                    <Link
                      href={`/study-sets/${set.id}`}
                      className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
                      title="미리보기"
                    >
                      <Eye className="w-4 h-4" />
                    </Link>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {filteredStudySets.length === 0 && (
          <div className="text-center py-12 text-gray-500">
            검색 결과가 없습니다.
          </div>
        )}
      </div>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const styles = {
    published: 'bg-green-100 text-green-800',
    draft: 'bg-yellow-100 text-yellow-800',
    archived: 'bg-gray-100 text-gray-800',
  };

  const labels = {
    published: '게시됨',
    draft: '임시저장',
    archived: '보관됨',
  };

  return (
    <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${styles[status as keyof typeof styles]}`}>
      {labels[status as keyof typeof labels]}
    </span>
  );
}