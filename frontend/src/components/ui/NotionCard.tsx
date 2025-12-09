import React from 'react';
import { cn } from '@/lib/utils';
import { MoreHorizontal } from 'lucide-react';

interface NotionCardProps {
  children: React.ReactNode;
  className?: string;
  hoverable?: boolean;
  onClick?: () => void;
  title?: string;
  icon?: React.ReactNode;
  actions?: React.ReactNode;
}

export function NotionCard({
  children,
  className,
  hoverable = true,
  onClick,
  title,
  icon,
  actions
}: NotionCardProps) {
  return (
    <div
      className={cn(
        "bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700",
        "transition-all duration-200",
        hoverable && "hover:shadow-lg hover:border-gray-300 dark:hover:border-gray-600",
        onClick && "cursor-pointer",
        className
      )}
      onClick={onClick}
    >
      {(title || icon || actions) && (
        <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100 dark:border-gray-700">
          <div className="flex items-center gap-2">
            {icon && <span className="text-gray-500 dark:text-gray-400">{icon}</span>}
            {title && <h3 className="font-medium text-gray-900 dark:text-gray-100">{title}</h3>}
          </div>
          {actions && <div className="flex items-center gap-2">{actions}</div>}
        </div>
      )}
      <div className="p-4">
        {children}
      </div>
    </div>
  );
}

interface NotionStatCardProps {
  title: string;
  value: string | number;
  description?: string;
  icon?: React.ReactNode;
  trend?: {
    value: number;
    isUp: boolean;
  };
  className?: string;
}

export function NotionStatCard({
  title,
  value,
  description,
  icon,
  trend,
  className
}: NotionStatCardProps) {
  return (
    <NotionCard className={cn("group", className)} hoverable>
      <div className="flex items-start justify-between">
        <div className="space-y-2">
          <div className="flex items-center gap-2">
            {icon && (
              <span className="text-gray-400 dark:text-gray-500 group-hover:text-blue-500 transition-colors">
                {icon}
              </span>
            )}
            <p className="text-sm text-gray-600 dark:text-gray-400">{title}</p>
          </div>
          <div className="space-y-1">
            <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">{value}</p>
            {description && (
              <p className="text-xs text-gray-500 dark:text-gray-500">{description}</p>
            )}
          </div>
        </div>
        {trend && (
          <div className={cn(
            "px-2 py-1 rounded-md text-xs font-medium",
            trend.isUp
              ? "bg-green-50 text-green-600 dark:bg-green-900/20 dark:text-green-400"
              : "bg-red-50 text-red-600 dark:bg-red-900/20 dark:text-red-400"
          )}>
            {trend.isUp ? '↑' : '↓'} {Math.abs(trend.value)}%
          </div>
        )}
      </div>
    </NotionCard>
  );
}

interface NotionPageHeaderProps {
  title: string;
  icon?: string;
  coverImage?: string;
  breadcrumbs?: Array<{ label: string; path?: string }>;
  actions?: React.ReactNode;
}

export function NotionPageHeader({
  title,
  icon = '📚',
  coverImage,
  breadcrumbs,
  actions
}: NotionPageHeaderProps) {
  return (
    <div className="mb-8">
      {coverImage && (
        <div className="h-48 -mx-6 -mt-6 mb-6 bg-gradient-to-r from-blue-400 to-purple-500 rounded-t-lg" />
      )}
      {breadcrumbs && (
        <div className="flex items-center gap-2 text-sm text-gray-500 mb-4">
          {breadcrumbs.map((crumb, index) => (
            <React.Fragment key={index}>
              {index > 0 && <span>/</span>}
              <span className={crumb.path ? "hover:text-gray-700 cursor-pointer" : ""}>
                {crumb.label}
              </span>
            </React.Fragment>
          ))}
        </div>
      )}
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-3">
          <span className="text-4xl">{icon}</span>
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-gray-100">{title}</h1>
          </div>
        </div>
        {actions && <div className="flex items-center gap-2">{actions}</div>}
      </div>
    </div>
  );
}

interface NotionEmptyStateProps {
  icon?: React.ReactNode;
  title: string;
  description?: string;
  action?: {
    label: string;
    onClick: () => void;
  };
}

export function NotionEmptyState({
  icon,
  title,
  description,
  action
}: NotionEmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-12 text-center">
      {icon && (
        <div className="mb-4 text-gray-300 dark:text-gray-600">
          {icon}
        </div>
      )}
      <h3 className="text-lg font-medium text-gray-900 dark:text-gray-100 mb-2">
        {title}
      </h3>
      {description && (
        <p className="text-sm text-gray-500 dark:text-gray-400 mb-6 max-w-sm">
          {description}
        </p>
      )}
      {action && (
        <button
          onClick={action.onClick}
          className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 transition-colors text-sm font-medium"
        >
          {action.label}
        </button>
      )}
    </div>
  );
}