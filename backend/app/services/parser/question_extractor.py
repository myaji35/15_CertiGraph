"""AI-powered question extraction using Claude.

Extracts structured questions from parsed PDF text,
including question text, options, correct answers, and explanations.
"""

import json
import asyncio
import httpx
from typing import Any
from dataclasses import dataclass, asdict
import logging

from app.core.config import get_settings
from app.core.exceptions import ServerInternalError

logger = logging.getLogger(__name__)

ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"


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

주어진 텍스트에서 다음 정보를 추출해주세요:
1. 문제 번호
2. 문제 내용 (질문)
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
      "question_text": "문제 내용",
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
- 문제와 보기를 정확히 구분하세요
- 보기 번호(①②③④⑤ 또는 1.2.3.4.5)를 1~5 숫자로 변환하세요
- 정답이 명시되어 있지 않으면 correct_answer를 0으로 설정하세요
- 해설이 없으면 explanation을 null로 설정하세요
- 텍스트에서 문제를 찾을 수 없으면 빈 배열을 반환하세요

추출할 텍스트:
"""


class QuestionExtractor:
    """Service for extracting questions from parsed document text using Claude."""

    MAX_RETRIES = 3
    CHUNK_SIZE = 15000  # Characters per chunk to stay within token limits

    def __init__(self):
        self.settings = get_settings()
        self.api_key = self.settings.anthropic_api_key

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
        # Split text into chunks if too long
        chunks = self._split_into_chunks(text)
        all_questions = []

        for i, chunk in enumerate(chunks):
            if on_progress:
                progress = int((i / len(chunks)) * 100)
                await on_progress(progress, f"문제 추출 중... ({i+1}/{len(chunks)})")

            try:
                questions = await self._extract_from_chunk(chunk)
                all_questions.extend(questions)
            except Exception as e:
                logger.error(f"Failed to extract from chunk {i}: {e}")
                continue

        # Deduplicate and sort by question number
        unique_questions = self._deduplicate_questions(all_questions)
        unique_questions.sort(key=lambda q: q.question_number)

        return unique_questions

    def _split_into_chunks(self, text: str) -> list[str]:
        """Split text into processable chunks."""
        if len(text) <= self.CHUNK_SIZE:
            return [text]

        chunks = []
        # Try to split at page boundaries or paragraph breaks
        paragraphs = text.split("\n\n")
        current_chunk = ""

        for para in paragraphs:
            if len(current_chunk) + len(para) > self.CHUNK_SIZE:
                if current_chunk:
                    chunks.append(current_chunk)
                current_chunk = para
            else:
                current_chunk += "\n\n" + para if current_chunk else para

        if current_chunk:
            chunks.append(current_chunk)

        return chunks

    async def _extract_from_chunk(self, chunk: str) -> list[ExtractedQuestion]:
        """Extract questions from a single text chunk using Claude."""
        last_error = None

        for attempt in range(self.MAX_RETRIES):
            try:
                response = await self._call_claude(chunk)
                return self._parse_response(response)

            except httpx.HTTPStatusError as e:
                last_error = e
                logger.warning(f"Claude API error (attempt {attempt + 1}): {e}")
                if e.response.status_code == 429:
                    await asyncio.sleep(5 * (attempt + 1))
                elif e.response.status_code >= 500:
                    await asyncio.sleep(2 * (attempt + 1))
                else:
                    raise

            except json.JSONDecodeError as e:
                last_error = e
                logger.warning(f"JSON parse error (attempt {attempt + 1}): {e}")
                await asyncio.sleep(1)

            except Exception as e:
                last_error = e
                logger.warning(f"Extraction error (attempt {attempt + 1}): {e}")
                await asyncio.sleep(2)

        logger.error(f"Failed to extract questions after {self.MAX_RETRIES} attempts: {last_error}")
        return []

    async def _call_claude(self, text: str) -> dict[str, Any]:
        """Make API call to Claude."""
        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                ANTHROPIC_API_URL,
                headers={
                    "x-api-key": self.api_key,
                    "anthropic-version": "2023-06-01",
                    "content-type": "application/json",
                },
                json={
                    "model": "claude-sonnet-4-20250514",
                    "max_tokens": 4096,
                    "messages": [
                        {
                            "role": "user",
                            "content": EXTRACTION_PROMPT + text,
                        }
                    ],
                },
            )
            response.raise_for_status()
            return response.json()

    def _parse_response(self, response: dict[str, Any]) -> list[ExtractedQuestion]:
        """Parse Claude response into ExtractedQuestion objects."""
        content = response.get("content", [])
        if not content:
            return []

        text = content[0].get("text", "")

        # Extract JSON from response (handle markdown code blocks)
        json_str = text
        if "```json" in text:
            start = text.find("```json") + 7
            end = text.find("```", start)
            json_str = text[start:end].strip()
        elif "```" in text:
            start = text.find("```") + 3
            end = text.find("```", start)
            json_str = text[start:end].strip()

        data = json.loads(json_str)
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
