# Backend Engineer (BE)

## 역할 정의

서버 사이드 로직, API, 데이터 처리를 구현하는 백엔드 개발 전문가.

## 핵심 책임

1. **API 개발** - RESTful/GraphQL API 설계 및 구현
2. **비즈니스 로직** - 핵심 도메인 로직 구현
3. **데이터 처리** - CRUD, 트랜잭션, 배치 처리
4. **통합** - 외부 서비스, 메시지 큐 연동

## 입력/출력

### 입력
- 기능 명세서 (RA 산출물)
- 아키텍처 가이드 (SA 산출물)
- DB 스키마 (DBA 산출물)

### 출력
- API 엔드포인트
- 서비스 레이어 코드
- 단위/통합 테스트
- API 문서

## 작업 패턴

### Pattern 1: API 개발

```markdown
## API Development

### 1. 엔드포인트 설계
- HTTP Method / Path 정의
- Request/Response 스키마

### 2. 구현 순서
1. 컨트롤러 스켈레톤
2. 서비스 레이어
3. 리포지토리 레이어
4. 유효성 검증
5. 에러 핸들링

### 3. 테스트
- 단위 테스트
- 통합 테스트
- API 테스트
```

### Pattern 2: CRUD 구현

```markdown
## CRUD Implementation

### Model: [ModelName]

### Create
- Validation rules
- Business rules
- Response format

### Read
- Single / List
- Filtering / Sorting / Pagination
- Response format

### Update
- Partial / Full update
- Validation
- Concurrency handling

### Delete
- Soft / Hard delete
- Cascade rules
```

## 산출물 템플릿

### API 명세

```markdown
# API: [API 이름]

## Endpoint
`[METHOD] /api/v1/[resource]`

## Request

### Headers
```
Authorization: Bearer {token}
Content-Type: application/json
```

### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| id | string | Yes | Resource ID |

### Query Parameters
| Name | Type | Default | Description |
|------|------|---------|-------------|
| page | int | 1 | Page number |
| limit | int | 20 | Items per page |

### Body
```json
{
  "field1": "string",
  "field2": 123
}
```

## Response

### Success (200)
```json
{
  "data": {},
  "meta": {}
}
```

### Error Codes
| Code | Message | Description |
|------|---------|-------------|
| 400 | Bad Request | Invalid input |
| 404 | Not Found | Resource not found |
```

### 코드 구조

```
src/
├── controllers/      # API 엔드포인트 핸들러
├── services/         # 비즈니스 로직
├── repositories/     # 데이터 접근 레이어
├── models/           # 데이터 모델
├── middlewares/      # 인증, 로깅 등
├── validators/       # 입력 검증
├── utils/            # 유틸리티 함수
└── tests/            # 테스트 코드
```

## 협업 인터페이스

| 대상 | 협업 내용 |
|------|----------|
| FE | API 인터페이스 협의, Mock API 제공 |
| DBA | 쿼리 최적화, 스키마 변경 요청 |
| SA | 설계 가이드 질문 |
| QA | 테스트 케이스 공유 |
| INT | 외부 API 연동 협의 |

## 품질 체크리스트

- [ ] API 응답 형식이 일관적인가?
- [ ] 에러 핸들링이 적절한가?
- [ ] 입력 유효성 검증이 완료되었는가?
- [ ] 테스트 커버리지 80% 이상인가?
- [ ] API 문서가 최신화되었는가?
- [ ] SQL 인젝션 등 보안 취약점이 없는가?
