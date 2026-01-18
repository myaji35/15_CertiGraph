# CertiGraph (ExamsGraph)

**AI 기반 자격증 시험 준비 플랫폼**

[![Rails](https://img.shields.io/badge/Rails-8.0-red.svg)](https://rubyonrails.org/)
[![Ruby](https://img.shields.io/badge/Ruby-3.3-red.svg)](https://www.ruby-lang.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue.svg)](https://www.postgresql.org/)

---

## 📚 목차

- [프로젝트 개요](#-프로젝트-개요)
- [주요 기능](#-주요-기능)
- [기술 스택](#-기술-스택)
- [시작하기](#-시작하기)
- [프로젝트 구조](#-프로젝트-구조)
- [문서](#-문서)
- [기여하기](#-기여하기)

---

## 🎯 프로젝트 개요

**CertiGraph**는 사회복지사 1급 등 자격증 시험 준비를 위한 AI 기반 학습 플랫폼입니다.

### 핵심 가치

- ✅ **PDF 자동 파싱**: AI가 PDF에서 문제/보기/해설을 자동 추출
- ✅ **Knowledge Graph**: 개념 간 관계를 시각화하여 약점 분석
- ✅ **CBT 모의고사**: 실전과 동일한 환경에서 시험 연습
- ✅ **AI 개념 설명**: 실시간 인터넷 검색 기반 최신 지식 제공
- ✅ **오답 노트**: 틀린 문제만 모아서 효율적 복습

---

## 🚀 주요 기능

### 1. PDF 업로드 & 자동 파싱
- PDF 파일 업로드
- AI 기반 문제/보기/해설 자동 추출
- 지문 복제 전략으로 정확도 향상

### 2. CBT 모의고사
- 실전과 동일한 시험 환경
- 타이머, 문제 네비게이션
- 즉시 채점 및 결과 분석

### 3. Knowledge Graph 분석
- 개념 간 관계 시각화
- 약점 자동 식별 (빨간 노드)
- AI 기반 학습 경로 추천

### 4. 오답 노트 + AI 설명
- 틀린 문제만 모아서 복습
- 실시간 인터넷 검색으로 최신 정보 확인
- AI가 핵심 개념을 쉽게 설명

---

## 🛠 기술 스택

### Backend
- **Framework**: Ruby on Rails 8.0
- **Language**: Ruby 3.3
- **Database**: PostgreSQL 16
- **ORM**: ActiveRecord
- **Authentication**: Devise

### Frontend
- **Template Engine**: ERB
- **CSS Framework**: Tailwind CSS
- **JavaScript**: Stimulus.js

### AI/ML
- **LLM**: OpenAI GPT-4
- **Search**: Perplexity API (실시간 검색)
- **Embedding**: OpenAI Embeddings

### Infrastructure
- **Deployment**: Dokploy
- **Web Server**: Nginx
- **Background Jobs**: Sidekiq (예정)

---

## 🏁 시작하기

### 사전 요구사항

- Ruby 3.3+
- PostgreSQL 16+
- Node.js 18+ (Tailwind CSS)

### 설치

```bash
# 1. 저장소 클론
git clone https://github.com/yourusername/15_CertiGraph.git
cd 15_CertiGraph

# 2. Rails 프로젝트로 이동
cd rails-api

# 3. 의존성 설치
bundle install
yarn install

# 4. 데이터베이스 설정
rails db:create
rails db:migrate
rails db:seed

# 5. 환경 변수 설정
cp .env.example .env
# .env 파일을 열어서 필요한 값 설정

# 6. 서버 실행
rails server
```

### 접속

- **로컬**: http://localhost:3000
- **계정**: 회원가입 또는 `rails db:seed`로 생성된 테스트 계정 사용

---

## 📁 프로젝트 구조

```
15_CertiGraph/
├── rails-api/              # Rails 백엔드 (메인 프로젝트)
│   ├── app/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── views/
│   │   └── services/
│   ├── config/
│   ├── db/
│   └── spec/
├── docs/                   # 프로젝트 문서
│   ├── guides/            # 가이드 문서
│   ├── deployment/        # 배포 관련 문서
│   └── archive/           # 완료된 문서
├── scripts/               # 유틸리티 스크립트
│   ├── deployment/        # 배포 스크립트
│   └── test/             # 테스트 스크립트
├── sample-data/           # 샘플 PDF 파일
├── assets/               # 이미지 등 정적 파일
│   └── images/
├── config/               # 프로젝트 설정 파일
│   ├── docker-compose.yaml
│   ├── nginx.conf
│   └── playwright.config.ts
├── prd.md                # 제품 요구사항 문서
└── README.md             # 이 파일
```

---

## 📖 문서

### 가이드
- [시작 가이드](docs/guides/START_HERE.md)
- [Rails 개발 가이드](docs/guides/Rails_dev.md)
- [프로젝트 구조](docs/guides/NEW_STRUCTURE.md)
- [로드맵](docs/guides/ROADMAP.md)

### 배포
- [배포 가이드](docs/deployment/DEPLOY.md)
- [Dokploy 설정](docs/deployment/DOKPLOY_SETUP.md)
- [도메인 설정](docs/deployment/DOMAIN_SETUP.md)

### 기능 기획
- [Knowledge Graph 분석 화면](docs/graph-analysis-screen-report.md)
- [틀린 문제 풀기 + AI 설명](docs/wrong-answer-review-with-ai-explanation.md)

---

## 🧪 테스트

```bash
# 단위 테스트
rspec

# 특정 테스트
rspec spec/models/question_spec.rb

# E2E 테스트 (Playwright)
npx playwright test
```

---

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 라이선스

This project is licensed under the MIT License.

---

## 👥 팀

- **개발자**: [Your Name]
- **프로젝트 관리**: BMAD 방법론 기반

---

## 📞 문의

프로젝트에 대한 질문이나 제안사항이 있으시면 이슈를 생성해주세요.

---

**Made with ❤️ for 사회복지사 수험생들**
