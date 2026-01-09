'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@clerk/nextjs';
import { useRouter } from 'next/navigation';
import { ArrowLeft, Book } from 'lucide-react';

export default function NewStudySetPage() {
  const router = useRouter();
  const { getToken } = useAuth();
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [certificationId, setCertificationId] = useState('');
  const [examDateId, setExamDateId] = useState('');
  const [userSubscription, setUserSubscription] = useState<any>(null);
  const [certifications, setCertifications] = useState<any[]>([]);
  const [selectedCertification, setSelectedCertification] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchUserSubscription();
    fetchCertifications();
  }, []);

  const fetchUserSubscription = async () => {
    try {
      const token = await getToken();
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/subscriptions/my-subscriptions`, {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const data = await response.json();
        // Get the first active subscription
        if (data.subscriptions && data.subscriptions.length > 0) {
          const subscription = data.subscriptions[0];
          setUserSubscription(subscription);

          // For non-VIP users, set certification from subscription
          if (subscription.id !== 'vip-pass') {
            setCertificationId(subscription.certification_id);
            setExamDateId(subscription.exam_date || '');
          }
        }
      }
    } catch (err) {
      console.error('Error fetching user subscription:', err);
    }
  };

  const fetchCertifications = async () => {
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/certifications`);
      if (response.ok) {
        const data = await response.json();
        setCertifications(data.certifications || []);
      }
    } catch (err) {
      console.error('Error fetching certifications:', err);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!name.trim()) {
      setError('문제집 이름을 입력해주세요.');
      return;
    }

    // For VIP users, use selected certification, otherwise use subscription certification
    const finalCertificationId = userSubscription?.id === 'vip-pass'
      ? selectedCertification
      : certificationId;

    if (!finalCertificationId) {
      if (userSubscription?.id === 'vip-pass') {
        setError('자격증을 선택해주세요.');
      } else {
        setError('이용권이 필요합니다. 먼저 이용권을 구매해주세요.');
      }
      return;
    }

    try {
      setLoading(true);
      setError('');

      const token = await getToken();

      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/study-sets`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name: name,
          description: description || '',
          certification_id: finalCertificationId,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || '문제집 생성에 실패했습니다.');
      }

      const data = await response.json();
      console.log('Study set created:', data);

      // Redirect to study set detail page to add materials
      router.push(`/dashboard/study-sets/${data.study_set.id}`);
    } catch (err: any) {
      console.error('Create study set error:', err);
      setError(err.message || '문제집 생성 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-3xl mx-auto px-6 py-8">
      {/* Header */}
      <div className="mb-8">
        <button
          onClick={() => router.back()}
          className="flex items-center gap-2 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 mb-4"
        >
          <ArrowLeft className="w-5 h-5" />
          뒤로 가기
        </button>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-2">
          새 문제집 만들기
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          문제집 이름을 입력하세요. 자격증과 시험일은 이용권에서 자동으로 설정됩니다.
        </p>
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Study Set Name */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            문제집 이름 *
          </label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="예: 2024년 대비"
            className="w-full px-4 py-3 border border-gray-300 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
            required
          />
        </div>

        {/* Study Set Description */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            문제집 개요
          </label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="이 문제집에 대한 설명을 입력하세요 (선택사항)"
            rows={4}
            className="w-full px-4 py-3 border border-gray-300 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
          />
          <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
            💡 나중에 여러 학습자료(PDF)를 이 문제집에 추가할 수 있습니다
          </p>
        </div>

        {/* Subscription Info */}
        {userSubscription ? (
          userSubscription.id === 'vip-pass' ? (
            // VIP Pass Display
            <div className="bg-gradient-to-r from-purple-50 to-pink-50 dark:from-purple-900/20 dark:to-pink-900/20 border-2 border-purple-300 dark:border-purple-700 rounded-lg p-6">
              <h3 className="font-medium text-purple-900 dark:text-purple-100 mb-2">
                👑 VIP 무료 이용권
              </h3>
              <div className="space-y-1 text-sm text-purple-700 dark:text-purple-300">
                <p>모든 자격증을 무제한으로 이용할 수 있습니다</p>
                <p>상태: 활성화됨</p>
              </div>
              <p className="mt-3 text-sm text-purple-600 dark:text-purple-400">
                VIP 회원님은 모든 기능을 자유롭게 이용하실 수 있습니다
              </p>

              {/* Certification Selection for VIP */}
              <div className="mt-4">
                <label className="block text-sm font-medium text-purple-900 dark:text-purple-100 mb-2">
                  자격증 선택
                </label>
                <select
                  value={selectedCertification}
                  onChange={(e) => setSelectedCertification(e.target.value)}
                  className="w-full px-3 py-2 border border-purple-300 dark:border-purple-700 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-purple-500"
                  required
                >
                  <option value="">자격증을 선택하세요</option>
                  {certifications.map((cert) => (
                    <option key={cert.id} value={cert.id}>
                      {cert.name} - {cert.organization}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          ) : (
            // Regular Subscription Display
            <div className="bg-green-50 dark:bg-green-900/20 border-2 border-green-300 dark:border-green-700 rounded-lg p-6">
              <h3 className="font-medium text-green-900 dark:text-green-100 mb-2">
                ✓ 이용권 정보
              </h3>
              <div className="space-y-1 text-sm text-green-700 dark:text-green-300">
                <p>자격증: {userSubscription.certification_name || '로딩 중...'}</p>
                <p>시험일: {userSubscription.exam_date || '로딩 중...'}</p>
              </div>
              <p className="mt-3 text-sm text-green-600 dark:text-green-400">
                이 정보로 문제집이 자동 생성됩니다
              </p>
            </div>
          )
        ) : (
          <div className="bg-yellow-50 dark:bg-yellow-900/20 border-2 border-yellow-300 dark:border-yellow-700 rounded-lg p-6">
            <h3 className="font-medium text-yellow-900 dark:text-yellow-100 mb-2">
              ⚠️ 이용권이 필요합니다
            </h3>
            <p className="text-sm text-yellow-700 dark:text-yellow-300 mb-3">
              문제집을 만들려면 먼저 이용권을 구매해야 합니다.
            </p>
            <button
              type="button"
              onClick={() => router.push('/certifications')}
              className="px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 transition-colors text-sm"
            >
              이용권 구매하러 가기
            </button>
          </div>
        )}

        {/* Error Message */}
        {error && (
          <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
            <p className="text-sm text-red-800 dark:text-red-200">{error}</p>
          </div>
        )}

        {/* Format Preview */}
        {name && userSubscription && (
          <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-6">
            <h3 className="font-medium text-blue-900 dark:text-blue-100 mb-2">
              📋 생성될 문제집 정보
            </h3>
            <div className="flex items-start gap-3">
              <Book className="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5" />
              <div>
                <p className="font-medium text-blue-900 dark:text-blue-100">
                  {userSubscription.id === 'vip-pass'
                    ? `${name}:${certifications.find(c => c.id === selectedCertification)?.name || '선택된 자격증'}`
                    : `${name}:${userSubscription.certification_name}_{userSubscription.exam_date?.split('T')[0]}`}
                </p>
                <p className="text-sm text-blue-700 dark:text-blue-300 mt-1">
                  학습자료 0개 · 문제 0개
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Actions */}
        <div className="flex gap-4">
          <button
            type="button"
            onClick={() => router.back()}
            className="flex-1 px-6 py-3 border border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
          >
            취소
          </button>
          <button
            type="submit"
            disabled={loading || !name || !userSubscription || (userSubscription?.id === 'vip-pass' && !selectedCertification)}
            className="flex-1 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
          >
            {loading ? (
              <span className="flex items-center justify-center gap-2">
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                생성 중...
              </span>
            ) : (
              '문제집 만들기'
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
