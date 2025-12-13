'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { Search, Filter, Eye, Book, Users, Clock, TrendingUp, Award, ChevronRight } from 'lucide-react';

interface StudySet {
  id: string;
  title: string;
  description: string;
  questionCount: number;
  author: string;
  views: number;
  tests: number;
  difficulty: 'easy' | 'medium' | 'hard';
  category: string;
  thumbnail?: string;
}

export default function PublicStudySets() {
  const [studySets, setStudySets] = useState<StudySet[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [selectedDifficulty, setSelectedDifficulty] = useState('all');

  useEffect(() => {
    // TODO: API에서 공개 문제집 데이터 가져오기
    setStudySets([
      {
        id: '1',
        title: '2024 사회복지사 1급 기출문제',
        description: '최신 기출문제를 바탕으로 구성된 실전 문제집입니다. 상세한 해설과 함께 학습할 수 있습니다.',
        questionCount: 120,
        author: '김교수',
        views: 1234,
        tests: 89,
        difficulty: 'hard',
        category: '사회복지사',
      },
      {
        id: '2',
        title: '정신건강론 핵심요약',
        description: '정신건강론의 주요 개념을 정리한 문제집입니다. 기초부터 심화까지 단계별 학습이 가능합니다.',
        questionCount: 85,
        author: '이강사',
        views: 987,
        tests: 67,
        difficulty: 'medium',
        category: '정신건강',
      },
      {
        id: '3',
        title: '사회복지정책론 모의고사',
        description: '실제 시험과 유사한 형태의 모의고사 5회분이 포함되어 있습니다.',
        questionCount: 200,
        author: '박교수',
        views: 756,
        tests: 45,
        difficulty: 'hard',
        category: '정책론',
      },
      {
        id: '4',
        title: '지역사회복지론 기초',
        description: '지역사회복지론 입문자를 위한 기초 문제집입니다.',
        questionCount: 60,
        author: '최강사',
        views: 543,
        tests: 32,
        difficulty: 'easy',
        category: '지역사회',
      },
    ]);
  }, []);

  const filteredStudySets = studySets.filter(set => {
    const matchesSearch = set.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         set.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = selectedCategory === 'all' || set.category === selectedCategory;
    const matchesDifficulty = selectedDifficulty === 'all' || set.difficulty === selectedDifficulty;
    return matchesSearch && matchesCategory && matchesDifficulty;
  });

  return (
    <div className="min-h-screen bg-gray-50">
      {/* 헤더 */}
      <div className="bg-white shadow-sm">
        <div className="container mx-auto px-4 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">공개 문제집</h1>
              <p className="mt-2 text-gray-600">다양한 문제집을 둘러보고 학습을 시작하세요</p>
            </div>
            <Link
              href="/sign-in"
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              로그인하여 더 많은 기능 사용
            </Link>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-4 py-8">
        {/* 검색 및 필터 */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-8">
          <div className="flex flex-col md:flex-row gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="text"
                placeholder="문제집 검색..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">모든 카테고리</option>
              <option value="사회복지사">사회복지사</option>
              <option value="정신건강">정신건강</option>
              <option value="정책론">정책론</option>
              <option value="지역사회">지역사회</option>
            </select>
            <select
              value={selectedDifficulty}
              onChange={(e) => setSelectedDifficulty(e.target.value)}
              className="px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">모든 난이도</option>
              <option value="easy">초급</option>
              <option value="medium">중급</option>
              <option value="hard">고급</option>
            </select>
          </div>
        </div>

        {/* 통계 카드 */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <StatCard icon={<Book />} label="전체 문제집" value={studySets.length} />
          <StatCard icon={<Users />} label="학습자" value="342명" />
          <StatCard icon={<Clock />} label="평균 학습시간" value="45분" />
          <StatCard icon={<Award />} label="평균 점수" value="72.5점" />
        </div>

        {/* 문제집 그리드 */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredStudySets.map((set) => (
            <div key={set.id} className="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow">
              {/* 썸네일 영역 */}
              <div className="h-32 bg-gradient-to-br from-blue-500 to-purple-600 rounded-t-lg flex items-center justify-center">
                <Book className="w-12 h-12 text-white" />
              </div>

              {/* 콘텐츠 */}
              <div className="p-6">
                <div className="mb-2">
                  <span className={`inline-block px-2 py-1 text-xs rounded-full ${
                    set.difficulty === 'easy' ? 'bg-green-100 text-green-800' :
                    set.difficulty === 'medium' ? 'bg-yellow-100 text-yellow-800' :
                    'bg-red-100 text-red-800'
                  }`}>
                    {set.difficulty === 'easy' ? '초급' : set.difficulty === 'medium' ? '중급' : '고급'}
                  </span>
                  <span className="ml-2 text-xs text-gray-500">{set.category}</span>
                </div>

                <h3 className="text-lg font-semibold text-gray-900 mb-2">{set.title}</h3>
                <p className="text-sm text-gray-600 mb-4 line-clamp-2">{set.description}</p>

                <div className="flex items-center justify-between text-sm text-gray-500 mb-4">
                  <span className="flex items-center gap-1">
                    <Eye className="w-4 h-4" />
                    {set.views}
                  </span>
                  <span className="flex items-center gap-1">
                    <Users className="w-4 h-4" />
                    {set.tests}명 응시
                  </span>
                  <span>{set.questionCount}문제</span>
                </div>

                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-500">작성: {set.author}</span>
                  <Link
                    href={`/study-sets/${set.id}`}
                    className="flex items-center gap-1 px-3 py-1 text-sm bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors"
                  >
                    상세보기
                    <ChevronRight className="w-4 h-4" />
                  </Link>
                </div>
              </div>
            </div>
          ))}
        </div>

        {filteredStudySets.length === 0 && (
          <div className="text-center py-12 bg-white rounded-lg">
            <Book className="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-500">검색 결과가 없습니다.</p>
          </div>
        )}

        {/* CTA 섹션 */}
        <div className="mt-12 bg-blue-50 rounded-lg p-8 text-center">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">
            더 많은 기능을 이용하고 싶으신가요?
          </h2>
          <p className="text-gray-600 mb-6">
            회원가입하시면 문제집 생성, 학습 기록 저장, 맞춤형 추천 등 다양한 기능을 이용할 수 있습니다.
          </p>
          <div className="flex gap-4 justify-center">
            <Link
              href="/sign-up"
              className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              무료 회원가입
            </Link>
            <Link
              href="/pricing"
              className="px-6 py-3 bg-white text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
            >
              요금제 보기
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}

function StatCard({ icon, label, value }: any) {
  return (
    <div className="bg-white rounded-lg p-4 flex items-center gap-3">
      <div className="p-2 bg-blue-50 rounded-lg text-blue-600">
        {icon}
      </div>
      <div>
        <p className="text-sm text-gray-500">{label}</p>
        <p className="text-lg font-semibold text-gray-900">{value}</p>
      </div>
    </div>
  );
}