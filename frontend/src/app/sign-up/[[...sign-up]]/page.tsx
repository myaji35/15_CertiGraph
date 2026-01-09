'use client';

import { SignUp } from "@clerk/nextjs";
import Link from 'next/link';
import { Brain } from 'lucide-react';

export default function SignUpPage() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-gray-100 flex flex-col items-center justify-center p-4">
      {/* Logo and Header */}
      <div className="mb-8 text-center">
        <Link href="/" className="inline-flex items-center gap-2 mb-4">
          <Brain className="w-10 h-10 text-blue-600" />
          <span className="text-2xl font-bold text-gray-900">CertiGraph</span>
        </Link>
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          회원가입
        </h1>
        <p className="text-gray-600">
          AI 자격증 마스터와 함께 시험 준비를 시작하세요
        </p>
      </div>

      {/* Sign Up Component */}
      <div className="w-full max-w-md">
        <SignUp
          appearance={{
            elements: {
              rootBox: "w-full",
              card: "shadow-xl border-0 rounded-2xl",
              headerTitle: "hidden",
              headerSubtitle: "hidden",
              socialButtonsBlockButton: "h-12 border-2 rounded-lg font-medium",
              formFieldInput: "h-12 text-base rounded-lg",
              formButtonPrimary: "h-12 bg-blue-600 hover:bg-blue-700 text-base font-semibold rounded-lg",
              footerActionLink: "text-blue-600 hover:text-blue-700 font-semibold",
              identityPreviewText: "text-gray-700",
              identityPreviewEditButton: "text-blue-600 hover:text-blue-700",
              formFieldLabel: "text-gray-700 font-medium",
              dividerLine: "bg-gray-200",
              dividerText: "text-gray-500",
              footer: "hidden"
            },
            layout: {
              socialButtonsPlacement: "top",
              socialButtonsVariant: "blockButton"
            }
          }}
          routing="path"
          path="/sign-up"
          signInUrl="/sign-in"
          afterSignUpUrl="/dashboard"
        />
      </div>

      {/* Footer Link */}
      <div className="mt-8 text-center">
        <p className="text-gray-600">
          이미 계정이 있으신가요?{' '}
          <Link href="/sign-in" className="text-blue-600 hover:text-blue-700 font-semibold">
            로그인
          </Link>
        </p>
      </div>

      {/* Features */}
      <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-6 max-w-4xl w-full">
        <div className="text-center">
          <div className="bg-blue-100 w-12 h-12 rounded-full flex items-center justify-center mx-auto mb-3">
            <span className="text-2xl">📚</span>
          </div>
          <h3 className="font-semibold text-gray-900 mb-1">PDF 자동 분석</h3>
          <p className="text-sm text-gray-600">문제집을 업로드하면 AI가 자동으로 분석</p>
        </div>
        <div className="text-center">
          <div className="bg-green-100 w-12 h-12 rounded-full flex items-center justify-center mx-auto mb-3">
            <span className="text-2xl">🧠</span>
          </div>
          <h3 className="font-semibold text-gray-900 mb-1">지식 그래프</h3>
          <p className="text-sm text-gray-600">약점을 시각화하여 효율적인 학습</p>
        </div>
        <div className="text-center">
          <div className="bg-purple-100 w-12 h-12 rounded-full flex items-center justify-center mx-auto mb-3">
            <span className="text-2xl">🎯</span>
          </div>
          <h3 className="font-semibold text-gray-900 mb-1">맞춤형 학습</h3>
          <p className="text-sm text-gray-600">개인별 취약점 분석 및 추천</p>
        </div>
      </div>
    </div>
  );
}
