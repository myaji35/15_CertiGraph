"""
Question Extractor Service using Google Gemini

Extracts structured exam questions from parsed PDF text:
- Question text and number
- Multiple choice options (A-E or 1-5)
- Correct answer
- Explanation
- Subject and topic metadata
"""

import json
import asyncio
import logging
from typing import Optional, Callable, List, Dict, Any
from dataclasses import dataclass, asdict
import re

from app.core.config import get_settings

logger = logging.getLogger(__name__)

# Try to import Gemini, fall back to mock if not available
try:
    import google.generativeai as genai
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False
    logger.warning("google-generativeai not installed - using mock mode")


@dataclass
class QuestionOption:
    """Single option for a multiple choice question"""
    number: int  # 1-5
    text: str


@dataclass
class ExtractedQuestion:
    """Extracted question with all metadata"""
    question_number: int
    question_text: str
    options: List[QuestionOption]
    correct_answer: int  # 1-5, or 0 if unknown
    explanation: Optional[str] = None
    subject: Optional[str] = None
    topic: Optional[str] = None
    passage: Optional[str] = None  # Context/passage for the question

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for API responses"""
        return {
            "question_number": self.question_number,
            "question_text": self.question_text,
            "options": [{"number": opt.number, "text": opt.text} for opt in self.options],
            "correct_answer": self.correct_answer,
            "explanation": self.explanation,
            "subject": self.subject,
            "topic": self.topic,
            "passage": self.passage,
        }


EXTRACTION_PROMPT = """당신은 한국 자격증 시험 기출문제 PDF에서 문제를 추출하는 전문가입니다.

시험 문제의 특성:
- 일부 문제는 **지문(passage)**이 먼저 제시되고, 그 지문에 대한 여러 문제가 이어집니다
- 지문은 "다음 글을 읽고", "다음을 보고", "다음 중" 등으로 시작할 수 있습니다
- 지문이 있는 경우 passage 필드에 저장하고, question_text에는 순수한 질문만 포함하세요
- 독립 문제(지문 없이 바로 질문으로 시작)도 있습니다

주어진 텍스트에서 다음 정보를 추출해주세요:
1. 문제 번호
2. 지문 (있는 경우) - "다음 글을 읽고" 다음에 나오는 내용
3. 문제 내용 (질문) - 순수한 질문만
4. 보기 (1~5번 또는 ①~⑤)
5. 정답 번호 (있는 경우)
6. 해설 (있는 경우)
7. 과목명 (있는 경우)
8. 세부 주제 (있는 경우)

반드시 아래 JSON 형식으로 응답해주세요. 다른 텍스트 없이 JSON만 출력하세요.

```json
{
  "questions": [
    {
      "question_number": 1,
      "passage": "지문 내용 (없으면 null)",
      "question_text": "순수한 질문 내용",
      "options": [
        {"number": 1, "text": "보기 1"},
        {"number": 2, "text": "보기 2"},
        {"number": 3, "text": "보기 3"},
        {"number": 4, "text": "보기 4"},
        {"number": 5, "text": "보기 5"}
      ],
      "correct_answer": 3,
      "explanation": "해설 내용 (없으면 null)",
      "subject": "과목명 (없으면 null)",
      "topic": "세부 주제 (없으면 null)"
    }
  ]
}
```

중요 지침:
- 지문과 문제를 정확히 구분하세요
- 보기 번호(①②③④⑤ 또는 1.2.3.4.5)를 1~5 숫자로 변환하세요
- 정답이 명시되어 있지 않으면 correct_answer를 0으로 설정하세요
- 해설이 없으면 explanation을 null로 설정하세요
- 텍스트에서 문제를 찾을 수 없으면 빈 배열을 반환하세요
- 같은 문제 번호가 중복되지 않도록 주의하세요

