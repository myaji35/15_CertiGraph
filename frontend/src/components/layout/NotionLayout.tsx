'use client';

import React, { useState, useCallback, useMemo } from 'react';
import { ChevronRight, ChevronDown, Search, Settings, Plus, Book, BookOpen, Brain, Target, Award, Calendar, Home, Menu, X, Moon, Sun } from 'lucide-react';
import { usePathname, useRouter } from 'next/navigation';
import { cn } from '@/lib/utils';

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
          path: '/study-sets',
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
          path: '/knowledge-graph',
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
          "flex flex-col border-r border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 transition-all duration-300",
          sidebarCollapsed ? "w-0 overflow-hidden" : "w-60"
        )}
      >
        {/* Sidebar Header */}
        <div className="flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-800">
          <div className="flex items-center gap-2">
            <Brain className="w-5 h-5 text-blue-500" />
            <span className="font-semibold text-gray-900 dark:text-gray-100">ExamsGraph</span>
          </div>
          <button
            onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
            className="p-1 hover:bg-gray-200 dark:hover:bg-gray-700 rounded transition-colors"
          >
            <Menu className="w-4 h-4 text-gray-500" />
          </button>
        </div>

        {/* Search */}
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

        {/* Navigation */}
        <div className="flex-1 overflow-y-auto px-3 py-2">
          <NavigationTree items={navigationItems} />
        </div>

        {/* Sidebar Footer */}
        <div className="p-3 border-t border-gray-200 dark:border-gray-800">
          <div className="flex items-center justify-between">
            <button className="flex items-center gap-2 px-2 py-1.5 text-sm text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 rounded transition-colors">
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
        </div>
      </div>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Top Bar */}
        <div className="flex items-center justify-between px-6 py-3 border-b border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
          {sidebarCollapsed && (
            <button
              onClick={() => setSidebarCollapsed(false)}
              className="p-1.5 hover:bg-gray-100 dark:hover:bg-gray-800 rounded transition-colors mr-4"
            >
              <Menu className="w-5 h-5 text-gray-500" />
            </button>
          )}
          <div className="flex items-center gap-2 text-sm text-gray-500">
            <span>학습 관리</span>
            <ChevronRight className="w-3 h-3" />
            <span className="text-gray-900 dark:text-gray-100">대시보드</span>
          </div>
          <button className="flex items-center gap-1.5 px-3 py-1.5 text-sm bg-blue-500 text-white rounded-md hover:bg-blue-600 transition-colors whitespace-nowrap">
            <Plus className="w-3.5 h-3.5 flex-shrink-0" />
            <span>새 문제집</span>
          </button>
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