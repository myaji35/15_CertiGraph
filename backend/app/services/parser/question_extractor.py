"""AI-powered question extraction using Google Gemini.

Extracts structured questions from parsed PDF text,
including question text, options, correct answers, and explanations.
"""

import json
import asyncio
from typing import Any
from dataclasses import dataclass, asdict
import logging
import google.generativeai as genai

from app.core.config import get_settings
from app.core.exceptions import ServerInternalError

logger = logging.getLogger(__name__)


@dataclass
class QuestionOption:
    """Represents a single option for a question."""
    number: int  # 1-5
    text: str


@dataclass
class ExtractedQuestion:
    """Represents an extracted question from the exam."""
    question_number: int
    question_text: str
    options: list[QuestionOption]
    correct_answer: int  # 1-5
    explanation: str | None = None
    subject: str | None = None  # 과목
    topic: str | None = None  # 세부 주제


EXTRACTION_PROMPT = """당신은 사회복지사 1급 시험 기출문제 PDF에서 문제를 추출하는 전문가입니다.

시험 문제의 특성:
- 일부 문제는 **지문(passage)**이 먼저 제시되고, 그 지문에 대한 여러 문제가 이어집니다
- 지문은 "다음 글을 읽고", "다음을 보고" 등으로 시작합니다
- 지문 관련 문제의 question_text에는 **지문 내용을 포함하지 마세요**. 순수한 질문만 추출하세요
- 독립 문제(지문 없이 바로 질문으로 시작)도 있습니다

주어진 텍스트에서 다음 정보를 추출해주세요:
1. 문제 번호
2. 문제 내용 (질문) - **지문 제외, 질문만**
3. 보기 (1~5번)
4. 정답 번호
5. 해설 (있는 경우)
6. 과목명 (사회복지기초, 사회복지실천, 사회복지정책과제도 등)
7. 세부 주제 (있는 경우)

반드시 아래 JSON 형식으로 응답해주세요. 다른 텍스트 없이 JSON만 출력하세요.

```json
{
  "questions": [
    {
      "question_number": 1,
      "question_text": "문제 내용 (순수한 질문만, 지문 제외)",
      "options": [
        {"number": 1, "text": "보기 1"},
        {"number": 2, "text": "보기 2"},
        {"number": 3, "text": "보기 3"},
        {"number": 4, "text": "보기 4"},
        {"number": 5, "text": "보기 5"}
      ],
      "correct_answer": 3,
      "explanation": "해설 내용 (없으면 null)",
      "subject": "과목명",
      "topic": "세부 주제 (없으면 null)"
    }
  ]
}
```

중요 지침:
- **지문과 문제를 구분**하세요. 지문은 question_text에 포함하지 마세요
- 문제와 보기를 정확히 구분하세요
- 보기 번호(①②③④⑤ 또는 1.2.3.4.5)를 1~5 숫자로 변환하세요
- 정답이 명시되어 있지 않으면 correct_answer를 0으로 설정하세요
- 해설이 없으면 explanation을 null로 설정하세요
- 텍스트에서 문제를 찾을 수 없으면 빈 배열을 반환하세요

추출할 텍스트:
"""


