'use client';

import React, { useState, useCallback, useMemo } from 'react';
import { ChevronRight, ChevronDown, Search, Settings, Plus, Book, BookOpen, Brain, Target, Award, Calendar, Home, Menu, X, Moon, Sun, LogOut, User } from 'lucide-react';
import { usePathname, useRouter } from 'next/navigation';
import { useUser, useClerk } from '@clerk/nextjs';
import { cn } from '@/lib/utils';
import SettingsModal from '@/components/modals/SettingsModal';

interface NavigationItem {
  id: string;
  title: string;
  icon?: React.ReactNode;
  path?: string;
  children?: NavigationItem[];
  expanded?: boolean;
}

interface NotionLayoutProps {
  children: React.ReactNode;
}

export default function NotionLayout({ children }: NotionLayoutProps) {
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [darkMode, setDarkMode] = useState(false);
  const [showSettingsModal, setShowSettingsModal] = useState(false);
  const { user } = useUser();
  const { signOut } = useClerk();
  const [navigationItems, setNavigationItems] = useState<NavigationItem[]>([
    {
      id: 'home',
      title: '홈',
      icon: <Home className="w-4 h-4" />,
      path: '/dashboard',
    },
    {
      id: 'learning',
      title: '학습',
      icon: <Book className="w-4 h-4" />,
      expanded: true,
      children: [
        {
          id: 'study-sets',
          title: '문제집',
          icon: <Book className="w-4 h-4" />,
          path: '/dashboard/study-sets',
        },
        {
          id: 'study-materials',
          title: '학습 자료',
          icon: <BookOpen className="w-4 h-4" />,
          path: '/study-materials',
        },
        {
          id: 'knowledge-graph',
          title: '지식 그래프',
          icon: <Brain className="w-4 h-4" />,
          path: '/dashboard/knowledge-graph',
        },
        {
          id: 'test-dashboard',
          title: '실전 모의고사',
          icon: <Target className="w-4 h-4" />,
          path: '/dashboard/test',
        },
        {
          id: 'weak-points',
          title: '취약점 분석',
          icon: <Target className="w-4 h-4" />,
          path: '/weak-points',
        },
      ],
    },
    {
      id: 'progress',
      title: '진도',
      icon: <Award className="w-4 h-4" />,
      expanded: false,
      children: [
        {
          id: 'achievements',
          title: '성취도',
          path: '/achievements',
        },
        {
          id: 'statistics',
          title: '통계',
          path: '/statistics',
        },
      ],
    },
    {
      id: 'certifications',
      title: '자격증',
      icon: <Award className="w-4 h-4" />,
      expanded: true,
      children: [
        {
          id: 'exam-schedule',
          title: '시험 일정',
          icon: <Calendar className="w-4 h-4" />,
          path: '/certifications',
        },
        {
          id: 'cert-search',
          title: '자격증 검색',
          icon: <Search className="w-4 h-4" />,
          path: '/certifications/search',
        },
      ],
    },
  ]);

  const pathname = usePathname();
  const router = useRouter();

  const toggleExpand = useCallback((itemId: string) => {
    setNavigationItems(prev =>
      prev.map(item => {
        if (item.id === itemId) {
          return { ...item, expanded: !item.expanded };
        }
        if (item.children) {
          return {
            ...item,
            children: item.children.map(child =>
              child.id === itemId ? { ...child, expanded: !child.expanded } : child
            ),
          };
        }
        return item;
      })
    );
  }, []);

  const NavigationTree = ({ items, level = 0 }: { items: NavigationItem[]; level?: number }) => {
    return (
      <div className="space-y-0.5">
        {items.map(item => (
          <div key={item.id}>
            <div
              className={cn(
                "flex items-center gap-2 px-2 py-1.5 rounded-md cursor-pointer transition-all duration-200",
                "hover:bg-gray-100 dark:hover:bg-gray-800",
                pathname === item.path && "bg-gray-100 dark:bg-gray-800",
                level > 0 && "ml-6"
              )}
              onClick={() => {
                if (item.path) {
                  router.push(item.path);
                } else if (item.children) {
                  toggleExpand(item.id);
                }
              }}
            >
              <div className="flex items-center gap-1">
                {item.children && (
                  <div
                    className="p-0.5 hover:bg-gray-200 dark:hover:bg-gray-700 rounded transition-colors"
                    onClick={(e) => {
                      e.stopPropagation();
                      toggleExpand(item.id);
                    }}
                  >
                    {item.expanded ? (
                      <ChevronDown className="w-3 h-3 text-gray-500" />
                    ) : (
                      <ChevronRight className="w-3 h-3 text-gray-500" />
                    )}
                  </div>
                )}
                {item.icon && (
                  <span className="text-gray-500 dark:text-gray-400">{item.icon}</span>
                )}
              </div>
              <span className="text-sm text-gray-700 dark:text-gray-300 flex-1">{item.title}</span>
            </div>
            {item.children && item.expanded && (
              <NavigationTree items={item.children} level={level + 1} />
            )}
          </div>
        ))}
      </div>
    );
  };

  return (
    <div className={cn("flex h-screen bg-white dark:bg-gray-900", darkMode && "dark")}>
      {/* Sidebar */}
      <div
        className={cn(
          "flex flex-col border-r border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 transition-all duration-300 relative",
          sidebarCollapsed ? "w-16" : "w-60"
        )}
      >
        {/* Sidebar Header */}
        <div className="flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-800">
          {!sidebarCollapsed && (
            <div className="flex items-center gap-2">
              <Brain className="w-5 h-5 text-blue-500" />
              <span className="font-semibold text-gray-900 dark:text-gray-100">ExamsGraph</span>
            </div>
          )}
          <button
            onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
            className={cn(
              "p-1 hover:bg-gray-200 dark:hover:bg-gray-700 rounded transition-colors",
              sidebarCollapsed && "mx-auto"
            )}
            title={sidebarCollapsed ? "사이드바 펼치기" : "사이드바 접기"}
          >
            <Menu className="w-4 h-4 text-gray-500" />
          </button>
        </div>

        {/* Search */}
        {!sidebarCollapsed && (
          <div className="p-3">
            <div className="relative">
              <Search className="absolute left-2 top-2 w-4 h-4 text-gray-400" />
              <input
                type="text"
                placeholder="빠른 검색..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-8 pr-3 py-1.5 text-sm border border-gray-200 dark:border-gray-700 rounded-md bg-white dark:bg-gray-800 focus:outline-none focus:ring-1 focus:ring-blue-500"
              />
            </div>
          </div>
        )}

        {/* Navigation */}
        <div className={cn("flex-1 px-3 py-2", !sidebarCollapsed && "overflow-y-auto")}>
          {sidebarCollapsed ? (
            // 축소 시 최상위 아이콘만 표시
            <div className="space-y-2">
              {navigationItems.map((item) => {
                // 하위 메뉴가 있는 경우, 클릭 시 사이드바 확장
                const handleClick = () => {
                  if (item.path) {
                    router.push(item.path);
                  } else if (item.children) {
                    setSidebarCollapsed(false);
                  }
                };

                // 현재 경로가 이 항목 또는 하위 항목과 일치하는지 확인
                const isActive = item.path === pathname ||
                  (item.children?.some(child => child.path === pathname));

                return (
                  <div key={item.id} className="relative group">
                    <button
                      onClick={handleClick}
                      className={cn(
                        "w-full p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors flex items-center justify-center",
                        isActive && "bg-gray-100 dark:bg-gray-800"
                      )}
                    >
                      {item.icon}
                    </button>
                    {/* 툴팁 */}
                    <div className="absolute left-full ml-2 px-2 py-1 bg-gray-900 dark:bg-gray-700 text-white text-xs rounded whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-50">
                      {item.title}
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <NavigationTree items={navigationItems} />
          )}
        </div>

        {/* Sidebar Footer */}
        <div className="p-3 border-t border-gray-200 dark:border-gray-800 space-y-2">
          {sidebarCollapsed ? (
            // 축소 시: 아이콘만 표시
            <div className="space-y-2">
              {user && (
                <div className="relative group">
                  <button
                    onClick={() => signOut()}
                    className="w-full p-2 hover:bg-red-50 dark:hover:bg-red-900/20 rounded transition-colors flex items-center justify-center"
                  >
                    <LogOut className="w-4 h-4 text-gray-500 group-hover:text-red-600 dark:group-hover:text-red-400" />
                  </button>
                  {/* 툴팁 */}
                  <div className="absolute left-full ml-2 px-2 py-1 bg-gray-900 dark:bg-gray-700 text-white text-xs rounded whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-50">
                    로그아웃
                  </div>
                </div>
              )}
              <div className="relative group">
                <button
                  onClick={() => setShowSettingsModal(true)}
                  className="w-full p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded transition-colors flex items-center justify-center"
                >
                  <Settings className="w-4 h-4 text-gray-600 dark:text-gray-400" />
                </button>
                {/* 툴팁 */}
                <div className="absolute left-full ml-2 px-2 py-1 bg-gray-900 dark:bg-gray-700 text-white text-xs rounded whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-50">
                  설정
                </div>
              </div>
              <div className="relative group">
                <button
                  onClick={() => setDarkMode(!darkMode)}
                  className="w-full p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded transition-colors flex items-center justify-center"
                >
                  {darkMode ? (
                    <Sun className="w-4 h-4 text-gray-500" />
                  ) : (
                    <Moon className="w-4 h-4 text-gray-500" />
                  )}
                </button>
                {/* 툴팁 */}
                <div className="absolute left-full ml-2 px-2 py-1 bg-gray-900 dark:bg-gray-700 text-white text-xs rounded whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-50">
                  {darkMode ? "라이트 모드" : "다크 모드"}
                </div>
              </div>
            </div>
          ) : (
            // 확장 시: 전체 정보 표시
            <>
              {/* User Info & Logout */}
              {user && (
                <div className="flex items-center justify-between gap-2 px-2 py-2 bg-gray-100 dark:bg-gray-800 rounded-md">
                  <div className="flex items-center gap-2 min-w-0 flex-1">
                    <div className="flex-shrink-0 w-7 h-7 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                      <User className="w-4 h-4 text-white" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium text-gray-900 dark:text-gray-100 truncate">
                        {user.firstName || user.username || '사용자'}
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-400 truncate">
                        {user.primaryEmailAddress?.emailAddress}
                      </p>
                    </div>
                  </div>
                  <button
                    onClick={() => signOut()}
                    className="flex-shrink-0 p-1.5 hover:bg-red-50 dark:hover:bg-red-900/20 rounded transition-colors group"
                    title="로그아웃"
                  >
                    <LogOut className="w-4 h-4 text-gray-500 group-hover:text-red-600 dark:group-hover:text-red-400" />
                  </button>
                </div>
              )}

              {/* Settings & Dark Mode */}
              <div className="flex items-center justify-between">
                <button
                  onClick={() => setShowSettingsModal(true)}
                  className="flex items-center gap-2 px-2 py-1.5 text-sm text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 rounded transition-colors"
                >
                  <Settings className="w-4 h-4" />
                  <span>설정</span>
                </button>
                <button
                  onClick={() => setDarkMode(!darkMode)}
                  className="p-1.5 hover:bg-gray-100 dark:hover:bg-gray-800 rounded transition-colors"
                >
                  {darkMode ? (
                    <Sun className="w-4 h-4 text-gray-500" />
                  ) : (
                    <Moon className="w-4 h-4 text-gray-500" />
                  )}
                </button>
              </div>
            </>
          )}
        </div>
      </div>

      {/* Settings Modal */}
      <SettingsModal
        isOpen={showSettingsModal}
        onClose={() => setShowSettingsModal(false)}
        darkMode={darkMode}
        setDarkMode={setDarkMode}
      />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Top Bar */}
        <div className="flex items-center justify-between px-6 py-3 border-b border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
          <div className="flex items-center gap-2 text-sm text-gray-500">
            <span>학습 관리</span>
            <ChevronRight className="w-3 h-3" />
            <span className="text-gray-900 dark:text-gray-100">대시보드</span>
          </div>
        </div>

        {/* Page Content */}
        <div className="flex-1 overflow-auto bg-white dark:bg-gray-900">
          <div className="max-w-7xl mx-auto p-6">
            {children}
          </div>
        </div>
      </div>
    </div>
  );
}