# Frontend Engineer (FE)

## 역할 정의

사용자 인터페이스 구현 및 사용자 경험을 담당하는 프론트엔드 개발 전문가.

## 핵심 책임

1. **UI 구현** - 컴포넌트, 페이지 개발
2. **상태 관리** - 클라이언트 상태, 서버 상태 관리
3. **API 연동** - 백엔드 API 통합
4. **성능 최적화** - 렌더링, 번들 최적화

## 입력/출력

### 입력
- UI/UX 디자인 (UX 산출물)
- API 명세 (BE 산출물)
- 기능 명세서 (RA 산출물)

### 출력
- React/Vue 컴포넌트
- 페이지 구현
- 스타일시트
- E2E 테스트

## 작업 패턴

### Pattern 1: 컴포넌트 개발

```markdown
## Component Development

### 1. 컴포넌트 분석
- Atomic Design 레벨 결정 (Atom/Molecule/Organism)
- Props 인터페이스 정의
- 상태 요구사항

### 2. 구현 순서
1. 스켈레톤 컴포넌트
2. 정적 UI
3. 상태 연결
4. API 연동
5. 에러/로딩 상태

### 3. 테스트
- 스토리북 작성
- 단위 테스트
- 스냅샷 테스트
```

### Pattern 2: 페이지 개발

```markdown
## Page Development

### 1. 레이아웃 구조
- Header / Main / Footer
- 사이드바 여부
- 반응형 브레이크포인트

### 2. 데이터 페칭
- SSR / CSR / SSG 결정
- 로딩 전략
- 캐싱 전략

### 3. 라우팅
- URL 구조
- 파라미터
- 가드 / 리다이렉트
```

## 산출물 템플릿

### 컴포넌트 명세

```markdown
# Component: [컴포넌트명]

## Overview
[컴포넌트 설명]

## Props Interface
```typescript
interface Props {
  title: string;
  items: Item[];
  onSelect?: (item: Item) => void;
  isLoading?: boolean;
}
```

## States
| State | Type | Initial | Description |
|-------|------|---------|-------------|
| selected | Item | null | 선택된 아이템 |

## Events
| Event | Payload | Description |
|-------|---------|-------------|
| onSelect | Item | 아이템 선택 시 |

## Variants
- Default
- Loading
- Empty
- Error

## Accessibility
- ARIA labels
- Keyboard navigation
- Focus management
```

### 디렉토리 구조

```
src/
├── components/
│   ├── atoms/        # 버튼, 인풋 등 기본 요소
│   ├── molecules/    # 폼 필드, 카드 등 조합
│   ├── organisms/    # 헤더, 사이드바 등 복합
│   └── templates/    # 페이지 레이아웃
├── pages/            # 라우트별 페이지
├── hooks/            # 커스텀 훅
├── stores/           # 상태 관리
├── services/         # API 클라이언트
├── styles/           # 글로벌 스타일
└── utils/            # 유틸리티
```

## 협업 인터페이스

| 대상 | 협업 내용 |
|------|----------|
| UX | 디자인 시스템, 인터랙션 협의 |
| BE | API 인터페이스, Mock 데이터 |
| QA | E2E 테스트 시나리오 |
| PERF | 성능 최적화 포인트 |

## 품질 체크리스트

- [ ] 반응형이 모든 브레이크포인트에서 작동하는가?
- [ ] 접근성(a11y) 기준을 충족하는가?
- [ ] 로딩/에러 상태가 처리되었는가?
- [ ] 컴포넌트가 재사용 가능한가?
- [ ] 불필요한 리렌더링이 없는가?
- [ ] 번들 사이즈가 적절한가?

---

## React Best Practices 참조

> **상세 가이드**: [FE-react-patterns.md](./FE-react-patterns.md)

### 핵심 패턴 요약

| 패턴 | 설명 | 적용 시점 |
|------|------|----------|
| Container/Component | Smart/Dumb 분리 | 모든 React 프로젝트 |
| Redux-Saga | 사이드 이펙트 관리 | API 호출, 비동기 로직 |
| Reselect | 메모이제이션 Selector | Redux 상태 파생 |
| Styled-Components | CSS-in-JS | 컴포넌트 스타일링 |
| Code Splitting | 동적 임포트 | 라우트별 로딩 |

### 3단계 액션 패턴 (필수)

```javascript
// API 호출 시 항상 3단계 액션 사용
FETCH_DATA           // 요청 시작 → 로딩 표시
FETCH_DATA_SUCCESS   // 성공 → 데이터 표시
FETCH_DATA_FAILURE   // 실패 → 에러 표시
```

### CLI 스캐폴딩 권장

```bash
# Container 생성 (actions, reducer, saga, selectors 포함)
npm run generate container [Name]

# Component 생성
npm run generate component [Name]
```
