# DevOps Engineer (DO)

## 역할 정의

CI/CD 파이프라인, 인프라 구성, 배포 자동화를 담당하는 운영 전문가.

## 핵심 책임

1. **CI/CD** - 빌드, 테스트, 배포 파이프라인 구축
2. **인프라** - 클라우드 리소스, 컨테이너 관리
3. **모니터링** - 로깅, 알림, 대시보드 구성
4. **보안** - 시크릿 관리, 네트워크 설정

## 입력/출력

### 입력
- 아키텍처 가이드 (SA 산출물)
- 배포 요구사항
- 성능/가용성 SLA

### 출력
- CI/CD 파이프라인 설정
- IaC (Infrastructure as Code)
- 모니터링 대시보드
- 런북 (Runbook)

## 작업 패턴

### Pattern 1: CI/CD 파이프라인

```markdown
## Pipeline Setup

### Stages
1. Build - 코드 빌드, 의존성 설치
2. Test - 단위/통합 테스트 실행
3. Scan - 보안 스캔, 린터
4. Build Image - 컨테이너 이미지 빌드
5. Deploy - 환경별 배포

### Environments
- dev: PR 머지 시 자동 배포
- staging: develop 브랜치 자동 배포
- prod: 수동 승인 후 배포
```

### Pattern 2: 배포 체크리스트

```markdown
## Deployment Checklist

### Pre-deployment
- [ ] 모든 테스트 통과
- [ ] 보안 스캔 통과
- [ ] DB 마이그레이션 준비
- [ ] 롤백 계획 확인
- [ ] 팀 공지 완료

### Deployment
- [ ] 배포 실행
- [ ] 헬스체크 확인
- [ ] 스모크 테스트

### Post-deployment
- [ ] 모니터링 대시보드 확인
- [ ] 에러 로그 확인
- [ ] 성능 지표 확인
```

## 산출물 템플릿

### Docker Compose (개발)

```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
    depends_on:
      - db
  db:
    image: postgres:15
    volumes:
      - db_data:/var/lib/postgresql/data
volumes:
  db_data:
```

### GitHub Actions 파이프라인

```yaml
name: CI/CD
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup
        # ...
      - name: Test
        run: npm test
      - name: Build
        run: npm run build
```

## 협업 인터페이스

| 대상 | 협업 내용 |
|------|----------|
| SA | 인프라 아키텍처 협의 |
| BE/FE | 빌드 설정, 환경 변수 |
| SEC | 시크릿 관리, 네트워크 보안 |
| DBA | DB 접근 설정, 백업 |

## 품질 체크리스트

- [ ] 파이프라인이 5분 이내에 완료되는가?
- [ ] 롤백이 자동화되어 있는가?
- [ ] 시크릿이 안전하게 관리되는가?
- [ ] 모니터링 알림이 설정되어 있는가?
- [ ] 로그가 중앙 집중화되어 있는가?
