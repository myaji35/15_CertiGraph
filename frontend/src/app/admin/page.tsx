'use client';

import { useState, useEffect } from 'react';
import { Book, Users, FileText, TrendingUp, Activity, Clock, Award, BarChart, Plus } from 'lucide-react';
import { useAuth } from '@clerk/nextjs';

export default function AdminDashboard() {
  const { getToken } = useAuth();
  const [stats, setStats] = useState({
    totalStudySets: 0,
    totalUsers: 0,
    totalQuestions: 0,
    activeUsers: 0,
    testsToday: 0,
    avgScore: 0,
  });
  const [showSubscriptionModal, setShowSubscriptionModal] = useState(false);

  useEffect(() => {
    // TODO: API에서 실제 통계 데이터 가져오기
    setStats({
      totalStudySets: 15,
      totalUsers: 342,
      totalQuestions: 1250,
      activeUsers: 89,
      testsToday: 47,
      avgScore: 72.5,
    });
  }, []);

  return (
    <div>
      <h1 className="text-3xl font-bold text-gray-900 mb-8">관리자 대시보드</h1>

      {/* 통계 카드 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        <StatCard
          icon={<Book className="w-6 h-6" />}
          title="전체 문제집"
          value={stats.totalStudySets}
          change="+12%"
          color="blue"
        />
        <StatCard
          icon={<Users className="w-6 h-6" />}
          title="전체 사용자"
          value={stats.totalUsers}
          change="+8%"
          color="green"
        />
        <StatCard
          icon={<FileText className="w-6 h-6" />}
          title="전체 문제"
          value={stats.totalQuestions.toLocaleString()}
          change="+15%"
          color="purple"
        />
        <StatCard
          icon={<Activity className="w-6 h-6" />}
          title="활성 사용자"
          value={stats.activeUsers}
          change="+5%"
          color="orange"
        />
        <StatCard
          icon={<Clock className="w-6 h-6" />}
          title="오늘 시험"
          value={stats.testsToday}
          change="+20%"
          color="pink"
        />
        <StatCard
          icon={<Award className="w-6 h-6" />}
          title="평균 점수"
          value={`${stats.avgScore}%`}
          change="+3%"
          color="indigo"
        />
      </div>

      {/* 최근 활동 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold mb-4 flex items-center gap-2">
            <Clock className="w-5 h-5 text-gray-500" />
            최근 활동
          </h2>
          <div className="space-y-3">
            <ActivityItem
              user="김철수"
              action="새 문제집 생성"
              target="2024 사회복지사 1급 기출"
              time="5분 전"
            />
            <ActivityItem
              user="이영희"
              action="시험 완료"
              target="정신건강론 모의고사"
              time="12분 전"
            />
            <ActivityItem
              user="박민수"
              action="회원 가입"
              target=""
              time="30분 전"
            />
            <ActivityItem
              user="정수연"
              action="문제 수정"
              target="사회복지정책론 #45"
              time="1시간 전"
            />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold mb-4 flex items-center gap-2">
            <BarChart className="w-5 h-5 text-gray-500" />
            인기 문제집
          </h2>
          <div className="space-y-3">
            <PopularItem
              rank={1}
              title="2024 사회복지사 1급 기출문제"
              views={1234}
              tests={89}
            />
            <PopularItem
              rank={2}
              title="정신건강론 핵심요약"
              views={987}
              tests={67}
            />
            <PopularItem
              rank={3}
              title="사회복지정책론 모의고사"
              views={756}
              tests={45}
            />
            <PopularItem
              rank={4}
              title="지역사회복지론 기출"
              views={543}
              tests={32}
            />
          </div>
        </div>
      </div>

      {/* 빠른 작업 */}
      <div className="mt-8 bg-blue-50 rounded-lg p-6">
        <h2 className="text-lg font-semibold mb-4">빠른 작업</h2>
        <div className="flex gap-4 flex-wrap">
          <QuickAction href="/admin/study-sets/new" label="새 문제집 추가" />
          <QuickAction href="/admin/users" label="사용자 관리" />
          <QuickAction href="/admin/certifications" label="자격증 관리" />
          <QuickAction href="/admin/settings" label="시스템 설정" />
          <button
            onClick={() => setShowSubscriptionModal(true)}
            className="px-4 py-2 bg-green-600 text-white rounded-lg shadow hover:bg-green-700 transition-colors text-sm font-medium flex items-center gap-2"
          >
            <Plus className="w-4 h-4" />
            강제 구독 생성
          </button>
        </div>
      </div>

      {/* 강제 구독 생성 모달 */}
      {showSubscriptionModal && (
        <ForceSubscriptionModal
          onClose={() => setShowSubscriptionModal(false)}
          getToken={getToken}
        />
      )}
    </div>
  );
}

