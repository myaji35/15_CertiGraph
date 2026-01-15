# PDF Processing Services Guide

## Overview

PDF Processing Services는 CertiGraph 프로젝트에서 PDF 시험 자료를 처리하는 핵심 서비스입니다. 세 개의 서비스로 구성되어 있습니다:

1. **UpstageClient**: Upstage Document Parse API와 통신하는 클라이언트
2. **PdfProcessingService**: PDF를 마크다운으로 변환하고 처리하는 메인 서비스
3. **QuestionExtractionService**: 마크다운에서 질문과 선택지를 추출하는 서비스

## Architecture

```
PDF File
  ↓
[UpstageClient] → Upstage API → Markdown
  ↓
[PdfProcessingService] → Passage Replication + Chunking
  ↓
[QuestionExtractionService] → Questions + Options
  ↓
Database (StudyMaterial → Question + Option)
```

## Environment Configuration

### Required Environment Variables

```bash
# Upstage Document Parse API Key
UPSTAGE_API_KEY=your_api_key_here

# Optional: OpenAI for embeddings (future use)
OPENAI_API_KEY=your_api_key_here
```

### Setting Up .env

1. `.env.example` 파일을 `.env`로 복사합니다:
```bash
cp .env.example .env
```

2. `.env` 파일에서 실제 API 키를 입력합니다:
```bash
UPSTAGE_API_KEY=sk-upstage_api_key_xxxxx
```

## Service Details

### 1. UpstageClient

Upstage Document Parse API와 통신하는 HTTP 클라이언트입니다.

#### Features
- PDF를 마크다운으로 변환
- 배치 처리 (여러 파일 동시 처리)
- 메타데이터 추출
- 자동 재시도 및 에러 처리

#### Usage

```ruby
# 단일 파일 처리
client = UpstageClient.new
response = client.parse_document('/path/to/file.pdf')
markdown = response['markdown']

# 여러 파일 배치 처리
files = ['/path/file1.pdf', '/path/file2.pdf']
results = client.batch_parse(files)

# 메타데이터 포함
response = client.parse_with_metadata('/path/to/file.pdf')
```

#### Error Handling

```ruby
begin
  client = UpstageClient.new
  response = client.parse_document(file_path)
rescue UpstageConfigurationError
  # API 키 설정 안 됨
rescue UpstageFileNotFoundError
  # 파일을 찾을 수 없음
rescue UpstageInvalidFileError
  # PDF 파일이 아님
rescue UpstageAuthenticationError
  # API 키가 잘못됨
rescue UpstageRateLimitError
  # API 호출 제한 초과
rescue UpstageServerError
  # Upstage 서버 에러
rescue UpstageError
  # 기타 에러
end
```

#### Custom Exceptions

- `UpstageError`: 기본 예외 클래스
- `UpstageConfigurationError`: API 키 미설정
- `UpstageFileNotFoundError`: 파일을 찾을 수 없음
- `UpstageInvalidFileError`: 유효하지 않은 파일 형식
- `UpstageApiError`: API 요청 실패
- `UpstageAuthenticationError`: 인증 실패
- `UpstageAuthorizationError`: 권한 없음
- `UpstageValidationError`: 요청 유효성 검사 실패
- `UpstageRateLimitError`: 호출 제한 초과
- `UpstageServerError`: 서버 에러

### 2. PdfProcessingService

PDF를 처리하는 메인 서비스입니다.

#### Features
- PDF를 마크다운으로 변환
- 지문 복제 전략 적용 (passage replication)
- 문제 청킹 (chunking)
- 메타데이터 추출
- 처리 통계 제공

#### Usage

```ruby
# 전체 처리 파이프라인
service = PdfProcessingService.new('/path/to/file.pdf')
result = service.process

if result[:success]
  questions = result[:questions]
  markdown = result[:markdown]
  metadata = result[:metadata]
  puts "Extracted #{result[:total_questions]} questions"
  puts "Organized into #{result[:chunks]} chunks"
else
  puts "Error: #{result[:error]}"
end

# 개별 메서드 사용
markdown = service.convert_to_markdown
service.apply_passage_replication
chunks = service.chunk_questions(questions, chunk_size: 10)
stats = service.processing_stats
captions = service.extract_image_captions
```

#### Passage Replication Strategy

지문 복제는 동일한 지문을 참조하는 여러 문제들을 식별하고 처리합니다:

```markdown
<!-- PASSAGE 1 START -->
다음을 읽고 문제에 답하시오.
[지문 내용]
<!-- PASSAGE 1 END -->

1. 첫 번째 문제
① 선택지

2. 두 번째 문제
② 선택지
```

#### Return Value

```ruby
{
  success: true,
  questions: [
    {
      question_number: 1,
      question_text: "...",
      options: { '①' => '...', '②' => '...' },
      answer: nil,
      explanation: nil,
      passage: "...",
      option_count: 5,
      has_table: false,
      has_image: false
    },
    # ... more questions
  ],
  markdown: "# Markdown content",
  metadata: { ... },
  total_questions: 100,
  chunks: 10
}
```

### 3. QuestionExtractionService

마크다운에서 질문과 선택지를 추출합니다.

#### Features
- 다양한 질문 번호 형식 지원 (1., 1), (1))
- 선택지 자동 파싱 (①②③④⑤)
- 표(table) 및 이미지 감지
- 지문 식별 및 처리
- 추출 통계 제공

#### Supported Question Number Formats

```
1. First format
2) Second format
(3) Third format
```

#### Usage

```ruby
markdown = "..."
service = QuestionExtractionService.new(markdown)

# 모든 질문 추출
questions = service.extract_questions

# 특정 질문 조회
question = service.find_question_by_number(1)

# 전체 추출 결과
all = service.all_questions

# 통계
stats = service.extraction_stats
# {
#   total_questions: 100,
#   questions_with_passages: 50,
#   questions_without_passages: 50,
#   average_options: 4.5
# }
```

