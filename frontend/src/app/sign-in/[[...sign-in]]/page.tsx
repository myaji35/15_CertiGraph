'use client';

import { SignIn } from "@clerk/nextjs";
import Link from 'next/link';
import { Brain } from 'lucide-react';

export default function SignInPage() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-gray-100 flex flex-col items-center justify-center p-4">
      {/* Logo and Header */}
      <div className="mb-8 text-center">
        <Link href="/" className="inline-flex items-center gap-2 mb-4">
          <Brain className="w-10 h-10 text-blue-600" />
          <span className="text-2xl font-bold text-gray-900">CertiGraph</span>
        </Link>
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          로그인
        </h1>
        <p className="text-gray-600">
          다시 만나서 반가워요! 학습을 계속해보세요.
        </p>
      </div>

      {/* Sign In Component */}
      <div className="w-full max-w-md">
        <SignIn
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
          path="/sign-in"
          signUpUrl="/sign-up"
          afterSignInUrl="/dashboard"
        />
      </div>

      {/* Footer Link */}
      <div className="mt-8 text-center">
        <p className="text-gray-600">
          아직 계정이 없으신가요?{' '}
          <Link href="/sign-up" className="text-blue-600 hover:text-blue-700 font-semibold">
            회원가입
          </Link>
        </p>
      </div>

      {/* Quick Stats */}
      <div className="mt-12 grid grid-cols-3 gap-8 max-w-2xl w-full text-center">
        <div>
          <p className="text-3xl font-bold text-blue-600">1,000+</p>
          <p className="text-sm text-gray-600 mt-1">활성 사용자</p>
        </div>
        <div>
          <p className="text-3xl font-bold text-green-600">50,000+</p>
          <p className="text-sm text-gray-600 mt-1">분석된 문제</p>
        </div>
        <div>
          <p className="text-3xl font-bold text-purple-600">95%</p>
          <p className="text-sm text-gray-600 mt-1">합격률</p>
        </div>
      </div>
    </div>
  );
}
