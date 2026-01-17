# 자격증 데이터 수집 스크립트

## 개요

HRD Korea (한국산업인력공단) 공공 API를 통해 **전체 국가기술자격증** 데이터를 수집하는 스크립트입니다.

## 왜 필요한가?

현재 코드베이스에는 IT 관련 자격증 6개만 Mock 데이터로 들어있습니다:
- 정보처리기사
- 정보처리산업기사
- 빅데이터분석기사
- SQL개발자(SQLD)
- 네트워크관리사 2급
- 리눅스마스터 2급

**하지만 실제 국가기술자격증은 500개 이상**입니다!

이 스크립트로 전체 자격증 데이터를 한번에 구축할 수 있습니다.

## 사전 준비

### 1. HRD Korea API 키 발급

1. [공공데이터포털](https://www.data.go.kr) 접속
2. 회원가입 및 로그인
3. 검색: "한국산업인력공단_국가기술자격 시험일정 정보"
4. 활용신청 → 일반 인증키(Encoding) 발급
5. 발급받은 API 키 복사

### 2. 환경 변수 설정

```bash
# .env 파일에 추가 또는 export 명령 사용
export HRDKOREA_API_KEY='발급받은실제API키'
```

### 3. 데이터베이스 테이블 확인

Supabase에 다음 테이블이 있어야 합니다:

**certifications** 테이블:
```sql
CREATE TABLE certifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  category TEXT,
  series TEXT,
  institution TEXT,
  difficulty TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**exam_schedules** 테이블:
```sql
CREATE TABLE exam_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  certification_name TEXT NOT NULL,
  exam_type TEXT,
  application_start DATE,
  application_end DATE,
  exam_date DATE,
  result_date DATE,
  year INTEGER,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(certification_name, exam_date, exam_type)
);
```

## 사용법

```bash
# 프로젝트 루트에서 실행
cd backend

# 가상환경 활성화
source ../.venv/bin/activate

# 스크립트 실행
python scripts/fetch_all_certifications.py
```

## 실행 결과

스크립트가 성공적으로 실행되면:

```
================================================================================
국가기술자격 전체 데이터 수집 시작
================================================================================

[1/3] 전체 자격증 종목 목록 조회 중...
✅ 총 532개 자격증 종목 발견

📊 분류별 자격증 수:
  • 정보통신: 45개
  • 건축: 82개
  • 기계: 67개
  • 전기전자: 53개
  ...

[2/3] 데이터베이스에 자격증 목록 저장 중...
  • 1~532 저장 완료
✅ 총 532개 자격증 정보 저장 완료

[3/3] 시험일정 데이터 수집 중...
  📅 2025년 시험일정 조회 중...
  ✅ 2025년: 1,247건의 시험일정 발견
  📅 2026년 시험일정 조회 중...
  ✅ 2026년: 1,189건의 시험일정 발견

💾 총 2,436건의 시험일정 저장 중...
✅ 시험일정 저장 완료

================================================================================
📊 데이터 수집 완료 요약
================================================================================
✅ 자격증 종목: 532개
✅ 시험일정: 2,436건
✅ 수집 시간: 2026-01-07 14:23:45

🎉 모든 데이터 수집이 완료되었습니다!
```

## 정기 업데이트

시험일정은 매년 변경되므로 정기적으로 업데이트가 필요합니다:

### 방법 1: Cron Job 설정

```bash
# 매주 월요일 오전 2시에 실행
0 2 * * 1 cd /path/to/backend && source ../.venv/bin/activate && python scripts/fetch_all_certifications.py >> logs/certification_sync.log 2>&1
```

### 방법 2: GitHub Actions

```yaml
# .github/workflows/sync-certifications.yml
name: Sync Certifications
on:
  schedule:
    - cron: '0 2 * * 1'  # 매주 월요일 오전 2시
  workflow_dispatch:  # 수동 실행도 가능

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      - name: Install dependencies
        run: |
          cd backend
          pip install -r requirements.txt
      - name: Sync certifications
        env:
          HRDKOREA_API_KEY: ${{ secrets.HRDKOREA_API_KEY }}
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_KEY: ${{ secrets.SUPABASE_KEY }}
        run: |
          cd backend
          python scripts/fetch_all_certifications.py
```

## 문제 해결

### API 키 오류
```
❌ HRD Korea API 키가 설정되지 않았습니다.
```
→ `.env` 파일에 `HRDKOREA_API_KEY` 설정 확인

### 네트워크 오류
```
❌ 자격증 목록을 가져오지 못했습니다.
```
→ 인터넷 연결 확인
→ API 키 활성화 상태 확인 (공공데이터포털에서 승인 대기 중일 수 있음)

### DB 연결 오류
→ `SUPABASE_URL`, `SUPABASE_KEY` 환경변수 확인
→ Supabase 테이블 존재 여부 확인

## 참고

- [HRD Korea Open API 문서](https://www.q-net.or.kr/man001.do?gSite=Q&gId=36)
- [공공데이터포털](https://www.data.go.kr)