#### Question Structure

```ruby
{
  question_number: 1,
  question_text: "문제 텍스트",
  options: {
    '①' => '첫 번째 선택지',
    '②' => '두 번째 선택지',
    '③' => '세 번째 선택지',
    '④' => '네 번째 선택지',
    '⑤' => '다섯 번째 선택지'
  },
  answer: nil,              # 별도 처리 필요
  explanation: nil,         # 별도 처리 필요
  passage: nil,             # 관련 지문
  option_count: 5,
  has_table: false,
  has_image: false
}
```

#### Constraints

- 최소 2개 이상의 선택지 필요
- 공백과 줄바꿈은 자동 정규화
- 이미지 및 표는 감지되지만 처리되지 않음

## Integration with Rails Models

### ProcessPdfJob

백그라운드 작업으로 PDF를 처리합니다:

```ruby
class ProcessPdfJob < ApplicationJob
  def perform(study_material_id)
    study_material = StudyMaterial.find(study_material_id)

    pdf_file.open do |file|
      # PdfProcessingService 사용
      service = PdfProcessingService.new(file.path)
      result = service.process

      if result[:success]
        # Question 모델에 저장
        result[:questions].each do |q|
          Question.create!(
            study_material: study_material,
            content: q[:question_text],
            options: q[:options],
            # ... 기타 필드
          )
        end
      end
    end
  end
end
```

### StudyMaterial Model

```ruby
class StudyMaterial < ApplicationRecord
  has_one_attached :pdf_file
  has_many :questions, dependent: :destroy

  # 처리 시작
  def process_pdf!
    update(status: 'processing')
    ProcessPdfJob.perform_later(id)
  end
end
```

## Testing

### Unit Tests

```bash
# 모든 서비스 테스트 실행
rails test test/services/

# 특정 서비스 테스트
rails test test/services/upstage_client_test.rb
rails test test/services/pdf_processing_service_test.rb
rails test test/services/question_extraction_service_test.rb
```

### Integration Test Script

```bash
# 통합 테스트 실행
ruby test_pdf_services.rb
```

이 스크립트는 다음을 테스트합니다:
- UpstageClient 설정 확인
- QuestionExtractionService 추출 기능
- PdfProcessingService 청킹
- 다양한 질문 형식 인식

## Performance Considerations

### API Rate Limits

Upstage API는 호출 제한이 있습니다:
- 배치 처리 시 에러 재시도 로직 포함
- Rate limit 에러 발생 시 자동 대기

### Memory Management

대용량 PDF 처리 시:
- 청킹으로 메모리 사용 최소화 (chunk_size: 10)
- 마크다운 변환 후 원본 PDF 파일 해제

### Caching

```ruby
# 마크다운 캐싱 (선택)
cached_markdown = Rails.cache.fetch("pdf_#{study_material.id}") do
  service.convert_to_markdown
end
```

## Debugging

### Logging

서비스는 다음 레벨로 로깅합니다:

```ruby
Rails.logger.info("[PdfProcessingService] ...")
Rails.logger.error("[PdfProcessingService] ...")
Rails.logger.warn("[PdfProcessingService] ...")
```

### Debug Mode

```ruby
service = PdfProcessingService.new(file_path)

# 각 단계별 로그 확인
service.convert_to_markdown
puts service.markdown_content[0..100]

service.apply_passage_replication
puts service.processing_stats
```

## Common Issues & Solutions

### Issue: UpstageConfigurationError

**원인**: UPSTAGE_API_KEY가 설정되지 않음

**해결책**:
```bash
export UPSTAGE_API_KEY='your_key'
# 또는 .env 파일에 추가
```

### Issue: Questions Not Extracted

**원인**: 질문 번호 형식이 예상과 다름

**해결책**: `QuestionExtractionService.QUESTION_NUMBER_PATTERNS` 수정

```ruby
# 새로운 패턴 추가
QUESTION_NUMBER_PATTERNS = [
  /^(\d{1,3})\.\s+/,      # 1.
  /^(\d{1,3})\)\s+/,      # 1)
  /^\((\d{1,3})\)\s+/,    # (1)
  /^문제\s+(\d{1,3})/     # 문제 1
]
```

### Issue: Rate Limit Exceeded

**원인**: API 호출 제한 초과

**해결책**: 재시도 로직 추가

```ruby
max_retries = 3
retry_count = 0

begin
  result = service.process
rescue UpstageRateLimitError
  retry_count += 1
  if retry_count <= max_retries
    sleep(2 ** retry_count)  # Exponential backoff
    retry
  else
    raise
  end
end
```

## Future Enhancements

1. **GraphRAG Integration**: 질문 간 관계 그래프 생성
2. **Answer Key Extraction**: 정답 및 해설 자동 추출
3. **Image Processing**: 이미지 캡션 및 OCR
4. **Caching**: 처리 결과 캐싱
5. **Async Processing**: WebSocket을 통한 실시간 처리 상태 업데이트
6. **Multi-language Support**: 다양한 언어의 PDF 처리

## References

- [Upstage API Documentation](https://www.upstage.ai/)
- [Rails Active Job](https://guides.rubyonrails.org/active_job_basics.html)
- [Rails Active Storage](https://guides.rubyonrails.org/active_storage_overview.html)

## Support

서비스 관련 문제가 발생하면:
1. 로그 파일 확인: `log/development.log`
2. 환경변수 확인: `echo $UPSTAGE_API_KEY`
3. 테스트 실행: `ruby test_pdf_services.rb`
4. 문제 제보: GitHub Issues에 로그와 함께 보고
