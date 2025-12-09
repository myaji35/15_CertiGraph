# 문제 추출 (Extract Questions) 기능 구현안

## 1. 개요

### 목적
PDF 형식의 기출문제/시험지를 업로드하면 자동으로 문제를 추출하여 구조화된 형태로 저장하는 기능

### 핵심 가치
- **자동화**: 수동 입력 대신 AI 기반 자동 추출
- **정확성**: OCR + GPT-4o 검증으로 높은 정확도 확보
- **효율성**: 대량의 기출문제를 빠르게 데이터베이스화

## 2. 시스템 아키텍처

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Frontend   │────▶│  API Routes  │────▶│   Upstage    │
│   (Next.js)  │     │  (Next.js)   │     │   OCR API    │
└──────────────┘     └──────────────┘     └──────────────┘
                            │                      │
                            ▼                      ▼
                     ┌──────────────┐     ┌──────────────┐
                     │   GPT-4o     │◀────│   Markdown   │
                     │  Validation  │     │   Output     │
                     └──────────────┘     └──────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │  PostgreSQL  │
                     │   Database   │
                     └──────────────┘
```

## 3. 데이터 플로우

### 3.1 업로드 단계
1. 사용자가 PDF 파일 선택 (최대 50MB)
2. 파일을 임시 스토리지에 저장
3. 파일 ID 생성 및 반환

### 3.2 OCR 처리 단계
```typescript
// Upstage OCR Request
POST https://api.upstage.ai/v1/document-parse
{
  file: Buffer,
  output_format: "markdown",
  page_split: true,
  coordinate: true,
  figure_caption: true
}
```

### 3.3 문제 파싱 단계
```typescript
// 한국 기출문제 패턴 인식
const patterns = {
  questionNumber: /^\d+\.\s+/,
  options: /^[①②③④⑤]\s+/,
  passageMarker: /^\[지문\]|^\※|^다음을 읽고/,
  imageMarker: /^\[그림\s*\d*\]|^\<img/
};
```

### 3.4 AI 검증 단계
```typescript
// GPT-4o-mini 프롬프트
const prompt = `
다음 OCR 추출 텍스트에서 시험 문제를 구조화하세요:
1. 문제 번호와 텍스트 분리
2. 각 선택지 추출 (①②③④ 형식)
3. 정답 식별 (있는 경우)
4. 지문이 있으면 관련 문제들과 연결
5. 난이도 추정 (상/중/하)

출력 형식:
{
  "questions": [{
    "number": 1,
    "text": "문제 내용",
    "options": [...],
    "answer": 3,
    "passage": "공유 지문",
    "difficulty": "medium"
  }]
}
`;
```

## 4. 주요 컴포넌트

### 4.1 Frontend Components

#### PDFUploader.tsx
- **역할**: PDF 파일 업로드 및 진행 상태 표시
- **기능**:
  - Drag & Drop 지원
  - 업로드 진행률 표시
  - SSE를 통한 실시간 처리 상태 업데이트

#### QuestionReviewer.tsx
- **역할**: 추출된 문제 검수 및 편집
- **기능**:
  - 문제별 수정 인터페이스
  - 신뢰도 낮은 문제 자동 표시
  - 실시간 미리보기
  - 일괄 저장

#### ExtractionModal.tsx
```typescript
'use client';

import { useState } from 'react';
import PDFUploader from './PDFUploader';
import QuestionReviewer from './QuestionReviewer';

export default function ExtractionModal({
  studySetId,
  isOpen,
  onClose
}: {
  studySetId: string;
  isOpen: boolean;
  onClose: () => void;
}) {
  const [step, setStep] = useState<'upload' | 'review' | 'complete'>('upload');
  const [extractedQuestions, setExtractedQuestions] = useState([]);

  const handleExtractComplete = (questions) => {
    setExtractedQuestions(questions);
    setStep('review');
  };

  const handleSaveQuestions = async (questions) => {
    await fetch('/api/questions/save', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ studySetId, questions })
    });
    setStep('complete');
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white dark:bg-gray-800 rounded-lg max-w-6xl w-full max-h-[90vh] overflow-auto">
        {step === 'upload' && (
          <PDFUploader
            studySetId={studySetId}
            onExtractComplete={handleExtractComplete}
          />
        )}
        {step === 'review' && (
          <QuestionReviewer
            questions={extractedQuestions}
            onSave={handleSaveQuestions}
          />
        )}
        {step === 'complete' && (
          <div className="p-8 text-center">
            <h2 className="text-2xl font-bold mb-4">추출 완료!</h2>
            <p>{extractedQuestions.length}개의 문제가 저장되었습니다.</p>
            <button onClick={onClose} className="mt-4 px-4 py-2 bg-blue-500 text-white rounded">
              닫기
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
```

### 4.2 API Routes

#### /api/extract/upload
```typescript
// app/api/extract/upload/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { writeFile } from 'fs/promises';
import { v4 as uuidv4 } from 'uuid';

export async function POST(request: NextRequest) {
  const formData = await request.formData();
  const file = formData.get('file') as File;

  if (!file) {
    return NextResponse.json({ error: 'No file provided' }, { status: 400 });
  }

  const bytes = await file.arrayBuffer();
  const buffer = Buffer.from(bytes);

  const fileId = uuidv4();
  const path = `/tmp/${fileId}.pdf`;

  await writeFile(path, buffer);

  return NextResponse.json({ fileId });
}
```

#### /api/extract/process
```typescript
// app/api/extract/process/route.ts
export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const fileId = searchParams.get('fileId');

  const encoder = new TextEncoder();
  const stream = new TransformStream();
  const writer = stream.writable.getWriter();

  // Start processing in background
  processFile(fileId, writer, encoder);

  return new Response(stream.readable, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  });
}

