"""LLM-based concept extraction for Knowledge Graph.

Extracts primary concepts, secondary concepts, and prerequisite relationships
from exam questions using Google Gemini.
"""

import json
import asyncio
import logging
from typing import Any, Optional
from dataclasses import dataclass, asdict
import google.generativeai as genai

from app.core.config import get_settings

logger = logging.getLogger(__name__)


@dataclass
class ExtractedConcepts:
    """Concepts extracted from a question."""
    primary_concept: str  # 주요 개념
    secondary_concepts: list[str]  # 관련 개념들
    prerequisite_concepts: list[str]  # 선수 개념들
    subject: str  # 과목 (사회복지기초, 사회복지실천, 사회복지정책과제도)
    chapter: str  # 장/단원


EXTRACTION_PROMPT = """당신은 사회복지사 1급 시험 문제에서 핵심 개념을 추출하는 전문가입니다.

주어진 문제를 분석하여 Knowledge Graph 구축에 필요한 개념 정보를 추출해주세요.

사회복지사 1급 시험 과목:
1. 사회복지기초 (인간행동과 사회환경, 사회복지조사론)
2. 사회복지실천 (사회복지실천론, 사회복지실천기술론, 지역사회복지론)
3. 사회복지정책과제도 (사회복지정책론, 사회복지행정론, 사회복지법제와 실천)

반드시 아래 JSON 형식으로만 응답해주세요:

```json
{
  "primary_concept": "이 문제가 테스트하는 핵심 개념 (예: 사회복지실천 과정)",
  "secondary_concepts": ["관련 세부 개념1", "관련 세부 개념2"],
  "prerequisite_concepts": ["이 개념을 이해하기 위해 필요한 선수 개념들"],
  "subject": "사회복지기초 | 사회복지실천 | 사회복지정책과제도",
  "chapter": "해당 장/단원명 (예: 사회복지실천기술론)"
}
```

문제:
"""


class ConceptExtractor:
    """Service for extracting concepts from questions using LLM."""

    MAX_RETRIES = 3
    BATCH_SIZE = 5  # Process in small batches to avoid rate limits

    def __init__(self):
        settings = get_settings()
        self.api_key = settings.google_api_key

        # Configure Gemini API
        genai.configure(api_key=self.api_key)
        self.model = genai.GenerativeModel('gemini-2.5-flash')

    async def extract_concepts(
        self,
        question: dict[str, Any],
    ) -> Optional[ExtractedConcepts]:
        """
        Extract concepts from a single question.

        Args:
            question: Question dict with question_text and options

        Returns:
            ExtractedConcepts or None if extraction fails
        """
        question_text = question.get("question_text", "")
        options = question.get("options", [])

        # Format the question for the prompt
        options_text = ""
        for opt in options:
            if isinstance(opt, dict):
                options_text += f"\n{opt.get('number', '')}. {opt.get('text', '')}"

        full_text = f"{question_text}{options_text}"

        for attempt in range(self.MAX_RETRIES):
            try:
                response = await self._call_gemini(full_text)
                concepts = self._parse_response(response)
                return concepts
            except Exception as e:
                logger.warning(f"Concept extraction failed (attempt {attempt + 1}): {e}")
                await asyncio.sleep(2 * (attempt + 1))

        logger.error(f"Failed to extract concepts after {self.MAX_RETRIES} attempts")
        return None

    async def extract_concepts_batch(
        self,
        questions: list[dict[str, Any]],
        on_progress: Optional[callable] = None,
    ) -> list[tuple[dict[str, Any], Optional[ExtractedConcepts]]]:
        """
        Extract concepts from a batch of questions.

        Args:
            questions: List of question dicts
            on_progress: Optional callback for progress updates

        Returns:
            List of (question, concepts) tuples
        """
        results = []
        total = len(questions)

        for i, question in enumerate(questions):
            concepts = await self.extract_concepts(question)
            results.append((question, concepts))

            if on_progress:
                progress = int(((i + 1) / total) * 100)
                await on_progress(progress, f"개념 추출 중... ({i + 1}/{total})")

            # Small delay to avoid rate limiting
            if i < total - 1:
                await asyncio.sleep(0.5)

        return results

    async def _call_gemini(self, text: str) -> str:
        """Make API call to Google Gemini."""
        prompt = EXTRACTION_PROMPT + text

        loop = asyncio.get_event_loop()
        response = await loop.run_in_executor(
            None,
            lambda: self.model.generate_content(
                prompt,
                generation_config=genai.types.GenerationConfig(
                    temperature=0.1,
                    max_output_tokens=1024,
                ),
                safety_settings=[
                    {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
                    {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
                    {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"},
                    {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"},
                ],
            )
        )

        if not response.text:
            raise ValueError("Empty response from Gemini API")

        return response.text

    def _parse_response(self, response_text: str) -> ExtractedConcepts:
        """Parse Gemini response into ExtractedConcepts."""
        # Extract JSON from response
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
            logger.error(f"Response: {response_text[:500]}")
            raise

        return ExtractedConcepts(
            primary_concept=data.get("primary_concept", ""),
            secondary_concepts=data.get("secondary_concepts", []),
            prerequisite_concepts=data.get("prerequisite_concepts", []),
            subject=data.get("subject", ""),
            chapter=data.get("chapter", ""),
        )

    def to_dict(self, concepts: ExtractedConcepts) -> dict[str, Any]:
        """Convert ExtractedConcepts to dict."""
        return asdict(concepts)
