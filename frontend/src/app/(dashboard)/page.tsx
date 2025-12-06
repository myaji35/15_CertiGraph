import { currentUser } from "@clerk/nextjs/server";

export default async function DashboardPage() {
  const user = await currentUser();

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">
        {user?.firstName || user?.emailAddresses[0]?.emailAddress}님, 환영합니다!
      </h1>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-100">
          <p className="text-sm text-gray-500">총 학습 문제</p>
          <p className="text-3xl font-bold text-gray-900">0</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-100">
          <p className="text-sm text-gray-500">평균 정답률</p>
          <p className="text-3xl font-bold text-gray-900">--%</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-100">
          <p className="text-sm text-gray-500">학습 세트</p>
          <p className="text-3xl font-bold text-gray-900">0개</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-100">
          <p className="text-sm text-gray-500">모의고사 응시</p>
          <p className="text-3xl font-bold text-gray-900">0회</p>
        </div>
      </div>

      {/* Onboarding */}
      <div className="bg-blue-50 border border-blue-200 rounded-lg p-6">
        <h2 className="text-lg font-semibold text-blue-900 mb-2">
          첫 번째 PDF를 업로드하고 학습을 시작해보세요!
        </h2>
        <p className="text-blue-700 mb-4">
          사회복지사 1급 기출문제 PDF를 업로드하면 AI가 자동으로 문제를 분석합니다.
        </p>
        <a
          href="/dashboard/study-sets/new"
          className="inline-block bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
        >
          PDF 업로드하기
        </a>
      </div>
    </div>
  );
}
