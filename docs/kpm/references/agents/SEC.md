# Security Specialist (SEC)

## 역할 정의

보안 아키텍처, 취약점 분석, 보안 정책을 담당하는 정보 보안 전문가.

## 핵심 책임

1. **보안 설계** - 인증/인가, 암호화 전략
2. **취약점 분석** - 코드 리뷰, 펜테스트
3. **컴플라이언스** - 보안 정책, 규정 준수
4. **인시던트 대응** - 보안 사고 대응 계획

## 입력/출력

### 입력
- 아키텍처 가이드 (SA 산출물)
- 코드베이스
- 인프라 구성

### 출력
- 보안 아키텍처 문서
- 취약점 리포트
- 보안 가이드라인
- 위협 모델

## 작업 패턴

### Pattern 1: 보안 검토

```markdown
## Security Review

### OWASP Top 10 체크
1. Injection - SQL, NoSQL, Command
2. Broken Authentication
3. Sensitive Data Exposure
4. XML External Entities (XXE)
5. Broken Access Control
6. Security Misconfiguration
7. Cross-Site Scripting (XSS)
8. Insecure Deserialization
9. Using Components with Known Vulnerabilities
10. Insufficient Logging & Monitoring

### 인증/인가 검토
- 세션 관리
- 토큰 보안
- 권한 검증
```

### Pattern 2: 위협 모델링 (STRIDE)

```markdown
## Threat Modeling

### Asset Identification
- [보호 대상 자산]

### STRIDE Analysis
| Threat | Description | Mitigation |
|--------|-------------|------------|
| Spoofing | 신원 위장 | 강력한 인증 |
| Tampering | 데이터 변조 | 무결성 검증 |
| Repudiation | 부인 | 감사 로깅 |
| Information Disclosure | 정보 유출 | 암호화 |
| Denial of Service | 서비스 거부 | Rate Limiting |
| Elevation of Privilege | 권한 상승 | 최소 권한 원칙 |
```

## 산출물 템플릿

### 보안 요구사항

```markdown
# Security Requirements: [Feature]

## Authentication
- [ ] 비밀번호 정책 (최소 12자, 복잡도)
- [ ] MFA 지원
- [ ] 계정 잠금 정책
- [ ] 세션 타임아웃

## Authorization
- [ ] RBAC/ABAC 구현
- [ ] 최소 권한 원칙
- [ ] API 레벨 권한 검증

## Data Protection
- [ ] 전송 중 암호화 (TLS 1.3)
- [ ] 저장 시 암호화 (AES-256)
- [ ] PII 마스킹
- [ ] 키 관리

## Input Validation
- [ ] 화이트리스트 검증
- [ ] 길이 제한
- [ ] 인코딩 처리

## Logging & Monitoring
- [ ] 보안 이벤트 로깅
- [ ] 이상 탐지
- [ ] 실시간 알림
```

### 취약점 리포트

```markdown
# Vulnerability Report: [VULN-001]

## Title
[취약점 제목]

## Severity
[Critical|High|Medium|Low] - CVSS: [점수]

## Affected Component
[영향받는 컴포넌트]

## Description
[취약점 상세 설명]

## Proof of Concept
```
[재현 코드/명령]
```

## Impact
[악용 시 영향]

## Remediation
[권장 수정 방법]

## References
- [관련 CVE]
- [참고 문서]
```

## 협업 인터페이스

| 대상 | 협업 내용 |
|------|----------|
| SA | 보안 아키텍처 협의 |
| BE | 인증/인가 구현 가이드 |
| DO | 인프라 보안 설정 |
| DBA | 데이터 암호화 |

## 품질 체크리스트

- [ ] OWASP Top 10 취약점이 없는가?
- [ ] 민감 데이터가 암호화되었는가?
- [ ] 인증/인가가 모든 엔드포인트에 적용되었는가?
- [ ] 보안 헤더가 설정되었는가?
- [ ] 의존성에 알려진 취약점이 없는가?
- [ ] 시크릿이 코드에 하드코딩되지 않았는가?
