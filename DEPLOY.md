# ExamsGraph 배포 가이드

## 🚀 빠른 배포 (토큰 설정 후)

```bash
# 배포 실행 (토큰이 .dokploy.env에 저장되어 있을 때)
./deploy.sh

# 배포 상태 확인
./deploy.sh status
```

## 🔑 초기 설정 (처음 한 번만)

### 1. Dokploy API 토큰 받기
1. Dokploy 대시보드 접속: http://34.64.143.114:3000
2. Settings → API Tokens 이동
3. "Create Token" 클릭
4. 토큰 복사

### 2. 토큰 저장
`.dokploy.env` 파일의 `DOKPLOY_AUTH_TOKEN` 값을 복사한 토큰으로 변경:

```bash
# .dokploy.env 파일 편집
DOKPLOY_AUTH_TOKEN=여기에_복사한_토큰_붙여넣기
```

### 3. 배포 실행
```bash
./deploy.sh
```

## 📋 배포 정보

- **Dokploy 서버**: http://34.64.143.114:3000
- **프로젝트**: CertiGraph (ID: SVSYksCZ8lAr2Mdrg8902)
- **애플리케이션**: examsgraph-app
- **GitHub 저장소**: git@github.com:myaji35/15_CertiGraph.git

## 🛠 수동 배포 (웹 대시보드)

1. Dokploy 대시보드 접속
2. CertiGraph 프로젝트 선택
3. "Deploy" 버튼 클릭

## 📂 파일 구조

```
/
├── .dokploy.env        # API 토큰 저장 (Git 제외)
├── .env.dokploy        # 배포 환경 변수 템플릿
├── deploy.sh           # 자동 배포 스크립트
├── dokploy.yaml        # Dokploy 설정
├── docker-compose.yaml # Docker 구성
└── ...
```

## 🔒 보안 주의사항

- `.dokploy.env` 파일은 절대 Git에 커밋하지 마세요
- API 토큰은 안전하게 보관하세요
- 환경 변수는 Dokploy 대시보드에서 관리됩니다

## 🐛 문제 해결

### 토큰 오류
```bash
✗ 유효한 DOKPLOY_AUTH_TOKEN이 설정되지 않았습니다
```
→ `.dokploy.env` 파일의 토큰 값 확인

### 프로젝트 연결 실패
```bash
✗ 프로젝트 연결 실패
```
→ Dokploy 서버 상태 확인: http://34.64.143.114:3000

### 배포 실패
→ Dokploy 대시보드의 로그 확인

## 📚 추가 리소스

- [Dokploy 문서](https://docs.dokploy.com)
- [프로젝트 대시보드](http://34.64.143.114:3000/project/SVSYksCZ8lAr2Mdrg8902)