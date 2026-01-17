# Design Gap Analysis: Mockup vs Implementation

**Date**: 2026-01-15
**Project**: CertiGraph (ExamsGraph) - AI-powered Certification Exam Study Platform
**Analyzed By**: UX/UI Specialist

---

## Executive Summary

This document provides a comprehensive analysis comparing the mockup designs (examsgraph-home.png, examsgraph-signin.png, examsgraph-signup.png) against the current Rails implementation. Overall, the implementation shows **strong alignment** with the mockup designs, with approximately **75-80% visual fidelity**.

### Key Findings
- **Home Page**: 80% complete - Good structure, minor design refinements needed
- **Sign In Page**: 70% complete - Functional but missing mockup's visual polish
- **Sign Up Page**: 60% complete - Basic Devise view needs complete redesign

---

## 1. Home Page Analysis (`/`)

**Implementation File**: `/app/views/home/index.html.erb`

### What Matches the Mockup ✓

1. **Hero Section Structure**
   - Badge/pill at top with icon: ✓ (Implemented as blue pill)
   - Large heading with colored keywords: ✓ (Blue and purple highlights)
   - Subtitle text: ✓
   - Two-button CTA layout: ✓
   - Feature checkmarks below CTAs: ✓

2. **Features Section**
   - Three-column grid layout: ✓
   - Icons with titles and descriptions: ✓
   - Clean spacing: ✓

3. **Popular Exams Section**
   - Section heading with subtitle: ✓
   - Three-column card grid: ✓
   - "See more" link at bottom: ✓

4. **Footer**
   - Multi-column layout: ✓
   - Service/Company/Legal sections: ✓
   - Copyright notice: ✓

5. **Navigation**
   - Logo with brain icon: ✓
   - Navigation links: ✓
   - CTA button (purple/blue): ✓

### What's Missing or Different ✗

1. **Color Scheme Discrepancies**
   - **Mockup**: Uses vibrant purple gradient CTA button
   - **Current**: Uses solid blue button
   - **Impact**: Medium - Reduces visual appeal

2. **Logo/Brand Inconsistency**
   - **Mockup**: Shows "ExamsGraph" text logo (simple, clean)
   - **Current**: Shows "ExamsGraph" with detailed brain SVG
   - **Mockup (Auth pages)**: Shows "CertiGraph" with blue brain icon
   - **Impact**: High - Brand identity confusion

3. **Feature Icons**
   - **Mockup**: Uses custom colored icons (blue document, green monitor, purple chart)
   - **Current**: Uses emoji icons (📄, 📊, 📈)
   - **Impact**: Medium - Less professional appearance

4. **Popular Exams Cards**
   - **Mockup**: Shows specific exam cards with custom icons and "살펴보기 →" links
   - **Current**: Dynamic data but uses generic 📚 emoji
   - **Impact**: Low - Functional but could be more polished

5. **Navigation Button Text**
   - **Mockup**: "무료 시작하기" button (top right)
   - **Current**: "무료 시작하기" (matches)
   - **Note**: Both use similar text, good alignment

### Design Refinements Needed

1. **Typography**
   - Mockup uses cleaner, more modern font hierarchy
   - Current implementation could benefit from tighter line-height on hero heading

2. **Spacing & Padding**
   - Mockup has slightly more generous whitespace
   - Card shadows in mockup are more subtle

3. **Button Styling**
   - Primary CTA needs gradient treatment: `bg-gradient-to-r from-purple-600 to-blue-600`
   - Hover states need enhancement

---

## 2. Sign In Page Analysis (`/signin` or `/users/sign_in`)

**Implementation Files**:
- Custom: `/app/views/home/signin.html.erb`
- Devise: `/app/views/devise/sessions/new.html.erb`

### Mockup Design Elements

The mockup shows a **highly polished** authentication page with:
- CertiGraph logo (blue brain icon)
- Title: "로그인"
- Subtitle: "다시 만나서 반가워요! 학습을 계속해보세요"
- White glassmorphic card with shadow
- Google OAuth button at top
- Divider: "또는"
- Email input field with placeholder
- Dark submit button with arrow: "계속 >"
- Link: "계정이 없으신가요? 회원가입" (blue)
- "Secured by Clerk" badge
- Stats at bottom: "1,000+ 활성 사용자", "50,000+ 분석된 문제", "95% 합격률"

