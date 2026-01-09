'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@clerk/nextjs';
import { Award, Calendar, Plus, Edit, Trash2, Eye, Users, BookOpen } from 'lucide-react';

interface ExamDate {
  id: string;
  exam_date: string;
  registration_start: string;
  registration_end: string;
  active_subscriptions: number;
}

interface Certification {
  id: string;
  name: string;
  short_name: string;
  category: string;
  description: string;
  exam_dates: ExamDate[];
  total_subscribers: number;
  total_questions: number;
  created_at: string;
  updated_at: string;
  is_active: boolean;
}

export default function AdminCertificationsPage() {
  const { getToken, isLoaded, isSignedIn } = useAuth();
  const [certifications, setCertifications] = useState<Certification[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCert, setSelectedCert] = useState<Certification | null>(null);
  const [showDetailModal, setShowDetailModal] = useState(false);

  useEffect(() => {
    if (isLoaded && isSignedIn) {
      fetchCertifications();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isLoaded, isSignedIn]);

  const fetchCertifications = async () => {
    try {
      setLoading(true);
      const token = await getToken();
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/v1/certifications`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const data = await response.json();
        setCertifications(data.certifications || []);
      } else {
        console.error('Failed to fetch certifications:', response.status);
        // Use mock data for testing with 2026 사회복지사1급
        setCertifications([
          {
            id: 'cert_social_worker_1',
            name: '사회복지사1급',
            short_name: '사복1급',
            category: 'national',
            description: '사회복지 전문인력 양성을 위한 국가자격증',
            exam_dates: [
              {
                id: 'exam_2026_01',
                exam_date: '2026-01-18',
                registration_start: '2025-11-01',
                registration_end: '2025-12-15',
                active_subscriptions: 45
              },
              {
                id: 'exam_2026_02',
                exam_date: '2026-07-19',
                registration_start: '2026-05-01',
                registration_end: '2026-06-15',
                active_subscriptions: 0
              }
            ],
            total_subscribers: 128,
            total_questions: 850,
            created_at: '2025-10-01T00:00:00Z',
            updated_at: '2026-01-01T00:00:00Z',
            is_active: true
          },
          {
            id: 'cert_info_processing',
            name: '정보처리기사',
            short_name: '정보기사',
            category: 'national',
            description: '정보시스템 개발 및 운영 전문가 자격증',
            exam_dates: [
              {
                id: 'exam_info_2026_01',
                exam_date: '2026-03-07',
                registration_start: '2026-01-15',
                registration_end: '2026-02-20',
                active_subscriptions: 12
              }
            ],
            total_subscribers: 67,
            total_questions: 620,
            created_at: '2025-09-15T00:00:00Z',
            updated_at: '2025-12-20T00:00:00Z',
            is_active: true
          }
        ]);
      }
    } catch (err: any) {
      console.error('Failed to fetch certifications:', err);
      alert(`요청 실패: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleToggleActive = async (cert: Certification) => {
    try {
      const token = await getToken();
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/admin/certifications/${cert.id}/toggle-active`,
        {
          method: 'PATCH',
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (response.ok) {
        setCertifications(certifications.map(c =>
          c.id === cert.id ? { ...c, is_active: !c.is_active } : c
        ));
        alert(`${cert.name}이(가) ${cert.is_active ? '비활성화' : '활성화'}되었습니다.`);
      } else {
        alert('상태 변경에 실패했습니다.');
      }
    } catch (err: any) {
      console.error('Toggle failed:', err);
      alert(`상태 변경 실패: ${err.message}`);
    }
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">자격증 관리</h1>
          <p className="text-gray-600 mt-2">자격증 및 시험일정 관리</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
          <Plus className="w-5 h-5" />
          자격증 추가
        </button>
      </div>

      {/* 통계 카드 */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">전체 자격증</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">{certifications.length}개</p>
            </div>
            <Award className="w-12 h-12 text-blue-500" />
          </div>
        </div>
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">총 구독자</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                {certifications.reduce((sum, c) => sum + c.total_subscribers, 0).toLocaleString()}명
              </p>
            </div>
            <Users className="w-12 h-12 text-green-500" />
          </div>
        </div>
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">총 문제 수</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                {certifications.reduce((sum, c) => sum + c.total_questions, 0).toLocaleString()}개
              </p>
            </div>
            <BookOpen className="w-12 h-12 text-purple-500" />
          </div>
        </div>
      </div>

      {/* 자격증 목록 */}
      <div className="bg-white rounded-lg shadow">
        <div className="p-6 border-b border-gray-200">
          <h2 className="text-lg font-semibold">자격증 목록</h2>
        </div>
        <div className="overflow-x-auto">
          {loading ? (
            <div className="text-center py-12 text-gray-500">
              <p>로딩 중...</p>
            </div>
          ) : certifications.length === 0 ? (
            <div className="text-center py-12 text-gray-500">
              <p>등록된 자격증이 없습니다.</p>
            </div>
          ) : (
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    자격증
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    카테고리
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    시험일정
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    구독자
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    문제수
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    상태
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    작업
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {certifications.map((cert) => (
                  <tr key={cert.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <div className="flex items-center">
                        <Award className="w-5 h-5 text-blue-600 mr-3" />
                        <div>
                          <div className="text-sm font-medium text-gray-900">{cert.name}</div>
                          <div className="text-sm text-gray-500">{cert.description}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <CategoryBadge category={cert.category} />
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">
                        {cert.exam_dates.length}개 일정
                        {cert.exam_dates.length > 0 && (
                          <div className="text-xs text-gray-500 mt-1 flex items-center">
                            <Calendar className="w-3 h-3 mr-1" />
                            다음: {new Date(cert.exam_dates[0].exam_date).toLocaleDateString('ko-KR')}
                          </div>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center text-sm text-gray-900">
                        <Users className="w-4 h-4 text-gray-400 mr-1" />
                        {cert.total_subscribers}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center text-sm text-gray-900">
                        <BookOpen className="w-4 h-4 text-gray-400 mr-1" />
                        {cert.total_questions}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <button
                        onClick={() => handleToggleActive(cert)}
                        className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                          cert.is_active
                            ? 'bg-green-100 text-green-800 hover:bg-green-200'
                            : 'bg-gray-100 text-gray-800 hover:bg-gray-200'
                        } transition-colors`}
                      >
                        {cert.is_active ? '활성' : '비활성'}
                      </button>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => {
                            setSelectedCert(cert);
                            setShowDetailModal(true);
                          }}
                          className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                          title="상세보기"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
                        <button
                          className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
                          title="수정"
                        >
                          <Edit className="w-4 h-4" />
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

      {/* 상세보기 모달 */}
      {showDetailModal && selectedCert && (
        <CertDetailModal
          certification={selectedCert}
          onClose={() => {
            setShowDetailModal(false);
            setSelectedCert(null);
          }}
        />
      )}
    </div>
  );
}

function CategoryBadge({ category }: { category: string }) {
  const styles = {
    national: 'bg-blue-100 text-blue-800',
    private: 'bg-purple-100 text-purple-800',
    international: 'bg-green-100 text-green-800',
  };

  const labels = {
    national: '국가자격증',
    private: '민간자격증',
    international: '국제자격증',
  };

  return (
    <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${styles[category as keyof typeof styles] || styles.national}`}>
      {labels[category as keyof typeof labels] || category}
    </span>
  );
}

function CertDetailModal({
  certification,
  onClose
}: {
  certification: Certification;
  onClose: () => void;
}) {
  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg max-w-2xl w-full p-6 max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-bold flex items-center gap-2">
            <Award className="w-6 h-6 text-blue-600" />
            {certification.name}
          </h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            ✕
          </button>
        </div>

        <div className="space-y-6">
          {/* 기본 정보 */}
          <div>
            <h3 className="text-sm font-semibold text-gray-700 mb-2">기본 정보</h3>
            <div className="bg-gray-50 rounded-lg p-4 space-y-2">
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">약칭:</span>
                <span className="text-sm font-medium">{certification.short_name}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">카테고리:</span>
                <CategoryBadge category={certification.category} />
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">설명:</span>
                <span className="text-sm">{certification.description}</span>
              </div>
            </div>
          </div>

          {/* 통계 */}
          <div>
            <h3 className="text-sm font-semibold text-gray-700 mb-2">통계</h3>
            <div className="grid grid-cols-3 gap-4">
              <div className="bg-blue-50 rounded-lg p-4 text-center">
                <Users className="w-6 h-6 text-blue-600 mx-auto mb-1" />
                <p className="text-xs text-gray-600">총 구독자</p>
                <p className="text-lg font-bold text-gray-900">{certification.total_subscribers}</p>
              </div>
              <div className="bg-purple-50 rounded-lg p-4 text-center">
                <BookOpen className="w-6 h-6 text-purple-600 mx-auto mb-1" />
                <p className="text-xs text-gray-600">총 문제수</p>
                <p className="text-lg font-bold text-gray-900">{certification.total_questions}</p>
              </div>
              <div className="bg-green-50 rounded-lg p-4 text-center">
                <Calendar className="w-6 h-6 text-green-600 mx-auto mb-1" />
                <p className="text-xs text-gray-600">시험일정</p>
                <p className="text-lg font-bold text-gray-900">{certification.exam_dates.length}</p>
              </div>
            </div>
          </div>

          {/* 시험 일정 */}
          <div>
            <h3 className="text-sm font-semibold text-gray-700 mb-2">시험 일정</h3>
            <div className="space-y-3">
              {certification.exam_dates.map((examDate) => (
                <div key={examDate.id} className="border rounded-lg p-4">
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <Calendar className="w-5 h-5 text-blue-600" />
                      <span className="font-medium">
                        {new Date(examDate.exam_date).toLocaleDateString('ko-KR', {
                          year: 'numeric',
                          month: 'long',
                          day: 'numeric',
                        })}
                      </span>
                    </div>
                    <span className="text-sm text-gray-500">
                      활성 구독: {examDate.active_subscriptions}명
                    </span>
                  </div>
                  <div className="text-sm text-gray-600 space-y-1">
                    <p>접수 시작: {new Date(examDate.registration_start).toLocaleDateString('ko-KR')}</p>
                    <p>접수 마감: {new Date(examDate.registration_end).toLocaleDateString('ko-KR')}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="mt-6 flex justify-end">
          <button
            onClick={onClose}
            className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
          >
            닫기
          </button>
        </div>
      </div>
    </div>
  );
}
