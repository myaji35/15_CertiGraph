'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { ArrowLeft, Book, Users, Clock, Calendar, Award, Play, Share2, Heart, ChevronRight, Eye, FileText } from 'lucide-react';

interface StudySetDetail {
  id: string;
  title: string;
  description: string;
  longDescription: string;
  questionCount: number;
  author: string;
  authorBio: string;
  createdAt: string;
  updatedAt: string;
  views: number;
  tests: number;
  likes: number;
  difficulty: 'easy' | 'medium' | 'hard';
  category: string;
  tags: string[];
  estimatedTime: number;
  chapters: Chapter[];
}

interface Chapter {
  id: string;
  title: string;
  questionCount: number;
  description: string;
}

export default function StudySetDetail() {
  const params = useParams();
  const [studySet, setStudySet] = useState<StudySetDetail | null>(null);
  const [liked, setLiked] = useState(false);

  useEffect(() => {
    // TODO: API에서 실제 데이터 가져오기
    setStudySet({
      id: params.id as string,
      title: '2024 사회복지사 1급 기출문제',
      description: '최신 기출문제를 바탕으로 구성된 실전 문제집입니다.',
      longDescription: `본 문제집은 2024년 사회복지사 1급 시험을 준비하는 수험생들을 위해 제작되었습니다.

      최근 5년간의 기출문제를 철저히 분석하여 출제 경향과 핵심 포인트를 파악하였으며,
      각 문제마다 상세한 해설을 제공하여 깊이 있는 학습이 가능하도록 구성하였습니다.

      특히 오답률이 높은 문제들을 별도로 선별하여 집중 학습할 수 있도록 하였으며,
      실제 시험과 동일한 형식의 모의고사도 포함되어 있어 실전 감각을 익힐 수 있습니다.`,
      questionCount: 120,
      author: '김교수',
      authorBio: '○○대학교 사회복지학과 교수, 15년 경력',
      createdAt: '2024-01-15',
      updatedAt: '2024-01-20',
      views: 1234,
      tests: 89,
      likes: 156,
      difficulty: 'hard',
      category: '사회복지사',
      tags: ['기출문제', '2024년', '사회복지사1급', '모의고사'],
      estimatedTime: 180,
      chapters: [
        { id: '1', title: '사회복지정책론', questionCount: 30, description: '사회복지정책의 기초 개념과 이론' },
        { id: '2', title: '사회복지실천론', questionCount: 25, description: '사회복지실천의 과정과 기술' },
        { id: '3', title: '지역사회복지론', questionCount: 25, description: '지역사회복지의 이해와 실천' },
        { id: '4', title: '사회복지행정론', questionCount: 20, description: '사회복지조직과 관리' },
        { id: '5', title: '모의고사', questionCount: 20, description: '실전 모의고사 문제' },
      ]
    });
  }, [params.id]);

  if (!studySet) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">로딩 중...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* 헤더 */}
      <div className="bg-white shadow-sm">
        <div className="container mx-auto px-4 py-4">
          <Link href="/study-sets" className="inline-flex items-center gap-2 text-gray-600 hover:text-gray-900">
            <ArrowLeft className="w-5 h-5" />
            문제집 목록으로
          </Link>
        </div>
      </div>

      {/* 메인 콘텐츠 */}
      <div className="container mx-auto px-4 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* 왼쪽: 상세 정보 */}
          <div className="lg:col-span-2 space-y-6">
            {/* 제목 섹션 */}
            <div className="bg-white rounded-lg p-6">
              <div className="flex items-start justify-between mb-4">
                <div>
                  <h1 className="text-3xl font-bold text-gray-900 mb-2">{studySet.title}</h1>
                  <p className="text-gray-600">{studySet.description}</p>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => setLiked(!liked)}
                    className={`p-2 rounded-lg transition-colors ${
                      liked ? 'bg-red-50 text-red-600' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                    }`}
                  >
                    <Heart className={`w-5 h-5 ${liked ? 'fill-current' : ''}`} />
                  </button>
                  <button className="p-2 bg-gray-100 text-gray-600 rounded-lg hover:bg-gray-200 transition-colors">
                    <Share2 className="w-5 h-5" />
                  </button>
                </div>
              </div>

              <div className="flex flex-wrap gap-2 mb-4">
                {studySet.tags.map((tag) => (
                  <span key={tag} className="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-sm">
                    #{tag}
                  </span>
                ))}
              </div>

              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <StatItem icon={<Eye />} label="조회수" value={studySet.views} />
                <StatItem icon={<Users />} label="응시자" value={studySet.tests} />
                <StatItem icon={<Heart />} label="좋아요" value={studySet.likes} />
                <StatItem icon={<Clock />} label="예상 시간" value={`${studySet.estimatedTime}분`} />
              </div>
            </div>

            {/* 상세 설명 */}
            <div className="bg-white rounded-lg p-6">
              <h2 className="text-xl font-semibold mb-4">상세 설명</h2>
              <div className="prose prose-gray max-w-none">
                <pre className="whitespace-pre-wrap font-sans text-gray-700">{studySet.longDescription}</pre>
              </div>
            </div>

            {/* 챕터 목록 */}
            <div className="bg-white rounded-lg p-6">
              <h2 className="text-xl font-semibold mb-4">구성 내용</h2>
              <div className="space-y-3">
                {studySet.chapters.map((chapter, index) => (
                  <div key={chapter.id} className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50 transition-colors">
                    <div className="flex items-start gap-3">
                      <span className="flex items-center justify-center w-8 h-8 bg-blue-100 text-blue-600 rounded-full text-sm font-semibold">
                        {index + 1}
                      </span>
                      <div>
                        <h3 className="font-medium text-gray-900">{chapter.title}</h3>
                        <p className="text-sm text-gray-600">{chapter.description}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 text-sm text-gray-500">
                      <FileText className="w-4 h-4" />
                      {chapter.questionCount}문제
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* 오른쪽: 사이드바 */}
          <div className="space-y-6">
            {/* 작성자 정보 */}
            <div className="bg-white rounded-lg p-6">
              <h3 className="font-semibold mb-4">작성자 정보</h3>
              <div className="flex items-center gap-3 mb-3">
                <div className="w-12 h-12 bg-gray-200 rounded-full flex items-center justify-center">
                  <Users className="w-6 h-6 text-gray-500" />
                </div>
                <div>
                  <p className="font-medium text-gray-900">{studySet.author}</p>
                  <p className="text-sm text-gray-600">{studySet.authorBio}</p>
                </div>
              </div>
              <div className="text-sm text-gray-500">
                <p>생성일: {studySet.createdAt}</p>
                <p>수정일: {studySet.updatedAt}</p>
              </div>
            </div>

            {/* 학습 시작 버튼 */}
            <div className="bg-white rounded-lg p-6">
              <div className="mb-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-gray-600">난이도</span>
                  <span className={`px-2 py-1 text-xs rounded-full ${
                    studySet.difficulty === 'easy' ? 'bg-green-100 text-green-800' :
                    studySet.difficulty === 'medium' ? 'bg-yellow-100 text-yellow-800' :
                    'bg-red-100 text-red-800'
                  }`}>
                    {studySet.difficulty === 'easy' ? '초급' : studySet.difficulty === 'medium' ? '중급' : '고급'}
                  </span>
                </div>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-gray-600">카테고리</span>
                  <span className="text-sm font-medium text-gray-900">{studySet.category}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-600">전체 문제</span>
                  <span className="text-sm font-medium text-gray-900">{studySet.questionCount}문제</span>
                </div>
              </div>

              <Link
                href="/sign-in"
                className="w-full flex items-center justify-center gap-2 px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                <Play className="w-5 h-5" />
                학습 시작하기
              </Link>
              <p className="text-xs text-gray-500 text-center mt-3">
                로그인이 필요한 기능입니다
              </p>
            </div>

            {/* 추천 문제집 */}
            <div className="bg-white rounded-lg p-6">
              <h3 className="font-semibold mb-4">추천 문제집</h3>
              <div className="space-y-3">
                <RecommendItem title="정신건강론 핵심요약" questionCount={85} />
                <RecommendItem title="사회복지정책론 모의고사" questionCount={200} />
                <RecommendItem title="지역사회복지론 기초" questionCount={60} />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function StatItem({ icon, label, value }: any) {
  return (
    <div className="flex items-center gap-2">
      <div className="text-gray-400">{icon}</div>
      <div>
        <p className="text-sm text-gray-500">{label}</p>
        <p className="font-semibold text-gray-900">{value}</p>
      </div>
    </div>
  );
}

function RecommendItem({ title, questionCount }: any) {
  return (
    <Link href="#" className="flex items-center justify-between p-3 border rounded-lg hover:bg-gray-50 transition-colors">
      <div>
        <p className="text-sm font-medium text-gray-900">{title}</p>
        <p className="text-xs text-gray-500">{questionCount}문제</p>
      </div>
      <ChevronRight className="w-4 h-4 text-gray-400" />
    </Link>
  );
}