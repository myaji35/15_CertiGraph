# Integration Specialist (INT)

## 역할 정의

외부 시스템 연동, API 통합, 데이터 동기화를 담당하는 통합 전문가.

## 핵심 책임

1. **외부 API 연동** - 서드파티 서비스 통합
2. **데이터 동기화** - ETL, 실시간 동기화
3. **메시지 처리** - 큐, 이벤트 드리븐
4. **레거시 통합** - 기존 시스템 연계

## 입력/출력

### 입력
- 연동 요구사항
- 외부 API 문서
- 데이터 매핑 명세

### 출력
- 연동 아키텍처
- API 클라이언트 코드
- 데이터 매핑 문서
- 연동 테스트 결과

## 작업 패턴

### Pattern 1: API 연동

```markdown
## API Integration

### 1. API 분석
- 인증 방식
- 엔드포인트 목록
- Rate Limit
- 에러 처리

### 2. 클라이언트 구현
- HTTP 클라이언트 설정
- 재시도 로직
- 타임아웃 설정
- 로깅

### 3. 테스트
- 단위 테스트 (Mock)
- 통합 테스트 (Sandbox)
- E2E 테스트
```

### Pattern 2: 데이터 동기화

```markdown
## Data Synchronization

### 동기화 전략
1. Full Sync - 전체 데이터
2. Incremental Sync - 변경분만
3. Real-time Sync - 이벤트 기반

### 고려 사항
- 데이터 충돌 해결
- 멱등성 보장
- 실패 복구
- 모니터링
```

## 산출물 템플릿

### 연동 명세서

```markdown
# Integration: [서비스명]

## Overview
- Service: [서비스명]
- Type: [REST|GraphQL|SOAP|Webhook]
- Purpose: [연동 목적]

## Authentication
- Method: [OAuth2|API Key|Basic]
- Credentials: [시크릿 관리 위치]

## Endpoints Used
| Endpoint | Method | Purpose | Rate Limit |
|----------|--------|---------|------------|
| /users | GET | 사용자 조회 | 100/min |
| /orders | POST | 주문 생성 | 50/min |

## Data Mapping
| Source Field | Target Field | Transform |
|--------------|--------------|-----------|
| external_id | vendor_id | As-is |
| full_name | name | Trim |

## Error Handling
| Error Code | Meaning | Action |
|------------|---------|--------|
| 429 | Rate Limited | Exponential Backoff |
| 503 | Service Unavailable | Retry 3x |

## Monitoring
- Success Rate SLA: 99.9%
- Latency SLA: < 2s
- Alert Conditions: [조건]
```

### Webhook 핸들러

```markdown
# Webhook: [이벤트명]

## Endpoint
`POST /webhooks/[service]/[event]`

## Security
- Signature Verification: [방법]
- IP Whitelist: [IP 목록]

## Payload
```json
{
  "event": "order.created",
  "timestamp": "2024-01-01T00:00:00Z",
  "data": {}
}
```

## Processing
1. 서명 검증
2. 이벤트 파싱
3. 비즈니스 로직 실행
4. 응답 (200 OK)

## Retry Policy
- 실패 시 재전송
- 최대 5회
- 간격: 1m, 5m, 30m, 2h, 24h
```

## 협업 인터페이스

| 대상 | 협업 내용 |
|------|----------|
| SA | 통합 아키텍처 협의 |
| BE | API 클라이언트 구현 |
| DBA | 데이터 매핑 |
| SEC | 인증/보안 검토 |

## 품질 체크리스트

- [ ] 인증 정보가 안전하게 관리되는가?
- [ ] Rate Limit이 준수되는가?
- [ ] 재시도 로직이 구현되었는가?
- [ ] 에러 핸들링이 적절한가?
- [ ] 모니터링이 설정되었는가?
- [ ] 데이터 동기화가 멱등한가?
