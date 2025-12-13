"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { motion, AnimatePresence } from "framer-motion";
import { UserButton } from "@clerk/nextjs";

interface LandingPageClientProps {
  isLoggedIn: boolean;
}

export function LandingPageClient({ isLoggedIn }: LandingPageClientProps) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return null; // Prevent SSR mismatch
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
      {/* Header */}
      <motion.header
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ duration: 0.5 }}
        className="container mx-auto px-4 py-6"
      >
        <nav className="flex items-center justify-between">
          <div className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
            ExamsGraph
          </div>
          <div className="flex items-center gap-4">
            {!isLoggedIn ? (
              <>
                <Link
                  href="/study-sets"
                  className="text-gray-600 hover:text-gray-900 transition-colors"
                >
                  공개 문제집
                </Link>
                <Link
                  href="/certifications"
                  className="text-gray-600 hover:text-gray-900 transition-colors"
                >
                  시험일정
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
                  className="bg-gradient-to-r from-blue-600 to-purple-600 text-white px-4 py-2 rounded-lg hover:opacity-90 transition-opacity"
                >
                  무료 시작하기
                </Link>
              </>
            ) : (
              <>
                <Link
                  href="/dashboard"
                  className="text-gray-600 hover:text-gray-900 transition-colors"
                >
                  대시보드
                </Link>
                <Link
                  href="/dashboard/study-sets"
                  className="text-gray-600 hover:text-gray-900 transition-colors"
                >
                  내 문제집
                </Link>
                <Link
                  href="/certifications"
                  className="text-gray-600 hover:text-gray-900 transition-colors"
                >
                  시험일정
                </Link>
                <UserButton afterSignOutUrl="/" />
              </>
            )}
          </div>
        </nav>
      </motion.header>

      {/* Hero Section */}
      <main className="container mx-auto px-4 py-20">
        <AnimatePresence mode="wait">
          {!isLoggedIn ? (
            <LoggedOutHero key="logged-out" />
          ) : (
            <LoggedInDashboard key="logged-in" />
          )}
        </AnimatePresence>

        {/* Features - 공통 섹션 */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3, duration: 0.5 }}
          className="mt-24 grid md:grid-cols-3 gap-8 max-w-5xl mx-auto"
        >
          <FeatureCard
            icon={
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            }
            iconColor="bg-blue-100 text-blue-600"
            title="PDF 자동 파싱"
            description="기출문제 PDF를 업로드하면 AI가 문제, 보기, 해설을 자동으로 분리합니다."
          />
          <FeatureCard
            icon={
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
            }
            iconColor="bg-green-100 text-green-600"
            title="CBT 모의고사"
            description="실제 시험과 유사한 환경에서 연습하고, 보기 순서가 매번 랜덤으로 바뀝니다."
          />
          <FeatureCard
            icon={
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
              </svg>
            }
            iconColor="bg-purple-100 text-purple-600"
            title="AI 취약점 분석"
            description="GraphRAG 기반 AI가 취약한 개념을 분석하고 맞춤형 학습 경로를 제안합니다."
          />
        </motion.div>

        {/* Popular Study Sets */}
        <PopularStudySets isLoggedIn={isLoggedIn} />
      </main>

      {/* Footer */}
      <footer className="mt-32 border-t border-gray-200 bg-white">
        <div className="container mx-auto px-4 py-12">
          <div className="grid md:grid-cols-4 gap-8">
            <div>
              <h3 className="font-bold text-gray-900 mb-4">ExamsGraph</h3>
              <p className="text-sm text-gray-600">
                AI 기반 자격증 학습 플랫폼으로 합격의 지름길을 제공합니다.
              </p>
            </div>
            <div>
              <h4 className="font-semibold text-gray-900 mb-4">서비스</h4>
              <ul className="space-y-2 text-sm">
                <li><Link href="/study-sets" className="text-gray-600 hover:text-gray-900">문제집</Link></li>
                <li><Link href="/certifications" className="text-gray-600 hover:text-gray-900">시험일정</Link></li>
                <li><Link href="/pricing" className="text-gray-600 hover:text-gray-900">요금제</Link></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold text-gray-900 mb-4">회사</h4>
              <ul className="space-y-2 text-sm">
                <li><Link href="/about" className="text-gray-600 hover:text-gray-900">회사소개</Link></li>
                <li><Link href="/contact" className="text-gray-600 hover:text-gray-900">문의하기</Link></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold text-gray-900 mb-4">법적고지</h4>
              <ul className="space-y-2 text-sm">
                <li><Link href="/privacy" className="text-gray-600 hover:text-gray-900">개인정보처리방침</Link></li>
                <li><Link href="/terms" className="text-gray-600 hover:text-gray-900">이용약관</Link></li>
              </ul>
            </div>
          </div>
          <div className="mt-8 pt-8 border-t border-gray-200 text-center text-sm text-gray-600">
            © 2024 ExamsGraph. All rights reserved.
          </div>
        </div>
      </footer>
    </div>
  );
}

