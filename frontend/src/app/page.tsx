import Link from "next/link";
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";

export default async function Home() {
  const { userId } = await auth();

  if (userId) {
    redirect("/dashboard");
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-white">
      {/* Header */}
      <header className="container mx-auto px-4 py-6">
        <nav className="flex items-center justify-between">
          <div className="text-2xl font-bold text-gray-900">ExamsGraph</div>
          <div className="flex items-center gap-4">
            <Link
              href="/study-sets"
              className="text-gray-600 hover:text-gray-900 transition-colors"
            >
              공개 문제집
            </Link>
            <Link
              href="/pricing"
              className="text-gray-600 hover:text-gray-900 transition-colors"
            >
              요금제
            </Link>
            <Link
              href="/sign-in"
              className="text-gray-600 hover:text-gray-900 transition-colors"
            >
              로그인
            </Link>
            <Link
              href="/sign-up"
              className="bg-gray-900 text-white px-4 py-2 rounded-lg hover:bg-gray-800 transition-colors"
            >
              회원가입
            </Link>
          </div>
        </nav>
      </header>

      {/* Hero */}
      <main className="container mx-auto px-4 py-20">
        <div className="max-w-3xl mx-auto text-center">
          <h1 className="text-5xl font-bold text-gray-900 mb-6">
            AI 기반 자격증 학습 플랫폼
          </h1>
          <p className="text-xl text-gray-600 mb-8">
            사회복지사 1급 시험 대비를 위한 스마트한 학습 도구.
            <br />
            PDF 기출문제를 업로드하면 AI가 자동으로 분석하고 맞춤형 학습을 제공합니다.
          </p>
          <div className="flex gap-4 justify-center">
            <Link
              href="/sign-up"
              className="bg-gray-900 text-white px-8 py-3 rounded-lg text-lg font-medium hover:bg-gray-800 transition-colors"
            >
              무료로 시작하기
            </Link>
            <Link
              href="/sign-in"
              className="border border-gray-300 text-gray-700 px-8 py-3 rounded-lg text-lg font-medium hover:bg-gray-50 transition-colors"
            >
              로그인
            </Link>
          </div>
        </div>

        {/* Features */}
        <div className="mt-24 grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
            <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center mb-4">
              <svg className="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">PDF 자동 파싱</h3>
            <p className="text-gray-600">
              기출문제 PDF를 업로드하면 AI가 문제, 보기, 해설을 자동으로 분리합니다.
            </p>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
            <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center mb-4">
              <svg className="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">CBT 모의고사</h3>
            <p className="text-gray-600">
              실제 시험과 유사한 환경에서 연습하고, 보기 순서가 매번 랜덤으로 바뀝니다.
            </p>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
            <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center mb-4">
              <svg className="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">취약점 분석</h3>
            <p className="text-gray-600">
              GraphRAG 기반 AI가 취약한 개념을 분석하고 맞춤형 학습 경로를 제안합니다.
            </p>
          </div>
        </div>

        {/* 공개 문제집 샘플 */}
        <div className="mt-24 max-w-5xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">인기 문제집</h2>
            <p className="text-gray-600">회원가입 없이도 문제집을 둘러볼 수 있습니다</p>
          </div>

          <div className="grid md:grid-cols-3 gap-6 mb-8">
            <div className="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow p-6">
              <div className="text-blue-600 mb-3">
                <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
              </div>
              <h3 className="font-semibold text-gray-900 mb-2">2024 사회복지사 1급 기출</h3>
              <p className="text-sm text-gray-600 mb-3">최신 기출문제 120문제</p>
              <div className="flex justify-between items-center text-sm">
                <span className="text-gray-500">조회 1,234</span>
                <Link href="/study-sets/1" className="text-blue-600 hover:text-blue-700">
                  상세보기 →
                </Link>
              </div>
            </div>

            <div className="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow p-6">
              <div className="text-green-600 mb-3">
                <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <h3 className="font-semibold text-gray-900 mb-2">정신건강론 핵심요약</h3>
              <p className="text-sm text-gray-600 mb-3">핵심 개념 정리 85문제</p>
              <div className="flex justify-between items-center text-sm">
                <span className="text-gray-500">조회 987</span>
                <Link href="/study-sets/2" className="text-blue-600 hover:text-blue-700">
                  상세보기 →
                </Link>
              </div>
            </div>

            <div className="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow p-6">
              <div className="text-purple-600 mb-3">
                <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
              </div>
              <h3 className="font-semibold text-gray-900 mb-2">사회복지정책론 모의고사</h3>
              <p className="text-sm text-gray-600 mb-3">실전 모의고사 200문제</p>
              <div className="flex justify-between items-center text-sm">
                <span className="text-gray-500">조회 756</span>
                <Link href="/study-sets/3" className="text-blue-600 hover:text-blue-700">
                  상세보기 →
                </Link>
              </div>
            </div>
          </div>

          <div className="text-center">
            <Link
              href="/study-sets"
              className="inline-flex items-center gap-2 text-blue-600 hover:text-blue-700 font-medium"
            >
              더 많은 문제집 보기
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </Link>
          </div>
        </div>
      </main>
    </div>
  );
}
