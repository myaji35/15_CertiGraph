import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { NotionCard, NotionStatCard, NotionPageHeader, NotionEmptyState } from './NotionCard';

describe('NotionCard 컴포넌트 테스트', () => {
  // FE-UNIT-001: NotionCard 렌더링 - children만 전달
  test('children만 전달했을 때 렌더링', () => {
    render(
      <NotionCard>
        <p>테스트 콘텐츠</p>
      </NotionCard>
    );
    expect(screen.getByText('테스트 콘텐츠')).toBeInTheDocument();
  });

  // FE-UNIT-002: NotionCard 렌더링 - title prop 전달
  test('title prop이 정상적으로 표시되는지 확인', () => {
    render(
      <NotionCard title="테스트 제목">
        <p>콘텐츠</p>
      </NotionCard>
    );
    expect(screen.getByText('테스트 제목')).toBeInTheDocument();
  });

  // FE-UNIT-003: NotionCard 렌더링 - icon prop 전달
  test('icon prop이 정상적으로 표시되는지 확인', () => {
    const TestIcon = () => <span data-testid="test-icon">📱</span>;
    render(
      <NotionCard icon={<TestIcon />}>
        <p>콘텐츠</p>
      </NotionCard>
    );
    expect(screen.getByTestId('test-icon')).toBeInTheDocument();
  });

  // FE-UNIT-004: NotionCard 렌더링 - actions prop 전달
  test('actions prop이 정상적으로 표시되는지 확인', () => {
    render(
      <NotionCard actions={<button>액션 버튼</button>}>
        <p>콘텐츠</p>
      </NotionCard>
    );
    expect(screen.getByText('액션 버튼')).toBeInTheDocument();
  });

  // FE-UNIT-005: NotionCard className prop 적용
  test('className prop이 정상적으로 적용되는지 확인', () => {
    const { container } = render(
      <NotionCard className="custom-class">
        <p>콘텐츠</p>
      </NotionCard>
    );
    expect(container.firstChild).toHaveClass('custom-class');
  });

  // FE-UNIT-006: NotionCard hoverable=false 설정
  test('hoverable=false일 때 hover 효과가 비활성화되는지 확인', () => {
    const { container } = render(
      <NotionCard hoverable={false}>
        <p>콘텐츠</p>
      </NotionCard>
    );
    expect(container.firstChild).not.toHaveClass('hover:shadow-lg');
  });

  // FE-UNIT-007: NotionCard onClick 핸들러 호출
  test('onClick 핸들러가 정상적으로 호출되는지 확인', () => {
    const handleClick = jest.fn();
    render(
      <NotionCard onClick={handleClick}>
        <p>클릭 가능한 콘텐츠</p>
      </NotionCard>
    );
    fireEvent.click(screen.getByText('클릭 가능한 콘텐츠'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  // FE-UNIT-008: NotionCard 다크모드 클래스 적용
  test('다크모드 클래스가 정상적으로 적용되는지 확인', () => {
    const { container } = render(
      <NotionCard>
        <p>콘텐츠</p>
      </NotionCard>
    );
    expect(container.firstChild).toHaveClass('dark:bg-gray-800');
  });
});

describe('NotionStatCard 컴포넌트 테스트', () => {
  // FE-UNIT-009: NotionStatCard title 렌더링
  test('title이 정상적으로 렌더링되는지 확인', () => {
    render(
      <NotionStatCard
        title="전체 문제집"
        value={10}
      />
    );
    expect(screen.getByText('전체 문제집')).toBeInTheDocument();
  });

  // FE-UNIT-010: NotionStatCard value 숫자 렌더링
  test('숫자 value가 정상적으로 렌더링되는지 확인', () => {
    render(
      <NotionStatCard
        title="테스트"
        value={42}
      />
    );
    expect(screen.getByText('42')).toBeInTheDocument();
  });

  // FE-UNIT-011: NotionStatCard value 문자열 렌더링
  test('문자열 value가 정상적으로 렌더링되는지 확인', () => {
    render(
      <NotionStatCard
        title="테스트"
        value="85%"
      />
    );
    expect(screen.getByText('85%')).toBeInTheDocument();
  });

  // FE-UNIT-012: NotionStatCard description 렌더링
  test('description이 정상적으로 렌더링되는지 확인', () => {
    render(
      <NotionStatCard
        title="테스트"
        value={10}
        description="활성화된 학습 세트"
      />
    );
    expect(screen.getByText('활성화된 학습 세트')).toBeInTheDocument();
  });

  // FE-UNIT-013: NotionStatCard icon 렌더링
  test('icon이 정상적으로 렌더링되는지 확인', () => {
    const TestIcon = () => <span data-testid="stat-icon">📊</span>;
    render(
      <NotionStatCard
        title="테스트"
        value={10}
        icon={<TestIcon />}
      />
    );
    expect(screen.getByTestId('stat-icon')).toBeInTheDocument();
  });

  // FE-UNIT-014: NotionStatCard trend.isUp=true
  test('상승 트렌드가 정상적으로 표시되는지 확인', () => {
    render(
      <NotionStatCard
        title="테스트"
        value={10}
        trend={{ value: 20, isUp: true }}
      />
    );
    expect(screen.getByText('↑ 20%')).toBeInTheDocument();
  });

  // FE-UNIT-015: NotionStatCard trend.isUp=false
  test('하락 트렌드가 정상적으로 표시되는지 확인', () => {
    render(
      <NotionStatCard
        title="테스트"
        value={10}
        trend={{ value: 15, isUp: false }}
      />
    );
    expect(screen.getByText('↓ 15%')).toBeInTheDocument();
  });

  // FE-UNIT-016: NotionStatCard trend.value 절대값 표시
  test('트렌드 값이 절대값으로 표시되는지 확인', () => {
    render(
      <NotionStatCard
        title="테스트"
        value={10}
        trend={{ value: -25, isUp: false }}
      />
    );
    expect(screen.getByText('↓ 25%')).toBeInTheDocument();
  });
});

describe('NotionPageHeader 컴포넌트 테스트', () => {
  // FE-UNIT-017: NotionPageHeader title 렌더링
  test('title이 정상적으로 렌더링되는지 확인', () => {
    render(
      <NotionPageHeader title="대시보드" />
    );
    expect(screen.getByText('대시보드')).toBeInTheDocument();
  });

  // FE-UNIT-018: NotionPageHeader 기본 icon 렌더링
  test('기본 icon(📚)이 렌더링되는지 확인', () => {
    render(
      <NotionPageHeader title="테스트" />
    );
    expect(screen.getByText('📚')).toBeInTheDocument();
  });

  // FE-UNIT-019: NotionPageHeader 커스텀 icon 렌더링
  test('커스텀 icon이 정상적으로 렌더링되는지 확인', () => {
    render(
      <NotionPageHeader title="테스트" icon="🎯" />
    );
    expect(screen.getByText('🎯')).toBeInTheDocument();
  });

  // FE-UNIT-020: NotionPageHeader coverImage 렌더링
  test('coverImage가 있을 때 커버 이미지 영역이 렌더링되는지 확인', () => {
    const { container } = render(
      <NotionPageHeader title="테스트" coverImage="/cover.jpg" />
    );
    const coverDiv = container.querySelector('.bg-gradient-to-r');
    expect(coverDiv).toBeInTheDocument();
  });

  // FE-UNIT-021: NotionPageHeader breadcrumbs 단일 항목
  test('breadcrumbs 단일 항목이 렌더링되는지 확인', () => {
    render(
      <NotionPageHeader
        title="테스트"
        breadcrumbs={[{ label: 'Home' }]}
      />
    );
    expect(screen.getByText('Home')).toBeInTheDocument();
  });

  // FE-UNIT-022: NotionPageHeader breadcrumbs 다중 항목
  test('breadcrumbs 다중 항목이 렌더링되는지 확인', () => {
    render(
      <NotionPageHeader
        title="테스트"
        breadcrumbs={[
          { label: 'Home' },
          { label: 'Dashboard' },
          { label: 'Settings' }
        ]}
      />
    );
    expect(screen.getByText('Home')).toBeInTheDocument();
    expect(screen.getByText('Dashboard')).toBeInTheDocument();
    expect(screen.getByText('Settings')).toBeInTheDocument();
  });

  // FE-UNIT-023: NotionPageHeader breadcrumbs 구분자 표시
  test('breadcrumbs 구분자(/)가 정상적으로 표시되는지 확인', () => {
    render(
      <NotionPageHeader
        title="테스트"
        breadcrumbs={[
          { label: 'Home' },
          { label: 'Dashboard' }
        ]}
      />
    );
    expect(screen.getByText('/')).toBeInTheDocument();
  });

  // FE-UNIT-024: NotionPageHeader actions 렌더링
  test('actions가 정상적으로 렌더링되는지 확인', () => {
    render(
      <NotionPageHeader
        title="테스트"
        actions={<button>추가</button>}
      />
    );
    expect(screen.getByText('추가')).toBeInTheDocument();
  });
});

describe('NotionEmptyState 컴포넌트 테스트', () => {
  // FE-UNIT-025: NotionEmptyState title 렌더링
  test('title이 정상적으로 렌더링되는지 확인', () => {
    render(
      <NotionEmptyState title="데이터가 없습니다" />
    );
    expect(screen.getByText('데이터가 없습니다')).toBeInTheDocument();
  });

  // FE-UNIT-026: NotionEmptyState icon 렌더링
  test('icon이 정상적으로 렌더링되는지 확인', () => {
    const TestIcon = () => <span data-testid="empty-icon">📭</span>;
    render(
      <NotionEmptyState
        title="테스트"
        icon={<TestIcon />}
      />
    );
    expect(screen.getByTestId('empty-icon')).toBeInTheDocument();
  });

  // FE-UNIT-027: NotionEmptyState description 렌더링
  test('description이 정상적으로 렌더링되는지 확인', () => {
    render(
      <NotionEmptyState
        title="테스트"
        description="데이터를 추가해주세요"
      />
    );
    expect(screen.getByText('데이터를 추가해주세요')).toBeInTheDocument();
  });

  // FE-UNIT-028: NotionEmptyState action.label 렌더링
  test('action 버튼 label이 정상적으로 렌더링되는지 확인', () => {
    render(
      <NotionEmptyState
        title="테스트"
        action={{
          label: '데이터 추가',
          onClick: () => {}
        }}
      />
    );
    expect(screen.getByText('데이터 추가')).toBeInTheDocument();
  });

  // FE-UNIT-029: NotionEmptyState action.onClick 호출
  test('action 버튼 클릭 시 onClick 핸들러가 호출되는지 확인', () => {
    const handleClick = jest.fn();
    render(
      <NotionEmptyState
        title="테스트"
        action={{
          label: '데이터 추가',
          onClick: handleClick
        }}
      />
    );
    fireEvent.click(screen.getByText('데이터 추가'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });
});