# ExamsGraph Design System
## Extracted from /stitch mockups

Last updated: 2026-01-14

---

## 🎨 Color Palette

### Primary Colors
```css
--color-primary: #137fec;           /* 주요 파란색 (버튼, 링크, 강조) */
--color-primary-hover: #0f6dd4;     /* Primary hover state */
--color-primary-light: rgba(19, 127, 236, 0.1);  /* Primary 배경 */
```

### Background Colors
```css
--color-bg-light: #f6f7f8;          /* 라이트 모드 배경 */
--color-bg-dark: #101922;           /* 다크 모드 메인 배경 */
--color-surface-dark: #1e293b;      /* 다크 모드 카드/서피스 */
--color-surface-light: #ffffff;     /* 라이트 모드 카드 */
```

### Text Colors
```css
--color-text-primary-dark: #ffffff;     /* 다크 모드 주요 텍스트 */
--color-text-secondary-dark: #94a3b8;   /* 다크 모드 보조 텍스트 */
--color-text-tertiary-dark: #64748b;    /* 다크 모드 3차 텍스트 */
--color-text-primary-light: #0d141b;    /* 라이트 모드 주요 텍스트 */
--color-text-secondary-light: #4c739a;  /* 라이트 모드 보조 텍스트 */
```

### Border Colors
```css
--color-border-dark: #334155;       /* 다크 모드 테두리 */
--color-border-light: #e7edf3;      /* 라이트 모드 테두리 */
```

### Status Colors
```css
--color-success: #10b981;           /* 성공/완료 */
--color-warning: #f59e0b;           /* 경고/처리중 */
--color-danger: #ef4444;            /* 위험/실패 */
--color-info: #3b82f6;              /* 정보 */
```

---

## 📝 Typography

### Font Families
```css
--font-display: 'Space Grotesk', 'Noto Sans KR', sans-serif;
--font-sans: 'Noto Sans KR', sans-serif;
--font-serif: 'Noto Serif KR', serif;  /* 시험 모드용 */
```

### Font Sizes
```css
--font-size-xs: 10px;       /* 0.625rem - 작은 라벨 */
--font-size-sm: 12px;       /* 0.75rem - 보조 텍스트 */
--font-size-base: 14px;     /* 0.875rem - 기본 텍스트 */
--font-size-md: 16px;       /* 1rem - 본문 */
--font-size-lg: 18px;       /* 1.125rem - 부제목 */
--font-size-xl: 20px;       /* 1.25rem - 제목 */
--font-size-2xl: 24px;      /* 1.5rem - 큰 제목 */
--font-size-3xl: 30px;      /* 1.875rem - 페이지 제목 */
--font-size-4xl: 40px;      /* 2.5rem - 히어로 제목 */
```

### Font Weights
```css
--font-weight-light: 300;
--font-weight-normal: 400;
--font-weight-medium: 500;
--font-weight-semibold: 600;
--font-weight-bold: 700;
--font-weight-black: 900;
```

### Line Heights
```css
--line-height-tight: 1.25;
--line-height-snug: 1.375;
--line-height-normal: 1.5;
--line-height-relaxed: 1.625;
--line-height-loose: 2;
```

---

## 📏 Spacing System

### Base Spacing Scale
```css
--spacing-0: 0;
--spacing-1: 4px;       /* 0.25rem */
--spacing-2: 8px;       /* 0.5rem */
--spacing-3: 12px;      /* 0.75rem */
--spacing-4: 16px;      /* 1rem */
--spacing-5: 20px;      /* 1.25rem */
--spacing-6: 24px;      /* 1.5rem */
--spacing-8: 32px;      /* 2rem */
--spacing-10: 40px;     /* 2.5rem */
--spacing-12: 48px;     /* 3rem */
--spacing-16: 64px;     /* 4rem */
```

### Component Spacing
```css
--padding-btn-sm: 8px 16px;
--padding-btn-md: 12px 24px;
--padding-btn-lg: 16px 32px;
--padding-card: 24px;
--padding-section: 32px;
```

---

## 🎭 Effects & Shadows

### Border Radius
```css
--radius-sm: 4px;       /* 0.25rem - 작은 요소 */
--radius-md: 8px;       /* 0.5rem - 기본 */
--radius-lg: 12px;      /* 0.75rem - 카드 */
--radius-xl: 16px;      /* 1rem - 큰 카드 */
--radius-2xl: 24px;     /* 1.5rem - 모달 */
--radius-full: 9999px;  /* 원형 */
```

