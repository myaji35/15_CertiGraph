"use client";

import { useState } from 'react';
import { CalendarDays, Check, Clock, Brain, Award, TrendingUp } from 'lucide-react';
import TossPayment from '@/components/payment/TossPayment';
import { useAuth } from '@clerk/nextjs';
import { useRouter } from 'next/navigation';

export default function PricingPage() {
  const { isSignedIn } = useAuth();
  const router = useRouter();
  const [selectedDate, setSelectedDate] = useState<string>('');
  const [showPayment, setShowPayment] = useState(false);

  // 시험 날짜 옵션 (예시)
  const examDates = [
    { id: '2025-03-08', date: '2025년 3월 8일', round: '27회', available: true },
    { id: '2025-09-06', date: '2025년 9월 6일', round: '28회', available: true },
    { id: '2026-03-07', date: '2026년 3월 7일', round: '29회', available: false },
  ];

  const features = [
    { icon: Brain, text: '모든 기출문제 무제한 학습' },
    { icon: TrendingUp, text: 'AI 기반 취약점 분석 및 맞춤 학습' },
    { icon: Clock, text: '시험일까지 무제한 이용' },
    { icon: Award, text: '합격 예측 및 학습 진도 관리' },
  ];

  const handleStartPayment = () => {
    if (!isSignedIn) {
      alert('로그인이 필요합니다.');
      router.push('/sign-in');
      return;
    }

    if (!selectedDate) {
      alert('시험 날짜를 선택해주세요.');
      return;
    }

    setShowPayment(true);
  };

  const handlePaymentSuccess = () => {
    setShowPayment(false);
    router.push('/dashboard');
  };

  const handlePaymentError = (error: string) => {
    alert(`결제 실패: ${error}`);
    setShowPayment(false);
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-white">
      <div className="max-w-4xl mx-auto px-6 py-12">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            사회복지사 1급 완벽 대비
          </h1>
          <p className="text-xl text-gray-600">
            AI 기반 맞춤형 학습으로 합격을 보장합니다
          </p>
        </div>

        {/* Pricing Card */}
        <div className="bg-white rounded-2xl shadow-xl p-8 mb-8">
          {/* Price */}
          <div className="text-center mb-8">
            <div className="flex items-center justify-center gap-3 mb-2">
              <span className="text-2xl text-gray-500 line-through">₩30,000</span>
              <span className="bg-red-500 text-white text-sm px-2 py-1 rounded-full">
                70% 할인
              </span>
            </div>
            <div className="text-5xl font-bold text-blue-600 mb-2">
              ₩10,000
            </div>
            <p className="text-gray-600">시험일까지 무제한 이용</p>
          </div>

          {/* Features */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
            {features.map((feature, index) => (
              <div key={index} className="flex items-center gap-3">
                <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0">
                  <feature.icon className="w-5 h-5 text-blue-600" />
                </div>
                <span className="text-gray-700">{feature.text}</span>
              </div>
            ))}
          </div>

          {/* Exam Date Selection */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <CalendarDays className="w-5 h-5" />
              시험 날짜 선택
            </h3>
            <div className="space-y-3">
              {examDates.map((exam) => (
                <button
                  key={exam.id}
                  onClick={() => exam.available && setSelectedDate(exam.id)}
                  disabled={!exam.available}
                  className={`w-full p-4 rounded-lg border-2 transition-all ${
                    selectedDate === exam.id
                      ? 'border-blue-500 bg-blue-50'
                      : exam.available
                      ? 'border-gray-200 hover:border-gray-300'
                      : 'border-gray-100 bg-gray-50 cursor-not-allowed opacity-50'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div className="text-left">
                      <p className="font-semibold text-gray-900">
                        {exam.date}
                      </p>
                      <p className="text-sm text-gray-600">
                        제{exam.round} 시험
                      </p>
                    </div>
                    {selectedDate === exam.id && (
                      <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center">
                        <Check className="w-5 h-5 text-white" />
                      </div>
                    )}
                    {!exam.available && (
                      <span className="text-sm text-gray-500">준비중</span>
                    )}
                  </div>
                </button>
              ))}
            </div>
          </div>

          {/* Payment Button */}
          <button
            onClick={handleStartPayment}
            className={`w-full py-4 rounded-lg font-semibold transition-colors ${
              selectedDate
                ? 'bg-blue-600 text-white hover:bg-blue-700'
                : 'bg-gray-200 text-gray-500 cursor-not-allowed'
            }`}
            disabled={!selectedDate}
          >
            결제하고 학습 시작하기
          </button>
        </div>

        {/* Trust Badges */}
        <div className="grid grid-cols-3 gap-4 text-center">
          <div className="bg-white rounded-lg p-4 shadow-sm">
            <p className="text-3xl font-bold text-blue-600">85%</p>
            <p className="text-sm text-gray-600">평균 합격률</p>
          </div>
          <div className="bg-white rounded-lg p-4 shadow-sm">
            <p className="text-3xl font-bold text-blue-600">10,000+</p>
            <p className="text-sm text-gray-600">합격생 배출</p>
          </div>
          <div className="bg-white rounded-lg p-4 shadow-sm">
            <p className="text-3xl font-bold text-blue-600">4.8</p>
            <p className="text-sm text-gray-600">사용자 평점</p>
          </div>
        </div>
      </div>

      {/* Toss Payment Modal */}
      {showPayment && selectedDate && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-3xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-4 border-b">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold">결제하기</h2>
                <button
                  onClick={() => setShowPayment(false)}
                  className="text-gray-500 hover:text-gray-700"
                >
                  ✕
                </button>
              </div>
            </div>
            <TossPayment
              examDate={selectedDate}
              amount={10000}
              onSuccess={handlePaymentSuccess}
              onError={handlePaymentError}
            />
          </div>
        </div>
      )}
    </div>
  );
}