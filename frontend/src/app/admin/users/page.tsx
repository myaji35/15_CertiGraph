'use client';

import { useState, useEffect } from 'react';
import { UserPlus, Mail, Calendar, CheckCircle, XCircle, Award, DollarSign, Gift } from 'lucide-react';
import { useAuth } from '@clerk/nextjs';

interface LatestSubscription {
  id: string;
  certification_name: string;
  exam_date: string;
  payment_amount: number;
  payment_method: string;
  created_at: string;
}

interface User {
  clerk_id: string;
  email: string;
  created_at: string;
  subscription_count: number;
  has_active_subscription: boolean;
  latest_subscription: LatestSubscription | null;
}

export default function UsersManagementPage() {
  const { getToken, isLoaded, isSignedIn } = useAuth();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [showSubscriptionModal, setShowSubscriptionModal] = useState(false);

  useEffect(() => {
    if (isLoaded && isSignedIn) {
      fetchUsers();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isLoaded, isSignedIn]);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      console.log('[1] Starting fetchUsers...');
      console.log('[2] API URL:', process.env.NEXT_PUBLIC_API_URL);
      console.log('[3] Full URL:', `${process.env.NEXT_PUBLIC_API_URL}/v1/admin/users`);

      const token = await getToken();
      console.log('[4] Token obtained:', token ? `Yes (${token.substring(0, 20)}...)` : 'No');

      console.log('[5] Making fetch request...');
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/v1/admin/users`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      console.log('[6] Response received. Status:', response.status);

      if (response.ok) {
        const data = await response.json();
        console.log('[7] Users data received:', data);
        setUsers(data.users || []);
      } else {
        const errorText = await response.text();
        console.error('[ERROR] API Error:', response.status, errorText);
        alert(`API 오류: ${response.status} - ${errorText}`);
      }
    } catch (err: any) {
      console.error('[ERROR] Failed to fetch users:', err);
      console.error('[ERROR] Error name:', err.name);
      console.error('[ERROR] Error message:', err.message);
      console.error('[ERROR] Error stack:', err.stack);
      alert(`요청 실패: ${err.message}`);
    } finally {
      console.log('[8] Fetch complete. Setting loading to false');
      setLoading(false);
    }
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">사용자 관리</h1>
          <p className="text-gray-600 mt-2">전체 사용자 목록 및 구독 관리</p>
        </div>
      </div>

      {/* 사용자 목록 */}
      <div className="bg-white rounded-lg shadow">
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-semibold">전체 사용자 ({users.length}명)</h2>
            <button
              onClick={fetchUsers}
              className="text-sm text-blue-600 hover:text-blue-700"
            >
              새로고침
            </button>
          </div>
        </div>
        <div className="overflow-x-auto">
          {loading ? (
            <div className="text-center py-12 text-gray-500">
              <p>로딩 중...</p>
            </div>
          ) : users.length === 0 ? (
            <div className="text-center py-12 text-gray-500">
              <p className="mb-2">등록된 사용자가 없습니다.</p>
            </div>
          ) : (
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    이메일
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    가입일
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    구독 현황
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    최근 구독
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    작업
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {users.map((user) => (
                  <tr key={user.clerk_id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <Mail className="w-4 h-4 text-gray-400 mr-2" />
                        <div className="text-sm font-medium text-gray-900">
                          {user.email}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center text-sm text-gray-500">
                        <Calendar className="w-4 h-4 mr-2" />
                        {new Date(user.created_at).toLocaleDateString('ko-KR')}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center gap-2">
                        {user.has_active_subscription ? (
                          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                            <CheckCircle className="w-3 h-3 mr-1" />
                            활성 구독
                          </span>
                        ) : user.subscription_count > 0 ? (
                          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                            <XCircle className="w-3 h-3 mr-1" />
                            만료됨
                          </span>
                        ) : (
                          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                            <XCircle className="w-3 h-3 mr-1" />
                            미구독
                          </span>
                        )}
                        <span className="text-xs text-gray-500">
                          (총 {user.subscription_count}건)
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      {user.latest_subscription ? (
                        <div className="text-sm">
                          <div className="font-medium text-gray-900">
                            {user.latest_subscription.certification_name}
                          </div>
                          <div className="text-gray-500 text-xs flex items-center gap-2 mt-1">
                            <Calendar className="w-3 h-3" />
                            {new Date(user.latest_subscription.exam_date).toLocaleDateString('ko-KR')}
                            {user.latest_subscription.payment_method === 'admin_promotional' ||
                            user.latest_subscription.payment_method === 'admin_force' ? (
                              <Gift className="w-3 h-3 text-purple-500" title="후원 구독" />
                            ) : (
                              <DollarSign className="w-3 h-3 text-green-500" title="결제 구독" />
                            )}
                          </div>
                        </div>
                      ) : (
                        <div className="text-sm text-gray-400">-</div>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <button
                        onClick={() => {
                          setSelectedUser(user);
                          setShowSubscriptionModal(true);
                        }}
                        className="inline-flex items-center px-3 py-1.5 bg-purple-600 text-white text-xs rounded-lg hover:bg-purple-700 transition-colors"
                      >
                        <Gift className="w-3 h-3 mr-1" />
                        후원 구독
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* 강제 구독 생성 모달 */}
      {showSubscriptionModal && (
        <ForceSubscriptionModal
          user={selectedUser}
          onClose={() => {
            setShowSubscriptionModal(false);
            setSelectedUser(null);
          }}
          getToken={getToken}
        />
      )}
    </div>
  );
}

function ForceSubscriptionModal({
  user,
  onClose,
  getToken
}: {
  user: User | null;
  onClose: () => void;
  getToken: any;
}) {
  const [certifications, setCertifications] = useState<any[]>([]);
  const [selectedCertId, setSelectedCertId] = useState('');
  const [selectedExamDateId, setSelectedExamDateId] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchCertifications();
  }, []);

  const fetchCertifications = async () => {
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/v1/certifications`);
      if (response.ok) {
        const data = await response.json();
        setCertifications(data.certifications || []);
      }
    } catch (err) {
      console.error('Failed to fetch certifications:', err);
    }
  };

  const handleCreateSubscription = async () => {
    if (!selectedCertId || !selectedExamDateId) {
      setError('자격증과 시험일을 모두 선택해주세요.');
      return;
    }

    if (!user) {
      setError('사용자 정보를 찾을 수 없습니다.');
      return;
    }

    try {
      setLoading(true);
      setError('');
      const token = await getToken();

      const selectedCert = certifications.find(c => c.id === selectedCertId);
      const selectedExamDate = selectedCert?.exam_dates.find((d: any) => d.id === selectedExamDateId);

      // Use admin endpoint to create subscription for specific user
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/v1/admin/users/${user.clerk_id}/force-subscription?certification_id=${selectedCertId}&exam_date_id=${selectedExamDateId}`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (response.ok) {
        const result = await response.json();
        alert(`후원 구독이 생성되었습니다!\n\n${result.message}`);
        onClose();
        // Refresh the page to update user list
        window.location.reload();
      } else {
        const errorData = await response.json();
        setError(errorData.detail || '구독 생성에 실패했습니다.');
      }
    } catch (err: any) {
      console.error('Failed to create subscription:', err);
      setError(err.message || '오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  const selectedCert = certifications.find(c => c.id === selectedCertId);

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg max-w-md w-full p-6">
        <h2 className="text-xl font-bold mb-2 flex items-center gap-2">
          <Gift className="w-6 h-6 text-purple-600" />
          후원 구독 생성
        </h2>
        <p className="text-sm text-gray-600 mb-4">
          <strong>{user?.email}</strong> 사용자에게 무료 후원 구독을 생성합니다.
        </p>

        <div className="space-y-4">
          {/* 자격증 선택 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              자격증 선택
            </label>
            <select
              value={selectedCertId}
              onChange={(e) => {
                setSelectedCertId(e.target.value);
                setSelectedExamDateId(''); // Reset exam date
              }}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">자격증을 선택하세요</option>
              {certifications.map((cert) => (
                <option key={cert.id} value={cert.id}>
                  {cert.name}
                </option>
              ))}
            </select>
          </div>

          {/* 시험일 선택 */}
          {selectedCert && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                시험일 선택
              </label>
              <select
                value={selectedExamDateId}
                onChange={(e) => setSelectedExamDateId(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">시험일을 선택하세요</option>
                {selectedCert.exam_dates?.map((examDate: any) => {
                  const date = new Date(examDate.exam_date);
                  const isAvailable = date > new Date();
                  return (
                    <option
                      key={examDate.id}
                      value={examDate.id}
                      disabled={!isAvailable}
                    >
                      {date.toLocaleDateString('ko-KR', {
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric',
                      })}
                      {!isAvailable && ' (종료됨)'}
                    </option>
                  );
                })}
              </select>
            </div>
          )}

          {/* 안내 메시지 */}
          <div className="bg-purple-50 border border-purple-200 rounded-lg p-3">
            <p className="text-sm text-purple-800">
              <Gift className="w-4 h-4 inline mr-1" />
              후원 구독은 결제 없이 무료로 생성됩니다. (payment_method: admin_promotional)
            </p>
          </div>

          {/* 에러 메시지 */}
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-3">
              <p className="text-sm text-red-800">{error}</p>
            </div>
          )}

          {/* 버튼 */}
          <div className="flex gap-3 mt-6">
            <button
              onClick={onClose}
              className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
              disabled={loading}
            >
              취소
            </button>
            <button
              onClick={handleCreateSubscription}
              className="flex-1 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              disabled={loading || !selectedCertId || !selectedExamDateId}
            >
              {loading ? (
                '생성 중...'
              ) : (
                <>
                  <Gift className="w-4 h-4" />
                  후원 구독 생성
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
