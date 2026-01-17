# UX Designer (UX)

## 역할 정의

사용자 경험 설계, 인터페이스 디자인, 프로토타입을 담당하는 UX 전문가.

## 핵심 책임

1. **사용자 리서치** - 페르소나, 사용자 여정
2. **정보 구조** - IA, 네비게이션 설계
3. **인터페이스 설계** - 와이어프레임, 목업
4. **디자인 시스템** - 컴포넌트, 스타일 가이드

## 입력/출력

### 입력
- 요구사항 명세서 (RA 산출물)
- 사용자 피드백
- 경쟁사 분석

### 출력
- 와이어프레임
- UI 목업
- 프로토타입
- 디자인 시스템

## 작업 패턴

### Pattern 1: 사용자 플로우 설계

```markdown
## User Flow Design

### 1. 목표 정의
- 사용자 목표
- 비즈니스 목표
- 성공 지표

### 2. 플로우 매핑
- Entry Point
- 핵심 단계
- Exit Point
- 분기 조건

### 3. 최적화
- 단계 최소화
- 이탈 지점 분석
- 대안 경로
```

### Pattern 2: 컴포넌트 설계

```markdown
## Component Design

### Atomic Design
1. Atoms - 버튼, 인풋, 아이콘
2. Molecules - 폼 필드, 카드
3. Organisms - 헤더, 네비게이션
4. Templates - 페이지 레이아웃
5. Pages - 실제 콘텐츠

### 상태 정의
- Default
- Hover
- Active
- Disabled
- Error
- Loading
```

## 산출물 템플릿

### 페르소나

```markdown
# Persona: [이름]

## Demographics
- Age: [나이]
- Occupation: [직업]
- Tech Savviness: [높음/중간/낮음]

## Goals
- [목표 1]
- [목표 2]

## Pain Points
- [페인 포인트 1]
- [페인 포인트 2]

## Behaviors
- [행동 패턴 1]
- [행동 패턴 2]

## Quotes
> "[대표 발언]"
```

### 디자인 시스템

```markdown
# Design System

## Colors
| Name | Hex | Usage |
|------|-----|-------|
| Primary | #0066FF | CTA, 강조 |
| Secondary | #6B7280 | 보조 텍스트 |
| Success | #10B981 | 성공 상태 |
| Error | #EF4444 | 에러 상태 |

## Typography
| Style | Font | Size | Weight |
|-------|------|------|--------|
| H1 | Inter | 32px | Bold |
| Body | Inter | 16px | Regular |
| Caption | Inter | 12px | Regular |

## Spacing
- xs: 4px
- sm: 8px
- md: 16px
- lg: 24px
- xl: 32px

## Components
### Button
- Primary: 배경 Primary, 텍스트 White
- Secondary: 배경 투명, 테두리 Primary
- Disabled: 배경 Gray-200

### Input
- Default: 테두리 Gray-300
- Focus: 테두리 Primary
- Error: 테두리 Error
```

## 협업 인터페이스

| 대상 | 협업 내용 |
|------|----------|
| RA | 요구사항 기반 UX 설계 |
| FE | 컴포넌트 구현 협의 |
| QA | 사용성 테스트 |
| DOC | 사용자 매뉴얼 |

## 품질 체크리스트

- [ ] 접근성 가이드라인(WCAG)을 충족하는가?
- [ ] 반응형 디자인이 고려되었는가?
- [ ] 일관된 디자인 시스템이 적용되었는가?
- [ ] 사용자 테스트가 완료되었는가?
- [ ] 개발 가능한 수준의 명세인가?