### Custom Sign In (`home/signin.html.erb`) - 70% Match

#### What Matches ✓
1. Brain emoji icon with circular background: ✓
2. ExamsGraph gradient text logo: ✓
3. "로그인" title: ✓
4. Subtitle present: ✓ (matches)
5. White card with shadow: ✓
6. Google OAuth button: ✓
7. "또는" divider: ✓
8. Email input field: ✓
9. Remember me checkbox: ✓
10. Stats section at bottom: ✓ (exact match!)

#### What's Missing/Different ✗
1. **Brand Name**: Uses "ExamsGraph" instead of "CertiGraph"
2. **Logo Icon**: Uses brain emoji (🧠) instead of custom blue brain icon
3. **Button Text**: Uses "로그인" instead of "계속 >"
4. **Button Color**: Uses blue (`bg-blue-600`) instead of dark gray/black
5. **"Secured by Clerk" badge**: Not present
6. **Password field**: Shows password input (mockup only shows email on first screen)
7. **Background gradient**: Uses `from-blue-50 to-purple-50` (close but slightly different)

### Devise Sign In (`devise/sessions/new.html.erb`) - 65% Match

More functional but less polished than custom signin:
- Has Google OAuth: ✓
- Has email/password form: ✓
- Missing stats section: ✗
- Missing mockup's visual polish: ✗
- Simpler layout without subtitle: ✗

---

## 3. Sign Up Page Analysis (`/signup` or `/users/sign_up`)

**Implementation Files**:
- Custom: `/app/views/home/signup.html.erb`
- Devise: `/app/views/devise/registrations/new.html.erb`

### Mockup Design Elements

- CertiGraph logo (blue brain icon)
- Title: "회원가입"
- Subtitle: "AI 자격증 마스터와 함께 시험 준비를 시작하세요"
- White glassmorphic card
- Google OAuth button at top
- Form fields:
  - 이름 (split into 선택사항/선택사항 - first name/last name)
  - 이메일 주소
  - 비밀번호 (with eye icon toggle)
- Dark submit button: "계속 >"
- Link to login: "계정이 있으신가요? 로그인하기"
- "Secured by Clerk" badge
- 3 feature icons at bottom:
  - 📚 PDF 자동 분석
  - 🎯 지식 그래프
  - 🚀 맞춤형 학습

### Custom Sign Up (`home/signup.html.erb`) - 75% Match

#### What Matches ✓
1. Brain emoji icon: ✓
2. ExamsGraph gradient logo: ✓
3. "회원가입" title: ✓
4. Subtitle: ✓ (exact match)
5. White card with shadow: ✓
6. Google OAuth at top: ✓
7. "또는" divider: ✓
8. Split name fields (first/last): ✓
9. Email field: ✓
10. Password field: ✓
11. Feature icons at bottom: ✓ (3 icons with descriptions)
12. Link to login: ✓

#### What's Missing/Different ✗
1. **Brand Name**: ExamsGraph vs CertiGraph
2. **Logo Icon**: Emoji vs custom blue brain icon
3. **Button Color**: Blue instead of dark gray/black
4. **Button Text**: "계속" instead of "계속 >"
5. **Password Eye Icon**: Not visible in current implementation
6. **"Secured by Clerk" badge**: Missing
7. **Terms checkbox**: Current has it, mockup doesn't show it explicitly
8. **Background gradient**: `from-purple-50 to-pink-50` (close match)

### Devise Sign Up (`devise/registrations/new.html.erb`) - 20% Match

**Status**: ✗ **Needs Complete Redesign**

This is the **default Devise view** with:
- Plain "Sign up" heading
- No styling or layout
- No Google OAuth integration
- No mockup elements present
- Basic HTML form only

**Recommendation**: Either redirect signup to custom `/signup` route or completely redesign this Devise view to match mockup.

---

## 4. Design System Analysis

### Color Palette

