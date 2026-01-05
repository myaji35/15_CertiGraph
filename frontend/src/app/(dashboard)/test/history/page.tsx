'use client';

import { BarChart3 } from 'lucide-react';

export default function TestHistoryPage() {
  return (
    <div className="max-w-5xl mx-auto px-6 py-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center gap-3 mb-4">
          <div className="p-3 bg-green-100 dark:bg-green-900/20 rounded-lg">
            <BarChart3 className="w-6 h-6 text-green-600 dark:text-green-400" />
          </div>
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-gray-100">
              성취도
            </h1>
            <p className="text-gray-600 dark:text-gray-400 mt-1">
              완료한 시험 기록과 점수를 확인하세요
            </p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
        <div className="text-center py-12">
          <BarChart3 className="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <p className="text-gray-600 dark:text-gray-400">
            아직 완료한 시험이 없습니다.
          </p>
        </div>
      </div>
    </div>
  );
}
