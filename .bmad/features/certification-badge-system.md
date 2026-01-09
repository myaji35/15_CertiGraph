# Feature: Certification Badge System

## Overview
GitHub README 프로필의 "Tech Stack" 뱃지와 유사한 자격증 뱃지 시스템을 구현합니다. 사용자가 취득한 자격증을 시각적으로 표시하여 GitHub 프로필이나 개인 블로그, LinkedIn 등에 임베드할 수 있습니다.

## User Story
**AS A** 자격증 취득자
**I WANT** 내가 취득한 자격증을 뱃지 형태로 프로필에 표시하고 싶다
**SO THAT** 나의 전문성과 자격을 시각적으로 효과적으로 어필할 수 있다

## Business Value
- **차별화**: 자격증 정보를 단순 텍스트가 아닌 시각적 뱃지로 표현
- **공유성**: Markdown, HTML 임베드로 다양한 플랫폼에서 사용 가능
- **브랜딩**: CertiGraph 플랫폼 자체의 인지도 향상 (뱃지에 플랫폼 링크 포함)
- **바이럴**: 사용자가 뱃지를 공유할수록 플랫폼 트래픽 증가

## Feature Requirements

### FR-1: Badge Design System
자격증별로 고유한 아이콘, 색상, 디자인을 가진 뱃지 시스템

