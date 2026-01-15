---
name: skills-agent
description: "/stitch 폴더의 HTML/CSS 목업 이미지를 분석하여 디자인 요소를 프로젝트에 적용하는 스킬. 다음 상황에서 사용: (1) stitch 폴더나 디자인 구현 언급 시, (2) 목업 이미지에서 UI 구현 필요 시, (3) 디자인 스크린샷을 CSS/코드로 변환 시, (4) 이미지에서 색상, 타이포그래피, 간격, 레이아웃 추출 시"
---

# Skills Agent

`/stitch` 폴더의 디자인 목업 이미지(*.png)를 분석하여 CSS 값과 디자인 요소를 프로젝트 코드에 적용한다.

## 워크플로우

1. **스캔** → `/stitch` 폴더의 모든 .png 파일 탐색
2. **분석** → 비전을 사용하여 각 이미지에서 디자인 요소 추출
3. **문서화** → 추출된 값으로 디자인 명세 작성
4. **구현** → 프로젝트 파일에 디자인 요소 적용

## 1단계: Stitch 폴더 스캔

```bash
# 디자인 이미지 찾기
ls -la /stitch/*.png 2>/dev/null || ls -la stitch/*.png 2>/dev/null
```

폴더를 찾을 수 없으면 상대 경로 확인: `./stitch/`, `../stitch/`, 또는 사용자에게 위치 문의.

## 2단계: 디자인 이미지 분석

각 .png 파일에서 비전을 사용하여 추출할 항목:

| 요소 | 추출 내용 |
|------|----------|
| **색상** | 주요, 보조, 강조, 배경, 텍스트 색상 (hex 값) |
| **타이포그래피** | 폰트 패밀리 힌트, 크기, 굵기, 줄 높이 |
| **간격** | 마진, 패딩, 갭 (px/rem 추정) |
| **레이아웃** | Flexbox/Grid 패턴, 정렬, 위치 |
| **컴포넌트** | 버튼, 카드, 입력 필드, 네비게이션 패턴 |
| **효과** | 그림자, 테두리, border-radius, 그라디언트 |

### 분석 프롬프트 템플릿

각 이미지 분석 시:
```
이 UI 디자인을 분석하여 추출:
1. 색상 팔레트 (모든 색상을 hex로)
2. 타이포그래피 (폰트 크기, 굵기)
3. 간격 시스템 (마진, 패딩 값)
4. 레이아웃 구조 (flex/grid, 정렬)
5. 컴포넌트 스타일 (버튼, 카드, 입력)
6. 시각 효과 (그림자, 테두리, radius)
```

## 3단계: 디자인 명세 작성

추출된 값을 구조화된 형식으로 문서화:

```css
/* === 추출된 디자인 토큰 === */

:root {
  /* 색상 */
  --color-primary: #추출값;
  --color-secondary: #추출값;
  --color-background: #추출값;
  --color-text: #추출값;
  
  /* 타이포그래피 */
  --font-family: '추출된 폰트', sans-serif;
  --font-size-base: 16px;
  --font-size-lg: 20px;
  --font-size-sm: 14px;
  
  /* 간격 */
  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
  
  /* 효과 */
  --border-radius: 8px;
  --shadow: 0 2px 4px rgba(0,0,0,0.1);
}
```

## 4단계: 프로젝트에 구현

### 대상 프레임워크 확인

프로젝트 구조에서 프레임워크 확인:
- `package.json`에 react/vue/svelte → 컴포넌트 기반
- `tailwind.config.js` → Tailwind CSS
- `*.css` 또는 `styles/` → 순수 CSS
- `*.scss` → SCSS/Sass

### 디자인 요소 적용

**Tailwind 프로젝트:**
```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: '#추출값',
        secondary: '#추출값',
      },
      // ... 기타 추출값
    }
  }
}
```

**CSS/SCSS 프로젝트:**
- 루트 스타일시트에 CSS 변수 추가
- 변수를 사용하도록 컴포넌트 스타일 업데이트

**React/Vue 컴포넌트:**
- 테마 프로바이더 생성/업데이트
- 목업과 일치하도록 컴포넌트에 스타일 적용

## 파일명 규칙

이미지 파일명을 컴포넌트/페이지에 매칭:
- `header.png` → Header 컴포넌트 스타일
- `button.png` → Button 컴포넌트 스타일
- `home.png` → Home 페이지 레이아웃
- `card.png` → Card 컴포넌트 스타일

## 품질 체크리스트

완료 전 확인:
- [ ] /stitch의 모든 이미지 분석 완료
- [ ] 디자인 토큰 문서화 완료
- [ ] 프로젝트 CSS/스타일 업데이트 완료
- [ ] 컴포넌트 스타일이 목업과 일치
- [ ] 반응형 고려사항 메모