'use client';

import { useState, useEffect } from 'react';
import { useSearchParams } from 'next/navigation';
import { Search, Book, Video, FileText, Download, ExternalLink, Star, Clock, Users, Filter, ChevronRight, BookOpen, Youtube, Globe, ShoppingCart } from 'lucide-react';

interface StudyMaterial {
  id: string;
  title: string;
  type: 'book' | 'video' | 'online-course' | 'pdf' | 'website' | 'app';
  provider: string;
  description: string;
  price?: string;
  rating?: number;
  reviewCount?: number;
  duration?: string;
  level?: '초급' | '중급' | '고급';
  url?: string;
  features?: string[];
  lastUpdated?: string;
}

// 샘플 학습 자료 데이터
const getStudyMaterials = (certName: string): StudyMaterial[] => {
  // 실제로는 자격증별로 다른 자료를 반환하겠지만, 여기서는 샘플 데이터 사용
  const materials: StudyMaterial[] = [
    // 교재
    {
      id: '1',
      title: `2024 ${certName} 한권으로 끝내기`,
      type: 'book',
      provider: '시대고시',
      description: '최신 출제경향을 완벽 반영한 수험서. 핵심이론과 기출문제를 한 권에 정리',
      price: '35,000원',
      rating: 4.5,
      reviewCount: 342,
      level: '초급',
      features: ['핵심요약', '기출문제', '모의고사 3회분', '온라인 강의 무료 제공'],
      url: 'https://www.yes24.com'
    },
    {
      id: '2',
      title: `${certName} 7일 완성 비법서`,
      type: 'book',
      provider: '에듀윌',
      description: '단기간 합격을 목표로 하는 수험생을 위한 압축 요약서',
      price: '28,000원',
      rating: 4.2,
      reviewCount: 189,
      level: '중급',
      features: ['7일 학습 플랜', '빈출 키워드 정리', '실전 모의고사'],
      url: 'https://www.aladin.co.kr'
    },

    // 온라인 강의
    {
      id: '3',
      title: `${certName} 올인원 패키지`,
      type: 'online-course',
      provider: '인프런',
      description: '기초부터 실전까지 완벽 대비하는 온라인 강의',
      price: '99,000원',
      rating: 4.7,
      reviewCount: 523,
      duration: '40시간',
      level: '초급',
      features: ['평생 수강', '질의응답', '수료증 발급', '실습 자료 제공'],
      url: 'https://www.inflearn.com'
    },
    {
      id: '4',
      title: `${certName} 합격 보장반`,
      type: 'online-course',
      provider: '패스트캠퍼스',
      description: '불합격시 100% 환불 보장하는 프리미엄 과정',
      price: '250,000원',
      rating: 4.8,
      reviewCount: 156,
      duration: '60시간',
      level: '초급',
      features: ['합격 보장', '1:1 멘토링', '스터디 그룹', '모의고사 무제한'],
      url: 'https://fastcampus.co.kr'
    },

    // YouTube 강의
    {
      id: '5',
      title: `[무료] ${certName} 기초 개념 정리`,
      type: 'video',
      provider: 'YouTube - IT 자격증 TV',
      description: '초보자도 쉽게 이해할 수 있는 무료 기초 강의',
      price: '무료',
      rating: 4.3,
      reviewCount: 1205,
      duration: '10시간',
      level: '초급',
      features: ['무료 시청', '기초 개념', '예제 풀이'],
      url: 'https://www.youtube.com'
    },
    {
      id: '6',
      title: `${certName} 족집게 특강`,
      type: 'video',
      provider: 'YouTube - 자격증의 신',
      description: '출제 포인트만 콕콕 짚어주는 핵심 요약 강의',
      price: '무료',
      rating: 4.6,
      reviewCount: 892,
      duration: '5시간',
      level: '중급',
      features: ['무료', '출제포인트', '빈출문제'],
      url: 'https://www.youtube.com'
    },

    // 학습 사이트
    {
      id: '7',
      title: '큐넷 기출문제 다운로드',
      type: 'website',
      provider: '한국산업인력공단',
      description: '공식 기출문제와 정답을 무료로 다운로드',
      price: '무료',
      rating: 5.0,
      reviewCount: 3421,
      features: ['공식 기출문제', '정답 및 해설', '출제기준'],
      url: 'https://www.q-net.or.kr'
    },
    {
      id: '8',
      title: `${certName} 커뮤니티`,
      type: 'website',
      provider: '네이버 카페',
      description: '합격 후기, 학습 자료 공유, 스터디 모집',
      price: '무료',
      rating: 4.4,
      reviewCount: 567,
      features: ['정보 공유', '스터디 모집', '합격 후기', '자료 공유'],
      url: 'https://cafe.naver.com'
    },

    // 모바일 앱
    {
      id: '9',
      title: '자격증 백과사전 앱',
      type: 'app',
      provider: '에듀테크랩',
      description: '언제 어디서나 학습 가능한 모바일 학습 앱',
      price: '월 9,900원',
      rating: 4.1,
      reviewCount: 234,
      features: ['오프라인 학습', '진도 관리', '오답노트', '데일리 퀴즈'],
      url: 'https://play.google.com'
    },

    // PDF 자료
    {
      id: '10',
      title: `${certName} 핵심 요약 노트`,
      type: 'pdf',
      provider: '개인 블로그',
      description: '합격자가 직접 정리한 핵심 요약 노트',
      price: '무료',
      rating: 4.5,
      reviewCount: 445,
      features: ['무료 다운로드', '핵심 정리', 'A4 20페이지'],
      url: '#'
    }
  ];

  return materials;
};

