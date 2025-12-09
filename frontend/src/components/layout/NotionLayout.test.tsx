import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import NotionLayout from './NotionLayout';

describe('NotionLayout 컴포넌트 테스트', () => {
  // FE-UNIT-030: NotionLayout 기본 렌더링
  test('컴포넌트가 정상적으로 렌더링되는지 확인', () => {
    render(
      <NotionLayout>
        <div>테스트 콘텐츠</div>
      </NotionLayout>
    );
    expect(screen.getByText('테스트 콘텐츠')).toBeInTheDocument();
  });

  // FE-UNIT-031: 사이드바 토글 버튼 표시
  test('사이드바 토글 버튼이 표시되는지 확인', () => {
    render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );
    const toggleButton = screen.getByLabelText('Toggle sidebar');
    expect(toggleButton).toBeInTheDocument();
  });

  // FE-UNIT-032: 사이드바 접기/펼치기 동작
  test('사이드바 토글 버튼 클릭 시 접기/펼치기가 동작하는지 확인', () => {
    render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    const toggleButton = screen.getByLabelText('Toggle sidebar');
    const sidebar = screen.getByRole('navigation');

    // 초기 상태: 사이드바 펼쳐짐 (w-64)
    expect(sidebar).toHaveClass('w-64');

    // 토글 버튼 클릭: 사이드바 접힘
    fireEvent.click(toggleButton);
    expect(sidebar).toHaveClass('w-16');

    // 다시 클릭: 사이드바 펼쳐짐
    fireEvent.click(toggleButton);
    expect(sidebar).toHaveClass('w-64');
  });

  // FE-UNIT-033: 네비게이션 항목 렌더링
  test('기본 네비게이션 항목들이 렌더링되는지 확인', () => {
    render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    expect(screen.getByText('홈')).toBeInTheDocument();
    expect(screen.getByText('문제집')).toBeInTheDocument();
    expect(screen.getByText('시험')).toBeInTheDocument();
    expect(screen.getByText('학습 분석')).toBeInTheDocument();
  });

  // FE-UNIT-034: 네비게이션 항목 클릭
  test('네비게이션 항목 클릭 시 active 상태가 변경되는지 확인', () => {
    render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    const examItem = screen.getByText('시험').closest('div');
    fireEvent.click(examItem!);

    // active 상태를 나타내는 클래스 확인
    expect(examItem).toHaveClass('bg-gray-100');
  });

  // FE-UNIT-035: 중첩된 네비게이션 항목 토글
  test('중첩된 네비게이션 항목의 펼치기/접기가 동작하는지 확인', () => {
    render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    // 초기 상태: 하위 항목들이 숨겨져 있음
    expect(screen.queryByText('전체 문제')).not.toBeInTheDocument();

    // 문제집 항목 클릭하여 펼치기
    const problemSetToggle = screen.getByText('문제집').closest('div');
    fireEvent.click(problemSetToggle!);

    // 하위 항목들이 표시됨
    expect(screen.getByText('전체 문제')).toBeInTheDocument();
    expect(screen.getByText('분야별')).toBeInTheDocument();
    expect(screen.getByText('난이도별')).toBeInTheDocument();
  });

  // FE-UNIT-036: 다크모드 토글 버튼 표시
  test('다크모드 토글 버튼이 표시되는지 확인', () => {
    render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    const darkModeButton = screen.getByLabelText('Toggle dark mode');
    expect(darkModeButton).toBeInTheDocument();
  });

  // FE-UNIT-037: 다크모드 토글 동작
  test('다크모드 토글 버튼 클릭 시 다크모드가 활성화되는지 확인', () => {
    const { container } = render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    const darkModeButton = screen.getByLabelText('Toggle dark mode');

    // 초기 상태: 라이트 모드
    expect(container.firstChild).not.toHaveClass('dark');

    // 다크모드 활성화
    fireEvent.click(darkModeButton);
    expect(container.firstChild).toHaveClass('dark');

    // 다시 클릭하여 라이트 모드로
    fireEvent.click(darkModeButton);
    expect(container.firstChild).not.toHaveClass('dark');
  });

  // FE-UNIT-038: 검색바 렌더링
  test('검색바가 정상적으로 렌더링되는지 확인', () => {
    render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    const searchInput = screen.getByPlaceholderText('검색...');
    expect(searchInput).toBeInTheDocument();
  });

  // FE-UNIT-039: 검색 입력 동작
  test('검색바에 텍스트 입력이 가능한지 확인', async () => {
    render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    const searchInput = screen.getByPlaceholderText('검색...') as HTMLInputElement;
    await userEvent.type(searchInput, 'PDF 업로드');

    expect(searchInput.value).toBe('PDF 업로드');
  });

  // FE-UNIT-040: 사용자 프로필 영역 렌더링
  test('사용자 프로필 영역이 표시되는지 확인', () => {
    render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    expect(screen.getByText('사용자')).toBeInTheDocument();
    expect(screen.getByText('user@example.com')).toBeInTheDocument();
  });

  // FE-UNIT-041: 설정 버튼 표시
  test('설정 버튼이 표시되는지 확인', () => {
    render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    const settingsButton = screen.getByLabelText('Settings');
    expect(settingsButton).toBeInTheDocument();
  });

  // FE-UNIT-042: 로그아웃 버튼 표시
  test('로그아웃 버튼이 표시되는지 확인', () => {
    render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    const logoutButton = screen.getByLabelText('Logout');
    expect(logoutButton).toBeInTheDocument();
  });

  // FE-UNIT-043: 사이드바 접힌 상태에서 아이콘만 표시
  test('사이드바가 접힌 상태에서 아이콘만 표시되는지 확인', () => {
    render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    const toggleButton = screen.getByLabelText('Toggle sidebar');
    fireEvent.click(toggleButton);

    // 텍스트는 숨겨짐
    const homeText = screen.getByText('홈');
    expect(homeText.parentElement).toHaveClass('opacity-0');
  });

  // FE-UNIT-044: 헤더 제목 표시
  test('헤더에 제목이 표시되는지 확인', () => {
    render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    expect(screen.getByText('CertiGraph')).toBeInTheDocument();
  });

  // FE-UNIT-045: 새로고침 버튼 표시
  test('새로고침 버튼이 표시되는지 확인', () => {
    render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    const refreshButton = screen.getByLabelText('Refresh');
    expect(refreshButton).toBeInTheDocument();
  });

  // FE-UNIT-046: 다중 레벨 네비게이션 항목
  test('3단계 깊이의 네비게이션 항목이 정상 동작하는지 확인', () => {
    render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    // 학습 분석 펼치기
    const analysisToggle = screen.getByText('학습 분석').closest('div');
    fireEvent.click(analysisToggle!);

    expect(screen.getByText('진도율')).toBeInTheDocument();
    expect(screen.getByText('성적 분석')).toBeInTheDocument();

    // 성적 분석 펼치기
    const gradeToggle = screen.getByText('성적 분석').closest('div');
    fireEvent.click(gradeToggle!);

    expect(screen.getByText('주간 리포트')).toBeInTheDocument();
    expect(screen.getByText('월간 리포트')).toBeInTheDocument();
  });

  // FE-UNIT-047: 메인 콘텐츠 영역 스크롤
  test('메인 콘텐츠 영역이 스크롤 가능한지 확인', () => {
    const { container } = render(
      <NotionLayout>
        <div style={{ height: '2000px' }}>긴 콘텐츠</div>
      </NotionLayout>
    );

    const mainContent = container.querySelector('main');
    expect(mainContent).toHaveClass('overflow-auto');
  });

  // FE-UNIT-048: 네비게이션 항목 아이콘 변경
  test('네비게이션 항목 펼침/접힘 시 아이콘이 변경되는지 확인', () => {
    render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    // 문제집 항목의 화살표 아이콘 찾기
    const problemSetItem = screen.getByText('문제집').closest('div');
    const arrow = problemSetItem?.querySelector('svg');

    // 초기: 오른쪽 화살표 (rotate-0)
    expect(arrow?.parentElement).not.toHaveClass('rotate-90');

    // 클릭 후: 아래쪽 화살표 (rotate-90)
    fireEvent.click(problemSetItem!);
    expect(arrow?.parentElement).toHaveClass('rotate-90');
  });

  // FE-UNIT-049: 반응형 레이아웃
  test('화면 크기에 따라 레이아웃이 조정되는지 확인', () => {
    const { container } = render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    const layout = container.firstChild;
    expect(layout).toHaveClass('flex', 'h-screen');
  });

  // FE-UNIT-050: 키보드 네비게이션
  test('Tab 키로 네비게이션 항목 이동이 가능한지 확인', async () => {
    render(
      <NotionLayout>
        <div>콘텐츠</div>
      </NotionLayout>
    );

    // Tab 키로 첫 번째 네비게이션 항목으로 이동
    await userEvent.tab();
    await userEvent.tab();

    // 포커스된 요소 확인
    const activeElement = document.activeElement;
    expect(activeElement).toBeInTheDocument();
  });

  // FE-UNIT-051: 빈 children 처리
  test('children이 없어도 에러 없이 렌더링되는지 확인', () => {
    const { container } = render(<NotionLayout />);
    expect(container.firstChild).toBeInTheDocument();
  });

  // FE-UNIT-052: 다크모드 상태 유지
  test('다크모드 상태가 컴포넌트 재렌더링 시에도 유지되는지 확인', () => {
    const { container, rerender } = render(
      <NotionLayout>
        <div>콘텐츠1</div>
      </NotionLayout>
    );

    // 다크모드 활성화
    const darkModeButton = screen.getByLabelText('Toggle dark mode');
    fireEvent.click(darkModeButton);
    expect(container.firstChild).toHaveClass('dark');

    // 컴포넌트 재렌더링
    rerender(
      <NotionLayout>
        <div>콘텐츠2</div>
      </NotionLayout>
    );

    // 다크모드 상태 유지 확인
    expect(container.firstChild).toHaveClass('dark');
  });
});