// Logged Out Hero
function LoggedOutHero() {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      transition={{ duration: 0.5 }}
      className="max-w-4xl mx-auto text-center relative"
    >
      {/* Animated Background Elements */}
      <div className="absolute inset-0 -z-10 overflow-hidden">
        {/* Large gradient blob - top right */}
        <motion.div
          animate={{
            scale: [1, 1.2, 1],
            rotate: [0, 90, 0],
            x: [0, 50, 0],
            y: [0, -30, 0],
          }}
          transition={{
            duration: 20,
            repeat: Infinity,
            ease: "easeInOut",
          }}
          className="absolute -top-40 -right-40 w-96 h-96 bg-gradient-to-br from-blue-400/30 to-purple-400/30 rounded-full blur-3xl"
        />

        {/* Medium gradient blob - bottom left */}
        <motion.div
          animate={{
            scale: [1, 1.3, 1],
            rotate: [0, -90, 0],
            x: [0, -30, 0],
            y: [0, 50, 0],
          }}
          transition={{
            duration: 15,
            repeat: Infinity,
            ease: "easeInOut",
            delay: 1,
          }}
          className="absolute -bottom-40 -left-40 w-80 h-80 bg-gradient-to-tr from-purple-400/30 to-pink-400/30 rounded-full blur-3xl"
        />

        {/* Small accent blob - top left */}
        <motion.div
          animate={{
            scale: [1, 1.5, 1],
            x: [0, -20, 0],
            y: [0, 30, 0],
          }}
          transition={{
            duration: 12,
            repeat: Infinity,
            ease: "easeInOut",
            delay: 2,
          }}
          className="absolute top-20 left-10 w-64 h-64 bg-gradient-to-br from-blue-300/20 to-cyan-300/20 rounded-full blur-2xl"
        />

        {/* Floating particles */}
        {[...Array(5)].map((_, i) => (
          <motion.div
            key={i}
            animate={{
              y: [0, -100, 0],
              x: [0, Math.random() * 50 - 25, 0],
              opacity: [0, 1, 0],
            }}
            transition={{
              duration: 5 + i * 2,
              repeat: Infinity,
              ease: "easeInOut",
              delay: i * 0.5,
            }}
            className="absolute w-2 h-2 bg-blue-400/50 rounded-full blur-sm"
            style={{
              left: `${20 + i * 15}%`,
              top: `${30 + i * 10}%`,
            }}
          />
        ))}
      </div>

      <motion.div
        initial={{ scale: 0.9 }}
        animate={{ scale: 1 }}
        transition={{ duration: 0.5, delay: 0.2 }}
        className="inline-block mb-6 px-6 py-3 bg-gradient-to-r from-blue-50 to-purple-50 border-2 border-blue-200 rounded-full relative z-10 backdrop-blur-sm"
      >
        <span className="text-blue-700 font-semibold text-sm md:text-base">
          📄 PDF 업로드만으로 자동 문제 분석
        </span>
      </motion.div>

      <h1 className="text-5xl md:text-6xl font-bold text-gray-900 mb-6 leading-tight">
        <span className="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
          기출문제 PDF를 업로드하면
        </span>
        <br />
        <span className="text-gray-900">
          AI가 문제, 보기, 해설을
        </span>
        <br />
        <span className="bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent">
          자동으로 분리합니다
        </span>
      </h1>

      <p className="text-xl text-gray-600 mb-10 max-w-2xl mx-auto leading-relaxed">
        번거로운 문제 입력은 그만!
        <span className="font-semibold text-gray-800"> PDF 한 번 업로드로 </span>
        CBT 모의고사부터 AI 취약점 분석까지.
        <br />
        <span className="text-blue-600 font-medium">사회복지사 1급</span> 시험 대비의 새로운 기준을 경험하세요.
      </p>

      <div className="flex gap-4 justify-center">
        <Link
          href="/sign-up"
          className="bg-gradient-to-r from-blue-600 to-purple-600 text-white px-8 py-4 rounded-lg text-lg font-medium hover:opacity-90 transition-opacity shadow-lg"
        >
          무료로 시작하기 →
        </Link>
        <Link
          href="/study-sets"
          className="border-2 border-gray-300 text-gray-700 px-8 py-4 rounded-lg text-lg font-medium hover:bg-gray-50 transition-colors"
        >
          둘러보기
        </Link>
      </div>

      <div className="mt-12 flex items-center justify-center gap-8 text-sm text-gray-600">
        <div className="flex items-center gap-2">
          <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
          </svg>
          <span>무료 시작</span>
        </div>
        <div className="flex items-center gap-2">
          <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
          </svg>
          <span>신용카드 불필요</span>
        </div>
        <div className="flex items-center gap-2">
          <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
          </svg>
          <span>즉시 사용 가능</span>
        </div>
      </div>
    </motion.div>
  );
}