추출할 텍스트:
"""


class QuestionExtractor:
    """
    Service for extracting questions from parsed document text.

    Uses Google Gemini 2.5 Flash for fast, accurate extraction.
    Falls back to mock data if API is unavailable.
    """

    MAX_RETRIES = 3
    CHUNK_SIZE = 8000  # Characters per chunk
    GEMINI_MODEL = "gemini-2.0-flash-exp"  # Fast experimental model

    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize question extractor.

        Args:
            api_key: Google API key (defaults to settings if not provided)
        """
        settings = get_settings()
        self.api_key = api_key or settings.google_api_key
        self.use_mock = not self.api_key or not GEMINI_AVAILABLE or settings.dev_mode

        if self.use_mock:
            logger.warning("⚠️ Google API key not configured or Gemini unavailable - using MOCK mode")
        else:
            try:
                genai.configure(api_key=self.api_key)
                self.model = genai.GenerativeModel(self.GEMINI_MODEL)
                logger.info(f"✅ Question extractor initialized with model: {self.GEMINI_MODEL}")
            except Exception as e:
                logger.error(f"Failed to initialize Gemini: {e}")
                self.use_mock = True

    async def extract_questions(
        self,
        text: str,
        progress_callback: Optional[Callable[[int, int, str], Any]] = None,
    ) -> List[ExtractedQuestion]:
        """
        Extract questions from parsed document text.

        Args:
            text: Full document text (from Upstage parser)
            progress_callback: Optional callback(current, total, message)

        Returns:
            List of extracted questions
        """
        if self.use_mock:
            return await self._mock_extract(text, progress_callback)

        logger.info(f"📄 Extracting questions from {len(text)} chars")

        # Split into chunks
        chunks = self._split_into_chunks(text)
        logger.info(f"📦 Split into {len(chunks)} chunks")

        all_questions = []

        for i, chunk in enumerate(chunks):
            logger.info(f"📦 Processing chunk {i+1}/{len(chunks)} ({len(chunk)} chars)")

            if progress_callback:
                await progress_callback(i, len(chunks), f"문제 추출 중... ({i+1}/{len(chunks)} 청크)")

            try:
                questions = await self._extract_from_chunk(chunk)
                logger.info(f"✅ Extracted {len(questions)} questions from chunk {i+1}")
                all_questions.extend(questions)
            except Exception as e:
                logger.error(f"Failed to extract from chunk {i+1}: {e}")
                continue

        # Deduplicate and sort
        unique_questions = self._deduplicate_questions(all_questions)
        unique_questions.sort(key=lambda q: q.question_number)

        logger.info(f"✅ Total extracted: {len(unique_questions)} unique questions")
        return unique_questions

    def _split_into_chunks(self, text: str) -> List[str]:
        """Split text into chunks while preserving context"""
        if len(text) <= self.CHUNK_SIZE:
            return [text]

        chunks = []
        # Split by page markers first
        pages = re.split(r"---\s*페이지\s*\d+\s*---", text)

        current_chunk = ""
        for page_text in pages:
            page_text = page_text.strip()
            if not page_text:
                continue

            # If adding this page exceeds chunk size
            if current_chunk and len(current_chunk) + len(page_text) > self.CHUNK_SIZE:
                chunks.append(current_chunk)
                current_chunk = page_text
            else:
                if current_chunk:
                    current_chunk += "\n\n" + page_text
                else:
                    current_chunk = page_text

        # Add remaining chunk
        if current_chunk:
            chunks.append(current_chunk)

        return chunks if chunks else [text]

    async def _extract_from_chunk(self, chunk: str) -> List[ExtractedQuestion]:
        """Extract questions from a single chunk using Gemini"""
        last_error = None

        for attempt in range(self.MAX_RETRIES):
            try:
                response = await self._call_gemini(chunk)
                return self._parse_response(response)

            except Exception as e:
                last_error = e
                logger.warning(f"Gemini API error (attempt {attempt + 1}): {e}")
                await asyncio.sleep(2 * (attempt + 1))

        logger.error(f"Failed after {self.MAX_RETRIES} attempts: {last_error}")
        return []

    async def _call_gemini(self, text: str) -> str:
        """Call Google Gemini API"""
        prompt = EXTRACTION_PROMPT + text

        try:
            # Gemini SDK is sync, run in thread pool
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None,
                lambda: self.model.generate_content(
                    prompt,
                    generation_config=genai.types.GenerationConfig(
                        temperature=0.1,
                        max_output_tokens=8192,
                    ),
                    safety_settings=[
                        {"category": cat, "threshold": "BLOCK_NONE"}
                        for cat in [
                            "HARM_CATEGORY_HARASSMENT",
                            "HARM_CATEGORY_HATE_SPEECH",
                            "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                            "HARM_CATEGORY_DANGEROUS_CONTENT",
                        ]
                    ],
                ),
            )

            if not response.text:
                raise ValueError("Empty response from Gemini")

            return response.text

        except Exception as e:
            logger.error(f"Gemini API error: {e}")
            raise

    def _parse_response(self, response_text: str) -> List[ExtractedQuestion]:
        """Parse Gemini JSON response into ExtractedQuestion objects"""
        # Extract JSON from markdown code blocks
        json_str = response_text
        if "```json" in response_text:
            start = response_text.find("```json") + 7
            end = response_text.find("```", start)
            json_str = response_text[start:end].strip()
        elif "```" in response_text:
            start = response_text.find("```") + 3
            end = response_text.find("```", start)
            json_str = response_text[start:end].strip()

        try:
            data = json.loads(json_str)
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON: {e}")
            logger.error(f"JSON string: {json_str[:500]}")
            return []

        questions = []

        for q in data.get("questions", []):
            try:
                options = [
                    QuestionOption(number=opt["number"], text=opt["text"])
                    for opt in q.get("options", [])
                ]

                question = ExtractedQuestion(
                    question_number=q.get("question_number", 0),
                    question_text=q.get("question_text", ""),
                    options=options,
                    correct_answer=q.get("correct_answer", 0),
                    explanation=q.get("explanation"),
                    subject=q.get("subject"),
                    topic=q.get("topic"),
                    passage=q.get("passage"),
                )
                questions.append(question)
            except Exception as e:
                logger.error(f"Failed to parse question: {e}")
                continue

        return questions

    def _deduplicate_questions(
        self,
        questions: List[ExtractedQuestion]
    ) -> List[ExtractedQuestion]:
        """Remove duplicate questions by question number"""
        seen = {}
        for q in questions:
            key = q.question_number
            if key not in seen or (q.correct_answer > 0 and seen[key].correct_answer == 0):
                # Prefer questions with known answers
                seen[key] = q
        return list(seen.values())

    async def _mock_extract(
        self,
        text: str,
        progress_callback: Optional[Callable] = None,
    ) -> List[ExtractedQuestion]:
        """Mock extraction for testing"""
        logger.warning("🔧 MOCK: Using mock question extraction")

        await asyncio.sleep(1.0)

        if progress_callback:
            await progress_callback(1, 1, "Mock 데이터 생성 중...")

        mock_questions = [
            ExtractedQuestion(
                question_number=1,
                question_text="사회복지의 기본 원칙에 대한 설명으로 옳은 것은?",
                options=[
                    QuestionOption(1, "사회복지는 선별적 서비스를 원칙으로 한다"),
                    QuestionOption(2, "사회복지는 잔여적 개념에 기초한다"),
                    QuestionOption(3, "사회복지는 보편적 서비스를 지향한다"),
                    QuestionOption(4, "사회복지는 시장 원리에 따라 운영된다"),
                    QuestionOption(5, "사회복지는 개인의 책임을 강조한다"),
                ],
                correct_answer=3,
                explanation="현대 사회복지는 보편적 서비스를 지향하며, 모든 국민의 기본적 권리를 보장하는 것을 목표로 한다.",
                subject="사회복지기초",
                topic="사회복지의 개념",
            ),
            ExtractedQuestion(
                question_number=2,
                question_text="다음 중 사회복지 실천의 가치로 적절하지 않은 것은?",
                options=[
                    QuestionOption(1, "인간의 존엄성"),
                    QuestionOption(2, "자기결정권"),
                    QuestionOption(3, "차별과 배제"),
                    QuestionOption(4, "사회정의"),
                    QuestionOption(5, "평등"),
                ],
                correct_answer=3,
                explanation="차별과 배제는 사회복지 실천의 가치가 아니라 극복해야 할 대상이다.",
                subject="사회복지기초",
                topic="사회복지 실천 가치",
            ),
        ]

        return mock_questions


# Singleton instance
_question_extractor: Optional[QuestionExtractor] = None


def get_question_extractor() -> QuestionExtractor:
    """Get or create singleton question extractor instance"""
    global _question_extractor
    if _question_extractor is None:
        _question_extractor = QuestionExtractor()
    return _question_extractor
