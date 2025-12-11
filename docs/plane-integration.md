# Plane Project Management Integration

CertiGraph는 Plane 프로젝트 관리 도구와 통합되어 개발 작업을 추적하고 관리할 수 있습니다.

## 설정 정보

### Plane 인스턴스
- **URL**: http://34.158.192.195:8000
- **Workspace**: testgraph
- **Project ID**: e9f6ed5d-adb5-4e5c-bee6-73e937cf08c4
- **Project URL**: http://34.158.192.195/testgraph/projects/e9f6ed5d-adb5-4e5c-bee6-73e937cf08c4/issues

### 환경 변수

백엔드 `.env` 파일에 다음 설정을 추가하세요:

```env
# Plane Integration
PLANE_API_URL=http://localhost:8000/api/v1
PLANE_API_KEY=your_plane_api_key_here
PLANE_WORKSPACE=testgraph
PLANE_PROJECT_ID=e9f6ed5d-adb5-4e5c-bee6-73e937cf08c4
```

### API 토큰 생성 방법

1. Plane에 로그인합니다
2. Profile Settings → Personal Access Tokens로 이동
3. 새 API 토큰을 생성합니다
4. 생성된 토큰을 `PLANE_API_KEY`에 설정합니다

## API 엔드포인트

CertiGraph 백엔드에서 제공하는 Plane 통합 엔드포인트:

### 1. Work Item 생성
```
POST /api/v1/plane/work-items
```

**Request Body:**
```json
{
  "title": "작업 제목",
  "description": "작업 설명",
  "priority": "medium",  // low, medium, high, urgent
  "state": "state_id",   // optional
  "labels": ["label1"]   // optional
}
```

### 2. Work Item 목록 조회
```
GET /api/v1/plane/work-items?per_page=20&cursor=xxx
```

### 3. 프로젝트 정보 조회
```
GET /api/v1/plane/project
```

### 4. 개발 작업 생성
```
POST /api/v1/plane/development-tasks
```

**Request Body:**
```json
{
  "feature_name": "기능 이름",
  "description": "기술적 설명",
  "task_type": "feature"  // feature, bug, enhancement
}
```

## 사용 예시

### cURL로 개발 작업 생성

```bash
curl -X POST http://34.158.192.195:8001/api/v1/plane/development-tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_CLERK_TOKEN" \
  -d '{
    "feature_name": "PDF 업로드 기능 개선",
    "description": "대용량 PDF 파일 처리를 위한 청크 업로드 구현",
    "task_type": "feature"
  }'
```

### Python으로 Work Item 생성

```python
import httpx

async def create_task():
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://34.158.192.195:8001/api/v1/plane/work-items",
            json={
                "title": "버그 수정: 로그인 오류",
                "description": "Clerk 인증 실패 시 에러 처리 개선",
                "priority": "high"
            },
            headers={"Authorization": "Bearer YOUR_TOKEN"}
        )
        return response.json()
```

## 통합 아키텍처

```
CertiGraph Backend (FastAPI)
    ↓
Plane Integration Service
    ↓ (HTTP API)
Plane API (http://34.158.192.195:8000)
    ↓
Plane Database
```

## 기능 활용 방안

1. **자동 이슈 생성**: 버그 리포트나 기능 요청을 자동으로 Plane 이슈로 변환
2. **개발 작업 추적**: CertiGraph 기능 개발을 Plane에서 추적
3. **프로젝트 대시보드**: Plane의 프로젝트 대시보드에서 진행 상황 모니터링
4. **팀 협업**: 개발 팀과 기획 팀이 Plane을 통해 협업

## 제한 사항

- API Rate Limit: 60 requests/분
- 최대 페이지 크기: 100개 항목
- API 응답 시간: 최대 30초

## 문제 해결

### API 키 오류
```
ValueError: Plane API key not configured
```
→ `.env` 파일에 `PLANE_API_KEY`가 설정되어 있는지 확인

### 연결 오류
```
Failed to create work item: Connection refused
```
→ Plane 서버가 실행 중인지 확인: `docker ps | grep plane`

### 권한 오류
```
403 Forbidden
```
→ API 토큰의 권한 설정 확인
