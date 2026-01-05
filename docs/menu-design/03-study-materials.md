# 학습 > 학습 자료

## 경로
`/study-materials`

## 목적
문제집에 속한 학습 자료(PDF) 관리

## 주요 기능 (계획)

### 1. 학습 자료 목록
- 문제집별 그룹화
- PDF 파일명
- 업로드 날짜
- 문제 개수
- 상태 (처리 중/완료)

### 2. PDF 업로드
- 드래그 앤 드롭
- 파일 선택 (최대 50MB)
- 중복 파일 감지 (MD5 해시)
- 진행 상태 표시

### 3. 자동 처리
- Upstage OCR로 텍스트 추출
- 이미지 → GPT-4o 캡션 생성
- 지문 복제 (Multi-question context)
- 문제 파싱 및 저장

## 구현 상태
- ❌ 전체 미구현
- 📝 계획 단계

## 관련 파일
- `/backend/app/services/pdf_processor.py` (미래 구현)
- `/backend/app/services/upstage_ocr.py` (미래 구현)

## 참고
- PRD의 "데이터 수집 및 처리 파이프라인" 섹션 참조
- 문제집 상세 페이지에서 PDF 업로드 시작점