async function processFile(fileId, writer, encoder) {
  try {
    // 1. OCR 처리
    await writer.write(encoder.encode(`event: progress\ndata: ${JSON.stringify({ progress: 10 })}\n\n`));

    const ocrResult = await callUpstageOCR(fileId);

    await writer.write(encoder.encode(`event: progress\ndata: ${JSON.stringify({ progress: 50 })}\n\n`));

    // 2. 문제 추출
    const questions = await extractQuestions(ocrResult);

    await writer.write(encoder.encode(`event: progress\ndata: ${JSON.stringify({ progress: 80 })}\n\n`));

    // 3. AI 검증
    const validated = await validateWithGPT(questions);

    await writer.write(encoder.encode(`event: progress\ndata: ${JSON.stringify({ progress: 100 })}\n\n`));

    // 4. 완료
    await writer.write(encoder.encode(`event: complete\ndata: ${JSON.stringify({ questions: validated })}\n\n`));

  } catch (error) {
    await writer.write(encoder.encode(`event: error\ndata: ${JSON.stringify({ error: error.message })}\n\n`));
  } finally {
    await writer.close();
  }
}
```

## 5. 데이터베이스 스키마

```sql
-- 추출된 문제 테이블
CREATE TABLE extracted_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  study_set_id UUID REFERENCES study_sets(id),
  question_number INTEGER NOT NULL,
  question_text TEXT NOT NULL,
  passage_text TEXT,
  image_url TEXT,
  correct_answer INTEGER,
  explanation TEXT,
  category VARCHAR(100),
  difficulty VARCHAR(20),
  confidence_score FLOAT,
  needs_review BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 문제 선택지 테이블
CREATE TABLE question_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID REFERENCES extracted_questions(id),
  option_number INTEGER NOT NULL,
  option_text TEXT NOT NULL,
  is_correct BOOLEAN DEFAULT false
);

-- 추출 작업 로그
CREATE TABLE extraction_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  study_set_id UUID REFERENCES study_sets(id),
  file_name VARCHAR(255),
  file_size INTEGER,
  total_pages INTEGER,
  extracted_questions INTEGER,
  ocr_confidence FLOAT,
  processing_time_ms INTEGER,
  status VARCHAR(50), -- 'processing', 'completed', 'failed'
  error_message TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

## 6. 특수 케이스 처리

### 6.1 지문 복제 (Passage Replication)
여러 문제가 하나의 지문을 공유하는 경우:
```typescript
function linkPassageToQuestions(passage: string, questions: Question[]) {
  // 지문 다음에 나오는 연속된 문제들 식별
  const linkedQuestions = [];
  let inPassageGroup = false;

  for (const question of questions) {
    if (question.text.includes('위 지문') ||
        question.text.includes('다음') ||
        inPassageGroup) {
      question.passageText = passage;
      linkedQuestions.push(question);
      inPassageGroup = true;
    } else {
      inPassageGroup = false;
    }
  }

  return linkedQuestions;
}
```

### 6.2 이미지 처리
```typescript
async function processImages(markdown: string) {
  const imageRegex = /!\[([^\]]*)\]\(([^)]+)\)/g;
  const images = [];

  let match;
  while ((match = imageRegex.exec(markdown)) !== null) {
    const [fullMatch, altText, imagePath] = match;

    // GPT-4o로 이미지 설명 생성
    const caption = await generateImageCaption(imagePath);

    images.push({
      path: imagePath,
      altText,
      caption,
      position: match.index
    });
  }

  return images;
}
```