**Acceptance Criteria:**
- [ ] 각 자격증에 고유한 아이콘/이모지 매핑
- [ ] 자격증 카테고리별 색상 체계
  - 국가기술자격: 파란색 계열 (#2563EB - Blue-600)
  - 국가전문자격: 녹색 계열 (#16A34A - Green-600)
  - 민간자격: 보라색 계열 (#9333EA - Purple-600)
  - 국제자격: 주황색 계열 (#EA580C - Orange-600)
- [ ] 뱃지에 표시할 정보:
  - 자격증명 (약칭 가능)
  - 취득년도
  - 자격증 아이콘/이모지
  - CertiGraph 로고/링크 (옵션)

### FR-2: Badge Generation API
동적으로 SVG 뱃지를 생성하는 백엔드 API

**Endpoint:** `GET /api/v1/badges/certification/{cert_id}`

**Query Parameters:**
- `year`: 취득년도 (필수)
- `style`: 뱃지 스타일 (flat, flat-square, for-the-badge, plastic) - 기본값: flat
- `label`: 커스텀 라벨 (옵션)
- `logo`: 로고 표시 여부 (true/false) - 기본값: true
- `theme`: 색상 테마 (default, dark, light) - 기본값: default

**Response:** SVG 이미지 (Content-Type: image/svg+xml)

**Acceptance Criteria:**
- [ ] SVG 형식으로 뱃지 생성
- [ ] Shields.io API 스타일 호환
- [ ] 캐싱 헤더 설정 (1일)
- [ ] 에러 처리 (404: 자격증 없음, 400: 잘못된 파라미터)

### FR-3: Badge Gallery & Code Generator
사용자가 취득한 자격증 뱃지를 한눈에 보고 코드를 복사할 수 있는 페이지

**Page:** `/profile/badges` (대시보드 내)

**Acceptance Criteria:**
- [ ] 사용자가 취득한 자격증 목록 표시
- [ ] 각 자격증별 뱃지 미리보기
- [ ] Markdown 코드 생성 및 복사 기능
- [ ] HTML 코드 생성 및 복사 기능
- [ ] 뱃지 스타일 커스터마이징 옵션
- [ ] "전체 뱃지 코드 복사" 기능 (모든 자격증 한 번에)

### FR-4: Certification Record Management
사용자가 자신의 자격증 취득 기록을 등록/관리하는 기능

**Acceptance Criteria:**
- [ ] 자격증 취득 기록 등록 폼
  - 자격증 선택 (드롭다운)
  - 취득년도 입력
  - 자격증 번호 (옵션)
  - 증빙 파일 업로드 (옵션)
- [ ] 취득 기록 목록 조회
- [ ] 취득 기록 수정/삭제
- [ ] 공개/비공개 설정 (뱃지 생성 가능 여부)

## Technical Specifications

### Badge Icon Mapping
```yaml
certifications:
  정보처리기사:
    icon: "💻"
    short_name: "정처기"
    category: national_professional

  정보처리산업기사:
    icon: "🖥️"
    short_name: "정처산기"
    category: national_professional

  빅데이터분석기사:
    icon: "📊"
    short_name: "빅분기"
    category: national_professional

  SQL개발자:
    icon: "🗄️"
    short_name: "SQLD"
    category: private

  네트워크관리사2급:
    icon: "🌐"
    short_name: "네관사2급"
    category: private

  리눅스마스터2급:
    icon: "🐧"
    short_name: "리마2급"
    category: private

  컴퓨터활용능력1급:
    icon: "📄"
    short_name: "컴활1급"
    category: national_professional

  워드프로세서:
    icon: "📝"
    short_name: "워드"
    category: national_professional
```

### Badge SVG Template Structure
```xml
<svg xmlns="http://www.w3.org/2000/svg" width="200" height="28">
  <!-- Background -->
  <rect width="200" height="28" fill="{category_color}" rx="4"/>

  <!-- Icon Section -->
  <g>
    <text x="10" y="18" font-size="16">{icon}</text>
  </g>

  <!-- Label Section -->
  <g>
    <text x="40" y="18" fill="white" font-family="Arial" font-size="12" font-weight="600">
      {cert_name}
    </text>
  </g>

  <!-- Year Section -->
  <g>
    <rect x="150" y="0" width="50" height="28" fill="rgba(0,0,0,0.2)"/>
    <text x="165" y="18" fill="white" font-family="Arial" font-size="11">
      {year}
    </text>
  </g>
</svg>
```

### Database Schema Updates
```sql
-- 사용자 자격증 취득 기록 테이블
CREATE TABLE user_certifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    certification_id VARCHAR(100) NOT NULL,
    acquired_year INTEGER NOT NULL CHECK (acquired_year >= 1900 AND acquired_year <= 2100),
    certificate_number VARCHAR(100),  -- 자격증 번호 (옵션)
    proof_file_url TEXT,              -- 증빙 파일 URL (옵션)
    is_public BOOLEAN DEFAULT true,   -- 뱃지 공개 여부
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(user_id, certification_id, acquired_year)
);

-- 인덱스
CREATE INDEX idx_user_certifications_user_id ON user_certifications(user_id);
CREATE INDEX idx_user_certifications_certification_id ON user_certifications(certification_id);
CREATE INDEX idx_user_certifications_public ON user_certifications(is_public) WHERE is_public = true;
```

## API Endpoints

### 1. Badge Generation API
```
GET /api/v1/badges/certification/{cert_id}?year={year}&style={style}&theme={theme}
```

**Response:**
- Content-Type: image/svg+xml
- Cache-Control: public, max-age=86400

### 2. User Certification CRUD
```
POST   /api/v1/user/certifications          # 자격증 취득 기록 등록
GET    /api/v1/user/certifications          # 내 자격증 목록 조회
GET    /api/v1/user/certifications/{id}     # 특정 자격증 상세
PUT    /api/v1/user/certifications/{id}     # 자격증 정보 수정
DELETE /api/v1/user/certifications/{id}     # 자격증 삭제
```

### 3. Public Badge Profile
```
GET /api/v1/users/{user_id}/certifications/badges   # 공개 뱃지 목록
GET /api/v1/badges/user/{user_id}/all              # 사용자의 모든 뱃지 (SVG 배열)
```

## Frontend Components

### BadgeGallery Component
```tsx
interface BadgeGalleryProps {
  certifications: UserCertification[];
  onCopyCode?: (code: string) => void;
}

export function BadgeGallery({ certifications, onCopyCode }: BadgeGalleryProps) {
  // 뱃지 미리보기 및 코드 생성 UI
}
```

### BadgeCodeGenerator Component
```tsx
interface BadgeCodeGeneratorProps {
  certification: UserCertification;
  style?: BadgeStyle;
  theme?: BadgeTheme;
}

export function BadgeCodeGenerator({ certification, style, theme }: BadgeCodeGeneratorProps) {
  // Markdown/HTML 코드 생성 및 복사
}
```

### CertificationRecordForm Component
```tsx
interface CertificationRecordFormProps {
  onSubmit: (data: CertificationRecordInput) => Promise<void>;
  initialData?: UserCertification;
}

export function CertificationRecordForm({ onSubmit, initialData }: CertificationRecordFormProps) {
  // 자격증 취득 기록 등록/수정 폼
}
```

## Implementation Phases

### Phase 1: Backend Infrastructure (Priority: High)
- [ ] Badge icon mapping configuration 파일 생성
- [ ] SVG badge generator 서비스 구현
- [ ] Badge generation API 엔드포인트 구현
- [ ] User certifications 데이터 모델 정의
- [ ] CRUD API 엔드포인트 구현

### Phase 2: Frontend UI (Priority: High)
- [ ] Badge Gallery 페이지 구현
- [ ] Badge Code Generator 컴포넌트
- [ ] Certification Record Form 구현
- [ ] 대시보드에 "내 자격증 뱃지" 섹션 추가

### Phase 3: Advanced Features (Priority: Medium)
- [ ] 뱃지 스타일 커스터마이징 (flat, plastic, for-the-badge 등)
- [ ] 다크모드 테마 지원
- [ ] 뱃지 클릭 시 CertiGraph 프로필 페이지로 연결
- [ ] 소셜 공유 기능 (Twitter, LinkedIn 원클릭 공유)

### Phase 4: Analytics & Optimization (Priority: Low)
- [ ] 뱃지 조회수 트래킹
- [ ] 인기 뱃지 통계
- [ ] CDN 캐싱 최적화
- [ ] 뱃지 이미지 프리로딩

## Success Metrics
- 월간 뱃지 생성 수
- 뱃지를 통한 CertiGraph 유입 트래픽
- 사용자 자격증 등록 완료율
- 뱃지 공유 빈도 (GitHub, LinkedIn, 블로그 등)

## Technical Risks & Mitigation
1. **Risk:** SVG 렌더링 성능 이슈
   - **Mitigation:** CDN 캐싱, 사전 생성된 뱃지 캐시

2. **Risk:** 자격증 위조/허위 등록
   - **Mitigation:** 증빙 파일 업로드 옵션, 관리자 검증 시스템

3. **Risk:** 뱃지 이미지 hotlinking으로 인한 서버 부하
   - **Mitigation:** Referer 체크, Rate limiting, CDN 사용

## Related Documentation
- [GitHub Badges Best Practices](https://shields.io/)
- [SVG Badge Design Patterns](https://github.com/badges/shields)
- [Markdown Badge Examples](https://github.com/Ileriayo/markdown-badges)

## Change Log
| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2026-01-06 | 1.0 | Initial feature specification | Claude Code |