class QuestionExtractor:
    """Service for extracting questions from parsed document text using Google Gemini."""

    MAX_RETRIES = 3
    CHUNK_SIZE = 5000  # Reduced to avoid Gemini safety filter issues

    def __init__(self):
        self.settings = get_settings()
        self.api_key = self.settings.google_api_key

        # Configure Gemini API
        genai.configure(api_key=self.api_key)

        # Use Gemini 2.5 Flash for fast, cost-effective processing
        # Supports up to 1M tokens, stable release
        self.model = genai.GenerativeModel('gemini-2.5-flash')

    async def extract_questions(
        self,
        text: str,
        on_progress: callable = None,
    ) -> list[ExtractedQuestion]:
        """
        Extract questions from document text.

        Args:
            text: Full document text from Upstage parser
            on_progress: Optional callback for progress updates

        Returns:
            List of extracted questions
        """
        # Log the input text for debugging
        logger.info(f"📄 Input text length: {len(text)} characters")
        logger.info(f"📄 First 500 chars: {text[:500]}")
        logger.info(f"📄 Last 500 chars: {text[-500:]}")

        # Split text into chunks if too long
        chunks = self._split_into_chunks(text)
        logger.info(f"📦 Split into {len(chunks)} chunks")

        all_questions = []

        for i, chunk in enumerate(chunks):
            logger.info(f"📦 Chunk {i+1}/{len(chunks)}: {len(chunk)} characters")
            logger.info(f"📦 Chunk {i+1} preview (first 300 chars): {chunk[:300]}")

            if on_progress:
                progress = int((i / len(chunks)) * 100)
                await on_progress(progress, f"문제 추출 중... ({i+1}/{len(chunks)})")

            try:
                questions = await self._extract_from_chunk(chunk)
                logger.info(f"✅ Extracted {len(questions)} questions from chunk {i+1}")
                all_questions.extend(questions)
            except Exception as e:
                logger.error(f"Failed to extract from chunk {i}: {e}")
                continue

        # Deduplicate and sort by question number
        unique_questions = self._deduplicate_questions(all_questions)
        unique_questions.sort(key=lambda q: q.question_number)

        return unique_questions

    def _split_into_chunks(self, text: str) -> list[str]:
        """
        Split text into processable chunks while preserving passage-question relationships.

        Strategy:
        1. Identify page boundaries (페이지 markers)
        2. Keep passages and their questions together
        3. Split at page boundaries when possible
        """
        if len(text) <= self.CHUNK_SIZE:
            return [text]

        chunks = []
        # Split by page markers first to maintain page structure
        pages = text.split("--- 페이지")

        current_chunk = ""

        for page_text in pages:
            page_text = page_text.strip()
            if not page_text:
                continue

            # If adding this page would exceed chunk size
            if current_chunk and len(current_chunk) + len(page_text) > self.CHUNK_SIZE:
                # Save current chunk and start new one
                chunks.append(current_chunk)
                current_chunk = page_text
            else:
                # Add to current chunk
                if current_chunk:
                    current_chunk += "\n--- 페이지" + page_text
                else:
                    current_chunk = page_text

        # Add remaining chunk
        if current_chunk:
            chunks.append(current_chunk)

        return chunks if chunks else [text]

    async def _extract_from_chunk(self, chunk: str) -> list[ExtractedQuestion]:
        """Extract questions from a single text chunk using Google Gemini."""
        last_error = None

        for attempt in range(self.MAX_RETRIES):
            try:
                response = await self._call_gemini(chunk)
                return self._parse_response(response)

            except Exception as e:
                last_error = e
                logger.warning(f"Gemini API error (attempt {attempt + 1}): {e}")
                await asyncio.sleep(2 * (attempt + 1))

        logger.error(f"Failed to extract questions after {self.MAX_RETRIES} attempts: {last_error}")
        return []

    async def _call_gemini(self, text: str) -> str:
        """Make API call to Google Gemini."""
        prompt = EXTRACTION_PROMPT + text

        logger.info(f"📤 Sending Gemini API request with model: {self.model._model_name}")
        logger.debug(f"📤 Prompt length: {len(prompt)} characters")

        try:
            # Gemini SDK is synchronous, so we run it in a thread pool
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None,
                lambda: self.model.generate_content(
                    prompt,
                    generation_config=genai.types.GenerationConfig(
                        temperature=0.1,
                        max_output_tokens=4096,
                    ),
                    # Disable ALL safety filters for educational content
                    safety_settings=[
                        {
                            "category": "HARM_CATEGORY_HARASSMENT",
                            "threshold": "BLOCK_NONE"
                        },
                        {
                            "category": "HARM_CATEGORY_HATE_SPEECH",
                            "threshold": "BLOCK_NONE"
                        },
                        {
                            "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                            "threshold": "BLOCK_NONE"
                        },
                        {
                            "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                            "threshold": "BLOCK_NONE"
                        }
                    ]
                )
            )

            # Check if response was blocked
            if hasattr(response, 'candidates') and response.candidates:
                candidate = response.candidates[0]
                if hasattr(candidate, 'finish_reason'):
                    if candidate.finish_reason == 2:  # SAFETY
                        logger.warning("⚠️ Gemini response blocked by safety filter - using fallback")
                        # Try to get partial content or use a simpler approach
                        if hasattr(candidate, 'content') and candidate.content:
                            return str(candidate.content)

            if not response.text:
                raise ValueError("Empty response from Gemini API")

            logger.info(f"✅ Gemini API response received: {len(response.text)} characters")
            logger.debug(f"📥 Response preview: {response.text[:500]}")

            return response.text

        except Exception as e:
            logger.error(f"❌ Gemini API error: {str(e)}")
            logger.error(f"API key configured: {'Yes' if self.api_key else 'No'}")

            # If blocked by safety, return empty list to avoid crash
            if "finish_reason" in str(e) and "is 2" in str(e):
                logger.warning("Content blocked by Gemini safety filter - returning empty result")
                return "[]"  # Return empty JSON array
            raise

    def _parse_response(self, response_text: str) -> list[ExtractedQuestion]:
        """Parse Gemini response into ExtractedQuestion objects."""
        # Extract JSON from response (handle markdown code blocks)
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
            raise

        questions = []

        for q in data.get("questions", []):
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
            )
            questions.append(question)

        return questions

    def _deduplicate_questions(
        self,
        questions: list[ExtractedQuestion]
    ) -> list[ExtractedQuestion]:
        """Remove duplicate questions based on question number."""
        seen = {}
        for q in questions:
            key = q.question_number
            if key not in seen or (q.correct_answer > 0 and seen[key].correct_answer == 0):
                # Prefer questions with known correct answers
                seen[key] = q
        return list(seen.values())

    def to_db_format(self, question: ExtractedQuestion) -> dict[str, Any]:
        """Convert ExtractedQuestion to database format."""
        return {
            "question_number": question.question_number,
            "question_text": question.question_text,
            "options": [asdict(opt) for opt in question.options],
            "correct_answer": question.correct_answer,
            "explanation": question.explanation,
            "subject": question.subject,
            "topic": question.topic,
        }

    async def extract_with_llm(self, text: str) -> list[dict[str, Any]]:
        """
        Extract questions using LLM (Google Gemini).

        Args:
            text: Full document text (markdown)

        Returns:
            List of questions in database format
        """
        questions = await self.extract_questions(text)
        return [self.to_db_format(q) for q in questions]

    def extract_with_rules(self, text: str) -> list[dict[str, Any]]:
        """
        Extract questions using rule-based parsing.

        Fallback for when no LLM API is available.

        Args:
            text: Full document text

        Returns:
            List of questions in database format
        """
        import re

        questions = []
        # Pattern: 문제 번호 + 내용 + 보기들
        question_pattern = r'(\d{1,3})\.\s+(.+?)(?=\d{1,3}\.\s+|\Z)'
        option_pattern = r'[①②③④⑤]\s*(.+?)(?=[①②③④⑤]|\Z)'

        matches = re.findall(question_pattern, text, re.DOTALL)

        for num_str, content in matches:
            q_num = int(num_str)
            content = content.strip()

            # Split question text and options
            parts = content.split('\n')
            question_text = parts[0] if parts else ""

            # Extract options
            options = []
            option_markers = ['①', '②', '③', '④', '⑤']
            for i, marker in enumerate(option_markers, 1):
                if marker in content:
                    start = content.find(marker) + 1
                    end = len(content)
                    for next_marker in option_markers[i:]:
                        next_pos = content.find(next_marker)
                        if next_pos != -1 and next_pos < end:
                            end = next_pos
                    opt_text = content[start:end].strip()
                    options.append({"number": i, "text": opt_text})

            if question_text and len(options) >= 2:
                questions.append({
                    "question_number": q_num,
                    "question_text": question_text,
                    "options": options,
                    "correct_answer": 0,  # Unknown without answer key
                    "explanation": None,
                    "subject": None,
                    "topic": None,
                })

        return questions
