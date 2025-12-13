'use client';

import { useState, useMemo, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Search, Filter, BookOpen, TrendingUp, Award, Users, Target, Clock, ChevronRight, X, Star, Info, Building } from 'lucide-react';
import { certificationCategories, popularCertifications, certificationsByDifficulty, certificationsByCareer } from '@/data/certificationCategories';
import type { CertificationCategory, CertificationInfo } from '@/data/certificationCategories';

export default function CertificationSearchPage() {
  const router = useRouter();
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('it-tech');  // 기본값을 IT로 설정
  const [selectedDifficulty, setSelectedDifficulty] = useState<string>('all');
  const [selectedExamType, setSelectedExamType] = useState<string>('all');
  const [selectedCareer, setSelectedCareer] = useState<string>('');
  const [showPopularOnly, setShowPopularOnly] = useState(false);
  const [selectedCertification, setSelectedCertification] = useState<{
    cert: CertificationInfo;
    category: CertificationCategory;
  } | null>(null);

  // 모든 자격증을 flat하게 만들어서 검색하기 쉽게
  const allCertifications = useMemo(() => {
    const certs: Array<{ cert: CertificationInfo; category: CertificationCategory }> = [];
    certificationCategories.forEach(category => {
      category.certifications.forEach(cert => {
        certs.push({ cert, category });
      });
    });
    return certs;
  }, []);

  // 디버깅용 - 컴포넌트 마운트 시 데이터 확인
  useEffect(() => {
    console.log('Component mounted. Total certifications loaded:', allCertifications.length);
    console.log('Categories available:', certificationCategories.map(c => c.id));
    console.log('Initial selected category:', selectedCategory);
  }, []);

  // 검색 및 필터링
  const filteredCertifications = useMemo(() => {
    let results = allCertifications;

    console.log('Total certifications:', allCertifications.length);
    console.log('Selected category:', selectedCategory);

    // 카테고리 필터를 먼저 적용
    if (selectedCategory && selectedCategory !== 'all') {
      console.log('Filtering by category:', selectedCategory);
      results = results.filter(({ category }) => {
        const matches = category.id === selectedCategory;
        if (matches) console.log('Match found for category:', category.name);
        return matches;
      });
      console.log('After category filter:', results.length);
    }

    // 검색어 필터
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      results = results.filter(({ cert, category }) =>
        cert.name.toLowerCase().includes(query) ||
        cert.englishName?.toLowerCase().includes(query) ||
        cert.organization.toLowerCase().includes(query) ||
        category.name.toLowerCase().includes(query) ||
        category.subcategories.some(sub => sub.toLowerCase().includes(query))
      );
    }

    // 난이도 필터
    if (selectedDifficulty !== 'all') {
      const difficultyNum = parseInt(selectedDifficulty);
      results = results.filter(({ cert }) => cert.difficulty === difficultyNum);
    }

    // 시험 유형 필터
    if (selectedExamType !== 'all') {
      results = results.filter(({ cert }) => cert.examType === selectedExamType);
    }

    // 인기 자격증만 표시
    if (showPopularOnly) {
      results = results.filter(({ cert }) =>
        cert.popularity && cert.popularity >= 4
      );
    }

    // 진로별 필터
    if (selectedCareer) {
      const careerCerts = certificationsByCareer[selectedCareer as keyof typeof certificationsByCareer] || [];
      results = results.filter(({ cert }) =>
        careerCerts.some(name => cert.name.includes(name))
      );
    }

    console.log('Final filtered results:', results.length);
    return results;
  }, [searchQuery, selectedCategory, selectedDifficulty, selectedExamType, showPopularOnly, selectedCareer, allCertifications]);

  // 카테고리별 통계
  const categoryStats = useMemo(() => {
    const stats: Record<string, number> = {};
    certificationCategories.forEach(cat => {
      stats[cat.id] = cat.certifications.length;
    });
    return stats;
  }, []);

  const getDifficultyStars = (difficulty?: number) => {
    if (!difficulty) return null;
    return (
      <div className="flex items-center gap-0.5">
        {[...Array(5)].map((_, i) => (
          <Star
            key={i}
            className={`w-3 h-3 ${i < difficulty ? 'text-yellow-500 fill-yellow-500' : 'text-gray-300'}`}
          />
        ))}
      </div>
    );
  };

  const getExamTypeColor = (type: string) => {
    switch (type) {
      case 'national': return 'bg-blue-100 text-blue-700';
      case 'private': return 'bg-green-100 text-green-700';
      case 'international': return 'bg-purple-100 text-purple-700';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  const getExamTypeLabel = (type: string) => {
    switch (type) {
      case 'national': return '국가자격';
      case 'private': return '민간자격';
      case 'international': return '국제자격';
      default: return type;
    }
  };

  return (
    <div className="max-w-7xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">자격증 검색</h1>
        <p className="text-gray-600">500개 이상의 자격증 정보를 한 곳에서 검색하고 비교하세요</p>
      </div>

      {/* 검색창 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
          <input
            type="text"
            placeholder="자격증 이름, 기관, 카테고리로 검색... (예: 정보처리, 토익, 한국산업인력공단)"
            className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg text-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        {/* 필터 옵션 */}
        <div className="mt-6 grid grid-cols-2 md:grid-cols-5 gap-3">
          {/* 카테고리 */}
          <select
            className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
          >
            <option value="all">모든 카테고리</option>
            {certificationCategories.map(cat => (
              <option key={cat.id} value={cat.id}>
                {cat.name} ({categoryStats[cat.id]}개)
              </option>
            ))}
          </select>

          {/* 난이도 */}
          <select
            className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            value={selectedDifficulty}
            onChange={(e) => setSelectedDifficulty(e.target.value)}
          >
            <option value="all">모든 난이도</option>
            <option value="1">⭐ 초급</option>
            <option value="2">⭐⭐ 초중급</option>
            <option value="3">⭐⭐⭐ 중급</option>
            <option value="4">⭐⭐⭐⭐ 고급</option>
            <option value="5">⭐⭐⭐⭐⭐ 최고급</option>
          </select>

          {/* 자격 유형 */}
          <select
            className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            value={selectedExamType}
            onChange={(e) => setSelectedExamType(e.target.value)}
          >
            <option value="all">모든 유형</option>
            <option value="national">국가자격</option>
            <option value="private">민간자격</option>
            <option value="international">국제자격</option>
          </select>

          {/* 진로별 */}
          <select
            className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            value={selectedCareer}
            onChange={(e) => setSelectedCareer(e.target.value)}
          >
            <option value="">진로별 추천</option>
            {Object.keys(certificationsByCareer).map(career => (
              <option key={career} value={career}>{career}</option>
            ))}
          </select>

          {/* 인기 자격증만 */}
          <button
            onClick={() => setShowPopularOnly(!showPopularOnly)}
            className={`px-3 py-2 border rounded-lg transition-colors ${
              showPopularOnly
                ? 'bg-blue-500 text-white border-blue-500'
                : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
            }`}
          >
            <TrendingUp className="w-4 h-4 inline mr-1" />
            인기 자격증
          </button>
        </div>

        {/* 빠른 검색 태그 */}
        <div className="mt-4 flex flex-wrap gap-2">
          <span className="text-sm text-gray-500">인기 검색:</span>
          {['정보처리기사', '토익', '공인중개사', '사회복지사', 'SQLD', '빅데이터'].map(tag => (
            <button
              key={tag}
              onClick={() => setSearchQuery(tag)}
              className="px-3 py-1 bg-gray-100 hover:bg-gray-200 rounded-full text-sm text-gray-700 transition-colors"
            >
              {tag}
            </button>
          ))}
        </div>
      </div>

      {/* 검색 결과 통계 */}
      <div className="mb-4 flex items-center justify-between">
        <div className="text-sm text-gray-600">
          검색 결과: <span className="font-semibold text-gray-900">{filteredCertifications.length}개</span> 자격증
        </div>
        {searchQuery && (
          <button
            onClick={() => {
              setSearchQuery('');
              setSelectedCategory('all');
              setSelectedDifficulty('all');
              setSelectedExamType('all');
              setSelectedCareer('');
              setShowPopularOnly(false);
            }}
            className="text-sm text-blue-600 hover:text-blue-700"
          >
            필터 초기화
          </button>
        )}
      </div>

      {/* 검색 결과 그리드 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredCertifications.map(({ cert, category }) => (
          <div
            key={`${category.id}-${cert.name}`}
            className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 hover:shadow-md transition-shadow cursor-pointer"
            onClick={() => setSelectedCertification({ cert, category })}
          >
            {/* 카테고리 헤더 */}
            <div className="flex items-center justify-between mb-3">
              <span className={`px-2 py-1 rounded-full text-xs font-medium ${category.color}`}>
                {category.name}
              </span>
              <span className={`px-2 py-1 rounded text-xs font-medium ${getExamTypeColor(cert.examType)}`}>
                {getExamTypeLabel(cert.examType)}
              </span>
            </div>

            {/* 자격증 이름 */}
            <h3 className="font-semibold text-gray-900 mb-1">
              {cert.name}
              {cert.levels && cert.levels.length > 0 && (
                <span className="text-sm text-gray-500 ml-2">
                  ({cert.levels.join(', ')})
                </span>
              )}
            </h3>

            {cert.englishName && (
              <p className="text-sm text-gray-500 mb-2">{cert.englishName}</p>
            )}

            {/* 기관 */}
            <div className="flex items-center gap-2 text-sm text-gray-600 mb-2">
              <Building className="w-3 h-3" />
              {cert.organization}
            </div>

            {/* 난이도 및 인기도 */}
            <div className="flex items-center justify-between">
              <div>{getDifficultyStars(cert.difficulty)}</div>
              {cert.popularity && (
                <div className="flex items-center gap-1">
                  <Users className="w-3 h-3 text-gray-400" />
                  <div className="flex gap-0.5">
                    {[...Array(cert.popularity)].map((_, i) => (
                      <div key={i} className="w-1 h-3 bg-blue-500 rounded-full" />
                    ))}
                  </div>
                </div>
              )}
            </div>

            {cert.averagePassRate && (
              <div className="mt-2 text-xs text-gray-500">
                평균 합격률: {cert.averagePassRate}%
              </div>
            )}
          </div>
        ))}
      </div>

      {/* 검색 결과 없음 */}
      {filteredCertifications.length === 0 && (
        <div className="text-center py-12">
          <Search className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <p className="text-gray-500">검색 결과가 없습니다.</p>
          <p className="text-sm text-gray-400 mt-2">다른 검색어나 필터를 시도해보세요.</p>
        </div>
      )}

      {/* 자격증 상세 모달 */}
      {selectedCertification && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-[80vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 p-4 flex items-center justify-between">
              <h2 className="text-xl font-semibold">{selectedCertification.cert.name}</h2>
              <button
                onClick={() => setSelectedCertification(null)}
                className="p-2 hover:bg-gray-100 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-6 space-y-4">
              {/* 기본 정보 */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-gray-500">카테고리</p>
                  <p className="font-medium">{selectedCertification.category.name}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">자격 유형</p>
                  <p className="font-medium">{getExamTypeLabel(selectedCertification.cert.examType)}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">시행 기관</p>
                  <p className="font-medium">{selectedCertification.cert.organization}</p>
                </div>
                {selectedCertification.cert.difficulty && (
                  <div>
                    <p className="text-sm text-gray-500">난이도</p>
                    <div>{getDifficultyStars(selectedCertification.cert.difficulty)}</div>
                  </div>
                )}
              </div>

              {selectedCertification.cert.levels && (
                <div>
                  <p className="text-sm text-gray-500 mb-2">응시 가능 등급</p>
                  <div className="flex flex-wrap gap-2">
                    {selectedCertification.cert.levels.map(level => (
                      <span key={level} className="px-3 py-1 bg-gray-100 rounded-full text-sm">
                        {level}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* 관련 정보 */}
              <div className="border-t pt-4">
                <p className="text-sm text-gray-500 mb-2">관련 하위 카테고리</p>
                <div className="flex flex-wrap gap-2">
                  {selectedCertification.category.subcategories.map(sub => (
                    <span key={sub} className="px-3 py-1 bg-blue-50 text-blue-700 rounded-full text-sm">
                      {sub}
                    </span>
                  ))}
                </div>
              </div>

              {/* 액션 버튼 */}
              <div className="flex gap-3 pt-4">
                <button
                  onClick={() => {
                    // 시험 일정 페이지로 이동하면서 자격증 이름을 쿼리 파라미터로 전달
                    router.push(`/certifications?search=${encodeURIComponent(selectedCertification.cert.name)}`);
                  }}
                  className="flex-1 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
                >
                  시험 일정 확인
                </button>
                <button
                  onClick={() => {
                    // 학습 자료 페이지로 이동
                    router.push(`/study-materials?cert=${encodeURIComponent(selectedCertification.cert.name)}`);
                  }}
                  className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  학습 자료 찾기
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}