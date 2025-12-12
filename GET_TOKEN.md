# Dokploy API 토큰 발급 방법

## 1단계: Dokploy 대시보드 접속
브라우저에서 열기:
```
http://34.64.143.114:3000
```

## 2단계: 로그인
계정으로 로그인

## 3단계: API 토큰 생성
1. 좌측 메뉴 또는 Settings로 이동
2. **"API Tokens"** 또는 **"Tokens"** 탭 클릭
3. **"Create Token"** 또는 **"Generate Token"** 버튼 클릭
4. 토큰 이름 입력 (예: "CLI Deployment")
5. **생성된 토큰 복사** (한 번만 표시됩니다!)

## 4단계: 토큰 사용

### 방법 A: 스크립트로 배포
```bash
cd /Users/gangseungsig/Documents/02_GitHub/15_CertiGraph
./deploy-dokploy.sh YOUR_TOKEN_HERE
```

### 방법 B: 환경 변수 설정 후 CLI 사용
```bash
export DOKPLOY_URL="http://34.64.143.114:3000"
export DOKPLOY_AUTH_TOKEN="YOUR_TOKEN_HERE"

# 인증 확인
dokploy verify

# 프로젝트 생성
dokploy project create

# 앱 생성
dokploy app create
```

## 토큰 형식 예시
```
dkp_1234567890abcdefghijklmnopqrstuvwxyz
```

## 주의사항
⚠️ **토큰은 한 번만 표시됩니다!**
- 토큰을 안전하게 보관하세요
- 분실 시 새 토큰을 생성해야 합니다
- 토큰은 절대 공개 저장소에 커밋하지 마세요

## 문제 해결

### "Unauthorized" 에러
- 토큰이 만료되었거나 잘못됨
- 새 토큰을 생성하세요

### API Tokens 메뉴를 찾을 수 없음
- Settings 아이콘 (⚙️) 클릭
- 또는 프로필 메뉴에서 확인
- 관리자 권한이 필요할 수 있음