// Logged In Dashboard Preview
function LoggedInDashboard() {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      transition={{ duration: 0.5 }}
      className="max-w-6xl mx-auto"
    >
      <div className="text-center mb-12">
        <h1 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
          안녕하세요! 👋
        </h1>
        <p className="text-xl text-gray-600">
          오늘도 목표를 향해 한 걸음 나아가볼까요?
        </p>
      </div>

      {/* Quick Stats */}
      <div className="grid md:grid-cols-4 gap-6 mb-12">
        <StatCard
          icon="📚"
          label="내 문제집"
          value="3개"
          bgColor="bg-blue-50"
          textColor="text-blue-700"
        />
        <StatCard
          icon="✅"
          label="오늘 학습"
          value="12문제"
          bgColor="bg-green-50"
          textColor="text-green-700"
        />
        <StatCard
          icon="🎯"
          label="정답률"
          value="85%"
          bgColor="bg-purple-50"
          textColor="text-purple-700"
        />
        <StatCard
          icon="🔥"
          label="연속 학습"
          value="7일"
          bgColor="bg-orange-50"
          textColor="text-orange-700"
        />
      </div>

      {/* Quick Actions */}
      <div className="grid md:grid-cols-3 gap-6">
        <QuickActionCard
          href="/study-sets"
          icon="📖"
          title="학습 이어하기"
          description="저번에 공부하던 문제집으로 이동합니다"
          buttonText="계속하기"
          color="blue"
        />
        <QuickActionCard
          href="/dashboard/test"
          icon="🎓"
          title="모의고사 보기"
          description="실전과 동일한 환경에서 실력을 테스트하세요"
          buttonText="시작하기"
          color="green"
        />
        <QuickActionCard
          href="/dashboard/analysis"
          icon="📊"
          title="취약점 분석"
          description="AI가 분석한 나의 약점을 확인하세요"
          buttonText="분석 보기"
          color="purple"
        />
      </div>
    </motion.div>
  );
}

// Reusable Components
function FeatureCard({ icon, iconColor, title, description }: {
  icon: React.ReactNode;
  iconColor: string;
  title: string;
  description: string;
}) {
  return (
    <motion.div
      whileHover={{ y: -5 }}
      className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-all"
    >
      <div className={`w-12 h-12 ${iconColor} rounded-lg flex items-center justify-center mb-4`}>
        {icon}
      </div>
      <h3 className="text-lg font-semibold text-gray-900 mb-2">{title}</h3>
      <p className="text-gray-600">{description}</p>
    </motion.div>
  );
}