### Box Shadows
```css
--shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
--shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
--shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
--shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
--shadow-2xl: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
--shadow-primary: 0 10px 20px rgba(19, 127, 236, 0.2);
```

### Glass Effect
```css
.glass-card {
  background: rgba(25, 38, 51, 0.6);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.05);
}
```

---

## 🧩 Layout

### Sidebar
```css
--sidebar-width: 264px;
--sidebar-collapsed-width: 64px;
```

### Header
```css
--header-height: 56px;
```

### Container
```css
--container-max-width: 1400px;
--container-padding: 24px;
```

### Grid
```css
--grid-gap: 24px;
--grid-columns-sm: 1;
--grid-columns-md: 2;
--grid-columns-lg: 3;
--grid-columns-xl: 4;
```

---

## 🎯 Component Patterns

### Button Styles

**Primary Button**
```css
.btn-primary {
  background: var(--color-primary);
  color: white;
  padding: 12px 24px;
  border-radius: 12px;
  font-weight: 700;
  box-shadow: 0 10px 20px rgba(19, 127, 236, 0.3);
  transition: all 150ms;
}

.btn-primary:hover {
  background: var(--color-primary-hover);
  transform: translateY(-1px);
}
```

**Secondary Button**
```css
.btn-secondary {
  background: var(--color-surface-dark);
  color: var(--color-text-primary-dark);
  padding: 12px 24px;
  border-radius: 12px;
  font-weight: 700;
  border: 1px solid var(--color-border-dark);
}
```

### Card Styles

**Glass Card**
```css
.card-glass {
  background: rgba(25, 38, 51, 0.6);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 16px;
  padding: 24px;
}
```

**Solid Card**
```css
.card-solid {
  background: var(--color-surface-dark);
  border: 1px solid var(--color-border-dark);
  border-radius: 16px;
  padding: 24px;
}
```

### Badge Styles

**Status Badges**
```css
.badge {
  display: inline-flex;
  align-items: center;
  padding: 4px 12px;
  border-radius: 9999px;
  font-size: 12px;
  font-weight: 700;
}

.badge-success {
  background: rgba(16, 185, 129, 0.1);
  color: #10b981;
  border: 1px solid rgba(16, 185, 129, 0.2);
}

.badge-warning {
  background: rgba(245, 158, 11, 0.1);
  color: #f59e0b;
  border: 1px solid rgba(245, 158, 11, 0.2);
}

.badge-danger {
  background: rgba(239, 68, 68, 0.1);
  color: #ef4444;
  border: 1px solid rgba(239, 68, 68, 0.2);
}
```

---

## 🎨 Specific Component Styles

### Sidebar Navigation Item
```css
.nav-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  color: var(--color-text-secondary-dark);
  transition: all 150ms;
}

.nav-item:hover {
  background: rgba(255, 255, 255, 0.05);
  color: var(--color-text-primary-dark);
}

.nav-item.active {
  background: rgba(19, 127, 236, 0.1);
  color: var(--color-primary);
  border: 1px solid rgba(19, 127, 236, 0.2);
}
```

### Material Icons
```css
.material-symbols-outlined {
  font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
}
```

---

## 📱 Responsive Breakpoints

```css
--breakpoint-sm: 640px;
--breakpoint-md: 768px;
--breakpoint-lg: 1024px;
--breakpoint-xl: 1280px;
--breakpoint-2xl: 1536px;
```

---

## 🌙 Dark Mode (Default)

ExamsGraph는 **다크 모드가 기본**입니다.

라이트 모드는 선택적으로 제공되며, 토글 버튼으로 전환 가능합니다.

---

## 📦 Implementation Notes

### Tailwind Config 적용
위의 디자인 토큰들을 `tailwind.config.js`의 `theme.extend`에 추가

### CSS Variables 적용
루트 레벨에서 CSS 변수로 정의하여 전역 사용

### Component Library
재사용 가능한 컴포넌트를 만들 때 위의 패턴 참조

---

**Generated from**: `/stitch` folder mockups
**Date**: 2026-01-14
**Framework**: Rails + Tailwind CSS
