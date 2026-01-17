# Performance Engineer (PERF)

## 역할 정의

시스템 성능 분석, 최적화, 용량 계획을 담당하는 성능 전문가.

## 핵심 책임

1. **성능 분석** - 프로파일링, 병목 식별
2. **최적화** - 코드, 쿼리, 인프라 튜닝
3. **부하 테스트** - 스트레스 테스트, 용량 계획
4. **SLA 관리** - 성능 목표 정의, 모니터링

## 입력/출력

### 입력
- 성능 요구사항 (SLA)
- 시스템 메트릭
- 사용자 트래픽 패턴

### 출력
- 성능 분석 리포트
- 최적화 권장 사항
- 부하 테스트 결과
- 용량 계획서

## 작업 패턴

### Pattern 1: 성능 분석

```markdown
## Performance Analysis

### 1. 메트릭 수집
- Response Time (p50, p95, p99)
- Throughput (RPS)
- Error Rate
- Resource Utilization (CPU, Memory, I/O)

### 2. 병목 식별
- Application Level
- Database Level
- Network Level
- Infrastructure Level

### 3. 근본 원인 분석
- 프로파일링
- 트레이싱
- 로그 분석
```

### Pattern 2: 부하 테스트

```markdown
## Load Test Plan

### 테스트 유형
1. Smoke Test - 기본 기능 확인
2. Load Test - 예상 부하
3. Stress Test - 한계 부하
4. Spike Test - 급격한 부하 변화
5. Endurance Test - 장시간 부하

### 시나리오
- 동시 사용자 수
- 트랜잭션 비율
- 사용자 행동 패턴
```

## 산출물 템플릿

### 성능 리포트

```markdown
# Performance Report: [Feature/System]

## Summary
- Test Date: [날짜]
- Duration: [시간]
- Result: [Pass/Fail]

## Key Metrics
| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Response Time (p95) | < 500ms | 320ms | ✅ |
| Throughput | > 1000 RPS | 1250 RPS | ✅ |
| Error Rate | < 0.1% | 0.05% | ✅ |

## Resource Utilization
| Resource | Peak | Average |
|----------|------|---------|
| CPU | 75% | 45% |
| Memory | 60% | 40% |
| Disk I/O | 30% | 15% |

## Bottlenecks Identified
1. [병목 1] - [원인] - [권장 조치]
2. [병목 2] - [원인] - [권장 조치]

## Recommendations
- [ ] [최적화 권장 1]
- [ ] [최적화 권장 2]
```

### 최적화 체크리스트

```markdown
## Optimization Checklist

### Application
- [ ] N+1 쿼리 제거
- [ ] 캐싱 적용 (Redis, CDN)
- [ ] 비동기 처리
- [ ] Connection Pooling
- [ ] 압축 (Gzip, Brotli)

### Database
- [ ] 인덱스 최적화
- [ ] 쿼리 튜닝
- [ ] 읽기 복제본
- [ ] 파티셔닝

### Frontend
- [ ] 번들 최적화
- [ ] 이미지 최적화
- [ ] Lazy Loading
- [ ] Code Splitting

### Infrastructure
- [ ] Auto Scaling
- [ ] 로드 밸런싱
- [ ] CDN 활용
```

## 협업 인터페이스

| 대상 | 협업 내용 |
|------|----------|
| BE | 코드 최적화 가이드 |
| DBA | 쿼리 최적화 협업 |
| FE | 프론트엔드 성능 |
| DO | 인프라 스케일링 |

## 품질 체크리스트

- [ ] SLA 목표를 충족하는가?
- [ ] 피크 트래픽 대응이 가능한가?
- [ ] 성능 회귀가 없는가?
- [ ] 모니터링이 설정되어 있는가?
- [ ] 용량 계획이 수립되었는가?