### 6.3 테이블 문제 처리
```typescript
function parseTableQuestion(markdown: string) {
  // 마크다운 테이블을 파싱
  const tableRegex = /\|(.+)\|[\r\n]+\|[-:| ]+\|[\r\n]+((?:\|.+\|[\r\n]?)+)/;
  const match = markdown.match(tableRegex);

  if (match) {
    const headers = match[1].split('|').map(h => h.trim());
    const rows = match[2].split('\n')
      .filter(row => row.trim())
      .map(row => row.split('|').map(cell => cell.trim()));

    return {
      type: 'table',
      headers,
      rows
    };
  }

  return null;
}
```

## 7. 에러 처리

### 7.1 OCR 실패 시
```typescript
const retryOCR = async (fileId: string, maxRetries = 3) => {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await callUpstageOCR(fileId);
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 2000 * (i + 1)));
    }
  }
};
```

### 7.2 파싱 실패 시
- 원본 텍스트 보존
- 수동 편집 모드로 전환
- 관리자에게 알림 전송

## 8. 성능 최적화

### 8.1 청크 처리
대용량 PDF의 경우 페이지별로 처리:
```typescript
async function processLargePDF(fileId: string, totalPages: number) {
  const CHUNK_SIZE = 10;
  const results = [];

  for (let i = 0; i < totalPages; i += CHUNK_SIZE) {
    const chunk = await processPages(fileId, i, Math.min(i + CHUNK_SIZE, totalPages));
    results.push(...chunk);

    // Progress update
    yield { progress: (i / totalPages) * 100 };
  }

  return results;
}
```

### 8.2 캐싱
```typescript
// Redis 캐싱 for processed questions
const cacheKey = `extraction:${fileHash}`;
const cached = await redis.get(cacheKey);

if (cached) {
  return JSON.parse(cached);
}

const result = await processFile(file);
await redis.set(cacheKey, JSON.stringify(result), 'EX', 86400); // 24시간
```

## 9. 테스트 시나리오

### 9.1 단위 테스트
- PDF 업로드 검증
- OCR 응답 파싱
- 문제 패턴 매칭
- 데이터베이스 저장

### 9.2 통합 테스트
- End-to-end 추출 프로세스
- 다양한 PDF 형식 테스트
- 에러 복구 시나리오
- 성능 벤치마크

### 9.3 테스트 데이터
```typescript
const testCases = [
  { name: '정보처리기사 2023 1회', pages: 20, expectedQuestions: 80 },
  { name: 'SQLD 2023', pages: 15, expectedQuestions: 50 },
  { name: '정보보안기사 2022 3회', pages: 25, expectedQuestions: 100 }
];
```

## 10. 모니터링

### 10.1 메트릭
- OCR 성공률
- 평균 처리 시간
- 문제당 수정 횟수
- 사용자 만족도

### 10.2 로깅
```typescript
logger.info('Extraction started', {
  fileId,
  fileName,
  fileSize,
  userId
});

logger.error('OCR failed', {
  fileId,
  error: error.message,
  retryCount
});
```

## 11. 보안 고려사항

### 11.1 파일 검증
- 파일 타입 확인 (PDF only)
- 파일 크기 제한 (50MB)
- 바이러스 스캔
- 악성 스크립트 검사

### 11.2 데이터 보호
- 임시 파일 자동 삭제
- 민감 정보 마스킹
- 접근 권한 확인

## 12. 향후 개선 사항

### Phase 2
- 다중 파일 동시 처리
- 이미지 기반 문제 자동 인식
- 문제 유형별 자동 분류

### Phase 3
- 유사 문제 자동 그룹핑
- 난이도 자동 조정
- 오답률 예측 모델

## 13. 구현 타임라인

| 단계 | 작업 | 예상 시간 |
|------|------|----------|
| 1 | UI 컴포넌트 개발 | 2일 |
| 2 | API Routes 구현 | 2일 |
| 3 | Upstage OCR 연동 | 1일 |
| 4 | GPT-4o 검증 로직 | 1일 |
| 5 | 데이터베이스 연동 | 1일 |
| 6 | 테스트 및 디버깅 | 2일 |
| 7 | 문서화 | 1일 |
| **총계** |  | **10일** |

## 14. 결론

"문제 추출" 기능은 CertiGraph의 핵심 차별화 요소로:
- **시간 절약**: 수동 입력 대비 90% 시간 단축
- **정확도 향상**: AI 검증으로 98% 이상 정확도
- **확장성**: 다양한 시험 형식 지원 가능

이 기능을 통해 사용자는 빠르고 정확하게 학습 자료를 구축할 수 있습니다.