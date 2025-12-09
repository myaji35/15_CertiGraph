'use client';

import { NotionCard, NotionPageHeader } from '@/components/ui/NotionCard';
import { User, Bell, Shield, Palette, Database, HelpCircle, Mail, Key, Moon, Globe } from 'lucide-react';
import { useState } from 'react';

export default function SettingsPage() {
  const [activeSection, setActiveSection] = useState('profile');

  const settingsSections = [
    { id: 'profile', label: '프로필', icon: <User className="w-4 h-4" /> },
    { id: 'notifications', label: '알림', icon: <Bell className="w-4 h-4" /> },
    { id: 'privacy', label: '개인정보', icon: <Shield className="w-4 h-4" /> },
    { id: 'appearance', label: '모양', icon: <Palette className="w-4 h-4" /> },
    { id: 'data', label: '데이터 관리', icon: <Database className="w-4 h-4" /> },
    { id: 'help', label: '도움말', icon: <HelpCircle className="w-4 h-4" /> },
  ];

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="설정"
        icon="⚙️"
        breadcrumbs={[
          { label: '홈' },
          { label: '설정' }
        ]}
      />

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* 설정 메뉴 */}
        <div className="lg:col-span-1">
          <NotionCard>
            <div className="p-4 space-y-2">
              {settingsSections.map((section) => (
                <button
                  key={section.id}
                  onClick={() => setActiveSection(section.id)}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-colors text-left ${
                    activeSection === section.id
                      ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400'
                      : 'hover:bg-gray-100 dark:hover:bg-gray-800'
                  }`}
                >
                  {section.icon}
                  <span className="font-medium">{section.label}</span>
                </button>
              ))}
            </div>
          </NotionCard>
        </div>

        {/* 설정 내용 */}
        <div className="lg:col-span-3 space-y-6">
          {activeSection === 'profile' && (
            <>
              <NotionCard title="프로필 설정" icon={<User className="w-5 h-5" />}>
                <div className="p-6 space-y-6">
                  <div className="flex items-center gap-6">
                    <div className="w-20 h-20 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white text-2xl font-bold">
                      AI
                    </div>
                    <div>
                      <button className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors">
                        사진 변경
                      </button>
                      <button className="ml-2 px-4 py-2 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100">
                        제거
                      </button>
                    </div>
                  </div>

                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                        이름
                      </label>
                      <input
                        type="text"
                        defaultValue="AI 학습자"
                        className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                        이메일
                      </label>
                      <input
                        type="email"
                        defaultValue="user@example.com"
                        className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                        목표 자격증
                      </label>
                      <select className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800">
                        <option>정보처리기사</option>
                        <option>SQLD</option>
                        <option>ADsP</option>
                        <option>빅데이터분석기사</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                        학습 목표
                      </label>
                      <textarea
                        rows={3}
                        defaultValue="3개월 내 정보처리기사 실기 합격"
                        className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800"
                      />
                    </div>
                  </div>

                  <div className="pt-4 border-t border-gray-200 dark:border-gray-700">
                    <button className="px-6 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors">
                      변경사항 저장
                    </button>
                  </div>
                </div>
              </NotionCard>
            </>
          )}

          {activeSection === 'notifications' && (
            <>
              <NotionCard title="알림 설정" icon={<Bell className="w-5 h-5" />}>
                <div className="p-6 space-y-6">
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <h4 className="font-medium">학습 리마인더</h4>
                        <p className="text-sm text-gray-600 dark:text-gray-400">
                          매일 설정한 시간에 학습 알림을 받습니다
                        </p>
                      </div>
                      <label className="relative inline-flex items-center cursor-pointer">
                        <input type="checkbox" className="sr-only peer" defaultChecked />
                        <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                      </label>
                    </div>

                    <div className="flex items-center justify-between">
                      <div>
                        <h4 className="font-medium">시험 일정 알림</h4>
                        <p className="text-sm text-gray-600 dark:text-gray-400">
                          시험 접수 및 시험일 알림
                        </p>
                      </div>
                      <label className="relative inline-flex items-center cursor-pointer">
                        <input type="checkbox" className="sr-only peer" defaultChecked />
                        <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                      </label>
                    </div>

                    <div className="flex items-center justify-between">
                      <div>
                        <h4 className="font-medium">성과 업데이트</h4>
                        <p className="text-sm text-gray-600 dark:text-gray-400">
                          주간 학습 성과 및 통계
                        </p>
                      </div>
                      <label className="relative inline-flex items-center cursor-pointer">
                        <input type="checkbox" className="sr-only peer" defaultChecked />
                        <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                      </label>
                    </div>

                    <div className="flex items-center justify-between">
                      <div>
                        <h4 className="font-medium">이메일 알림</h4>
                        <p className="text-sm text-gray-600 dark:text-gray-400">
                          중요한 알림을 이메일로도 받기
                        </p>
                      </div>
                      <label className="relative inline-flex items-center cursor-pointer">
                        <input type="checkbox" className="sr-only peer" />
                        <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                      </label>
                    </div>
                  </div>

                  <div className="space-y-4 pt-4 border-t border-gray-200 dark:border-gray-700">
                    <h4 className="font-medium">알림 시간 설정</h4>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                          아침 알림
                        </label>
                        <input
                          type="time"
                          defaultValue="08:00"
                          className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                          저녁 알림
                        </label>
                        <input
                          type="time"
                          defaultValue="20:00"
                          className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800"
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </NotionCard>
            </>
          )}

          {activeSection === 'privacy' && (
            <>
              <NotionCard title="개인정보 및 보안" icon={<Shield className="w-5 h-5" />}>
                <div className="p-6 space-y-6">
                  <div className="space-y-4">
                    <div>
                      <h4 className="font-medium mb-3">비밀번호 변경</h4>
                      <div className="space-y-3">
                        <input
                          type="password"
                          placeholder="현재 비밀번호"
                          className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800"
                        />
                        <input
                          type="password"
                          placeholder="새 비밀번호"
                          className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800"
                        />
                        <input
                          type="password"
                          placeholder="새 비밀번호 확인"
                          className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800"
                        />
                        <button className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors">
                          비밀번호 변경
                        </button>
                      </div>
                    </div>

                    <div className="pt-4 border-t border-gray-200 dark:border-gray-700">
                      <h4 className="font-medium mb-3">2단계 인증</h4>
                      <div className="flex items-center justify-between p-4 bg-green-50 dark:bg-green-900/20 rounded-lg">
                        <div className="flex items-center gap-3">
                          <Key className="w-5 h-5 text-green-600" />
                          <div>
                            <p className="font-medium">2단계 인증 활성화</p>
                            <p className="text-sm text-gray-600 dark:text-gray-400">
                              계정 보안을 강화합니다
                            </p>
                          </div>
                        </div>
                        <button className="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors">
                          설정하기
                        </button>
                      </div>
                    </div>

                    <div className="pt-4 border-t border-gray-200 dark:border-gray-700">
                      <h4 className="font-medium mb-3">로그인 기록</h4>
                      <div className="space-y-2">
                        <div className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
                          <div>
                            <p className="font-medium">Chrome - MacOS</p>
                            <p className="text-sm text-gray-600 dark:text-gray-400">
                              서울 • 2시간 전
                            </p>
                          </div>
                          <span className="text-xs px-2 py-1 bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300 rounded">
                            현재 세션
                          </span>
                        </div>
                        <div className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
                          <div>
                            <p className="font-medium">Safari - iPhone</p>
                            <p className="text-sm text-gray-600 dark:text-gray-400">
                              서울 • 어제
                            </p>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </NotionCard>
            </>
          )}

          {activeSection === 'appearance' && (
            <>
              <NotionCard title="모양 설정" icon={<Palette className="w-5 h-5" />}>
                <div className="p-6 space-y-6">
                  <div className="space-y-4">
                    <div>
                      <h4 className="font-medium mb-3">테마</h4>
                      <div className="grid grid-cols-3 gap-3">
                        <button className="p-4 border-2 border-blue-500 rounded-lg bg-white">
                          <div className="flex items-center justify-center mb-2">
                            ☀️
                          </div>
                          <p className="text-sm font-medium">라이트</p>
                        </button>
                        <button className="p-4 border-2 border-gray-300 dark:border-gray-600 rounded-lg bg-gray-900">
                          <div className="flex items-center justify-center mb-2">
                            🌙
                          </div>
                          <p className="text-sm font-medium text-white">다크</p>
                        </button>
                        <button className="p-4 border-2 border-gray-300 dark:border-gray-600 rounded-lg bg-gradient-to-br from-white to-gray-900">
                          <div className="flex items-center justify-center mb-2">
                            🖥️
                          </div>
                          <p className="text-sm font-medium">시스템</p>
                        </button>
                      </div>
                    </div>

                    <div>
                      <h4 className="font-medium mb-3">강조 색상</h4>
                      <div className="flex gap-3">
                        <button className="w-10 h-10 bg-blue-500 rounded-lg border-2 border-blue-600"></button>
                        <button className="w-10 h-10 bg-green-500 rounded-lg"></button>
                        <button className="w-10 h-10 bg-purple-500 rounded-lg"></button>
                        <button className="w-10 h-10 bg-red-500 rounded-lg"></button>
                        <button className="w-10 h-10 bg-yellow-500 rounded-lg"></button>
                        <button className="w-10 h-10 bg-pink-500 rounded-lg"></button>
                      </div>
                    </div>

                    <div>
                      <h4 className="font-medium mb-3">글꼴 크기</h4>
                      <div className="flex items-center gap-4">
                        <button className="text-sm px-3 py-1 border border-gray-300 dark:border-gray-600 rounded">
                          작게
                        </button>
                        <button className="px-3 py-1 border-2 border-blue-500 rounded bg-blue-50 dark:bg-blue-900/20">
                          보통
                        </button>
                        <button className="text-lg px-3 py-1 border border-gray-300 dark:border-gray-600 rounded">
                          크게
                        </button>
                      </div>
                    </div>

                    <div className="flex items-center justify-between">
                      <div>
                        <h4 className="font-medium">콤팩트 모드</h4>
                        <p className="text-sm text-gray-600 dark:text-gray-400">
                          더 많은 콘텐츠를 한 화면에 표시
                        </p>
                      </div>
                      <label className="relative inline-flex items-center cursor-pointer">
                        <input type="checkbox" className="sr-only peer" />
                        <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                      </label>
                    </div>
                  </div>
                </div>
              </NotionCard>
            </>
          )}

          {activeSection === 'data' && (
            <>
              <NotionCard title="데이터 관리" icon={<Database className="w-5 h-5" />}>
                <div className="p-6 space-y-6">
                  <div className="space-y-4">
                    <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
                      <div className="flex items-start gap-3">
                        <Database className="w-5 h-5 text-blue-600 mt-1" />
                        <div className="flex-1">
                          <h4 className="font-medium mb-2">데이터 백업</h4>
                          <p className="text-sm text-gray-600 dark:text-gray-400 mb-3">
                            학습 데이터를 안전하게 백업합니다
                          </p>
                          <button className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors">
                            지금 백업
                          </button>
                          <p className="text-xs text-gray-500 mt-2">
                            마지막 백업: 2024년 12월 7일 오후 3:42
                          </p>
                        </div>
                      </div>
                    </div>

                    <div className="p-4 bg-green-50 dark:bg-green-900/20 rounded-lg">
                      <div className="flex items-start gap-3">
                        <Mail className="w-5 h-5 text-green-600 mt-1" />
                        <div className="flex-1">
                          <h4 className="font-medium mb-2">데이터 내보내기</h4>
                          <p className="text-sm text-gray-600 dark:text-gray-400 mb-3">
                            학습 기록을 CSV 또는 JSON으로 내보냅니다
                          </p>
                          <div className="flex gap-2">
                            <button className="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors">
                              CSV 내보내기
                            </button>
                            <button className="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors">
                              JSON 내보내기
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>

                    <div className="p-4 bg-red-50 dark:bg-red-900/20 rounded-lg">
                      <div className="flex items-start gap-3">
                        <Shield className="w-5 h-5 text-red-600 mt-1" />
                        <div className="flex-1">
                          <h4 className="font-medium mb-2">데이터 삭제</h4>
                          <p className="text-sm text-gray-600 dark:text-gray-400 mb-3">
                            모든 학습 데이터를 영구적으로 삭제합니다
                          </p>
                          <button className="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors">
                            모든 데이터 삭제
                          </button>
                          <p className="text-xs text-red-500 mt-2">
                            ⚠️ 이 작업은 되돌릴 수 없습니다
                          </p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </NotionCard>
            </>
          )}

          {activeSection === 'help' && (
            <>
              <NotionCard title="도움말 및 지원" icon={<HelpCircle className="w-5 h-5" />}>
                <div className="p-6 space-y-6">
                  <div className="grid grid-cols-2 gap-4">
                    <a href="#" className="p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800">
                      <div className="flex items-center gap-3 mb-2">
                        <BookOpen className="w-5 h-5 text-blue-500" />
                        <h4 className="font-medium">사용자 가이드</h4>
                      </div>
                      <p className="text-sm text-gray-600 dark:text-gray-400">
                        CertiGraph 사용법 알아보기
                      </p>
                    </a>
                    <a href="#" className="p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800">
                      <div className="flex items-center gap-3 mb-2">
                        <Mail className="w-5 h-5 text-green-500" />
                        <h4 className="font-medium">문의하기</h4>
                      </div>
                      <p className="text-sm text-gray-600 dark:text-gray-400">
                        support@certigraph.ai
                      </p>
                    </a>
                  </div>

                  <div className="space-y-4 pt-4 border-t border-gray-200 dark:border-gray-700">
                    <h4 className="font-medium">자주 묻는 질문</h4>
                    <div className="space-y-3">
                      <details className="p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
                        <summary className="font-medium cursor-pointer">
                          PDF 파일을 어떻게 업로드하나요?
                        </summary>
                        <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">
                          학습 세트 페이지에서 'PDF 업로드' 버튼을 클릭하고 파일을 선택하세요.
                        </p>
                      </details>
                      <details className="p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
                        <summary className="font-medium cursor-pointer">
                          Knowledge Graph는 어떻게 활용하나요?
                        </summary>
                        <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">
                          취약점 분석 페이지에서 개념 간 연결 관계를 확인하고 취약 부분을 집중 학습할 수 있습니다.
                        </p>
                      </details>
                      <details className="p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
                        <summary className="font-medium cursor-pointer">
                          구독을 해지하려면 어떻게 하나요?
                        </summary>
                        <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">
                          결제 관리 페이지에서 구독을 해지할 수 있습니다. 해지 후에도 남은 기간 동안 서비스를 이용할 수 있습니다.
                        </p>
                      </details>
                    </div>
                  </div>

                  <div className="pt-4 border-t border-gray-200 dark:border-gray-700">
                    <div className="flex items-center justify-between">
                      <div>
                        <h4 className="font-medium">버전 정보</h4>
                        <p className="text-sm text-gray-600 dark:text-gray-400">
                          CertiGraph v1.0.0
                        </p>
                      </div>
                      <button className="text-sm text-blue-600 dark:text-blue-400 hover:underline">
                        업데이트 확인
                      </button>
                    </div>
                  </div>
                </div>
              </NotionCard>
            </>
          )}
        </div>
      </div>
    </div>
  );
}