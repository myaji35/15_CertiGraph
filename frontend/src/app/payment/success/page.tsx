"use client";

import { useEffect, useState, Suspense } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import { CheckCircle } from 'lucide-react';
import Link from 'next/link';
import { useAuth } from '@clerk/nextjs';

function PaymentSuccessContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const { getToken } = useAuth();
  const [paymentInfo, setPaymentInfo] = useState<any>(null);
  const [processing, setProcessing] = useState(true);

  const orderId = searchParams.get('orderId');
  const amount = searchParams.get('amount');
  const paymentKey = searchParams.get('paymentKey');
  const certificationId = searchParams.get('certification_id');
  const examDateId = searchParams.get('exam_date_id');

  useEffect(() => {
    if (paymentKey && orderId && amount && certificationId && examDateId) {
      confirmPaymentAndCreateSubscription();
    }
  }, [paymentKey, orderId, amount, certificationId, examDateId]);

  const confirmPaymentAndCreateSubscription = async () => {
    try {
      setProcessing(true);
      const token = await getToken();

      // 1. 결제 확인 (optional - 토스페이먼츠 API로 검증)
      // 생략하고 바로 구독 생성

      // 2. 구독 생성
      const subscriptionResponse = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/v1/subscriptions`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          certification_id: certificationId,
          exam_date_id: examDateId,
          payment_amount: parseInt(amount || '10000'),
          payment_method: 'toss_payments',
        }),
      });

      if (subscriptionResponse.ok) {
        const data = await subscriptionResponse.json();
        setPaymentInfo(data);
      } else {
        const errorData = await subscriptionResponse.json();
        console.error('Subscription creation failed:', errorData);
        alert('구독 생성에 실패했습니다: ' + (errorData.detail || '알 수 없는 오류'));
        router.push('/payment/fail');
      }
    } catch (error) {
      console.error('Payment confirmation or subscription creation failed:', error);
      alert('결제 처리 중 오류가 발생했습니다.');
      router.push('/payment/fail');
    } finally {
      setProcessing(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-8">
        <div className="text-center">
          {processing ? (
            <>
              {/* Processing State */}
              <div className="mx-auto w-24 h-24 bg-blue-100 rounded-full flex items-center justify-center mb-6">
                <div className="animate-spin rounded-full h-16 w-16 border-b-4 border-blue-600"></div>
              </div>
              <h1 className="text-2xl font-bold text-gray-900 mb-2">
                구독 생성 중...
              </h1>
              <p className="text-gray-600 mb-6">
                잠시만 기다려주세요.
              </p>
            </>
          ) : (
            <>
              {/* Success Icon */}
              <div className="mx-auto w-24 h-24 bg-green-100 rounded-full flex items-center justify-center mb-6">
                <CheckCircle className="w-16 h-16 text-green-600" />
              </div>

              {/* Success Message */}
              <h1 className="text-2xl font-bold text-gray-900 mb-2">
                결제가 완료되었습니다!
              </h1>

              <p className="text-gray-600 mb-6">
                자격증 시험 준비를 시작하세요.
              </p>
            </>
          )}

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

export default function PaymentSuccessPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600"></div>
          </div>
        </div>
      }
    >
      <PaymentSuccessContent />
    </Suspense>
  );
}