export default function StudyMaterialsPage() {
  const searchParams = useSearchParams();
  const certName = searchParams.get('cert') || '';
  const [materials, setMaterials] = useState<StudyMaterial[]>([]);
  const [filteredMaterials, setFilteredMaterials] = useState<StudyMaterial[]>([]);
  const [selectedType, setSelectedType] = useState<string>('all');
  const [selectedLevel, setSelectedLevel] = useState<string>('all');
  const [selectedPrice, setSelectedPrice] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    if (certName) {
      const data = getStudyMaterials(certName);
      setMaterials(data);
      setFilteredMaterials(data);
    }
  }, [certName]);

  useEffect(() => {
    let filtered = [...materials];

    // 타입 필터
    if (selectedType !== 'all') {
      filtered = filtered.filter(m => m.type === selectedType);
    }

    // 레벨 필터
    if (selectedLevel !== 'all') {
      filtered = filtered.filter(m => m.level === selectedLevel);
    }

    // 가격 필터
    if (selectedPrice === 'free') {
      filtered = filtered.filter(m => m.price === '무료');
    } else if (selectedPrice === 'paid') {
      filtered = filtered.filter(m => m.price !== '무료');
    }

    // 검색어 필터
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(m =>
        m.title.toLowerCase().includes(query) ||
        m.description.toLowerCase().includes(query) ||
        m.provider.toLowerCase().includes(query)
      );
    }

    setFilteredMaterials(filtered);
  }, [selectedType, selectedLevel, selectedPrice, searchQuery, materials]);

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'book': return <Book className="w-5 h-5" />;
      case 'video': return <Youtube className="w-5 h-5" />;
      case 'online-course': return <Video className="w-5 h-5" />;
      case 'pdf': return <FileText className="w-5 h-5" />;
      case 'website': return <Globe className="w-5 h-5" />;
      case 'app': return <Download className="w-5 h-5" />;
      default: return <BookOpen className="w-5 h-5" />;
    }
  };

  const getTypeLabel = (type: string) => {
    switch (type) {
      case 'book': return '교재';
      case 'video': return '동영상';
      case 'online-course': return '온라인 강의';
      case 'pdf': return 'PDF';
      case 'website': return '웹사이트';
      case 'app': return '앱';
      default: return type;
    }
  };

  const getTypeColor = (type: string) => {
    switch (type) {
      case 'book': return 'bg-blue-100 text-blue-700';
      case 'video': return 'bg-red-100 text-red-700';
      case 'online-course': return 'bg-purple-100 text-purple-700';
      case 'pdf': return 'bg-orange-100 text-orange-700';
      case 'website': return 'bg-green-100 text-green-700';
      case 'app': return 'bg-pink-100 text-pink-700';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  return (
    <div className="max-w-7xl mx-auto">
      <div className="mb-8">
        <div className="flex items-center gap-2 text-sm text-gray-500 mb-4">
          <span>자격증 검색</span>
          <ChevronRight className="w-4 h-4" />
          <span className="text-gray-900">{certName || '학습 자료'}</span>
        </div>
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          {certName ? `${certName} 학습 자료` : '학습 자료 찾기'}
        </h1>
        <p className="text-gray-600">
          {certName ? `${certName} 합격을 위한 다양한 학습 자료를 찾아보세요` : '자격증별 맞춤 학습 자료를 검색하세요'}
        </p>
      </div>

      {/* 검색 및 필터 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <div className="relative mb-4">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
          <input
            type="text"
            placeholder="학습 자료 검색..."
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        <div className="grid grid-cols-3 gap-3">
          <select
            className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            value={selectedType}
            onChange={(e) => setSelectedType(e.target.value)}
          >
            <option value="all">모든 유형</option>
            <option value="book">교재</option>
            <option value="online-course">온라인 강의</option>
            <option value="video">동영상</option>
            <option value="website">웹사이트</option>
            <option value="pdf">PDF</option>
            <option value="app">앱</option>
          </select>

          <select
            className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            value={selectedLevel}
            onChange={(e) => setSelectedLevel(e.target.value)}
          >
            <option value="all">모든 레벨</option>
            <option value="초급">초급</option>
            <option value="중급">중급</option>
            <option value="고급">고급</option>
          </select>

          <select
            className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            value={selectedPrice}
            onChange={(e) => setSelectedPrice(e.target.value)}
          >
            <option value="all">모든 가격</option>
            <option value="free">무료</option>
            <option value="paid">유료</option>
          </select>
        </div>
      </div>

      {/* 검색 결과 */}
      <div className="mb-4 text-sm text-gray-600">
        검색 결과: <span className="font-semibold text-gray-900">{filteredMaterials.length}개</span>
      </div>

      {/* 자료 목록 */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {filteredMaterials.map(material => (
          <div key={material.id} className="bg-white rounded-lg shadow-sm border border-gray-200 p-5 hover:shadow-md transition-shadow">
            <div className="flex items-start justify-between mb-3">
              <div className="flex items-center gap-2">
                <span className={`p-2 rounded-lg ${getTypeColor(material.type)}`}>
                  {getTypeIcon(material.type)}
                </span>
                <div>
                  <span className={`px-2 py-1 rounded text-xs font-medium ${getTypeColor(material.type)}`}>
                    {getTypeLabel(material.type)}
                  </span>
                </div>
              </div>
              {material.price && (
                <span className={`font-semibold ${material.price === '무료' ? 'text-green-600' : 'text-gray-900'}`}>
                  {material.price}
                </span>
              )}
            </div>

            <h3 className="font-semibold text-gray-900 mb-2">{material.title}</h3>
            <p className="text-sm text-gray-600 mb-2">{material.provider}</p>
            <p className="text-sm text-gray-500 mb-3">{material.description}</p>

            {/* 메타 정보 */}
            <div className="flex items-center gap-4 mb-3 text-sm">
              {material.rating && (
                <div className="flex items-center gap-1">
                  <Star className="w-4 h-4 text-yellow-500 fill-yellow-500" />
                  <span>{material.rating}</span>
                  {material.reviewCount && (
                    <span className="text-gray-500">({material.reviewCount})</span>
                  )}
                </div>
              )}
              {material.duration && (
                <div className="flex items-center gap-1 text-gray-500">
                  <Clock className="w-4 h-4" />
                  <span>{material.duration}</span>
                </div>
              )}
              {material.level && (
                <span className="px-2 py-1 bg-gray-100 rounded text-xs">
                  {material.level}
                </span>
              )}
            </div>

            {/* 특징 */}
            {material.features && (
              <div className="flex flex-wrap gap-1 mb-3">
                {material.features.slice(0, 3).map((feature, idx) => (
                  <span key={idx} className="px-2 py-1 bg-blue-50 text-blue-700 rounded-full text-xs">
                    {feature}
                  </span>
                ))}
                {material.features.length > 3 && (
                  <span className="px-2 py-1 text-gray-500 text-xs">
                    +{material.features.length - 3}
                  </span>
                )}
              </div>
            )}

            {/* 액션 버튼 */}
            <div className="flex gap-2">
              {material.url && (
                <a
                  href={material.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex-1 flex items-center justify-center gap-2 px-3 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors text-sm"
                >
                  <ExternalLink className="w-4 h-4" />
                  바로가기
                </a>
              )}
              {material.price && material.price !== '무료' && (
                <button className="px-3 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors text-sm">
                  <ShoppingCart className="w-4 h-4" />
                </button>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* 결과 없음 */}
      {filteredMaterials.length === 0 && (
        <div className="text-center py-12">
          <BookOpen className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <p className="text-gray-500">검색 결과가 없습니다.</p>
          <p className="text-sm text-gray-400 mt-2">다른 검색어나 필터를 시도해보세요.</p>
        </div>
      )}

      {/* 추가 정보 */}
      <div className="mt-8 p-4 bg-blue-50 rounded-lg">
        <h3 className="font-semibold text-blue-900 mb-2">💡 학습 팁</h3>
        <ul className="text-sm text-blue-700 space-y-1">
          <li>• 기출문제는 큐넷에서 무료로 다운로드할 수 있습니다</li>
          <li>• YouTube에서 무료 강의를 먼저 들어보고 유료 강의를 선택하세요</li>
          <li>• 네이버 카페나 커뮤니티에서 스터디 그룹을 찾아보세요</li>
          <li>• 모바일 앱을 활용하면 이동 중에도 학습할 수 있습니다</li>
        </ul>
      </div>
    </div>
  );
}