"""PDF Processing Service - Extracts questions from exam PDFs using Python algorithm."""

import asyncio
import uuid
import os
import tempfile
from typing import Optional
import logging

logger = logging.getLogger(__name__)


class SimplePDFProcessor:
    """PDF processor that extracts exam questions using Python regex algorithm."""

    def __init__(self):
        logger.info("📡 Using Python Algorithm Parser (NO LLM, NO MOCK DATA)")

    async def process_pdf(
        self,
        material_id: str,
        file_content: bytes,
        title: str,
        update_callback: Optional[callable] = None,
    ) -> dict:
        """
        Process PDF and extract questions using Python algorithm.

        Args:
            material_id: ID of the study material
            file_content: PDF file bytes
            title: Title of the material
            update_callback: Callback for progress updates (status, progress, message)

        Returns:
            Dict with processing result
        """
        try:
            logger.info(f"📄 Starting PDF processing for material {material_id}")
            logger.info(f"📊 File size: {len(file_content)} bytes")

            # Step 1: Save to temporary file
            if update_callback:
                await update_callback("processing", 10, "임시 파일 생성 중...")

            with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as temp_file:
                temp_file.write(file_content)
                temp_path = temp_file.name

            try:
                # Step 2: Parse questions using Python algorithm
                if update_callback:
                    await update_callback("processing", 30, "Python 알고리즘으로 문제 파싱 중...")

                questions = await self._parse_questions_with_algorithm(
                    material_id, temp_path, title, update_callback
                )

                # Step 3: Final processing
                if update_callback:
                    await update_callback("processing", 90, "문제 저장 중...")
                await asyncio.sleep(0.5)

                if update_callback:
                    await update_callback("completed", 100, f"{len(questions)}개 문제 추출 완료")

                logger.info(f"✅ PDF processing completed: {len(questions)} questions extracted")

                return {
                    "success": True,
                    "total_questions": len(questions),
                    "questions": questions,
                }

            finally:
                # Clean up temporary file
                if os.path.exists(temp_path):
                    os.unlink(temp_path)

        except Exception as e:
            logger.error(f"❌ PDF processing failed: {str(e)}", exc_info=True)
            if update_callback:
                await update_callback("failed", 0, f"처리 실패: {str(e)}")

            return {
                "success": False,
                "error": str(e),
                "total_questions": 0,
                "questions": [],
            }

    async def _parse_questions_with_algorithm(
        self,
        material_id: str,
        pdf_path: str,
        title: str,
        update_callback: Optional[callable] = None,
    ) -> list[dict]:
        """Parse questions from PDF using Python regex algorithm. NO LLM, NO MOCK."""
        from app.services.parser.exam_pdf_parser_v2 import ExamPDFParser

        logger.info("🤖 Parsing questions with Python Algorithm")

        if update_callback:
            await update_callback("processing", 40, "PDF 텍스트 추출 중...")

        # Run parser in thread to avoid blocking
        parser = ExamPDFParser(pdf_path)

        # Extract text
        await asyncio.to_thread(parser.extract_text)

        if update_callback:
            await update_callback("processing", 60, "문제 구조 분석 중...")

        # Parse questions
        parsed_questions = await asyncio.to_thread(parser.parse_questions)

        if update_callback:
            await update_callback("processing", 80, "문제 정규화 중...")

        # Convert to our format
        questions = []
        for q in parsed_questions:
            # Combine passage items into options-style format
            options = []
            for i, choice in enumerate(q.choices, 1):
                options.append({
                    "number": choice.number,
                    "text": choice.text
                })

            # Build passage text
            passage_text = None
            if q.passage:
                passage_parts = []
                for p in q.passage:
                    if p.marker == '○':
                        passage_parts.append(f"○ {p.text}")
                    else:
                        passage_parts.append(f"{p.marker}. {p.text}")
                if passage_parts:
                    passage_text = "\n".join(passage_parts)

            question = {
                "id": str(uuid.uuid4()),
                "material_id": material_id,
                "question_number": q.number,
                "passage": passage_text,
                "question_text": q.question,
                "options": options,
                "correct_answer": None,  # Algorithm can't extract answers
                "explanation": None,
            }
            questions.append(question)

        logger.info(f"✅ Python Algorithm extracted {len(questions)} questions")
        return questions
