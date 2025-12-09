'use client';

import { NotionCard, NotionPageHeader } from '@/components/ui/NotionCard';
import { BookOpen, Database, Code, Settings, Monitor, Terminal, TrendingUp, Clock } from 'lucide-react';
import { useRouter } from 'next/navigation';

export default function StudyPage() {
  const router = useRouter();

  const studyCategories = [
    {
      id: 'database',
      title: '데이터베이스 구축',
      icon: <Database className="w-8 h-8" />,
      description: 'SQL, 정규화, 트랜잭션, 인덱싱 등',
      progress: 78,
      totalQuestions: 450,
      completedQuestions: 351,
      lastStudied: '2시간 전',
      difficulty: '중급',
      color: 'blue'
    },
    {
      id: 'software-dev',
      title: '소프트웨어 개발',
      icon: <Code className="w-8 h-8" />,
      description: '개발 방법론, 테스팅, 디버깅, 형상관리',
      progress: 65,
      totalQuestions: 380,
      completedQuestions: 247,
      lastStudied: '1일 전',
      difficulty: '중급',
      color: 'green'
    },
    {
      id: 'software-design',
      title: '소프트웨어 설계',
      icon: <Settings className="w-8 h-8" />,
      description: '설계 패턴, UML, 아키텍처, 모듈화',
      progress: 82,
      totalQuestions: 320,
      completedQuestions: 262,
      lastStudied: '3시간 전',
      difficulty: '고급',
      color: 'purple'
    },
    {
      id: 'info-system',
      title: '정보시스템 구축관리',
      icon: <Monitor className="w-8 h-8" />,
      description: '프로젝트 관리, 시스템 분석, 보안',
      progress: 71,
      totalQuestions: 280,
      completedQuestions: 199,
      lastStudied: '5시간 전',
      difficulty: '중급',
      color: 'orange'
    },
    {
      id: 'programming',
      title: '프로그래밍 언어 활용',
      icon: <Terminal className="w-8 h-8" />,
      description: 'Java, Python, C++, 알고리즘',
      progress: 88,
      totalQuestions: 420,
      completedQuestions: 370,
      lastStudied: '방금 전',
      difficulty: '초급',
      color: 'pink'
    }
  ];

  const handleCategoryClick = (categoryId: string) => {
    router.push(`/dashboard/study/${categoryId}`);
  };

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="학습"
        icon="📚"
        breadcrumbs={[
          { label: '대시보드' },
          { label: '학습' }
        ]}
      />

      {/* 전체 학습 진도 */}
      <NotionCard title="전체 학습 현황" icon={<TrendingUp className="w-5 h-5" />}>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="text-center">
              <div className="text-4xl font-bold text-blue-600 dark:text-blue-400">75.2%</div>
              <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">전체 진도율</p>
            </div>
            <div className="text-center">
              <div className="text-4xl font-bold text-green-600 dark:text-green-400">1,429</div>
              <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">완료한 문제</p>
            </div>
            <div className="text-center">
              <div className="text-4xl font-bold text-purple-600 dark:text-purple-400">45일</div>
              <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">학습 일수</p>
            </div>
          </div>
          <div className="mt-6">
            <div className="flex justify-between mb-2">
              <span className="text-sm font-medium">전체 진행률</span>
              <span className="text-sm text-gray-600 dark:text-gray-400">1,429 / 1,850 문제</span>
            </div>
            <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-3">
              <div className="bg-gradient-to-r from-blue-500 to-purple-600 h-3 rounded-full" style={{ width: '75.2%' }} />
            </div>
          </div>
        </div>
      </NotionCard>

      {/* 학습 카테고리 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {studyCategories.map((category) => (
          <NotionCard
            key={category.id}
            className="cursor-pointer hover:shadow-lg transition-shadow"
            onClick={() => handleCategoryClick(category.id)}
          >
            <div className="p-6">
              <div className={`inline-flex p-3 rounded-lg bg-${category.color}-100 dark:bg-${category.color}-900/20 text-${category.color}-600 dark:text-${category.color}-400 mb-4`}>
                {category.icon}
              </div>
              <h3 className="text-lg font-semibold mb-2">{category.title}</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                {category.description}
              </p>

              <div className="space-y-3">
                <div>
                  <div className="flex justify-between mb-1">
                    <span className="text-sm font-medium">{category.progress}% 완료</span>
                    <span className="text-xs text-gray-500">
                      {category.completedQuestions}/{category.totalQuestions}
                    </span>
                  </div>
                  <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                    <div
                      className={`bg-${category.color}-500 h-2 rounded-full`}
                      style={{ width: `${category.progress}%` }}
                    />
                  </div>
                </div>

                <div className="flex items-center justify-between text-sm">
                  <span className="flex items-center gap-1 text-gray-600 dark:text-gray-400">
                    <Clock className="w-3 h-3" />
                    {category.lastStudied}
                  </span>
                  <span className={`px-2 py-1 rounded text-xs ${
                    category.difficulty === '초급'
                      ? 'bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300'
                      : category.difficulty === '중급'
                      ? 'bg-yellow-100 dark:bg-yellow-900 text-yellow-700 dark:text-yellow-300'
                      : 'bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300'
                  }`}>
                    {category.difficulty}
                  </span>
                </div>
              </div>

              <button className="mt-4 w-full px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors">
                학습 시작
              </button>
            </div>
          </NotionCard>
        ))}
      </div>

      {/* 오늘의 학습 추천 */}
      <NotionCard title="오늘의 학습 추천" icon={<BookOpen className="w-5 h-5" />}>
        <div className="p-6">
          <div className="p-4 bg-gradient-to-r from-purple-500 to-pink-500 rounded-lg text-white">
            <h3 className="text-xl font-bold mb-2">AI 추천 학습 경로</h3>
            <p className="mb-4">
              당신의 학습 패턴과 취약점을 분석한 결과, 오늘은 <strong>소프트웨어 개발</strong> 카테고리를 집중 학습하는 것을 추천합니다.
            </p>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
              <div className="bg-white/20 rounded-lg p-3">
                <p className="text-sm font-medium">추천 학습량</p>
                <p className="text-2xl font-bold">30문제</p>
              </div>
              <div className="bg-white/20 rounded-lg p-3">
                <p className="text-sm font-medium">예상 시간</p>
                <p className="text-2xl font-bold">45분</p>
              </div>
              <div className="bg-white/20 rounded-lg p-3">
                <p className="text-sm font-medium">목표 정답률</p>
                <p className="text-2xl font-bold">80%</p>
              </div>
            </div>
            <button
              onClick={() => handleCategoryClick('software-dev')}
              className="w-full md:w-auto px-6 py-3 bg-white text-purple-600 font-medium rounded-lg hover:bg-gray-100"
            >
              추천 학습 시작하기
            </button>
          </div>
        </div>
      </NotionCard>
    </div>
  );
}