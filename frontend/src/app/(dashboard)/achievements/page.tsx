'use client';

import { NotionCard, NotionPageHeader, NotionStatCard } from '@/components/ui/NotionCard';
import { Trophy, Award, Star, Target, TrendingUp, Calendar, Medal, Zap } from 'lucide-react';
import { useState } from 'react';

export default function AchievementsPage() {
  const [selectedCategory, setSelectedCategory] = useState('all');

  const achievementStats = {
    totalEarned: 47,
    totalPossible: 150,
    recentlyEarned: 5,
    pointsEarned: 12850,
    currentLevel: 24,
    nextLevelPoints: 1150
  };

  const achievements = [
    {
      id: 1,
      category: 'study',
      title: '첫 걸음',
      description: '첫 문제 풀이 완료',
      icon: '👶',
      earned: true,
      earnedDate: '2024-10-15',
      points: 50,
      rarity: 'common'
    },
    {
      id: 2,
      category: 'study',
      title: '연속 학습 7일',
      description: '7일 연속으로 학습 진행',
      icon: '🔥',
      earned: true,
      earnedDate: '2024-11-20',
      points: 250,
      rarity: 'rare'
    },
    {
      id: 3,
      category: 'mastery',
      title: 'SQL 마스터',
      description: 'SQL 카테고리 90% 이상 달성',
      icon: '🎯',
      earned: true,
      earnedDate: '2024-12-01',
      points: 500,
      rarity: 'epic'
    },
    {
      id: 4,
      category: 'challenge',
      title: '완벽주의자',
      description: '모의고사 100점 달성',
      icon: '💯',
      earned: true,
      earnedDate: '2024-12-05',
      points: 1000,
      rarity: 'legendary'
    },
    {
      id: 5,
      category: 'study',
      title: '1000문제 돌파',
      description: '총 1000문제 풀이 완료',
      icon: '🎊',
      earned: true,
      earnedDate: '2024-11-25',
      points: 750,
      rarity: 'epic'
    },
    {
      id: 6,
      category: 'challenge',
      title: '스피드런',
      description: '30문제를 30분 안에 모두 맞추기',
      icon: '⚡',
      earned: false,
      points: 300,
      rarity: 'rare',
      progress: 75
    },
    {
      id: 7,
      category: 'mastery',
      title: '올라운더',
      description: '모든 카테고리 70% 이상 달성',
      icon: '🌟',
      earned: false,
      points: 2000,
      rarity: 'legendary',
      progress: 60
    },
    {
      id: 8,
      category: 'social',
      title: '지식 공유자',
      description: '다른 사용자 10명 도움',
      icon: '🤝',
      earned: false,
      points: 400,
      rarity: 'rare',
      progress: 30
    }
  ];

  const levels = {
    current: {
      level: 24,
      title: '숙련자',
      totalPoints: 12850,
      badge: '🥈'
    },
    next: {
      level: 25,
      title: '전문가',
      requiredPoints: 14000,
      badge: '🥇'
    }
  };

  const leaderboard = [
    { rank: 1, name: 'CodeMaster', points: 28500, level: 42, badge: '💎' },
    { rank: 2, name: 'StudyKing', points: 25200, level: 38, badge: '🏆' },
    { rank: 3, name: 'AlgoExpert', points: 21800, level: 35, badge: '🥇' },
    { rank: 4, name: 'DBGuru', points: 18900, level: 31, badge: '🥇' },
    { rank: 5, name: '나', points: 12850, level: 24, badge: '🥈', isMe: true },
  ];

  const monthlyChallenge = {
    title: '12월 도전 과제',
    description: '정보처리기사 전 과목 80% 이상 달성',
    reward: 1500,
    participants: 342,
    daysLeft: 22,
    progress: 65
  };

  const filteredAchievements = selectedCategory === 'all'
    ? achievements
    : achievements.filter(a => a.category === selectedCategory);

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="성취도"
        icon="🏆"
        breadcrumbs={[
          { label: '대시보드' },
          { label: '진도' },
          { label: '성취도' }
        ]}
      />

      {/* 통계 카드 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <NotionStatCard
          title="획득 배지"
          value={`${achievementStats.totalEarned}/${achievementStats.totalPossible}`}
          icon={<Trophy className="w-5 h-5 text-yellow-500" />}
        />
        <NotionStatCard
          title="총 포인트"
          value={achievementStats.pointsEarned.toLocaleString()}
          icon={<Star className="w-5 h-5 text-purple-500" />}
          trend={{ value: 250, isUp: true }}
        />
        <NotionStatCard
          title="현재 레벨"
          value={`Lv.${achievementStats.currentLevel}`}
          description={levels.current.title}
          icon={<Award className="w-5 h-5 text-blue-500" />}
        />
        <NotionStatCard
          title="최근 획득"
          value={`${achievementStats.recentlyEarned}개`}
          description="이번 주"
          icon={<Zap className="w-5 h-5 text-green-500" />}
        />
      </div>

      {/* 레벨 진행도 */}
      <NotionCard title="레벨 진행도" icon={<TrendingUp className="w-5 h-5" />}>
        <div className="p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-4">
              <div className="text-4xl">{levels.current.badge}</div>
              <div>
                <h3 className="text-xl font-bold">Level {levels.current.level} - {levels.current.title}</h3>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  다음 레벨까지 {achievementStats.nextLevelPoints}점
                </p>
              </div>
            </div>
            <div className="text-right">
              <div className="text-3xl">{levels.next.badge}</div>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                Lv.{levels.next.level}
              </p>
            </div>
          </div>
          <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-4">
            <div
              className="bg-gradient-to-r from-blue-500 to-purple-600 h-4 rounded-full"
              style={{ width: `${((levels.current.totalPoints - 12000) / (levels.next.requiredPoints - 12000)) * 100}%` }}
            />
          </div>
          <div className="flex justify-between mt-2 text-sm text-gray-600 dark:text-gray-400">
            <span>12,000</span>
            <span className="font-medium">{levels.current.totalPoints.toLocaleString()}</span>
            <span>14,000</span>
          </div>
        </div>
      </NotionCard>

      {/* 배지 컬렉션 */}
      <NotionCard title="배지 컬렉션" icon={<Medal className="w-5 h-5" />}>
        <div className="p-6">
          <div className="flex gap-2 mb-6">
            <button
              onClick={() => setSelectedCategory('all')}
              className={`px-3 py-1 rounded ${
                selectedCategory === 'all'
                  ? 'bg-purple-500 text-white'
                  : 'bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600'
              }`}
            >
              전체
            </button>
            <button
              onClick={() => setSelectedCategory('study')}
              className={`px-3 py-1 rounded ${
                selectedCategory === 'study'
                  ? 'bg-purple-500 text-white'
                  : 'bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600'
              }`}
            >
              학습
            </button>
            <button
              onClick={() => setSelectedCategory('mastery')}
              className={`px-3 py-1 rounded ${
                selectedCategory === 'mastery'
                  ? 'bg-purple-500 text-white'
                  : 'bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600'
              }`}
            >
              마스터리
            </button>
            <button
              onClick={() => setSelectedCategory('challenge')}
              className={`px-3 py-1 rounded ${
                selectedCategory === 'challenge'
                  ? 'bg-purple-500 text-white'
                  : 'bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600'
              }`}
            >
              도전
            </button>
          </div>

          <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
            {filteredAchievements.map(achievement => (
              <div
                key={achievement.id}
                className={`relative p-4 rounded-lg border-2 text-center transition-all ${
                  achievement.earned
                    ? 'border-yellow-400 bg-yellow-50 dark:bg-yellow-900/20'
                    : 'border-gray-300 dark:border-gray-600 bg-gray-100 dark:bg-gray-800 opacity-75'
                }`}
              >
                <div className="text-3xl mb-2">{achievement.icon}</div>
                <h4 className="text-sm font-medium mb-1">{achievement.title}</h4>
                <p className="text-xs text-gray-600 dark:text-gray-400 mb-2">
                  {achievement.description}
                </p>
                <div className="text-xs font-bold">
                  +{achievement.points}점
                </div>
                {achievement.earned && achievement.earnedDate && (
                  <p className="text-xs text-gray-500 mt-1">
                    {achievement.earnedDate}
                  </p>
                )}
                {!achievement.earned && achievement.progress && (
                  <div className="mt-2">
                    <div className="w-full bg-gray-300 dark:bg-gray-700 rounded-full h-1.5">
                      <div
                        className="bg-purple-500 h-1.5 rounded-full"
                        style={{ width: `${achievement.progress}%` }}
                      />
                    </div>
                    <p className="text-xs mt-1">{achievement.progress}%</p>
                  </div>
                )}
                {/* 희귀도 표시 */}
                <div className={`absolute top-2 right-2 text-xs px-1.5 py-0.5 rounded ${
                  achievement.rarity === 'legendary'
                    ? 'bg-gradient-to-r from-purple-500 to-pink-500 text-white'
                    : achievement.rarity === 'epic'
                    ? 'bg-purple-500 text-white'
                    : achievement.rarity === 'rare'
                    ? 'bg-blue-500 text-white'
                    : 'bg-gray-500 text-white'
                }`}>
                  {achievement.rarity === 'legendary' ? '전설' :
                   achievement.rarity === 'epic' ? '영웅' :
                   achievement.rarity === 'rare' ? '희귀' : '일반'}
                </div>
              </div>
            ))}
          </div>
        </div>
      </NotionCard>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 월간 도전 과제 */}
        <NotionCard title="월간 도전 과제" icon={<Target className="w-5 h-5" />}>
          <div className="p-6">
            <div className="p-4 bg-gradient-to-r from-orange-500 to-red-500 rounded-lg text-white">
              <div className="flex items-center justify-between mb-3">
                <h3 className="text-lg font-bold">{monthlyChallenge.title}</h3>
                <div className="text-right">
                  <p className="text-2xl font-bold">+{monthlyChallenge.reward}</p>
                  <p className="text-xs">포인트</p>
                </div>
              </div>
              <p className="text-sm mb-3">{monthlyChallenge.description}</p>
              <div className="flex items-center justify-between text-sm mb-3">
                <span>참가자: {monthlyChallenge.participants}명</span>
                <span>남은 기간: {monthlyChallenge.daysLeft}일</span>
              </div>
              <div className="w-full bg-white/30 rounded-full h-3 mb-2">
                <div
                  className="bg-white h-3 rounded-full"
                  style={{ width: `${monthlyChallenge.progress}%` }}
                />
              </div>
              <div className="text-center text-sm">
                현재 진행률: {monthlyChallenge.progress}%
              </div>
            </div>

            <div className="mt-4 space-y-2">
              <h4 className="font-medium">이번 주 도전 과제</h4>
              <div className="space-y-2">
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded" defaultChecked />
                  <span className="text-sm">데이터베이스 50문제 풀기</span>
                </label>
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded" />
                  <span className="text-sm">3일 연속 학습</span>
                </label>
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded" />
                  <span className="text-sm">모의고사 70점 이상</span>
                </label>
              </div>
            </div>
          </div>
        </NotionCard>

        {/* 리더보드 */}
        <NotionCard title="리더보드" icon={<Trophy className="w-5 h-5" />}>
          <div className="p-6">
            <div className="space-y-3">
              {leaderboard.map((user) => (
                <div
                  key={user.rank}
                  className={`flex items-center justify-between p-3 rounded-lg ${
                    user.isMe
                      ? 'bg-blue-50 dark:bg-blue-900/20 border-2 border-blue-500'
                      : 'bg-gray-50 dark:bg-gray-800'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <div className={`text-lg font-bold ${
                      user.rank === 1 ? 'text-yellow-500' :
                      user.rank === 2 ? 'text-gray-400' :
                      user.rank === 3 ? 'text-orange-600' :
                      'text-gray-600 dark:text-gray-400'
                    }`}>
                      #{user.rank}
                    </div>
                    <div className="text-2xl">{user.badge}</div>
                    <div>
                      <p className="font-medium">
                        {user.name}
                        {user.isMe && <span className="ml-2 text-xs text-blue-500">(나)</span>}
                      </p>
                      <p className="text-xs text-gray-600 dark:text-gray-400">
                        Lv.{user.level}
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="font-bold">{user.points.toLocaleString()}</p>
                    <p className="text-xs text-gray-600 dark:text-gray-400">포인트</p>
                  </div>
                </div>
              ))}
            </div>
            <button className="mt-4 w-full px-4 py-2 bg-purple-500 text-white rounded-lg hover:bg-purple-600">
              전체 순위 보기
            </button>
          </div>
        </NotionCard>
      </div>

      {/* 활동 타임라인 */}
      <NotionCard title="최근 획득 기록" icon={<Calendar className="w-5 h-5" />}>
        <div className="p-6">
          <div className="space-y-4">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 bg-yellow-100 dark:bg-yellow-900/20 rounded-full flex items-center justify-center text-xl">
                💯
              </div>
              <div className="flex-1">
                <h4 className="font-medium">완벽주의자 배지 획득</h4>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  모의고사에서 100점을 달성했습니다!
                </p>
                <p className="text-xs text-gray-500 mt-1">2024-12-05</p>
              </div>
              <div className="text-right">
                <p className="font-bold text-green-600 dark:text-green-400">+1000</p>
              </div>
            </div>

            <div className="flex items-start gap-3">
              <div className="w-10 h-10 bg-blue-100 dark:bg-blue-900/20 rounded-full flex items-center justify-center text-xl">
                🎯
              </div>
              <div className="flex-1">
                <h4 className="font-medium">SQL 마스터 달성</h4>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  SQL 카테고리 90% 이상 달성
                </p>
                <p className="text-xs text-gray-500 mt-1">2024-12-01</p>
              </div>
              <div className="text-right">
                <p className="font-bold text-green-600 dark:text-green-400">+500</p>
              </div>
            </div>

            <div className="flex items-start gap-3">
              <div className="w-10 h-10 bg-green-100 dark:bg-green-900/20 rounded-full flex items-center justify-center text-xl">
                🎊
              </div>
              <div className="flex-1">
                <h4 className="font-medium">1000문제 돌파</h4>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  누적 1000문제 풀이를 달성했습니다!
                </p>
                <p className="text-xs text-gray-500 mt-1">2024-11-25</p>
              </div>
              <div className="text-right">
                <p className="font-bold text-green-600 dark:text-green-400">+750</p>
              </div>
            </div>
          </div>
        </div>
      </NotionCard>
    </div>
  );
}