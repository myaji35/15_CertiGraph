"use client";

import { useEffect, useRef, useState } from 'react';
import { loadTossPayments } from '@tosspayments/payment-sdk';

type PaymentWidgetInstance = any; // Temporary type for build
import { useAuth } from '@clerk/nextjs';

interface TossPaymentProps {
  examDate: string;
  amount?: number;
  onSuccess?: () => void;
  onError?: (error: string) => void;
}

export default function TossPayment({
  examDate,
  amount = 10000,
  onSuccess,
  onError
}: TossPaymentProps) {
  const { getToken, userId } = useAuth();
  const paymentWidgetRef = useRef<PaymentWidgetInstance | null>(null);
  const paymentMethodsWidgetRef = useRef<ReturnType<PaymentWidgetInstance["renderPaymentMethods"]> | null>(null);
  const [loading, setLoading] = useState(true);

  // 테스트용 클라이언트 키 (실제 운영 시 환경 변수로 변경)
  const clientKey = process.env.NEXT_PUBLIC_TOSS_CLIENT_KEY || "test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq";
  const customerKey = userId || `guest_${Date.now()}`;

  useEffect(() => {
    (async () => {
      try {
        // 토스 결제 위젯 로드
        const tossPayments = await loadTossPayments(clientKey);
        const paymentWidget = tossPayments.widgets({ customerKey });

        // 결제 UI 렌더링
        const paymentMethodsWidget = paymentWidget.renderPaymentMethods(
          "#payment-widget",
          { value: amount },
          { variantKey: "DEFAULT" }
        );

        // 약관 UI 렌더링
        paymentWidget.renderAgreement(
          "#agreement-widget",
          { variantKey: "DEFAULT" }
        );

        paymentWidgetRef.current = paymentWidget;
        paymentMethodsWidgetRef.current = paymentMethodsWidget;

        setLoading(false);
      } catch (error) {
        console.error("결제 위젯 로드 실패:", error);
        if (onError) onError("결제 시스템 로드에 실패했습니다.");
      }
    })();
  }, [clientKey, customerKey, amount]);

  const handlePaymentRequest = async () => {
    const paymentWidget = paymentWidgetRef.current;

    if (!paymentWidget) {
      alert("결제 시스템이 준비되지 않았습니다.");
      return;
    }

    try {
      const token = await getToken();
      const orderId = `ORDER_${userId}_${examDate}_${Date.now()}`;

      // 토스페이먼츠 결제 요청
      await paymentWidget.requestPayment({
        orderId: orderId,
        orderName: `사회복지사 1급 시험 대비 (${examDate})`,
        customerName: userId || "Guest",
        customerEmail: `${userId}@examsgraph.com`,
        successUrl: `${window.location.origin}/payment/success`,
        failUrl: `${window.location.origin}/payment/fail`,
      });

      // 성공 시 백엔드에 결제 정보 저장
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/payment/confirm`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          payment_key: orderId,
          order_id: orderId,
          amount: amount,
        }),
      });

      if (response.ok && onSuccess) {
        onSuccess();
      }

    } catch (error: any) {
      console.error("결제 요청 실패:", error);
      if (onError) onError(error.message || "결제 처리 중 오류가 발생했습니다.");
    }
  };

  const formatPrice = (price: number) => {
    return price.toLocaleString('ko-KR');
  };

  return (
    <div className="max-w-2xl mx-auto p-6">
      {/* 상품 정보 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <h2 className="text-xl font-bold mb-4">주문 정보</h2>
        <div className="flex justify-between items-start">
          <div>
            <h3 className="font-semibold text-gray-900">사회복지사 1급 시험 대비</h3>
            <p className="text-sm text-gray-600 mt-1">시험일: {examDate}</p>
            <ul className="mt-3 space-y-1">
              <li className="text-sm text-gray-600 flex items-center">
                <span className="text-blue-500 mr-2">✓</span>
                모든 문제 무제한 학습
              </li>
              <li className="text-sm text-gray-600 flex items-center">
                <span className="text-blue-500 mr-2">✓</span>
                AI 기반 취약점 분석
              </li>
              <li className="text-sm text-gray-600 flex items-center">
                <span className="text-blue-500 mr-2">✓</span>
                맞춤형 학습 추천
              </li>
            </ul>
          </div>
          <div className="text-right">
            <p className="text-2xl font-bold text-blue-600">
              ₩{formatPrice(amount)}
            </p>
            <p className="text-sm text-gray-500 line-through mt-1">
              ₩30,000
            </p>
            <p className="text-xs text-green-600 font-semibold mt-1">
              70% 할인
            </p>
          </div>
        </div>
      </div>

      {/* 토스 결제 위젯 영역 */}
      {loading ? (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <span className="ml-3 text-gray-600">결제 시스템 로딩 중...</span>
        </div>
      ) : (
        <>
          {/* 결제 방법 선택 */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
            <h3 className="text-lg font-semibold mb-4">결제 방법</h3>
            <div id="payment-widget" />
          </div>

          {/* 약관 동의 */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
            <h3 className="text-lg font-semibold mb-4">약관 동의</h3>
            <div id="agreement-widget" />
          </div>

          {/* 결제 버튼 */}
          <button
            onClick={handlePaymentRequest}
            className="w-full py-4 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition-colors"
          >
            ₩{formatPrice(amount)} 결제하기
          </button>
        </>
      )}

      {/* 안내 사항 */}
      <div className="mt-6 p-4 bg-gray-50 rounded-lg">
        <p className="text-sm text-gray-600">
          <span className="font-semibold">안내사항:</span>
        </p>
        <ul className="mt-2 space-y-1 text-xs text-gray-500">
          <li>• 결제 후 즉시 학습을 시작할 수 있습니다</li>
          <li>• 시험일까지 무제한 학습이 가능합니다</li>
          <li>• 결제 취소는 이용 전 7일 이내 가능합니다</li>
          <li>• 문의사항: support@examsgraph.com</li>
        </ul>
      </div>
    </div>
  );
}