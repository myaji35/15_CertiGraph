import React from 'react';

export interface NotionStatCardProps {
  title: string;
  value: number | string;
  trend?: 'up' | 'down' | 'neutral';
  trendValue?: string;
  icon?: string;
  isLoading?: boolean;
  onClick?: () => void;
  'data-testid'?: string;
}

export function NotionStatCard({
  title,
  value,
  trend,
  trendValue,
  icon,
  isLoading = false,
  onClick,
  'data-testid': testId,
}: NotionStatCardProps) {
  // Format large numbers with commas
  const formatValue = (val: number | string): string => {
    if (typeof val === 'number') {
      return val.toLocaleString();
    }
    // Handle percentage strings
    if (typeof val === 'string' && val.includes('%')) {
      const num = parseFloat(val.replace('%', ''));
      return `${num}%`;
    }
    return val;
  };

  const getTrendIcon = () => {
    if (trend === 'up') return '↑';
    if (trend === 'down') return '↓';
    return '→';
  };

  const getTrendColor = () => {
    if (trend === 'up') return 'text-green-600';
    if (trend === 'down') return 'text-red-600';
    return 'text-gray-600';
  };

  if (isLoading) {
    return (
      <div
        data-testid={testId}
        className="bg-white p-6 rounded-lg shadow-md"
      >
        <div data-testid="skeleton" className="h-4 bg-gray-200 rounded w-1/2 mb-4 animate-pulse"></div>
        <div data-testid="skeleton" className="h-8 bg-gray-200 rounded w-3/4 animate-pulse"></div>
      </div>
    );
  }

  return (
    <div
      data-testid={testId}
      onClick={onClick}
      className={`bg-white p-6 rounded-lg shadow-md ${onClick ? 'cursor-pointer hover:shadow-lg transition-shadow' : ''}`}
    >
      <div className="flex items-center justify-between mb-2">
        <span data-testid="stat-title" className="text-gray-500 text-sm">{title}</span>
        {icon && <span className="text-2xl">{icon}</span>}
      </div>

      <div data-testid={typeof value === 'string' && value.includes('%') ? 'stat-percentage' : 'stat-value'} className="text-3xl font-bold text-blue-600 mb-2">
        {formatValue(value)}
      </div>

      {trendValue && (
        <div data-testid="trend-icon" className={`text-xs ${getTrendColor()} flex items-center gap-1`}>
          <span>{getTrendIcon()}</span>
          <span>{trendValue}</span>
        </div>
      )}
    </div>
  );
}
