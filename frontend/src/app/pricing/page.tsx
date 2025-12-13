"use client";

import { useState, useEffect } from 'react';
import { CalendarDays, Check, Clock, Brain, Award, TrendingUp, BookOpen } from 'lucide-react';
import TossPayment from '@/components/payment/TossPayment';
import { useAuth } from '@clerk/nextjs';
import { useRouter } from 'next/navigation';

interface ExamDate {
  id: string;
  exam_date: string;
  round_number: number | null;
  registration_start: string | null;
  registration_end: string | null;
}

interface Certification {
  id: string;
  name: string;
  category: string;
  organization: string;
  exam_dates: ExamDate[];
}

export default function PricingPage() {
  const { isSignedIn } = useAuth();
  const router = useRouter();
  const [selectedCertificationId, setSelectedCertificationId] = useState<string>('');
  const [selectedExamDateId, setSelectedExamDateId] = useState<string>('');
  const [showPayment, setShowPayment] = useState(false);
  const [certifications, setCertifications] = useState<Certification[]>([]);
  const [loadingCerts, setLoadingCerts] = useState(true);

  // Fetch certifications with exam dates
  useEffect(() => {
    const fetchCertifications = async () => {
      try {
        const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/v1/certifications`);
        if (response.ok) {
          const data = await response.json();
          setCertifications(data.certifications || []);
        } else {
          console.error('Failed to fetch certifications');
        }
      } catch (err) {
        console.error('Error fetching certifications:', err);
      } finally {
        setLoadingCerts(false);
      }
    };

    fetchCertifications();
  }, []);

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

    if (!selectedCertificationId) {
      alert('자격증을 선택해주세요.');
      return;
    }

    if (!selectedExamDateId) {
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

  const selectedCertification = certifications.find(c => c.id === selectedCertificationId);
  const selectedExamDate = selectedCertification?.exam_dates.find(d => d.id === selectedExamDateId);

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-white">
      <div className="max-w-4xl mx-auto px-6 py-12">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            {selectedCertification?.name || '자격증 시험 완벽 대비'}
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
            <div className="flex items-baseline justify-center gap-2 mb-3">
              <div className="text-5xl font-bold text-blue-600">₩10,000</div>
              <span className="text-xl text-gray-500">/자격증</span>
            </div>

            {/* 구독 방식 설명 박스 */}
            <div className="bg-blue-50 border-2 border-blue-200 rounded-xl p-4 max-w-2xl mx-auto mb-4">
              <p className="text-sm font-semibold text-blue-900 mb-2">
                📅 구독 방식 안내
              </p>
              <p className="text-sm text-blue-800">
                선택한 <strong>자격증의 시험일자까지</strong> 모든 기능을 무제한으로 이용하실 수 있습니다.
              </p>
              <div className="mt-3 pt-3 border-t border-blue-200">
                <p className="text-xs text-blue-700">
                  <strong>예시:</strong> 사회복지사 1급 2025.03.08 시험 선택 시<br/>
                  → 결제일부터 <strong>2025년 3월 8일 시험일까지</strong> 이용 가능
                </p>
              </div>
            </div>

            <p className="text-gray-600 text-sm">
              💳 토스페이먼츠 안전 결제
            </p>
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

          {/* Certification Selection */}
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <Award className="w-5 h-5" />
              자격증 선택
            </h3>
            {loadingCerts ? (
              <div className="flex items-center justify-center py-8">
                <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
                <span className="ml-3 text-gray-600">자격증 목록 로딩 중...</span>
              </div>
            ) : certifications.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                현재 이용 가능한 자격증이 없습니다.
              </div>
            ) : (
              <div className="space-y-3">
                {certifications.map((cert) => (
                  <button
                    key={cert.id}
                    onClick={() => {
                      setSelectedCertificationId(cert.id);
                      setSelectedExamDateId(''); // Reset exam date selection
                    }}
                    className={`w-full p-4 rounded-lg border-2 transition-all ${
                      selectedCertificationId === cert.id
                        ? 'border-blue-500 bg-blue-50'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="text-left">
                        <p className="font-semibold text-gray-900">{cert.name}</p>
                        <p className="text-sm text-gray-600">{cert.organization}</p>
                      </div>
                      {selectedCertificationId === cert.id && (
                        <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center">
                          <Check className="w-5 h-5 text-white" />
                        </div>
                      )}
                    </div>
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Exam Date Selection */}
          {selectedCertification && (
            <div className="mb-8">
              <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
                <CalendarDays className="w-5 h-5" />
                시험 날짜 선택
              </h3>
              {selectedCertification.exam_dates.length === 0 ? (
                <div className="text-center py-8 text-gray-500 bg-gray-50 rounded-lg">
                  등록된 시험 일정이 없습니다.
                </div>
              ) : (
                <div className="space-y-3">
                  {selectedCertification.exam_dates.map((examDate) => {
                    const date = new Date(examDate.exam_date);
                    const isAvailable = date > new Date();
                    const formattedDate = date.toLocaleDateString('ko-KR', {
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric',
                    });

                    return (
                      <button
                        key={examDate.id}
                        onClick={() => isAvailable && setSelectedExamDateId(examDate.id)}
                        disabled={!isAvailable}
                        className={`w-full p-4 rounded-lg border-2 transition-all ${
                          selectedExamDateId === examDate.id
                            ? 'border-blue-500 bg-blue-50'
                            : isAvailable
                            ? 'border-gray-200 hover:border-gray-300'
                            : 'border-gray-100 bg-gray-50 cursor-not-allowed opacity-50'
                        }`}
                      >
                        <div className="flex items-center justify-between">
                          <div className="text-left">
                            <p className="font-semibold text-gray-900">{formattedDate}</p>
                            {examDate.round_number && (
                              <p className="text-sm text-gray-600">제{examDate.round_number}회 시험</p>
                            )}
                          </div>
                          {selectedExamDateId === examDate.id && (
                            <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center">
                              <Check className="w-5 h-5 text-white" />
                            </div>
                          )}
                          {!isAvailable && (
                            <span className="text-sm text-gray-500">종료됨</span>
                          )}
                        </div>
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          )}

          {/* Payment Button */}
          <button
            onClick={handleStartPayment}
            className={`w-full py-4 rounded-lg font-semibold transition-colors ${
              selectedCertificationId && selectedExamDateId
                ? 'bg-blue-600 text-white hover:bg-blue-700'
                : 'bg-gray-200 text-gray-500 cursor-not-allowed'
            }`}
            disabled={!selectedCertificationId || !selectedExamDateId}
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
      {showPayment && selectedCertificationId && selectedExamDateId && selectedExamDate && (
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
              certificationId={selectedCertificationId}
              examDateId={selectedExamDateId}
              examDate={selectedExamDate.exam_date}
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