'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@clerk/nextjs';
import {
  NotionCard,
  NotionPageHeader,
  NotionStatCard,
} from '@/components/ui/NotionCard';
import {
  FileText,
  Play,
  Clock,
  Trophy,
  Calendar,
  ChevronRight,
  AlertTriangle,
  CheckCircle,
  XCircle,
} from 'lucide-react';

interface PastExam {
  exam_year: number;
  exam_round: number;
  exam_name: string;
  total_questions: number;
  available_sessions: number[];
  tags: string[];
  created_at: string;
}

interface ExamStats {
  totalExams: number;
  avgScore: number;
  passRate: number;
  lastExamDate: string | null;
}

export default function MockExamPage() {
  const { getToken, isLoaded, isSignedIn } = useAuth();
  const router = useRouter();
  const [pastExams, setPastExams] = useState<PastExam[]>([]);
  const [stats, setStats] = useState<ExamStats>({
    totalExams: 0,
    avgScore: 0,
    passRate: 0,
    lastExamDate: null,
  });
  const [loading, setLoading] = useState(true);
  const [selectedExam, setSelectedExam] = useState<PastExam | null>(null);
  const [selectedMode, setSelectedMode] = useState<'mock_full' | 'mock_session' | 'past_exam'>('mock_full');
  const [selectedSession, setSelectedSession] = useState<number | null>(null);
  const [showStartModal, setShowStartModal] = useState(false);

  useEffect(() => {
    if (isLoaded && isSignedIn) {
      fetchData();
    }
  }, [isLoaded, isSignedIn]);

  const fetchData = async () => {
    try {
      setLoading(true);
      const token = await getToken();

      // 기출문제 목록 가져오기
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/mock-exam/past-exams`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (response.ok) {
        const data = await response.json();
        setPastExams(data.data.exams || []);

        // 통계 계산 (임시)
        setStats({
          totalExams: data.data.total || 0,
          avgScore: 75,
          passRate: 68,
          lastExamDate: data.data.exams?.[0]?.created_at || null,
        });
      }
    } catch (error) {
      console.error('데이터 로딩 실패:', error);
    } finally {
      setLoading(false);
    }
  };

  const startMockExam = async () => {
    try {
      const token = await getToken();

      const requestBody: any = {
        mode: selectedMode,
        time_limit_enabled: true,
      };

      if (selectedMode === 'past_exam' && selectedExam) {
        requestBody.exam_year = selectedExam.exam_year;
        requestBody.exam_round = selectedExam.exam_round;
      }

      if (selectedSession) {
        requestBody.session_number = `session_${selectedSession}`;
      }

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/mock-exam/start`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(requestBody),
        }
      );

      if (response.ok) {
        const data = await response.json();
        // 시험 페이지로 이동
        router.push(`/dashboard/mock-exam/session/${data.data.exam_id}`);
      } else {
        alert('모의고사 시작에 실패했습니다.');
      }
    } catch (error) {
      console.error('모의고사 시작 실패:', error);
      alert('오류가 발생했습니다.');
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('ko-KR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="실전모의고사"
        icon="🎯"
        breadcrumbs={[{ label: '홈' }, { label: '실전모의고사' }]}
        actions={
          <button
            onClick={() => setShowStartModal(true)}
            className="flex items-center gap-2 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
          >
            <Play className="w-4 h-4" />
            <span>모의고사 시작</span>
          </button>
        }
      />

      {/* 통계 카드 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <NotionStatCard
          title="기출문제"
          value={loading ? '-' : `${stats.totalExams}개`}
          icon={<FileText className="w-5 h-5 text-blue-500" />}
          description="사용 가능한 기출문제"
        />
        <NotionStatCard
          title="평균 점수"
          value={loading ? '-' : `${stats.avgScore}점`}
          icon={<Trophy className="w-5 h-5 text-yellow-500" />}
          trend={{ value: 5, isUp: true }}
        />
        <NotionStatCard
          title="예상 합격률"
          value={loading ? '-' : `${stats.passRate}%`}
          icon={<CheckCircle className="w-5 h-5 text-green-500" />}
          description="과락 기준 적용"
        />
        <NotionStatCard
          title="최근 응시"
          value={stats.lastExamDate ? formatDate(stats.lastExamDate) : '없음'}
          icon={<Calendar className="w-5 h-5 text-purple-500" />}
        />
      </div>

      {/* 시험 모드 선택 */}
      <NotionCard title="시험 모드 선택" icon={<FileText className="w-5 h-5" />}>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 p-4">
          <button
            onClick={() => {
              setSelectedMode('mock_full');
              setShowStartModal(true);
            }}
            className="p-6 border-2 border-gray-200 dark:border-gray-700 rounded-xl hover:border-blue-500 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-all group"
          >
            <div className="text-3xl mb-3">📝</div>
            <h3 className="font-semibold text-lg mb-2">실전 모의고사</h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              3교시 전체 · 180분
            </p>
            <p className="text-xs text-gray-500 dark:text-gray-500 mt-2">
              실제 시험과 동일한 환경
            </p>
          </button>

          <button
            onClick={() => {
              setSelectedMode('mock_session');
              setShowStartModal(true);
            }}
            className="p-6 border-2 border-gray-200 dark:border-gray-700 rounded-xl hover:border-purple-500 hover:bg-purple-50 dark:hover:bg-purple-900/20 transition-all group"
          >
            <div className="text-3xl mb-3">⏱️</div>
            <h3 className="font-semibold text-lg mb-2">교시별 응시</h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              선택 교시 · 60분
            </p>
            <p className="text-xs text-gray-500 dark:text-gray-500 mt-2">
              원하는 교시만 연습
            </p>
          </button>

          <button
            onClick={() => {
              setSelectedMode('past_exam');
              setShowStartModal(true);
            }}
            className="p-6 border-2 border-gray-200 dark:border-gray-700 rounded-xl hover:border-green-500 hover:bg-green-50 dark:hover:bg-green-900/20 transition-all group"
          >
            <div className="text-3xl mb-3">📚</div>
            <h3 className="font-semibold text-lg mb-2">기출문제</h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              연도별 · 회차별
            </p>
            <p className="text-xs text-gray-500 dark:text-gray-500 mt-2">
              과거 실제 시험 문제
            </p>
          </button>
        </div>
      </NotionCard>

      {/* 기출문제 목록 */}
      <NotionCard title="업로드된 문제 목록" icon={<Calendar className="w-5 h-5" />}>
        <div className="p-4">
          {loading ? (
            <div className="text-center py-8 text-gray-500">로딩 중...</div>
          ) : pastExams.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              아직 업로드된 문제가 없습니다.
              <br />
              <span className="text-sm">PDF를 업로드하여 문제를 추가하세요.</span>
            </div>
          ) : (
            <div className="space-y-3">
              {pastExams.map((exam) => (
                <div
                  key={`${exam.exam_year}-${exam.exam_round}`}
                  className="p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors cursor-pointer group"
                  onClick={() => {
                    setSelectedExam(exam);
                    setSelectedMode('past_exam');
                    setShowStartModal(true);
                  }}
                >
                  <div className="flex items-center justify-between">
                    <div>
                      <h4 className="font-medium text-gray-900 dark:text-gray-100 group-hover:text-blue-600 dark:group-hover:text-blue-400">
                        {exam.exam_name}
                      </h4>
                      <div className="flex items-center gap-3 mt-1 text-sm text-gray-600 dark:text-gray-400">
                        <span>{exam.exam_year}년</span>
                        <span>•</span>
                        <span>{exam.total_questions}문제</span>
                        <span>•</span>
                        <span>
                          {exam.available_sessions.length === 3
                            ? '전체 교시'
                            : `${exam.available_sessions.join(', ')}교시`}
                        </span>
                      </div>
                      {exam.tags && exam.tags.length > 0 && (
                        <div className="flex gap-2 mt-2">
                          {exam.tags.map((tag) => (
                            <span
                              key={tag}
                              className="px-2 py-1 text-xs bg-gray-100 dark:bg-gray-700 rounded-full"
                            >
                              {tag}
                            </span>
                          ))}
                        </div>
                      )}
                    </div>
                    <ChevronRight className="w-5 h-5 text-gray-400 group-hover:text-blue-600 dark:group-hover:text-blue-400" />
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </NotionCard>

      {/* 과락 시스템 안내 */}
      <NotionCard title="과락 시스템 안내" icon={<AlertTriangle className="w-5 h-5 text-yellow-500" />}>
        <div className="p-4 space-y-3">
          <div className="flex items-start gap-3">
            <XCircle className="w-5 h-5 text-red-500 mt-0.5" />
            <div>
              <p className="font-medium">과락 기준</p>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                각 교시별 40점 미만 시 과락 처리됩니다.
              </p>
            </div>
          </div>
          <div className="flex items-start gap-3">
            <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
            <div>
              <p className="font-medium">합격 기준</p>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                전 교시 평균 60점 이상 및 과락 과목이 없어야 합니다.
              </p>
            </div>
          </div>
          <div className="flex items-start gap-3">
            <Clock className="w-5 h-5 text-blue-500 mt-0.5" />
            <div>
              <p className="font-medium">시간 제한</p>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                각 교시당 60분, 시간 초과 시 자동 제출됩니다.
              </p>
            </div>
          </div>
        </div>
      </NotionCard>

      {/* 시작 모달 */}
      {showStartModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 p-4">
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-xl w-full max-w-md">
            <div className="p-6">
              <h2 className="text-xl font-semibold mb-4">모의고사 시작</h2>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium mb-2">시험 모드</label>
                  <div className="p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                    {selectedMode === 'mock_full' && '실전 모의고사 (3교시 전체)'}
                    {selectedMode === 'mock_session' && '교시별 응시'}
                    {selectedMode === 'past_exam' && selectedExam?.exam_name}
                  </div>
                </div>

                {selectedMode === 'mock_session' && (
                  <div>
                    <label className="block text-sm font-medium mb-2">교시 선택</label>
                    <div className="grid grid-cols-3 gap-2">
                      {[1, 2, 3].map((session) => (
                        <button
                          key={session}
                          onClick={() => setSelectedSession(session)}
                          className={`p-2 border rounded-lg transition-colors ${
                            selectedSession === session
                              ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                              : 'border-gray-200 dark:border-gray-700'
                          }`}
                        >
                          {session}교시
                        </button>
                      ))}
                    </div>
                  </div>
                )}

                {selectedMode === 'past_exam' && selectedExam && (
                  <div>
                    <label className="block text-sm font-medium mb-2">응시 방식</label>
                    <div className="space-y-2">
                      <button
                        onClick={() => setSelectedSession(null)}
                        className={`w-full p-2 border rounded-lg text-left transition-colors ${
                          selectedSession === null
                            ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                            : 'border-gray-200 dark:border-gray-700'
                        }`}
                      >
                        전체 교시 (3교시 연속)
                      </button>
                      {selectedExam.available_sessions.map((session) => (
                        <button
                          key={session}
                          onClick={() => setSelectedSession(session)}
                          className={`w-full p-2 border rounded-lg text-left transition-colors ${
                            selectedSession === session
                              ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                              : 'border-gray-200 dark:border-gray-700'
                          }`}
                        >
                          {session}교시만 응시
                        </button>
                      ))}
                    </div>
                  </div>
                )}

                <div className="p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
                  <p className="text-sm text-yellow-800 dark:text-yellow-200">
                    ⚠️ 시험 시작 후에는 중간에 나갈 수 없습니다.
                  </p>
                </div>
              </div>

              <div className="flex gap-3 mt-6">
                <button
                  onClick={() => setShowStartModal(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                >
                  취소
                </button>
                <button
                  onClick={startMockExam}
                  className="flex-1 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
                >
                  시작하기
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}