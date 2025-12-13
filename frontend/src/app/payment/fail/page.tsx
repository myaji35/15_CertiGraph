"use client";

import { useSearchParams } from 'next/navigation';
import { XCircle } from 'lucide-react';
import Link from 'next/link';

export default function PaymentFailPage() {
  const searchParams = useSearchParams();

  const code = searchParams.get('code');
  const message = searchParams.get('message');
  const orderId = searchParams.get('orderId');

  const getErrorMessage = () => {
    if (message) return decodeURIComponent(message);

    switch (code) {
      case 'USER_CANCEL':
        return '결제를 취소하셨습니다.';
      case 'EXPIRED_CARD':
        return '만료된 카드입니다. 다른 카드를 사용해주세요.';
      case 'INSUFFICIENT_BALANCE':
        return '잔액이 부족합니다.';
      default:
        return '결제 처리 중 오류가 발생했습니다.';
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-8">
        <div className="text-center">
          {/* Error Icon */}
          <div className="mx-auto w-24 h-24 bg-red-100 rounded-full flex items-center justify-center mb-6">
            <XCircle className="w-16 h-16 text-red-600" />
          </div>

          {/* Error Message */}
          <h1 className="text-2xl font-bold text-gray-900 mb-2">
            결제 실패
          </h1>

          <p className="text-gray-600 mb-6">
            {getErrorMessage()}
          </p>

          {/* Error Details */}
          {(code || orderId) && (
            <div className="bg-gray-50 rounded-lg p-4 mb-6 text-left">
              <div className="space-y-2">
                {code && (
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-600">오류 코드</span>
                    <span className="text-sm font-medium text-gray-900">{code}</span>
                  </div>
                )}
                {orderId && (
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-600">주문번호</span>
                    <span className="text-sm font-medium text-gray-900">{orderId}</span>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Action Buttons */}
          <div className="space-y-3">
            <Link href="/pricing">
              <button className="w-full py-3 px-4 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition-colors">
                다시 시도하기
              </button>
            </Link>

            <Link href="/">
              <button className="w-full py-3 px-4 bg-gray-100 text-gray-700 rounded-lg font-medium hover:bg-gray-200 transition-colors">
                홈으로 돌아가기
              </button>
            </Link>
          </div>

          {/* Support Info */}
          <div className="mt-6 p-4 bg-blue-50 rounded-lg">
            <p className="text-sm text-blue-800 font-medium mb-1">
              도움이 필요하신가요?
            </p>
            <p className="text-xs text-blue-700">
              support@examsgraph.com으로 문의주시면 빠르게 도와드리겠습니다.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}