#### Mockup Colors
```css
/* Primary Colors */
--primary-blue: #4F46E5 (Indigo)
--primary-purple: #9333EA (Purple)

/* Button Colors */
--dark-button: #2C2C2C (Almost black)
--dark-button-hover: #1A1A1A

/* Background */
--bg-light: #FAFAFA or #F9FAFB
--bg-gradient-signin: linear-gradient(to-br, #EFF6FF, #F3E8FF)
--bg-gradient-signup: linear-gradient(to-br, #FAF5FF, #FCE7F3)

/* Feature Icon Colors */
--icon-blue: #3B82F6
--icon-green: #10B981
--icon-purple: #A855F7
```

#### Current Implementation Colors
```css
/* From application.html.erb */
--primary: #137fec (Brighter blue)

/* Buttons */
--button-primary: #2563EB (Tailwind blue-600)

/* Backgrounds */
--background-light: #f6f7f8
--background-dark: #101922
```

**Gap**: Color palette needs alignment. Mockup uses more purple accent, current uses more blue.

### Typography

#### Mockup
- Clean sans-serif (appears to be Inter or similar)
- Strong hierarchy with bold headings
- Medium weight for body text

#### Current Implementation
- Noto Sans KR + Lexend (Good choice for Korean + English)
- Similar hierarchy
- Good match overall

**Gap**: Minor - Typography is well-implemented

### Component Styles

#### Cards
- **Mockup**: Subtle shadow, clean white background, slight rounded corners
- **Current**: Similar, uses `shadow-xl` and `rounded-lg`
- **Gap**: Minimal - good alignment

#### Buttons
- **Mockup**: Dark (almost black) primary, with white arrow icon ">"
- **Current**: Blue gradient, no arrow icon
- **Gap**: Medium - needs dark button style option

#### Form Inputs
- **Mockup**: Clean borders, subtle focus states
- **Current**: Uses Tailwind forms plugin, good implementation
- **Gap**: Minimal - well implemented

---

## 5. Missing Design Elements

### High Priority

1. **CertiGraph Logo SVG**
   - Mockup shows custom blue brain icon
   - Need to create/source this icon
   - Current uses emoji placeholder

2. **Dark Button Component**
   - Mockup uses dark gray/black buttons with white text
   - Current only has blue button style
   - Need to add dark button variant

3. **"Secured by Clerk" Badge**
   - Mockup shows this security indicator
   - Not present in current implementation
   - Low priority but adds trust

4. **Feature Icons (SVG)**
   - Replace emoji icons with custom colored SVGs
   - Three styles needed: blue, green, purple
   - Affects home page and signup page

### Medium Priority

5. **Password Toggle (Eye Icon)**
   - Mockup shows eye icon for password visibility toggle
   - Common UX pattern, should be added
   - Requires minimal JavaScript

6. **Button Arrow Icon**
   - Mockup shows ">" arrow in primary buttons
   - Adds visual direction/affordance
   - Simple to add

7. **Glassmorphism Effect**
   - Mockup uses subtle glassmorphic cards
   - Current uses standard white cards
   - Nice-to-have enhancement

### Low Priority

8. **Navigation "무료 시작하기" Button**
   - Mockup may use purple gradient
   - Current uses solid blue
   - Check both mockup versions

9. **Gradient Text Effect**
   - Current uses `bg-clip-text` gradient
   - Good implementation, matches mockup

---

## 6. Responsive Design Considerations

**Not visible in mockups** (desktop only), but current implementation includes:
- Responsive grid systems: ✓
- Mobile-friendly navigation: ✓
- Responsive forms: ✓

**Recommendation**: Ensure mockup designs work well on mobile. Current Tailwind implementation likely handles this well.

---

## 7. Completion Percentages by Page

| Page | Visual Fidelity | Functional Completeness | Priority |
|------|----------------|------------------------|----------|
| **Home Page** | 80% | 95% | High |
| **Custom Sign In** | 70% | 90% | High |
| **Custom Sign Up** | 75% | 90% | High |
| **Devise Sign In** | 65% | 100% | Medium |
| **Devise Sign Up** | 20% | 100% | Low |

**Overall Project**: 72% visual fidelity to mockups

---

## 8. Brand Identity Issue

