'use client';

import React, { useState } from 'react';
import { X, Moon, Sun, Type, CreditCard, Calendar, Check } from 'lucide-react';
import { useUser } from '@clerk/nextjs';
import { cn } from '@/lib/utils';

interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  darkMode: boolean;
  setDarkMode: (value: boolean) => void;
}

export default function SettingsModal({ isOpen, onClose, darkMode, setDarkMode }: SettingsModalProps) {
  const { user } = useUser();
  const [fontSize, setFontSize] = useState<'small' | 'medium' | 'large'>('medium');
  const [activeTab, setActiveTab] = useState<'display' | 'subscription'>('display');

  if (!isOpen) return null;

  // Mock subscription data - 나중에 실제 API로 교체
  const subscriptionData = {
    tier: 'free',
    planName: '무료 플랜',
    pdfsUsed: 0,
    pdfsLimit: 1,
    validUntil: null as string | null,
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white dark:bg-gray-900 rounded-lg shadow-xl w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-gray-100">설정</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        {/* Tabs */}
        <div className="flex border-b border-gray-200 dark:border-gray-700">
          <button
            onClick={() => setActiveTab('display')}
            className={cn(
              "flex-1 px-6 py-3 text-sm font-medium transition-colors relative",
              activeTab === 'display'
                ? "text-blue-600 dark:text-blue-400"
                : "text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200"
            )}
          >
            화면 설정
            {activeTab === 'display' && (
              <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-blue-600 dark:bg-blue-400" />
            )}
          </button>
          <button
            onClick={() => setActiveTab('subscription')}
            className={cn(
              "flex-1 px-6 py-3 text-sm font-medium transition-colors relative",
              activeTab === 'subscription'
                ? "text-blue-600 dark:text-blue-400"
                : "text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200"
            )}
          >
            구독 관리
            {activeTab === 'subscription' && (
              <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-blue-600 dark:bg-blue-400" />
            )}
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6">
          {activeTab === 'display' && (
            <div className="space-y-6">
              {/* Dark Mode */}
              <div>
                <h3 className="text-sm font-medium text-gray-900 dark:text-gray-100 mb-3">테마</h3>
                <div className="grid grid-cols-2 gap-3">
                  <button
                    onClick={() => setDarkMode(false)}
                    className={cn(
                      "flex items-center gap-3 p-4 border-2 rounded-lg transition-all",
                      !darkMode
                        ? "border-blue-500 bg-blue-50 dark:bg-blue-900/20"
                        : "border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600"
                    )}
                  >
                    <Sun className="w-5 h-5 text-gray-700 dark:text-gray-300" />
                    <div className="text-left flex-1">
                      <p className="text-sm font-medium text-gray-900 dark:text-gray-100">라이트 모드</p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">밝은 테마</p>
                    </div>
                    {!darkMode && <Check className="w-5 h-5 text-blue-500" />}
                  </button>

                  <button
                    onClick={() => setDarkMode(true)}
                    className={cn(
                      "flex items-center gap-3 p-4 border-2 rounded-lg transition-all",
                      darkMode
                        ? "border-blue-500 bg-blue-50 dark:bg-blue-900/20"
                        : "border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600"
                    )}
                  >
                    <Moon className="w-5 h-5 text-gray-700 dark:text-gray-300" />
                    <div className="text-left flex-1">
                      <p className="text-sm font-medium text-gray-900 dark:text-gray-100">다크 모드</p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">어두운 테마</p>
                    </div>
                    {darkMode && <Check className="w-5 h-5 text-blue-500" />}
                  </button>
                </div>
              </div>

              {/* Font Size */}
              <div>
                <h3 className="text-sm font-medium text-gray-900 dark:text-gray-100 mb-3">글자 크기</h3>
                <div className="grid grid-cols-3 gap-3">
                  {(['small', 'medium', 'large'] as const).map((size) => (
                    <button
                      key={size}
                      onClick={() => setFontSize(size)}
                      className={cn(
                        "flex flex-col items-center gap-2 p-4 border-2 rounded-lg transition-all",
                        fontSize === size
                          ? "border-blue-500 bg-blue-50 dark:bg-blue-900/20"
                          : "border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600"
                      )}
                    >
                      <Type className={cn(
                        "text-gray-700 dark:text-gray-300",
                        size === 'small' && "w-4 h-4",
                        size === 'medium' && "w-5 h-5",
                        size === 'large' && "w-6 h-6"
                      )} />
                      <div className="text-center">
                        <p className="text-sm font-medium text-gray-900 dark:text-gray-100">
                          {size === 'small' ? '작게' : size === 'medium' ? '보통' : '크게'}
                        </p>
                      </div>
                      {fontSize === size && (
                        <Check className="w-4 h-4 text-blue-500 absolute top-2 right-2" />
                      )}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          )}

          {activeTab === 'subscription' && (
            <div className="space-y-6">
              {/* Current Plan */}
              <div>
                <h3 className="text-sm font-medium text-gray-900 dark:text-gray-100 mb-3">현재 플랜</h3>
                <div className="border border-gray-200 dark:border-gray-700 rounded-lg p-4 bg-gray-50 dark:bg-gray-800">
                  <div className="flex items-center justify-between mb-4">
                    <div>
                      <p className="text-lg font-semibold text-gray-900 dark:text-gray-100">
                        {subscriptionData.planName}
                      </p>
                      <p className="text-sm text-gray-500 dark:text-gray-400">
                        PDF 업로드: {subscriptionData.pdfsUsed}/{subscriptionData.pdfsLimit}회/월
                      </p>
                    </div>
                    <span className="px-3 py-1 bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-full text-sm font-medium">
                      FREE
                    </span>
                  </div>

                  {/* Usage Bar */}
                  <div className="mb-4">
                    <div className="h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-blue-500 transition-all"
                        style={{ width: `${(subscriptionData.pdfsUsed / subscriptionData.pdfsLimit) * 100}%` }}
                      />
                    </div>
                  </div>

                  {/* Limitations */}
                  <div className="space-y-2 text-sm text-gray-600 dark:text-gray-400">
                    <p>✓ PDF 업로드: 1개/월</p>
                    <p>✓ 문제풀이: 2회/PDF</p>
                    <p className="text-gray-500 dark:text-gray-500">✗ 무제한 문제풀이</p>
                    <p className="text-gray-500 dark:text-gray-500">✗ AI 취약점 분석</p>
                    <p className="text-gray-500 dark:text-gray-500">✗ 합격 예측</p>
                  </div>
                </div>
              </div>

              {/* Upgrade Section */}
              <div>
                <h3 className="text-sm font-medium text-gray-900 dark:text-gray-100 mb-3">프리미엄 플랜</h3>
                <div className="border-2 border-blue-200 dark:border-blue-800 rounded-lg p-6 bg-gradient-to-br from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20">
                  {/* 가격 및 기간 설명 */}
                  <div className="mb-6">
                    <div className="flex items-baseline gap-2 mb-2">
                      <p className="text-4xl font-bold text-blue-600 dark:text-blue-400">₩10,000</p>
                      <span className="text-gray-500 dark:text-gray-400 text-sm">/자격증</span>
                    </div>
                    <div className="bg-blue-100 dark:bg-blue-900/30 border border-blue-300 dark:border-blue-700 rounded-lg p-3 mb-4">
                      <p className="text-sm text-blue-900 dark:text-blue-100 font-medium mb-1">
                        📅 구독 방식 안내
                      </p>
                      <p className="text-xs text-blue-800 dark:text-blue-200">
                        선택한 <strong>자격증의 시험일자까지</strong> 모든 기능을 무제한으로 이용하실 수 있습니다.
                      </p>
                      <p className="text-xs text-blue-700 dark:text-blue-300 mt-2">
                        예: 정보처리기사 2025.06.15 시험 선택 시<br/>
                        → 결제일부터 2025.06.15까지 이용 가능
                      </p>
                    </div>
                  </div>

                  {/* 혜택 목록 */}
                  <ul className="space-y-2.5 mb-6 text-sm text-gray-700 dark:text-gray-300">
                    <li className="flex items-start gap-2">
                      <Check className="w-4 h-4 text-blue-600 dark:text-blue-400 flex-shrink-0 mt-0.5" />
                      <span>무제한 PDF 업로드 및 문제풀이</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <Check className="w-4 h-4 text-blue-600 dark:text-blue-400 flex-shrink-0 mt-0.5" />
                      <span>AI 기반 취약점 분석 및 맞춤 학습 추천</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <Check className="w-4 h-4 text-blue-600 dark:text-blue-400 flex-shrink-0 mt-0.5" />
                      <span>합격 예측 및 실시간 학습 진도 관리</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <Check className="w-4 h-4 text-blue-600 dark:text-blue-400 flex-shrink-0 mt-0.5" />
                      <span>3D 지식 그래프 시각화</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <Check className="w-4 h-4 text-blue-600 dark:text-blue-400 flex-shrink-0 mt-0.5" />
                      <span><strong>시험일까지</strong> 모든 프리미엄 기능 무제한 이용</span>
                    </li>
                  </ul>

                  {/* 결제 버튼 */}
                  <button
                    onClick={() => window.location.href = '/pricing'}
                    className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-lg font-semibold transition-colors flex items-center justify-center gap-2 shadow-md hover:shadow-lg"
                  >
                    <CreditCard className="w-5 h-5" />
                    결제하고 시작하기
                  </button>

                  <p className="text-xs text-center text-gray-500 dark:text-gray-400 mt-3">
                    💳 토스페이먼츠 안전 결제
                  </p>
                </div>
              </div>

              {/* Payment History (for paid users) */}
              {subscriptionData.tier !== 'free' && (
                <div>
                  <h3 className="text-sm font-medium text-gray-900 dark:text-gray-100 mb-3">결제 내역</h3>
                  <div className="border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
                    <div className="p-4 bg-gray-50 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
                      <div className="flex items-center justify-between text-sm">
                        <span className="text-gray-600 dark:text-gray-400">결제 내역이 없습니다</span>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end gap-3 p-6 border-t border-gray-200 dark:border-gray-700">
          <button
            onClick={onClose}
            className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors"
          >
            닫기
          </button>
        </div>
      </div>
    </div>
  );
}
