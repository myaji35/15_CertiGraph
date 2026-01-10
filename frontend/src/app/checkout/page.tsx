'use client';

import { useSearchParams } from 'next/navigation';
import { useEffect, useState } from 'react';

export default function CheckoutPage() {
  const searchParams = useSearchParams();
  const certification = searchParams.get('certification');
  const price = searchParams.get('price');
  const [customerName, setCustomerName] = useState('');
  const [customerEmail, setCustomerEmail] = useState('');

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md mx-auto bg-white rounded-lg shadow-md p-8">
        <h1 className="text-2xl font-bold mb-6">결제하기</h1>

        {/* Order Summary */}
        <div className="order-summary mb-6 p-4 bg-gray-100 rounded">
          <h2 className="font-semibold mb-3">주문 내역</h2>

          {/* 자격증 정보 */}
          <div className="flex justify-between mb-2 pb-2 border-b border-gray-300">
            <span className="text-gray-700">자격증</span>
            <span className="font-medium">{certification || '정보처리기사'}</span>
          </div>

          {/* 총 결제 금액 */}
          <div className="flex justify-between items-center mt-3">
            <span className="text-lg font-semibold">총 결제 금액</span>
            <span className="text-2xl font-bold text-blue-600">₩10,000</span>
          </div>
        </div>

        {/* Customer Info Form */}
        <div className="space-y-4 mb-6">
          <div>
            <label className="block text-sm font-medium mb-1">
              이름
            </label>
            <input
              type="text"
              name="customerName"
              placeholder="이름을 입력하세요"
              value={customerName}
              onChange={(e) => setCustomerName(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">
              이메일
            </label>
            <input
              type="email"
              name="customerEmail"
              placeholder="email@example.com"
              value={customerEmail}
              onChange={(e) => setCustomerEmail(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
            />
          </div>
        </div>

        {/* Payment Widget Placeholder */}
        <div id="payment-widget" className="mb-6 p-4 border-2 border-dashed border-gray-300 rounded text-center text-gray-500">
          Toss Payments 위젯 영역
        </div>

        {/* Pay Button */}
        <button
          className="w-full bg-blue-600 text-white py-3 rounded-md hover:bg-blue-700 font-semibold"
          onClick={() => {
            // Simulate payment processing
            console.log('Payment submitted');
          }}
        >
          결제
        </button>
      </div>
    </div>
  );
}
