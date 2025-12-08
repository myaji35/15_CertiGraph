'use client';

import { useState, useEffect, useMemo } from 'react';
import {
  BookOpen,
  Calendar,
  Award,
  Building,
  ChevronRight,
  Filter,
  Check,
  Star,
  Search,
  Clock,
  Users,
  TrendingUp,
  Info,
  X,
  BookmarkPlus,
  Bookmark,
  Download,
  AlertCircle,
  CheckCircle
} from 'lucide-react';
import { getCertifications, saveCertificationPreference } from '@/lib/api/certifications';
import type { Certification, CertificationCategory } from '@/types/certification';

const CATEGORY_LABELS = {
  national: '국가기술자격',
  national_professional: '국가전문자격',
  private: '민간자격',
  international: '국제자격'
};

const LEVEL_LABELS = {
  technician: '기능사',
  industrial_engineer: '산업기사',
  engineer: '기사',
  master: '기능장/기술사',
  level_1: '1급',
  level_2: '2급',
  level_3: '3급',
  single: '단일등급'
};

// 카테고리별 색상
const CATEGORY_COLORS = {
  national: 'bg-blue-50 text-blue-700 border-blue-200',
  national_professional: 'bg-purple-50 text-purple-700 border-purple-200',
  private: 'bg-indigo-50 text-indigo-700 border-indigo-200',
  international: 'bg-green-50 text-green-700 border-green-200'
};

// 난이도별 색상
const DIFFICULTY_COLORS = {
  beginner: 'bg-green-100 text-green-700',
  intermediate: 'bg-yellow-100 text-yellow-700',
  advanced: 'bg-red-100 text-red-700'
};

interface CertificationListProps {
  onSelect?: (certification: Certification) => void;
}

