"use client";

import { useState } from 'react';
import { useAuth } from '@clerk/nextjs';
import { CreditCard, Smartphone, Building2, Wallet, Shield, ChevronRight, Check, X } from 'lucide-react';

interface CoupangPaymentProps {
  examDate: string;
  amount?: number;
  onSuccess?: () => void;
  onCancel?: () => void;
}

export default function CoupangPayment({
  examDate,
  amount = 10000,
  onSuccess,
  onCancel
}: CoupangPaymentProps) {
  const { getToken } = useAuth();
  const [selectedMethod, setSelectedMethod] = useState<string>('card');
  const [processing, setProcessing] = useState(false);
  const [agreedTerms, setAgreedTerms] = useState(false);
  const [showModal, setShowModal] = useState(true);

  const paymentMethods = [
    { id: 'card', name: '신용/체크카드', icon: CreditCard, popular: true },
    { id: 'kakao', name: '카카오페이', icon: Smartphone, popular: true },
    { id: 'naver', name: '네이버페이', icon: Smartphone },
    { id: 'toss', name: '토스페이', icon: Smartphone },
    { id: 'bank', name: '계좌이체', icon: Building2 },
    { id: 'payco', name: '페이코', icon: Wallet },
  ];

  const handlePayment = async () => {
    if (!agreedTerms) {
      alert('결제 약관에 동의해주세요.');
      return;
    }

    setProcessing(true);

    try {
      const token = await getToken();

      // 1. 결제 요청 생성
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/payment/create`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          exam_date: examDate,
          amount: amount,
          order_name: `사회복지사 1급 시험 대비 (${examDate})`,
        }),
      });

      if (!response.ok) {
        throw new Error('결제 요청 실패');
      }

      const paymentData = await response.json();

      // 2. 토스 결제 위젯 로드 (실제 구현 시)
      // 여기서는 시뮬레이션으로 처리
      setTimeout(() => {
        setProcessing(false);
        alert('결제가 완료되었습니다!');
        setShowModal(false);
        if (onSuccess) onSuccess();
      }, 2000);

    } catch (error) {
      console.error('Payment error:', error);
      setProcessing(false);
      alert('결제 처리 중 오류가 발생했습니다.');
    }
  };

  const formatPrice = (price: number) => {
    return price.toLocaleString('ko-KR');
  };

  if (!showModal) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg w-full max-w-md mx-4 shadow-2xl">
        {/* Header - 쿠팡 스타일 */}
        <div className="bg-gradient-to-r from-orange-500 to-orange-600 text-white p-6 rounded-t-lg">
          <div className="flex items-center justify-between mb-2">
            <h2 className="text-xl font-bold">간편 결제</h2>
            <button
              onClick={() => {
                setShowModal(false);
                if (onCancel) onCancel();
              }}
              className="text-white hover:text-gray-200"
            >
              <X className="w-6 h-6" />
            </button>
          </div>
          <p className="text-sm opacity-90">안전하고 빠른 결제</p>
        </div>

        {/* Product Info */}
        <div className="p-6 border-b">
          <div className="flex justify-between items-start">
            <div>
              <h3 className="font-semibold text-gray-900">사회복지사 1급 시험 대비</h3>
              <p className="text-sm text-gray-600 mt-1">시험일: {examDate}</p>
              <p className="text-xs text-gray-500 mt-1">• 모든 문제 무제한 학습</p>
              <p className="text-xs text-gray-500">• AI 취약점 분석 제공</p>
            </div>
            <div className="text-right">
              <p className="text-2xl font-bold text-orange-600">
                ₩{formatPrice(amount)}
              </p>
              <p className="text-xs text-gray-500 line-through">₩30,000</p>
            </div>
          </div>
        </div>

        {/* Payment Methods */}
        <div className="p-6 border-b">
          <h4 className="text-sm font-semibold text-gray-700 mb-3">결제 수단 선택</h4>
          <div className="grid grid-cols-2 gap-2">
            {paymentMethods.map((method) => (
              <button
                key={method.id}
                onClick={() => setSelectedMethod(method.id)}
                className={`relative flex items-center gap-2 p-3 rounded-lg border-2 transition-all ${
                  selectedMethod === method.id
                    ? 'border-orange-500 bg-orange-50'
                    : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                <method.icon className="w-5 h-5 text-gray-600" />
                <span className="text-sm font-medium">{method.name}</span>
                {method.popular && (
                  <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs px-1.5 py-0.5 rounded">
                    인기
                  </span>
                )}
              </button>
            ))}
          </div>
        </div>

        {/* Terms Agreement */}
        <div className="p-6 border-b">
          <label className="flex items-start gap-3 cursor-pointer">
            <input
              type="checkbox"
              checked={agreedTerms}
              onChange={(e) => setAgreedTerms(e.target.checked)}
              className="mt-1 w-4 h-4 text-orange-500 rounded focus:ring-orange-500"
            />
            <div className="flex-1">
              <span className="text-sm text-gray-700">
                결제 진행 및 서비스 이용약관에 모두 동의합니다
              </span>
              <div className="mt-2 space-y-1">
                <p className="text-xs text-gray-500">• 전자금융거래 이용약관</p>
                <p className="text-xs text-gray-500">• 개인정보 제3자 제공 동의</p>
                <p className="text-xs text-gray-500">• 서비스 이용약관</p>
              </div>
            </div>
          </label>
        </div>

        {/* Security Badge */}
        <div className="px-6 py-3 bg-gray-50">
          <div className="flex items-center justify-center gap-2 text-xs text-gray-600">
            <Shield className="w-4 h-4 text-green-600" />
            <span>안전한 PG사 결제 | 256bit SSL 암호화</span>
          </div>
        </div>

        {/* Payment Button */}
        <div className="p-6">
          <button
            onClick={handlePayment}
            disabled={processing || !agreedTerms}
            className={`w-full py-4 rounded-lg font-semibold text-white transition-all flex items-center justify-center gap-2 ${
              processing || !agreedTerms
                ? 'bg-gray-400 cursor-not-allowed'
                : 'bg-orange-500 hover:bg-orange-600 active:bg-orange-700'
            }`}
          >
            {processing ? (
              <>
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                <span>결제 처리 중...</span>
              </>
            ) : (
              <>
                <span>₩{formatPrice(amount)} 결제하기</span>
                <ChevronRight className="w-5 h-5" />
              </>
            )}
          </button>

          {/* Cancel Button */}
          <button
            onClick={() => {
              setShowModal(false);
              if (onCancel) onCancel();
            }}
            className="w-full mt-2 py-2 text-sm text-gray-600 hover:text-gray-800"
            disabled={processing}
          >
            나중에 결제하기
          </button>
        </div>

        {/* Benefits */}
        <div className="px-6 pb-4">
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3">
            <p className="text-xs font-semibold text-yellow-800 mb-1">💡 결제 혜택</p>
            <p className="text-xs text-yellow-700">지금 결제하면 70% 할인된 가격!</p>
            <p className="text-xs text-yellow-700">불합격 시 다음 시험 50% 할인 쿠폰 제공</p>
          </div>
        </div>
      </div>
    </div>
  );
}