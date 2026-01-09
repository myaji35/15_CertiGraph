'use client';

import { NotionStatCard } from '@/components/NotionStatCard';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

export default function NotionStatCardTestPage() {
  const router = useRouter();
  const [clickCount, setClickCount] = useState(0);

  return (
    <div className="min-h-screen bg-gray-100 p-8">
      <h1 className="text-2xl font-bold mb-6">Notion Stat Card Component Test</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
        {/* FE-UNIT-009: Default props */}
        <NotionStatCard
          data-testid="notion-stat-card-default"
          title="Default Stat"
          value={42}
        />

        {/* FE-UNIT-010: Title and value - Updated testid */}
        <NotionStatCard
          data-testid="notion-stat-card-with-data"
          title="Total Questions"
          value={1234}
          icon="📝"
        />

        {/* FE-UNIT-011: Trend up */}
        <NotionStatCard
          data-testid="notion-stat-card-trend-up"
          title="Revenue"
          value={5000}
          trend="up"
          trendValue="12% from last week"
          icon="💰"
        />

        {/* FE-UNIT-012: Trend down */}
        <NotionStatCard
          data-testid="notion-stat-card-trend-down"
          title="Issues"
          value={23}
          trend="down"
          trendValue="5% from last week"
          icon="⚠️"
        />

        {/* FE-UNIT-013: Large numbers */}
        <NotionStatCard
          data-testid="notion-stat-card-large-number"
          title="Total Views"
          value={1000000}
          icon="👁️"
        />

        {/* FE-UNIT-014: Percentage */}
        <NotionStatCard
          data-testid="notion-stat-card-percentage"
          title="Success Rate"
          value="95.5%"
          trend="up"
          trendValue="2% increase"
          icon="✅"
        />

        {/* FE-UNIT-015: Loading state */}
        <NotionStatCard
          data-testid="notion-stat-card-loading"
          title="Loading..."
          value={0}
          isLoading={true}
        />

        {/* FE-UNIT-016: Click to navigate */}
        <NotionStatCard
          data-testid="notion-stat-card-clickable"
          title="Clickable"
          value={clickCount}
          onClick={() => {
            setClickCount(prev => prev + 1);
            // Simulate navigation
            console.log('Navigate to details');
          }}
          icon="🔗"
        />
      </div>

      {clickCount > 0 && (
        <div className="p-4 bg-blue-100 rounded">
          Card clicked {clickCount} time(s)
        </div>
      )}
    </div>
  );
}
