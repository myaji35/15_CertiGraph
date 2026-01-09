'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@clerk/nextjs';
import {
  Settings,
  Save,
  Database,
  Mail,
  Bell,
  Lock,
  Globe,
  Palette,
  Zap,
  AlertCircle,
  CheckCircle
} from 'lucide-react';

interface SystemSettings {
  site_name: string;
  site_description: string;
  admin_email: string;
  support_email: string;
  max_upload_size_mb: number;
  session_timeout_minutes: number;
  enable_registration: boolean;
  enable_email_notifications: boolean;
  enable_analytics: boolean;
  maintenance_mode: boolean;
  api_rate_limit: number;
  default_language: string;
}

export default function AdminSettingsPage() {
  const { getToken, isLoaded, isSignedIn } = useAuth();
  const [settings, setSettings] = useState<SystemSettings>({
    site_name: 'Certi-Graph',
    site_description: 'AI 자격증 마스터 - 지식 그래프 기반 학습 플랫폼',
    admin_email: 'admin@certigraph.com',
    support_email: 'support@certigraph.com',
    max_upload_size_mb: 50,
    session_timeout_minutes: 60,
    enable_registration: true,
    enable_email_notifications: true,
    enable_analytics: true,
    maintenance_mode: false,
    api_rate_limit: 100,
    default_language: 'ko'
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [activeTab, setActiveTab] = useState<'general' | 'email' | 'security' | 'advanced'>('general');

  useEffect(() => {
    if (isLoaded && isSignedIn) {
      fetchSettings();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isLoaded, isSignedIn]);

  const fetchSettings = async () => {
    try {
      setLoading(true);
      const token = await getToken();
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/settings`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const data = await response.json();
        setSettings(data.settings);
      } else {
        console.error('Failed to fetch settings:', response.status);
      }
    } catch (err: any) {
      console.error('Failed to fetch settings:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    try {
      setSaving(true);
      setSaveSuccess(false);
      const token = await getToken();
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/settings`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(settings),
      });

      if (response.ok) {
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        alert('설정 저장에 실패했습니다.');
      }
    } catch (err: any) {
      console.error('Save failed:', err);
      alert(`저장 실패: ${err.message}`);
    } finally {
      setSaving(false);
    }
  };

  const updateSetting = (key: keyof SystemSettings, value: any) => {
    setSettings({ ...settings, [key]: value });
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">시스템 설정</h1>
          <p className="text-gray-600 mt-2">서비스 전반적인 설정 관리</p>
        </div>
        <button
          onClick={handleSave}
          disabled={saving}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:bg-gray-400"
        >
          {saving ? (
            <>처리 중...</>
          ) : (
            <>
              <Save className="w-5 h-5" />
              저장
            </>
          )}
        </button>
      </div>

      {/* 저장 성공 메시지 */}
      {saveSuccess && (
        <div className="mb-6 bg-green-50 border border-green-200 rounded-lg p-4 flex items-center gap-2">
          <CheckCircle className="w-5 h-5 text-green-600" />
          <span className="text-green-800">설정이 성공적으로 저장되었습니다.</span>
        </div>
      )}

      {/* 탭 메뉴 */}
      <div className="bg-white rounded-lg shadow mb-6">
        <div className="border-b border-gray-200">
          <nav className="flex -mb-px">
            <button
              onClick={() => setActiveTab('general')}
              className={`px-6 py-4 text-sm font-medium border-b-2 ${
                activeTab === 'general'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <Globe className="w-4 h-4 inline mr-2" />
              일반 설정
            </button>
            <button
              onClick={() => setActiveTab('email')}
              className={`px-6 py-4 text-sm font-medium border-b-2 ${
                activeTab === 'email'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <Mail className="w-4 h-4 inline mr-2" />
              이메일/알림
            </button>
            <button
              onClick={() => setActiveTab('security')}
              className={`px-6 py-4 text-sm font-medium border-b-2 ${
                activeTab === 'security'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <Lock className="w-4 h-4 inline mr-2" />
              보안
            </button>
            <button
              onClick={() => setActiveTab('advanced')}
              className={`px-6 py-4 text-sm font-medium border-b-2 ${
                activeTab === 'advanced'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <Zap className="w-4 h-4 inline mr-2" />
              고급 설정
            </button>
          </nav>
        </div>
      </div>

      {loading ? (
        <div className="text-center py-12 text-gray-500">
          <p>로딩 중...</p>
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow">
          <div className="p-6">
            {/* 일반 설정 */}
            {activeTab === 'general' && (
              <div className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    사이트 이름
                  </label>
                  <input
                    type="text"
                    value={settings.site_name}
                    onChange={(e) => updateSetting('site_name', e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    사이트 설명
                  </label>
                  <textarea
                    value={settings.site_description}
                    onChange={(e) => updateSetting('site_description', e.target.value)}
                    rows={3}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    기본 언어
                  </label>
                  <select
                    value={settings.default_language}
                    onChange={(e) => updateSetting('default_language', e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="ko">한국어</option>
                    <option value="en">English</option>
                    <option value="ja">日本語</option>
                  </select>
                </div>

                <div className="flex items-center gap-3">
                  <input
                    type="checkbox"
                    id="enable_registration"
                    checked={settings.enable_registration}
                    onChange={(e) => updateSetting('enable_registration', e.target.checked)}
                    className="w-4 h-4 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
                  />
                  <label htmlFor="enable_registration" className="text-sm text-gray-700">
                    신규 회원 가입 허용
                  </label>
                </div>

                <div className="flex items-center gap-3">
                  <input
                    type="checkbox"
                    id="enable_analytics"
                    checked={settings.enable_analytics}
                    onChange={(e) => updateSetting('enable_analytics', e.target.checked)}
                    className="w-4 h-4 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
                  />
                  <label htmlFor="enable_analytics" className="text-sm text-gray-700">
                    분석 도구 활성화
                  </label>
                </div>
              </div>
            )}

            {/* 이메일/알림 설정 */}
            {activeTab === 'email' && (
              <div className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    관리자 이메일
                  </label>
                  <input
                    type="email"
                    value={settings.admin_email}
                    onChange={(e) => updateSetting('admin_email', e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    지원팀 이메일
                  </label>
                  <input
                    type="email"
                    value={settings.support_email}
                    onChange={(e) => updateSetting('support_email', e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div className="flex items-center gap-3">
                  <input
                    type="checkbox"
                    id="enable_email_notifications"
                    checked={settings.enable_email_notifications}
                    onChange={(e) => updateSetting('enable_email_notifications', e.target.checked)}
                    className="w-4 h-4 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
                  />
                  <label htmlFor="enable_email_notifications" className="text-sm text-gray-700">
                    이메일 알림 활성화
                  </label>
                </div>

                <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                  <p className="text-sm text-blue-800 flex items-start gap-2">
                    <Bell className="w-4 h-4 mt-0.5" />
                    이메일 알림은 사용자 활동, 구독 변경, 시스템 공지 등에 대해 발송됩니다.
                  </p>
                </div>
              </div>
            )}

            {/* 보안 설정 */}
            {activeTab === 'security' && (
              <div className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    세션 타임아웃 (분)
                  </label>
                  <input
                    type="number"
                    value={settings.session_timeout_minutes}
                    onChange={(e) => updateSetting('session_timeout_minutes', parseInt(e.target.value))}
                    min="15"
                    max="480"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <p className="text-xs text-gray-500 mt-1">사용자 세션이 유지되는 시간 (15-480분)</p>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    API 요청 제한 (분당)
                  </label>
                  <input
                    type="number"
                    value={settings.api_rate_limit}
                    onChange={(e) => updateSetting('api_rate_limit', parseInt(e.target.value))}
                    min="10"
                    max="1000"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <p className="text-xs text-gray-500 mt-1">사용자당 분당 최대 API 요청 수</p>
                </div>

                <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                  <p className="text-sm text-yellow-800 flex items-start gap-2">
                    <AlertCircle className="w-4 h-4 mt-0.5" />
                    보안 설정 변경 시 모든 사용자의 세션이 재설정될 수 있습니다.
                  </p>
                </div>
              </div>
            )}

            {/* 고급 설정 */}
            {activeTab === 'advanced' && (
              <div className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    최대 업로드 크기 (MB)
                  </label>
                  <input
                    type="number"
                    value={settings.max_upload_size_mb}
                    onChange={(e) => updateSetting('max_upload_size_mb', parseInt(e.target.value))}
                    min="1"
                    max="500"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <p className="text-xs text-gray-500 mt-1">PDF 파일 업로드 최대 크기</p>
                </div>

                <div className="flex items-center gap-3">
                  <input
                    type="checkbox"
                    id="maintenance_mode"
                    checked={settings.maintenance_mode}
                    onChange={(e) => updateSetting('maintenance_mode', e.target.checked)}
                    className="w-4 h-4 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
                  />
                  <label htmlFor="maintenance_mode" className="text-sm text-gray-700">
                    유지보수 모드
                  </label>
                </div>

                {settings.maintenance_mode && (
                  <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                    <p className="text-sm text-red-800 flex items-start gap-2">
                      <AlertCircle className="w-4 h-4 mt-0.5" />
                      유지보수 모드가 활성화되면 관리자를 제외한 모든 사용자의 접근이 차단됩니다.
                    </p>
                  </div>
                )}

                <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
                  <h3 className="text-sm font-semibold text-gray-700 mb-2 flex items-center gap-2">
                    <Database className="w-4 h-4" />
                    시스템 정보
                  </h3>
                  <div className="space-y-1 text-xs text-gray-600">
                    <p>• 서버 버전: 1.0.0</p>
                    <p>• API 버전: v1</p>
                    <p>• 데이터베이스: Supabase (PostgreSQL)</p>
                    <p>• 캐시: Redis (optional)</p>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
