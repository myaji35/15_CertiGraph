"use client";

import { useEffect, useState } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import { CheckCircle } from 'lucide-react';
import Link from 'next/link';

export default function PaymentSuccessPage() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const [paymentInfo, setPaymentInfo] = useState<any>(null);

  const orderId = searchParams.get('orderId');
  const amount = searchParams.get('amount');
  const paymentKey = searchParams.get('paymentKey');

  useEffect(() => {
    if (paymentKey && orderId && amount) {
      // 결제 확인 처리
      confirmPayment();
    }
  }, [paymentKey, orderId, amount]);

  const confirmPayment = async () => {
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/payment/confirm`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          payment_key: paymentKey,
          order_id: orderId,
          amount: parseInt(amount || '0'),
        }),
      });

      if (response.ok) {
        const data = await response.json();
        setPaymentInfo(data);
      } else {
        // 실패 시 에러 페이지로 리다이렉트
        router.push('/payment/fail');
      }
    } catch (error) {
      console.error('Payment confirmation failed:', error);
      router.push('/payment/fail');
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-8">
        <div className="text-center">
          {/* Success Icon */}
          <div className="mx-auto w-24 h-24 bg-green-100 rounded-full flex items-center justify-center mb-6">
            <CheckCircle className="w-16 h-16 text-green-600" />
          </div>

          {/* Success Message */}
          <h1 className="text-2xl font-bold text-gray-900 mb-2">
            결제가 완료되었습니다!
          </h1>

          <p className="text-gray-600 mb-6">
            사회복지사 1급 시험 준비를 시작하세요.
          </p>

          {/* Payment Details */}
          {orderId && (
            <div className="bg-gray-50 rounded-lg p-4 mb-6 text-left">
              <div className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600">주문번호</span>
                  <span className="text-sm font-medium text-gray-900">{orderId}</span>
                </div>
                {amount && (
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-600">결제금액</span>
                    <span className="text-sm font-medium text-gray-900">
                      ₩{parseInt(amount).toLocaleString('ko-KR')}
                    </span>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Action Buttons */}
          <div className="space-y-3">
            <Link href="/dashboard">
              <button className="w-full py-3 px-4 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition-colors">
                학습 시작하기
              </button>
            </Link>

            <Link href="/">
              <button className="w-full py-3 px-4 bg-gray-100 text-gray-700 rounded-lg font-medium hover:bg-gray-200 transition-colors">
                홈으로 돌아가기
              </button>
            </Link>
          </div>

          {/* Support Info */}
          <p className="mt-6 text-xs text-gray-500">
            문의사항이 있으시면 support@examsgraph.com으로 연락주세요.
          </p>
        </div>
      </div>
    </div>
  );
}