export function CertificationList({ onSelect }: CertificationListProps) {
  const [certifications, setCertifications] = useState<Certification[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<CertificationCategory | null>(null);
  const [selectedCertification, setSelectedCertification] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [bookmarkedCerts, setBookmarkedCerts] = useState<Set<string>>(new Set());
  const [showDetail, setShowDetail] = useState(false);
  const [detailCert, setDetailCert] = useState<Certification | null>(null);
  const [syncing, setSyncing] = useState(false);
  const [syncResult, setSyncResult] = useState<{
    type: 'success' | 'error' | null;
    message: string;
    count?: number;
  }>({ type: null, message: '' });

  useEffect(() => {
    loadCertifications();
    loadBookmarks();
  }, [selectedCategory]);

  // 북마크 로드
  const loadBookmarks = () => {
    const saved = localStorage.getItem('bookmarkedCertifications');
    if (saved) {
      setBookmarkedCerts(new Set(JSON.parse(saved)));
    }
  };

  // 북마크 토글
  const toggleBookmark = (certId: string, e?: React.MouseEvent) => {
    if (e) {
      e.stopPropagation();
    }

    const newBookmarks = new Set(bookmarkedCerts);
    if (newBookmarks.has(certId)) {
      newBookmarks.delete(certId);
    } else {
      newBookmarks.add(certId);
    }

    setBookmarkedCerts(newBookmarks);
    localStorage.setItem('bookmarkedCertifications', JSON.stringify(Array.from(newBookmarks)));
  };

  const loadCertifications = async () => {
    setLoading(true);
    try {
      const data = await getCertifications(
        selectedCategory ? { category: selectedCategory } : undefined
      );
      setCertifications(data.certifications);
    } catch (error) {
      console.error('Failed to load certifications:', error);
    } finally {
      setLoading(false);
    }
  };

  // 공공 API에서 데이터 동기화
  const syncFromPublicAPI = async () => {
    setSyncing(true);
    setSyncResult({ type: null, message: '' });

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/certifications/sync-from-api`);
      const result = await response.json();

      if (result.success) {
        setSyncResult({
          type: 'success',
          message: `${result.data?.count || 0}개의 시험 일정을 성공적으로 가져왔습니다!`,
          count: result.data?.count
        });

        // 3초 후 성공 메시지 숨기기
        setTimeout(() => {
          setSyncResult({ type: null, message: '' });
        }, 3000);

        // 데이터 새로고침
        await loadCertifications();
      } else {
        setSyncResult({
          type: 'error',
          message: result.message || '데이터 동기화에 실패했습니다.'
        });
      }
    } catch (error) {
      console.error('Sync failed:', error);
      setSyncResult({
        type: 'error',
        message: 'API 연결에 실패했습니다. 잠시 후 다시 시도해주세요.'
      });
    } finally {
      setSyncing(false);
    }
  };

  const handleSelectCertification = async (certification: Certification) => {
    setSelectedCertification(certification.id);

    if (onSelect) {
      onSelect(certification);
    }

    // Save preference
    setSaving(true);
    try {
      await saveCertificationPreference(certification.id);
    } catch (error) {
      console.error('Failed to save preference:', error);
    } finally {
      setSaving(false);
    }
  };

  // 상세 정보 보기
  const showCertificationDetail = (certification: Certification, e?: React.MouseEvent) => {
    if (e) {
      e.stopPropagation();
    }
    setDetailCert(certification);
    setShowDetail(true);
  };

  const getNextExamDate = (certification: Certification) => {
    const today = new Date();
    const upcomingExam = certification.schedules_2025.find(schedule => {
      const examDate = new Date(schedule.exam_date);
      return examDate >= today;
    });

    if (upcomingExam) {
      const date = new Date(upcomingExam.exam_date);
      const appStart = new Date(upcomingExam.application_start);
      const appEnd = new Date(upcomingExam.application_end);
      const daysLeft = Math.ceil((date.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));

      // 접수 상태 확인
      let applicationStatus: 'before' | 'open' | 'closed' = 'before';
      if (today >= appStart && today <= appEnd) {
        applicationStatus = 'open';
      } else if (today > appEnd) {
        applicationStatus = 'closed';
      }

      return {
        date: date.toLocaleDateString('ko-KR', {
          month: 'long',
          day: 'numeric'
        }),
        fullDate: date,
        daysLeft,
        round: upcomingExam.round,
        examType: upcomingExam.exam_type,
        applicationStart: appStart,
        applicationEnd: appEnd,
        applicationStatus,
        daysUntilApplication: Math.ceil((appStart.getTime() - today.getTime()) / (1000 * 60 * 60 * 24))
      };
    }
    return {
      date: '예정 없음',
      daysLeft: null,
      round: null,
      examType: null,
      applicationStart: null,
      applicationEnd: null,
      applicationStatus: null,
      daysUntilApplication: null
    };
  };

  // 검색 필터링
  const filteredCertifications = useMemo(() => {
    return certifications.filter(cert => {
      const matchesSearch = searchQuery === '' ||
        cert.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        cert.organization.toLowerCase().includes(searchQuery.toLowerCase()) ||
        cert.exam_subjects.some(subject => subject.toLowerCase().includes(searchQuery.toLowerCase()));

      return matchesSearch;
    });
  }, [certifications, searchQuery]);

  return (
    <div>
      {/* Search Bar */}
      <div className="mb-6 p-6 bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="flex gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-5 w-5" />
            <input
              type="text"
              placeholder="자격증 이름, 발급기관, 시험과목으로 검색..."
              className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>

          {/* 공공 API 데이터 가져오기 버튼 */}
          <button
            onClick={syncFromPublicAPI}
            disabled={syncing}
            className={`px-6 py-3 rounded-lg font-medium flex items-center gap-2 transition-all ${
              syncing
                ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                : 'bg-indigo-600 text-white hover:bg-indigo-700 hover:shadow-lg'
            }`}
          >
            {syncing ? (
              <>
                <div className="animate-spin rounded-full h-5 w-5 border-2 border-white border-t-transparent"></div>
                <span>동기화 중...</span>
              </>
            ) : (
              <>
                <Download className="h-5 w-5" />
                <span>공공 API 데이터 가져오기</span>
              </>
            )}
          </button>
        </div>

        {/* Sync Result Alert */}
        {syncResult.type && (
          <div className={`mt-4 p-3 rounded-lg flex items-center gap-2 animate-fadeIn ${
            syncResult.type === 'success'
              ? 'bg-green-100 text-green-800 border border-green-300'
              : 'bg-red-100 text-red-800 border border-red-300'
          }`}>
            {syncResult.type === 'success' ? (
              <CheckCircle className="h-5 w-5 flex-shrink-0" />
            ) : (
              <AlertCircle className="h-5 w-5 flex-shrink-0" />
            )}
            <span className="text-sm font-medium">{syncResult.message}</span>
          </div>
        )}

        {/* Quick Stats */}
        <div className="grid grid-cols-4 gap-4 mt-4">
          <div className="text-center p-3 bg-gray-50 rounded-lg">
            <div className="text-2xl font-bold text-gray-900">{certifications.length}</div>
            <div className="text-xs text-gray-600">전체 자격증</div>
          </div>
          <div className="text-center p-3 bg-indigo-50 rounded-lg">
            <div className="text-2xl font-bold text-indigo-600">{bookmarkedCerts.size}</div>
            <div className="text-xs text-gray-600">관심 자격증</div>
          </div>
          <div className="text-center p-3 bg-green-50 rounded-lg">
            <div className="text-2xl font-bold text-green-600">
              {certifications.filter(c => {
                const nextExam = getNextExamDate(c);
                return nextExam.daysLeft !== null && nextExam.daysLeft <= 30;
              }).length}
            </div>
            <div className="text-xs text-gray-600">접수 임박</div>
          </div>
          <div className="text-center p-3 bg-yellow-50 rounded-lg">
            <div className="text-2xl font-bold text-yellow-600">
              {selectedCertification ? '1' : '0'}
            </div>
            <div className="text-xs text-gray-600">선택됨</div>
          </div>
        </div>
      </div>

      {/* Category Filter */}
      <div className="mb-6 p-4 bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="flex items-center gap-2 mb-3">
          <Filter className="h-4 w-4 text-gray-500" />
          <span className="text-sm font-medium">자격증 분류</span>
        </div>
        <div className="flex flex-wrap gap-2">
          <button
            onClick={() => setSelectedCategory(null)}
            className={`px-4 py-2.5 rounded-lg text-sm font-medium transition-all ${
              selectedCategory === null
                ? 'bg-indigo-600 text-white shadow-lg transform scale-105'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            전체 ({certifications.length})
          </button>
          {(Object.keys(CATEGORY_LABELS) as CertificationCategory[]).map(category => {
            const count = certifications.filter(c => c.category === category).length;
            return (
              <button
                key={category}
                onClick={() => setSelectedCategory(category)}
                className={`px-4 py-2.5 rounded-lg text-sm font-medium transition-all ${
                  selectedCategory === category
                    ? 'bg-indigo-600 text-white shadow-lg transform scale-105'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {CATEGORY_LABELS[category]} ({count})
              </button>
            );
          })}
        </div>
      </div>

      {/* Certification List */}
      <div className="space-y-4">
        {loading ? (
          <div className="flex justify-center items-center py-16 bg-white rounded-xl">
            <div className="text-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
              <p className="mt-4 text-gray-600">자격증 목록을 불러오는 중...</p>
            </div>
          </div>
        ) : filteredCertifications.length === 0 ? (
          <div className="text-center py-16 bg-white rounded-xl">
            <BookOpen className="h-12 w-12 text-gray-400 mx-auto" />
            <p className="mt-4 text-gray-600">
              {searchQuery ? '검색 결과가 없습니다.' : '해당하는 자격증이 없습니다.'}
            </p>
          </div>
        ) : (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-2">
            {filteredCertifications.map(certification => {
              const nextExam = getNextExamDate(certification);
              const isBookmarked = bookmarkedCerts.has(certification.id);
              const isSelected = selectedCertification === certification.id;

              return (
                <div
                  key={certification.id}
                  className={`group bg-white rounded-xl shadow-md hover:shadow-2xl transition-all duration-300 cursor-pointer overflow-hidden transform hover:-translate-y-1 ${
                    isSelected ? 'ring-2 ring-indigo-600 ring-offset-2' : ''
                  }`}
                  onClick={() => handleSelectCertification(certification)}
                >
                  {/* Card Header with Gradient */}
                  <div className={`p-4 bg-gradient-to-r ${
                    isSelected ? 'from-indigo-600 to-purple-600' : 'from-gray-700 to-gray-900'
                  }`}>
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <Award className={`h-5 w-5 ${isSelected ? 'text-yellow-300' : 'text-white'}`} />
                          <h3 className="text-lg font-bold text-white">
                            {certification.name}
                          </h3>
                        </div>
                        {certification.level && (
                          <span className="inline-block mt-1 px-2 py-1 text-xs font-medium bg-white/20 text-white rounded">
                            {LEVEL_LABELS[certification.level]}
                          </span>
                        )}
                      </div>

                      <div className="flex items-start gap-1">
                        {isSelected && (
                          <div className="p-1.5 bg-green-500 rounded-full">
                            <Check className="h-4 w-4 text-white" />
                          </div>
                        )}
                        <button
                          onClick={(e) => toggleBookmark(certification.id, e)}
                          className="p-1.5 hover:bg-white/20 rounded-full transition-colors"
                        >
                          {isBookmarked ? (
                            <Bookmark className="h-4 w-4 text-yellow-400 fill-current" />
                          ) : (
                            <BookmarkPlus className="h-4 w-4 text-white/70" />
                          )}
                        </button>
                      </div>
                    </div>
                  </div>

                  {/* Card Body */}
                  <div className="p-5">
                    {/* Organization */}
                    <div className="flex items-center gap-2 mb-3 text-sm text-gray-600">
                      <Building className="h-4 w-4" />
                      <span>{certification.organization}</span>
                    </div>

                    {/* Category Badge */}
                    <div className="mb-3">
                      <span className={`inline-block px-3 py-1 text-xs font-medium rounded-full border ${
                        CATEGORY_COLORS[certification.category]
                      }`}>
                        {CATEGORY_LABELS[certification.category]}
                      </span>
                    </div>

                    {/* Description */}
                    {certification.description && (
                      <p className="text-sm text-gray-600 mb-3 line-clamp-2">
                        {certification.description}
                      </p>
                    )}

                    {/* Next Exam Date with Detailed Info */}
                    <div className="mb-3 bg-gradient-to-br from-blue-50 to-indigo-50 rounded-lg overflow-hidden border border-blue-200">
                      <div className="px-3 py-2 bg-gradient-to-r from-blue-600 to-indigo-600 text-white">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <Calendar className="h-4 w-4" />
                            <span className="text-sm font-semibold">다음 시험 일정</span>
                          </div>
                          {nextExam.daysLeft !== null && (
                            <span className="text-xs font-bold bg-white/20 px-2 py-0.5 rounded-full">
                              D-{nextExam.daysLeft}
                            </span>
                          )}
                        </div>
                      </div>

                      {nextExam.daysLeft !== null ? (
                        <div className="p-3 space-y-2">
                          {/* 시험 정보 테이블 */}
                          <div className="bg-white rounded-md p-2.5 space-y-2 text-xs">
                            <div className="flex items-center justify-between py-1 border-b border-gray-100">
                              <span className="text-gray-600 font-medium">시험일</span>
                              <span className="font-bold text-gray-900">
                                {nextExam.fullDate?.toLocaleDateString('ko-KR', {
                                  year: 'numeric',
                                  month: 'long',
                                  day: 'numeric',
                                  weekday: 'short'
                                })}
                              </span>
                            </div>

                            <div className="flex items-center justify-between py-1 border-b border-gray-100">
                              <span className="text-gray-600 font-medium">회차/유형</span>
                              <div className="flex items-center gap-2">
                                {nextExam.round && (
                                  <span className="px-1.5 py-0.5 bg-indigo-100 text-indigo-700 rounded text-xs font-medium">
                                    {nextExam.round}회
                                  </span>
                                )}
                                {nextExam.examType && (
                                  <span className="px-1.5 py-0.5 bg-purple-100 text-purple-700 rounded text-xs font-medium">
                                    {nextExam.examType}
                                  </span>
                                )}
                              </div>
                            </div>

                            <div className="flex items-center justify-between py-1">
                              <span className="text-gray-600 font-medium">접수기간</span>
                              <div className="text-right">
                                {nextExam.applicationStart && nextExam.applicationEnd ? (
                                  <div>
                                    <div className="font-medium text-gray-900">
                                      {nextExam.applicationStart.toLocaleDateString('ko-KR', {
                                        month: 'numeric',
                                        day: 'numeric'
                                      })} ~ {nextExam.applicationEnd.toLocaleDateString('ko-KR', {
                                        month: 'numeric',
                                        day: 'numeric'
                                      })}
                                    </div>
                                    {nextExam.applicationStatus === 'open' && (
                                      <span className="inline-block mt-0.5 px-1.5 py-0.5 bg-green-500 text-white rounded text-xs font-bold animate-pulse">
                                        접수중
                                      </span>
                                    )}
                                    {nextExam.applicationStatus === 'before' && nextExam.daysUntilApplication > 0 && (
                                      <span className="inline-block mt-0.5 text-xs text-gray-500">
                                        접수 D-{nextExam.daysUntilApplication}
                                      </span>
                                    )}
                                    {nextExam.applicationStatus === 'closed' && (
                                      <span className="inline-block mt-0.5 px-1.5 py-0.5 bg-gray-400 text-white rounded text-xs">
                                        접수마감
                                      </span>
                                    )}
                                  </div>
                                ) : (
                                  <span className="text-gray-500">-</span>
                                )}
                              </div>
                            </div>
                          </div>

                          {/* 시험까지 남은 기간 시각화 */}
                          {nextExam.daysLeft !== null && (
                            <div className="mt-2">
                              <div className="w-full bg-white rounded-full h-2">
                                <div
                                  className={`h-2 rounded-full transition-all ${
                                    nextExam.applicationStatus === 'open' ? 'bg-gradient-to-r from-green-400 to-green-600 animate-pulse' :
                                    nextExam.daysLeft <= 7 ? 'bg-gradient-to-r from-red-400 to-red-600' :
                                    nextExam.daysLeft <= 30 ? 'bg-gradient-to-r from-yellow-400 to-yellow-600' :
                                    'bg-gradient-to-r from-blue-400 to-blue-600'
                                  }`}
                                  style={{
                                    width: `${Math.max(10, 100 - (nextExam.daysLeft / 90) * 100)}%`
                                  }}
                                />
                              </div>
                            </div>
                          )}
                        </div>
                      ) : (
                        <div className="p-4 text-center text-sm text-gray-500">
                          예정된 시험 일정이 없습니다
                        </div>
                      )}
                    </div>

                    {/* Exam Subjects */}
                    {certification.exam_subjects.length > 0 && (
                      <div className="flex flex-wrap gap-1 mb-3">
                        {certification.exam_subjects.slice(0, 3).map((subject, idx) => (
                          <span
                            key={idx}
                            className="px-2 py-1 text-xs bg-indigo-50 text-indigo-700 rounded"
                          >
                            {subject}
                          </span>
                        ))}
                        {certification.exam_subjects.length > 3 && (
                          <span className="px-2 py-1 text-xs bg-gray-100 text-gray-600 rounded">
                            +{certification.exam_subjects.length - 3}개
                          </span>
                        )}
                      </div>
                    )}

                    {/* Actions */}
                    <div className="flex items-center justify-between pt-3 border-t border-gray-100">
                      <button
                        onClick={(e) => showCertificationDetail(certification, e)}
                        className="text-sm text-indigo-600 hover:text-indigo-700 font-medium flex items-center gap-1"
                      >
                        <Info className="h-4 w-4" />
                        상세정보
                      </button>
                      <ChevronRight className="h-5 w-5 text-gray-400 group-hover:text-indigo-600 transition-colors" />
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Detail Modal */}
      {showDetail && detailCert && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-3xl w-full max-h-[85vh] overflow-hidden">
            {/* Modal Header */}
            <div className="p-6 bg-gradient-to-r from-indigo-600 to-purple-600 text-white">
              <div className="flex justify-between items-start">
                <div>
                  <div className="flex items-center gap-3 mb-2">
                    <Award className="h-6 w-6 text-yellow-300" />
                    <h2 className="text-2xl font-bold">{detailCert.name}</h2>
                  </div>
                  <p className="text-indigo-100">{detailCert.organization}</p>
                </div>
                <button
                  onClick={() => setShowDetail(false)}
                  className="p-2 hover:bg-white/20 rounded-lg transition-colors"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>
            </div>

            {/* Modal Body */}
            <div className="p-6 overflow-y-auto max-h-[calc(85vh-200px)]">
              <div className="space-y-6">
                {/* 기본 정보 */}
                <div>
                  <h3 className="font-bold text-lg mb-3 flex items-center gap-2">
                    <Info className="h-5 w-5 text-indigo-600" />
                    기본 정보
                  </h3>
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <span className="text-gray-600">분류:</span>
                      <span className="ml-2 font-medium">{CATEGORY_LABELS[detailCert.category]}</span>
                    </div>
                    {detailCert.level && (
                      <div>
                        <span className="text-gray-600">등급:</span>
                        <span className="ml-2 font-medium">{LEVEL_LABELS[detailCert.level]}</span>
                      </div>
                    )}
                    {detailCert.exam_fee && (
                      <div>
                        <span className="text-gray-600">응시료:</span>
                        <span className="ml-2 font-medium">
                          필기: {detailCert.exam_fee.written?.toLocaleString()}원
                          {detailCert.exam_fee.practical && ` / 실기: ${detailCert.exam_fee.practical.toLocaleString()}원`}
                        </span>
                      </div>
                    )}
                    {detailCert.passing_criteria && (
                      <div>
                        <span className="text-gray-600">합격기준:</span>
                        <span className="ml-2 font-medium">
                          {detailCert.passing_criteria.written}
                          {detailCert.passing_criteria.practical && ` / ${detailCert.passing_criteria.practical}`}
                        </span>
                      </div>
                    )}
                  </div>
                  {detailCert.description && (
                    <p className="mt-3 text-sm text-gray-600">{detailCert.description}</p>
                  )}
                </div>

                {/* 시험 과목 */}
                {detailCert.exam_subjects.length > 0 && (
                  <div>
                    <h3 className="font-bold text-lg mb-3 flex items-center gap-2">
                      <BookOpen className="h-5 w-5 text-indigo-600" />
                      시험 과목
                    </h3>
                    <div className="flex flex-wrap gap-2">
                      {detailCert.exam_subjects.map((subject, idx) => (
                        <span
                          key={idx}
                          className="px-3 py-1.5 bg-indigo-50 text-indigo-700 rounded-lg text-sm"
                        >
                          {subject}
                        </span>
                      ))}
                    </div>
                  </div>
                )}

                {/* 2025년 시험 일정 */}
                <div>
                  <h3 className="font-bold text-lg mb-3 flex items-center gap-2">
                    <Calendar className="h-5 w-5 text-indigo-600" />
                    2025년 시험 일정
                  </h3>
                  <div className="space-y-3">
                    {detailCert.schedules_2025.map((schedule, idx) => {
                      const examDate = new Date(schedule.exam_date);
                      const appStart = new Date(schedule.application_start);
                      const appEnd = new Date(schedule.application_end);
                      const isUpcoming = examDate >= new Date();

                      return (
                        <div
                          key={idx}
                          className={`p-4 rounded-lg border ${
                            isUpcoming
                              ? 'bg-green-50 border-green-200'
                              : 'bg-gray-50 border-gray-200'
                          }`}
                        >
                          <div className="flex items-center justify-between mb-2">
                            <span className="font-medium text-sm">
                              {schedule.round}
                            </span>
                            {schedule.exam_type && (
                              <span className="px-2 py-1 text-xs bg-white rounded">
                                {schedule.exam_type}
                              </span>
                            )}
                          </div>
                          <div className="space-y-1 text-xs text-gray-600">
                            <div>
                              접수: {appStart.toLocaleDateString('ko-KR')} ~ {appEnd.toLocaleDateString('ko-KR')}
                            </div>
                            <div>
                              시험: {examDate.toLocaleDateString('ko-KR')}
                            </div>
                            {schedule.result_date && (
                              <div>
                                발표: {new Date(schedule.result_date).toLocaleDateString('ko-KR')}
                              </div>
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>

                {/* 관련 통계 */}
                {detailCert.statistics && (
                  <div>
                    <h3 className="font-bold text-lg mb-3 flex items-center gap-2">
                      <TrendingUp className="h-5 w-5 text-indigo-600" />
                      관련 통계
                    </h3>
                    <div className="grid grid-cols-3 gap-4">
                      {detailCert.statistics.pass_rate && (
                        <div className="text-center p-3 bg-blue-50 rounded-lg">
                          <div className="text-2xl font-bold text-blue-600">
                            {detailCert.statistics.pass_rate}%
                          </div>
                          <div className="text-xs text-gray-600">합격률</div>
                        </div>
                      )}
                      {detailCert.statistics.applicants && (
                        <div className="text-center p-3 bg-green-50 rounded-lg">
                          <div className="text-2xl font-bold text-green-600">
                            {detailCert.statistics.applicants.toLocaleString()}
                          </div>
                          <div className="text-xs text-gray-600">연간 응시자</div>
                        </div>
                      )}
                      {detailCert.statistics.popularity_rank && (
                        <div className="text-center p-3 bg-purple-50 rounded-lg">
                          <div className="text-2xl font-bold text-purple-600">
                            {detailCert.statistics.popularity_rank}위
                          </div>
                          <div className="text-xs text-gray-600">인기 순위</div>
                        </div>
                      )}
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Modal Footer */}
            <div className="p-6 bg-gray-50 border-t border-gray-200">
              <div className="flex gap-3">
                <button
                  onClick={() => {
                    handleSelectCertification(detailCert);
                    setShowDetail(false);
                  }}
                  className="flex-1 px-4 py-3 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 font-medium transition-colors"
                >
                  이 자격증으로 학습 시작
                </button>
                <button
                  onClick={() => toggleBookmark(detailCert.id)}
                  className={`px-6 py-3 rounded-lg font-medium transition-colors ${
                    bookmarkedCerts.has(detailCert.id)
                      ? 'bg-yellow-100 text-yellow-700 hover:bg-yellow-200'
                      : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                  }`}
                >
                  {bookmarkedCerts.has(detailCert.id) ? (
                    <>
                      <Bookmark className="inline h-4 w-4 mr-2" />
                      북마크됨
                    </>
                  ) : (
                    <>
                      <BookmarkPlus className="inline h-4 w-4 mr-2" />
                      북마크
                    </>
                  )}
                </button>
                <button
                  onClick={() => setShowDetail(false)}
                  className="px-6 py-3 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 font-medium transition-colors"
                >
                  닫기
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Saving Indicator */}
      {saving && (
        <div className="fixed bottom-4 right-4 bg-gray-800 text-white px-4 py-2 rounded-lg shadow-lg">
          선택 저장 중...
        </div>
      )}
    </div>
  );
}