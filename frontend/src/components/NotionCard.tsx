import React from 'react';

export interface NotionCardProps {
  title: string;
  description?: string;
  icon?: string;
  className?: string;
  onClick?: () => void;
  'data-testid'?: string;
}

export function NotionCard({
  title,
  description,
  icon,
  className = '',
  onClick,
  'data-testid': testId,
}: NotionCardProps) {
  const titleId = testId ? `${testId}-title` : undefined;

  return (
    <div
      data-testid={testId}
      onClick={onClick}
      role="article"
      className={`bg-white p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow cursor-pointer ${className}`}
    >
      <div className="flex items-start justify-between mb-4">
        <h3
          id={titleId}
          className="text-lg font-semibold text-gray-900 overflow-hidden text-ellipsis"
        >
          {title}
        </h3>
        {icon && (
          icon.startsWith('<svg') ? (
            <span className="text-2xl flex-shrink-0" dangerouslySetInnerHTML={{ __html: icon }} />
          ) : (
            <span className="text-2xl flex-shrink-0">{icon}</span>
          )
        )}
      </div>
      {description && (
        <p className="text-gray-600 text-sm overflow-hidden text-ellipsis line-clamp-3">
          {description}
        </p>
      )}
    </div>
  );
}
