'use client';

import { NotionCard } from '@/components/NotionCard';
import { useState } from 'react';

export default function NotionCardTestPage() {
  const [clickedCard, setClickedCard] = useState<string | null>(null);

  return (
    <div className="min-h-screen bg-gray-100 p-8">
      <h1 className="text-2xl font-bold mb-6">Notion Card Component Test</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {/* FE-UNIT-001: Default props */}
        <NotionCard
          data-testid="notion-card-default"
          title="Default Card"
        />

        {/* FE-UNIT-002: Title and description */}
        <NotionCard
          data-testid="notion-card-with-content"
          title="Sample Title"
          description="Sample Description"
        />

        {/* FE-UNIT-003: Hover effects (already has hover:shadow-lg) */}
        <NotionCard
          data-testid="notion-card-hover"
          title="Hover Me"
          description="This card has hover effects"
        />

        {/* FE-UNIT-004: Click events */}
        <NotionCard
          data-testid="notion-card-clickable"
          title="Clickable Card"
          description={clickedCard === 'clickable' ? 'Clicked!' : 'Click me'}
          onClick={() => setClickedCard('clickable')}
        />

        {/* FE-UNIT-005: Custom className */}
        <NotionCard
          data-testid="notion-card-custom-class"
          title="Custom Class"
          description="This has custom styling"
          className="custom-card-class border-2 border-blue-500"
        />

        {/* FE-UNIT-006: Icon display */}
        <NotionCard
          data-testid="notion-card-with-icon"
          title="Card with Icon"
          description="This card has an icon"
          icon="<svg width='24' height='24' viewBox='0 0 24 24' fill='none' xmlns='http://www.w3.org/2000/svg'><circle cx='12' cy='12' r='10' fill='#3B82F6'/></svg>"
        />

        {/* FE-UNIT-007: Long text overflow */}
        <NotionCard
          data-testid="notion-card-long-text"
          title="Very Long Title That Should Be Truncated When It Exceeds Maximum Width"
          description="Very long description that should be truncated with ellipsis when it exceeds the maximum number of lines allowed in the card component which is typically three lines for optimal readability and visual consistency across the interface. This text is intentionally very long to test the overflow behavior."
        />

        {/* FE-UNIT-008: ARIA attributes */}
        <NotionCard
          data-testid="notion-card-accessible"
          title="Accessible Card"
          description="This card is accessible"
          onClick={() => {}}
        />
      </div>

      {clickedCard && (
        <div className="mt-6 p-4 bg-green-100 rounded">
          Last clicked: {clickedCard}
        </div>
      )}
    </div>
  );
}
