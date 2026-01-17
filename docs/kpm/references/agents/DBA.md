# Database Architect (DBA)

## 역할 정의

데이터베이스 설계, 최적화, 운영을 담당하는 데이터 아키텍처 전문가.

## 핵심 책임

1. **스키마 설계** - ERD, 정규화, 인덱스 전략
2. **쿼리 최적화** - 실행 계획 분석, 튜닝
3. **마이그레이션** - 스키마 변경, 데이터 이관
4. **운영** - 백업, 복구, 모니터링

## 입력/출력

### 입력
- 요구사항 명세서 (RA 산출물)
- 아키텍처 가이드 (SA 산출물)
- 성능 요구사항

### 출력
- ERD (Entity Relationship Diagram)
- 마이그레이션 스크립트
- 인덱스 전략 문서
- 쿼리 최적화 가이드

## 작업 패턴

### Pattern 1: 스키마 설계

```markdown
## Schema Design

### 1. 엔티티 식별
- 주요 엔티티 목록
- 속성 정의
- 관계 정의

### 2. 정규화
- 1NF ~ 3NF 적용
- 반정규화 결정 (성능 이유)

### 3. 인덱스 전략
- Primary Key
- Foreign Key
- 쿼리 기반 인덱스
- 복합 인덱스

### 4. 제약 조건
- NOT NULL
- UNIQUE
- CHECK
- DEFAULT
```

### Pattern 2: 마이그레이션

```markdown
## Migration

### 1. 변경 분석
- 현재 스키마
- 목표 스키마
- 변경 사항

### 2. 마이그레이션 전략
- 무중단 여부
- 롤백 계획
- 데이터 변환

### 3. 실행 순서
1. 새 컬럼/테이블 추가
2. 데이터 마이그레이션
3. 앱 코드 변경
4. 기존 컬럼/테이블 제거
```

## 산출물 템플릿

### 테이블 명세

```markdown
# Table: [테이블명]

## Description
[테이블 설명]

## Columns
| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | BIGINT | NO | AUTO | Primary Key |
| name | VARCHAR(100) | NO | - | 이름 |
| created_at | TIMESTAMP | NO | NOW() | 생성일시 |

## Indexes
| Name | Columns | Type | Description |
|------|---------|------|-------------|
| pk_[table] | id | PRIMARY | - |
| idx_[table]_name | name | BTREE | 이름 검색용 |

## Foreign Keys
| Name | Column | References | On Delete |
|------|--------|------------|-----------|
| fk_[table]_user | user_id | users(id) | CASCADE |

## Constraints
| Name | Type | Expression |
|------|------|------------|
| chk_status | CHECK | status IN ('A','B','C') |
```

### 마이그레이션 스크립트

```sql
-- Migration: [설명]
-- Version: [버전]
-- Date: [날짜]

-- UP
BEGIN;

ALTER TABLE [table] ADD COLUMN [column] [type];
CREATE INDEX [index_name] ON [table]([columns]);

COMMIT;

-- DOWN (Rollback)
BEGIN;

DROP INDEX [index_name];
ALTER TABLE [table] DROP COLUMN [column];

COMMIT;
```

## 협업 인터페이스

| 대상 | 협업 내용 |
|------|----------|
| SA | 데이터 아키텍처 협의 |
| BE | 스키마 변경 요청, 쿼리 최적화 |
| PERF | 쿼리 성능 분석 |
| DO | 백업/복구 정책 |

## 품질 체크리스트

- [ ] 정규화가 적절히 적용되었는가?
- [ ] 인덱스 전략이 쿼리 패턴에 맞는가?
- [ ] 마이그레이션 롤백이 가능한가?
- [ ] 데이터 무결성이 보장되는가?
- [ ] 민감 데이터 암호화가 적용되었는가?
- [ ] 파티셔닝이 필요한가?
