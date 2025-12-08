"""Vision-based multimodal question extractor using OpenAI GPT-4 Vision.

Converts PDF pages to images and uses vision AI to extract questions,
avoiding text-based safety filters that block exam content.
"""

import json
import asyncio
import base64
from typing import Any, BinaryIO, Optional
from dataclasses import dataclass, asdict
import logging
from io import BytesIO
from pdf2image import convert_from_bytes
from PIL import Image
import httpx

from app.core.config import get_settings
from app.core.exceptions import ServerInternalError

logger = logging.getLogger(__name__)

# Import the same data classes
from app.services.parser.question_extractor import (
    QuestionOption,
    ExtractedQuestion
)


VISION_PROMPT = """You are analyzing an exam paper page. Extract all questions from this image.

For each question you find:
1. Extract the question number
2. Extract the full question text
3. Extract all answer options (usually numbered 1-5 or marked with ①②③④⑤)
4. Identify the correct answer if shown
5. Extract any explanation provided

Important:
- Return the results as a JSON array
- Each question should have: question_number, question_text, options (array), correct_answer, explanation, subject, topic
- Options should be an array of {number: int, text: string}
- If no correct answer is shown, set correct_answer to null
- If no explanation is provided, set explanation to null

Return ONLY valid JSON in this format:
{
  "questions": [
    {
      "question_number": 1,
      "question_text": "Question text here",
      "options": [
        {"number": 1, "text": "Option 1"},
        {"number": 2, "text": "Option 2"},
        {"number": 3, "text": "Option 3"},
        {"number": 4, "text": "Option 4"},
        {"number": 5, "text": "Option 5"}
      ],
      "correct_answer": 2,
      "explanation": "Explanation text or null",
      "subject": "Subject name or null",
      "topic": "Topic name or null"
    }
  ]
}
"""


class VisionQuestionExtractor:
    """Extract questions from PDF using vision AI."""

    MAX_RETRIES = 3
    MAX_IMAGE_SIZE = (1920, 1080)  # Resize images to fit within these dimensions

    def __init__(self):
        self.settings = get_settings()
        self.api_key = self.settings.openai_api_key

    async def extract_questions(
        self,
        pdf_content: bytes,
        on_progress: Optional[callable] = None,
    ) -> list[ExtractedQuestion]:
        """
        Extract questions from PDF using vision AI.

        Args:
            pdf_content: PDF file content as bytes
            on_progress: Optional progress callback

        Returns:
            List of extracted questions
        """
        try:
            # Convert PDF to images
            logger.info("📸 Converting PDF to images...")
            images = self._pdf_to_images(pdf_content)
            logger.info(f"📸 Converted PDF to {len(images)} images")

            all_questions = []
            total_pages = len(images)

            for idx, image in enumerate(images):
                page_num = idx + 1

                if on_progress:
                    progress = int((idx / total_pages) * 100)
                    await on_progress(progress, f"페이지 {page_num}/{total_pages} 분석 중...")

                logger.info(f"🔍 Processing page {page_num}/{total_pages}")

                # Convert image to base64
                image_base64 = self._image_to_base64(image)

                # Extract questions from this page
                page_questions = await self._extract_from_image(image_base64, page_num)
                all_questions.extend(page_questions)

                logger.info(f"✅ Page {page_num}: Found {len(page_questions)} questions")

            if on_progress:
                await on_progress(100, "문제 추출 완료!")

            logger.info(f"📊 Total extracted: {len(all_questions)} questions")
            return all_questions

        except Exception as e:
            logger.error(f"Vision extraction failed: {e}")
            raise ServerInternalError(f"문제 추출 실패: {str(e)}")

    def _pdf_to_images(self, pdf_content: bytes) -> list[Image.Image]:
        """Convert PDF bytes to list of PIL Images."""
        try:
            # Convert PDF to images (one per page)
            images = convert_from_bytes(
                pdf_content,
                dpi=150,  # Good quality without being too large
                fmt='PNG'
            )

            # Resize images if too large
            resized_images = []
            for img in images:
                if img.size[0] > self.MAX_IMAGE_SIZE[0] or img.size[1] > self.MAX_IMAGE_SIZE[1]:
                    img.thumbnail(self.MAX_IMAGE_SIZE, Image.Resampling.LANCZOS)
                resized_images.append(img)

            return resized_images

        except Exception as e:
            logger.error(f"PDF to image conversion failed: {e}")
            raise ServerInternalError(f"PDF 변환 실패: {str(e)}")

    def _image_to_base64(self, image: Image.Image) -> str:
        """Convert PIL Image to base64 string."""
        buffer = BytesIO()
        image.save(buffer, format='PNG')
        image_bytes = buffer.getvalue()
        return base64.b64encode(image_bytes).decode('utf-8')

    async def _extract_from_image(
        self,
        image_base64: str,
        page_num: int
    ) -> list[ExtractedQuestion]:
        """Extract questions from a single image using OpenAI Vision API."""

        for attempt in range(self.MAX_RETRIES):
            try:
                async with httpx.AsyncClient(timeout=60.0) as client:
                    response = await client.post(
                        "https://api.openai.com/v1/chat/completions",
                        headers={
                            "Authorization": f"Bearer {self.api_key}",
                            "Content-Type": "application/json"
                        },
                        json={
                            "model": "gpt-4o-mini",  # Cheaper vision model
                            "messages": [
                                {
                                    "role": "user",
                                    "content": [
                                        {
                                            "type": "text",
                                            "text": VISION_PROMPT
                                        },
                                        {
                                            "type": "image_url",
                                            "image_url": {
                                                "url": f"data:image/png;base64,{image_base64}",
                                                "detail": "high"  # High detail for better text recognition
                                            }
                                        }
                                    ]
                                }
                            ],
                            "max_tokens": 4096,
                            "temperature": 0.1
                        }
                    )

                if response.status_code == 200:
                    result = response.json()
                    content = result['choices'][0]['message']['content']

                    # Parse JSON from response
                    return self._parse_vision_response(content)

                else:
                    logger.error(f"OpenAI API error: {response.status_code} - {response.text}")

            except Exception as e:
                logger.warning(f"Vision API attempt {attempt + 1} failed: {e}")
                await asyncio.sleep(2 * (attempt + 1))

        logger.error(f"Failed to extract from page {page_num} after {self.MAX_RETRIES} attempts")
        return []

    def _parse_vision_response(self, response_text: str) -> list[ExtractedQuestion]:
        """Parse Vision API response into ExtractedQuestion objects."""
        try:
            # Clean the response (remove markdown code blocks if present)
            clean_text = response_text
            if "```json" in clean_text:
                clean_text = clean_text.split("```json")[1].split("```")[0]
            elif "```" in clean_text:
                clean_text = clean_text.split("```")[1].split("```")[0]

            # Parse JSON
            data = json.loads(clean_text.strip())

            questions = []
            for q_data in data.get("questions", []):
                # Convert options
                options = []
                for opt in q_data.get("options", []):
                    options.append(QuestionOption(
                        number=opt.get("number", 0),
                        text=opt.get("text", "")
                    ))

                # Create question
                question = ExtractedQuestion(
                    question_number=q_data.get("question_number", 0),
                    question_text=q_data.get("question_text", ""),
                    options=options,
                    correct_answer=q_data.get("correct_answer"),
                    explanation=q_data.get("explanation"),
                    subject=q_data.get("subject"),
                    topic=q_data.get("topic")
                )
                questions.append(question)

            return questions

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Vision response: {e}")
            logger.debug(f"Response text: {response_text[:500]}")
            return []
        except Exception as e:
            logger.error(f"Error processing Vision response: {e}")
            return []