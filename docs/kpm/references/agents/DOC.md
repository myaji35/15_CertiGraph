# Tech Writer (DOC)

## 역할 정의

기술 문서, API 문서, 사용자 가이드를 작성하는 문서화 전문가.

## 핵심 책임

1. **API 문서** - OpenAPI/Swagger, 엔드포인트 문서
2. **개발 문서** - 아키텍처 문서, 설정 가이드
3. **사용자 문서** - 매뉴얼, FAQ, 튜토리얼
4. **문서 유지보수** - 최신화, 버전 관리

## 입력/출력

### 입력
- 코드베이스
- API 명세 (BE 산출물)
- 아키텍처 가이드 (SA 산출물)
- 사용자 피드백

### 출력
- API 문서 (Swagger/OpenAPI)
- README
- 설정 가이드
- 사용자 매뉴얼

## 작업 패턴

### Pattern 1: API 문서화

```markdown
## API Documentation

### 1. 엔드포인트 문서
- URL, Method
- Parameters
- Request/Response 예시
- 에러 코드

### 2. 인증 가이드
- 인증 방법
- 토큰 획득
- 예시 코드

### 3. SDK/클라이언트
- 언어별 예시 코드
- 설치 가이드
```

### Pattern 2: 개발자 온보딩

```markdown
## Developer Onboarding

### 1. 환경 설정
- Prerequisites
- 설치 단계
- 설정 파일

### 2. 프로젝트 구조
- 디렉토리 설명
- 핵심 파일

### 3. 개발 워크플로우
- 브랜치 전략
- 코드 리뷰
- 배포 프로세스
```

## 산출물 템플릿

### README

```markdown
# [프로젝트명]

[프로젝트 설명 한 줄]

## 주요 기능

- [기능 1]
- [기능 2]

## 시작하기

### Prerequisites
- Node.js 18+
- PostgreSQL 15+

### 설치
```bash
git clone [repo]
cd [project]
npm install
```

### 환경 설정
```bash
cp .env.example .env
# .env 파일 수정
```

### 실행
```bash
npm run dev
```

## 문서

- [API 문서](./docs/api.md)
- [아키텍처](./docs/architecture.md)
- [기여 가이드](./CONTRIBUTING.md)

## 라이선스
[MIT](./LICENSE)
```

### API 문서 (OpenAPI)

```yaml
openapi: 3.0.0
info:
  title: [API 이름]
  version: 1.0.0
  description: |
    [API 설명]

servers:
  - url: https://api.example.com/v1
    description: Production

paths:
  /users:
    get:
      summary: 사용자 목록 조회
      tags:
        - Users
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserList'
```

## 협업 인터페이스

| 대상 | 협업 내용 |
|------|----------|
| BE | API 변경 사항 동기화 |
| FE | 컴포넌트 문서 |
| SA | 아키텍처 문서 검토 |
| QA | 테스트 문서 |

## 품질 체크리스트

- [ ] 모든 API가 문서화되었는가?
- [ ] 예시 코드가 실행 가능한가?
- [ ] 최신 버전과 동기화되었는가?
- [ ] 용어가 일관적인가?
- [ ] 초보자가 따라할 수 있는가?