function ForceSubscriptionModal({ onClose, getToken }: { onClose: () => void; getToken: any }) {
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

    try {
      setLoading(true);
      setError('');
      const token = await getToken();

      const selectedCert = certifications.find(c => c.id === selectedCertId);
      const selectedExamDate = selectedCert?.exam_dates.find((d: any) => d.id === selectedExamDateId);

      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/v1/subscriptions`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          certification_id: selectedCertId,
          exam_date_id: selectedExamDateId,
          payment_amount: 10000,
          payment_method: 'admin_force',
        }),
      });

      if (response.ok) {
        alert('구독이 생성되었습니다!');
        onClose();
        window.location.reload(); // 페이지 새로고침으로 대시보드 업데이트
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
        <h2 className="text-xl font-bold mb-4">강제 구독 생성 (테스트용)</h2>

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
                {selectedCert.exam_dates?.map((examDate: any) => (
                  <option key={examDate.id} value={examDate.id}>
                    {new Date(examDate.exam_date).toLocaleDateString('ko-KR', {
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric',
                    })}
                  </option>
                ))}
              </select>
            </div>
          )}

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
              className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
              disabled={loading || !selectedCertId || !selectedExamDateId}
            >
              {loading ? '생성 중...' : '구독 생성'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function StatCard({ icon, title, value, change, color }: any) {
  const colorClasses = {
    blue: 'bg-blue-100 text-blue-600',
    green: 'bg-green-100 text-green-600',
    purple: 'bg-purple-100 text-purple-600',
    orange: 'bg-orange-100 text-orange-600',
    pink: 'bg-pink-100 text-pink-600',
    indigo: 'bg-indigo-100 text-indigo-600',
  };

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex items-center justify-between mb-4">
        <div className={`p-3 rounded-lg ${colorClasses[color]}`}>
          {icon}
        </div>
        <span className="text-sm text-green-600 font-medium">{change}</span>
      </div>
      <h3 className="text-2xl font-bold text-gray-900">{value}</h3>
      <p className="text-sm text-gray-500 mt-1">{title}</p>
    </div>
  );
}

function ActivityItem({ user, action, target, time }: any) {
  return (
    <div className="flex items-center justify-between py-2 border-b last:border-0">
      <div>
        <span className="font-medium text-gray-900">{user}</span>
        <span className="text-gray-500 mx-1">{action}</span>
        {target && <span className="text-blue-600">{target}</span>}
      </div>
      <span className="text-xs text-gray-400">{time}</span>
    </div>
  );
}

function PopularItem({ rank, title, views, tests }: any) {
  return (
    <div className="flex items-center justify-between py-2 border-b last:border-0">
      <div className="flex items-center gap-3">
        <span className="text-lg font-bold text-gray-400 w-6">{rank}</span>
        <span className="text-gray-900">{title}</span>
      </div>
      <div className="flex gap-4 text-sm text-gray-500">
        <span>{views} 조회</span>
        <span>{tests} 시험</span>
      </div>
    </div>
  );
}

function QuickAction({ href, label }: any) {
  return (
    <a
      href={href}
      className="px-4 py-2 bg-white rounded-lg shadow hover:shadow-md transition-shadow text-sm font-medium text-gray-700 hover:text-blue-600"
    >
      {label}
    </a>
  );
}