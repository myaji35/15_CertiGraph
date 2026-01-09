'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@clerk/nextjs';
import { FileText, Calendar, Eye, Edit, Trash2, Plus, Search, Filter } from 'lucide-react';

interface Content {
  id: string;
  title: string;
  certification_name: string;
  content_type: 'pdf' | 'video' | 'article';
  description: string;
  file_url?: string;
  page_count?: number;
  created_at: string;
  updated_at: string;
  views: number;
  status: 'published' | 'draft';
}

export default function AdminContentPage() {
  const { getToken, isLoaded, isSignedIn } = useAuth();
  const [contents, setContents] = useState<Content[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState<string>('all');
  const [filterStatus, setFilterStatus] = useState<string>('all');

  useEffect(() => {
    if (isLoaded && isSignedIn) {
      fetchContents();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isLoaded, isSignedIn]);

  const fetchContents = async () => {
    try {
      setLoading(true);
      const token = await getToken();
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/content`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const data = await response.json();
        setContents(data.contents || []);
      } else {
        console.error('Failed to fetch contents:', response.status);
        // Use mock data for testing with 2026 사회복지사1급
        setContents([
          {
            id: '1',
            title: '2026 사회복지사1급 핵심 이론 PDF',
            certification_name: '사회복지사1급',
            content_type: 'pdf',
            description: '2026년 시험 대비 핵심 이론 정리',
            file_url: '/content/social-worker-2026.pdf',
            page_count: 320,
            created_at: '2025-12-01T00:00:00Z',
            updated_at: '2026-01-01T00:00:00Z',
            views: 1542,
            status: 'published'
          },
          {
            id: '2',
            title: '정신건강사회복지론 요약',
            certification_name: '사회복지사1급',
            content_type: 'article',
            description: '정신건강사회복지론 핵심 개념 정리',
            created_at: '2025-11-15T00:00:00Z',
            updated_at: '2025-12-20T00:00:00Z',
            views: 892,
            status: 'published'
          },
          {
            id: '3',
            title: '사회복지정책론 기출문제 해설',
            certification_name: '사회복지사1급',
            content_type: 'pdf',
            description: '최근 5개년 기출문제 상세 해설',
            file_url: '/content/policy-past-papers.pdf',
            page_count: 180,
            created_at: '2025-12-10T00:00:00Z',
            updated_at: '2025-12-28T00:00:00Z',
            views: 2103,
            status: 'published'
          },
        ]);
      }
    } catch (err: any) {
      console.error('Failed to fetch contents:', err);
      alert(`요청 실패: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('정말로 이 콘텐츠를 삭제하시겠습니까?')) return;

    try {
      const token = await getToken();
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/content/${id}`, {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        setContents(contents.filter(c => c.id !== id));
        alert('콘텐츠가 삭제되었습니다.');
      } else {
        alert('삭제에 실패했습니다.');
      }
    } catch (err: any) {
      console.error('Delete failed:', err);
      alert(`삭제 실패: ${err.message}`);
    }
  };

  const filteredContents = contents.filter(content => {
    const matchesSearch = content.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         content.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesType = filterType === 'all' || content.content_type === filterType;
    const matchesStatus = filterStatus === 'all' || content.status === filterStatus;
    return matchesSearch && matchesType && matchesStatus;
  });

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">공식 콘텐츠 관리</h1>
          <p className="text-gray-600 mt-2">학습 자료 및 콘텐츠 관리</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
          <Plus className="w-5 h-5" />
          콘텐츠 추가
        </button>
      </div>

      {/* 검색 및 필터 */}
      <div className="bg-white rounded-lg shadow p-4 mb-6">
        <div className="flex gap-4 items-center">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="text"
              placeholder="콘텐츠 검색..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <select
            value={filterType}
            onChange={(e) => setFilterType(e.target.value)}
            className="px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">모든 유형</option>
            <option value="pdf">PDF</option>
            <option value="video">동영상</option>
            <option value="article">아티클</option>
          </select>
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">모든 상태</option>
            <option value="published">게시됨</option>
            <option value="draft">임시저장</option>
          </select>
        </div>
      </div>

      {/* 콘텐츠 목록 */}
      <div className="bg-white rounded-lg shadow">
        <div className="p-6 border-b border-gray-200">
          <h2 className="text-lg font-semibold">전체 콘텐츠 ({filteredContents.length}개)</h2>
        </div>
        <div className="overflow-x-auto">
          {loading ? (
            <div className="text-center py-12 text-gray-500">
              <p>로딩 중...</p>
            </div>
          ) : filteredContents.length === 0 ? (
            <div className="text-center py-12 text-gray-500">
              <p>등록된 콘텐츠가 없습니다.</p>
            </div>
          ) : (
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    콘텐츠
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    자격증
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    유형
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    상태
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    조회수
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    수정일
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    작업
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredContents.map((content) => (
                  <tr key={content.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <div className="flex items-start">
                        <FileText className="w-5 h-5 text-gray-400 mr-3 mt-0.5" />
                        <div>
                          <div className="text-sm font-medium text-gray-900">{content.title}</div>
                          <div className="text-sm text-gray-500 mt-1">{content.description}</div>
                          {content.page_count && (
                            <div className="text-xs text-gray-400 mt-1">{content.page_count}페이지</div>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                        {content.certification_name}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <ContentTypeBadge type={content.content_type} />
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <StatusBadge status={content.status} />
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center text-sm text-gray-500">
                        <Eye className="w-4 h-4 mr-1" />
                        {content.views.toLocaleString()}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center text-sm text-gray-500">
                        <Calendar className="w-4 h-4 mr-2" />
                        {new Date(content.updated_at).toLocaleDateString('ko-KR')}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                          title="수정"
                        >
                          <Edit className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleDelete(content.id)}
                          className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                          title="삭제"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}

function ContentTypeBadge({ type }: { type: string }) {
  const styles = {
    pdf: 'bg-red-100 text-red-800',
    video: 'bg-purple-100 text-purple-800',
    article: 'bg-green-100 text-green-800',
  };

  const labels = {
    pdf: 'PDF',
    video: '동영상',
    article: '아티클',
  };

  return (
    <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${styles[type as keyof typeof styles]}`}>
      {labels[type as keyof typeof labels]}
    </span>
  );
}

function StatusBadge({ status }: { status: string }) {
  const styles = {
    published: 'bg-green-100 text-green-800',
    draft: 'bg-yellow-100 text-yellow-800',
  };

  const labels = {
    published: '게시됨',
    draft: '임시저장',
  };

  return (
    <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${styles[status as keyof typeof styles]}`}>
      {labels[status as keyof typeof labels]}
    </span>
  );
}