function StatCard({ icon, label, value, bgColor, textColor }: {
  icon: string;
  label: string;
  value: string;
  bgColor: string;
  textColor: string;
}) {
  return (
    <motion.div
      whileHover={{ scale: 1.05 }}
      className={`${bgColor} p-6 rounded-xl`}
    >
      <div className="text-3xl mb-2">{icon}</div>
      <div className="text-sm text-gray-600 mb-1">{label}</div>
      <div className={`text-2xl font-bold ${textColor}`}>{value}</div>
    </motion.div>
  );
}

function QuickActionCard({ href, icon, title, description, buttonText, color }: {
  href: string;
  icon: string;
  title: string;
  description: string;
  buttonText: string;
  color: 'blue' | 'green' | 'purple';
}) {
  const colorClasses = {
    blue: 'from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700',
    green: 'from-green-500 to-green-600 hover:from-green-600 hover:to-green-700',
    purple: 'from-purple-500 to-purple-600 hover:from-purple-600 hover:to-purple-700',
  };

  return (
    <motion.div
      whileHover={{ y: -5 }}
      className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-all"
    >
      <div className="text-4xl mb-4">{icon}</div>
      <h3 className="text-xl font-semibold text-gray-900 mb-2">{title}</h3>
      <p className="text-gray-600 mb-4">{description}</p>
      <Link
        href={href}
        className={`inline-block w-full text-center bg-gradient-to-r ${colorClasses[color]} text-white px-4 py-2 rounded-lg font-medium transition-all`}
      >
        {buttonText} →
      </Link>
    </motion.div>
  );
}

function PopularStudySets({ isLoggedIn }: { isLoggedIn: boolean }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: 0.5, duration: 0.5 }}
      className="mt-24 max-w-5xl mx-auto"
    >
      <div className="text-center mb-12">
        <h2 className="text-3xl font-bold text-gray-900 mb-4">
          {isLoggedIn ? "추천 문제집" : "인기 문제집"}
        </h2>
        <p className="text-gray-600">
          {isLoggedIn
            ? "회원님의 학습 패턴에 맞춘 문제집을 추천합니다"
            : "회원가입 없이도 문제집을 둘러볼 수 있습니다"}
        </p>
      </div>

      <div className="grid md:grid-cols-3 gap-6 mb-8">
        <StudySetCard
          icon="📘"
          title="2024 사회복지사 1급 기출"
          description="최신 기출문제 120문제"
          views={1234}
          href="/study-sets/1"
          color="blue"
        />
        <StudySetCard
          icon="💚"
          title="정신건강론 핵심요약"
          description="핵심 개념 정리 85문제"
          views={987}
          href="/study-sets/2"
          color="green"
        />
        <StudySetCard
          icon="⚡"
          title="사회복지정책론 모의고사"
          description="실전 모의고사 200문제"
          views={756}
          href="/study-sets/3"
          color="purple"
        />
      </div>

      <div className="text-center">
        <Link
          href="/study-sets"
          className="inline-flex items-center gap-2 text-blue-600 hover:text-blue-700 font-medium text-lg group"
        >
          더 많은 문제집 보기
          <svg
            className="w-5 h-5 group-hover:translate-x-1 transition-transform"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
          </svg>
        </Link>
      </div>
    </motion.div>
  );
}

function StudySetCard({ icon, title, description, views, href, color }: {
  icon: string;
  title: string;
  description: string;
  views: number;
  href: string;
  color: 'blue' | 'green' | 'purple';
}) {
  const colorClasses = {
    blue: 'text-blue-600',
    green: 'text-green-600',
    purple: 'text-purple-600',
  };

  return (
    <motion.div
      whileHover={{ y: -5 }}
      className="bg-white rounded-lg shadow-sm hover:shadow-md transition-all p-6 border border-gray-100"
    >
      <div className={`text-4xl mb-3 ${colorClasses[color]}`}>{icon}</div>
      <h3 className="font-semibold text-gray-900 mb-2">{title}</h3>
      <p className="text-sm text-gray-600 mb-3">{description}</p>
      <div className="flex justify-between items-center text-sm">
        <span className="text-gray-500">조회 {views.toLocaleString()}</span>
        <Link href={href} className={`${colorClasses[color]} hover:underline font-medium`}>
          상세보기 →
        </Link>
      </div>
    </motion.div>
  );
}