**Critical Finding**: Inconsistent branding between mockup pages

- **Home mockup**: "ExamsGraph" branding
- **Auth mockups**: "CertiGraph" branding

**Current implementation**: Uses "ExamsGraph" consistently

**Recommendation**:
1. Clarify with stakeholders: Is the brand "CertiGraph" or "ExamsGraph"?
2. Update all instances to match chosen brand
3. PRD mentions "Certi-Graph (AI 자격증 마스터)" - suggests "CertiGraph" is correct

**Decision needed**: Update codebase to "CertiGraph"?

---

## 9. Implementation Priority Matrix

### Phase 1: Critical Fixes (1-2 hours)
1. Resolve brand naming (CertiGraph vs ExamsGraph)
2. Create dark button component
3. Update Devise sign up view to match custom signup
4. Add arrow icons to primary buttons

### Phase 2: Visual Polish (2-3 hours)
5. Create/add custom logo SVG (blue brain icon)
6. Replace emoji feature icons with colored SVGs
7. Add "Secured by Clerk" badges (or equivalent security indicator)
8. Fine-tune color palette to match mockup

### Phase 3: UX Enhancements (1-2 hours)
9. Add password visibility toggle
10. Enhance glassmorphism effects
11. Refine button hover states
12. Add micro-animations

### Phase 4: Testing & QA (1 hour)
13. Cross-browser testing
14. Mobile responsiveness verification
15. Accessibility audit
16. Screenshot comparison with mockups

**Total Estimated Time**: 6-8 hours

---

## 10. Recommended Next Steps

### Immediate Actions

1. **Stakeholder Decision**: Confirm brand name (CertiGraph vs ExamsGraph)
2. **Asset Creation**: Design/source custom logo SVG and feature icons
3. **Component Library**: Create dark button and other missing components
4. **Devise Views**: Update or redirect to custom auth views

### Code Changes Required

**Files to Create:**
- `/app/views/shared/_logo.html.erb` - Reusable logo component
- `/app/views/shared/_dark_button.html.erb` - Dark button component
- `/app/views/shared/_security_badge.html.erb` - "Secured by" badge

**Files to Update:**
- `/app/views/devise/registrations/new.html.erb` - Complete redesign
- `/app/views/home/signin.html.erb` - Button color and arrow icon
- `/app/views/home/signup.html.erb` - Button color and eye icon
- `/app/views/home/index.html.erb` - Feature icons and button gradient
- `/app/views/shared/_navbar.html.erb` - Logo update
- `/app/views/layouts/application.html.erb` - Color variables update
- `/config/tailwind.config.js` - Add custom colors

**New CSS Needed:**
```css
/* Dark button variant */
.btn-dark {
  background: #2C2C2C;
  color: white;
  /* ... */
}

/* Glassmorphic card */
.glass-card-enhanced {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  /* ... */
}
```

---

## 11. Visual Comparison Summary

### Strengths of Current Implementation ✓
1. Clean, modern Tailwind CSS implementation
2. Good responsive structure
3. Google OAuth integration working
4. Strong layout hierarchy
5. Accessibility considerations (forms plugin)
6. Korean + English typography handled well

### Areas for Improvement ✗
1. Brand consistency (CertiGraph vs ExamsGraph)
2. Button color scheme (needs dark variant)
3. Icon system (emoji → custom SVG)
4. Missing security badge
5. Password visibility toggle
6. Color palette alignment with mockup

---

## 12. Conclusion

The current implementation demonstrates **strong foundational work** with good structure and functionality. The gap analysis reveals that most discrepancies are **cosmetic refinements** rather than structural issues.

**Key Success Factors:**
- Tailwind CSS provides excellent foundation for rapid iteration
- Custom views for auth pages show design intention
- Layout structure closely matches mockup

**Primary Blockers:**
- Brand name decision required
- Custom assets needed (logo, icons)
- Dark button component missing

**Recommendation**: Proceed with Phase 1 and 2 improvements to achieve 90%+ visual fidelity. The work is well-structured and only needs polish to match the mockup exactly.

---

**Document Version**: 1.0
**Last Updated**: 2026-01-15
**Next Review**: After Phase 1 completion
