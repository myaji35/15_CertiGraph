"""PDF processing pipeline.

Orchestrates the full PDF parsing flow:
1. Download PDF from storage
2. Extract text (PyMuPDF or Upstage OCR)
3. Extract questions with AI
4. Save to database
"""

import asyncio
import uuid
from datetime import datetime
from typing import Any, Callable
import httpx
import logging

from app.core.config import get_settings
from app.models.study_set import StudySetStatus
from app.repositories.study_set import StudySetRepository
from app.services.parser.upstage import UpstageDocumentParser
from app.services.parser.question_extractor import QuestionExtractor
from app.services.parser.vision_extractor import VisionQuestionExtractor
from app.services.parser.pymupdf_extractor import PyMuPDFTextExtractor

logger = logging.getLogger(__name__)


class PdfProcessingPipeline:
    """Orchestrates the full PDF processing flow."""

    # Extraction method selection
    EXTRACTION_METHOD = "pymupdf"  # Options: "pymupdf", "vision", "upstage"

    def __init__(self, repo=None, storage=None):
        self.settings = get_settings()
        self.repo = repo or StudySetRepository()
        self.storage = storage
        self.upstage_parser = UpstageDocumentParser()
        self.question_extractor = QuestionExtractor()
        self.vision_extractor = VisionQuestionExtractor()
        self.pymupdf_extractor = PyMuPDFTextExtractor()

    async def process(
        self,
        study_set_id: str,
        pdf_path: str,
    ) -> bool:
        """
        Process a PDF file through the full pipeline.

        Args:
            study_set_id: ID of the study set
            pdf_path: Storage path to the PDF

        Returns:
            True if processing succeeded, False otherwise
        """
        try:
            # Step 1: Update status to parsing
            await self._update_status(
                study_set_id,
                StudySetStatus.PARSING,
                10,
                "PDF 다운로드 중...",
            )

            # Step 2: Download PDF from storage
            pdf_content = await self._download_pdf(pdf_path)

            if self.EXTRACTION_METHOD == "pymupdf":
                # ===== PYMUPDF DIRECT TEXT EXTRACTION =====
                logger.info("📄 Using PyMuPDF direct text extraction")

                await self._update_status(
                    study_set_id,
                    StudySetStatus.PROCESSING,
                    20,
                    "텍스트 추출 중...",
                )

                # Extract text directly from PDF
                full_text = await self.pymupdf_extractor.extract_text(pdf_content)

                logger.info(
                    f"📊 PyMuPDF extraction: {len(full_text)} characters extracted"
                )

                # Save extracted text for debugging
                import os
                debug_dir = "debug_ocr"
                os.makedirs(debug_dir, exist_ok=True)
                debug_file = f"{debug_dir}/pymupdf_result_{study_set_id}.txt"
                with open(debug_file, "w", encoding="utf-8") as f:
                    f.write(f"=== PyMuPDF Result for Study Set: {study_set_id} ===\n")
                    f.write(f"Total Characters: {len(full_text)}\n")
                    f.write("="*50 + "\n\n")
                    f.write(full_text)
                logger.info(f"📝 PyMuPDF result saved to: {debug_file}")

                await self._update_status(
                    study_set_id,
                    StudySetStatus.PROCESSING,
                    40,
                    "문제 추출 중...",
                )

                # Extract questions with Gemini
                async def progress_callback(progress: int, step: str):
                    # Map extraction progress (0-100) to overall progress (40-90)
                    overall_progress = 40 + int(progress * 0.5)
                    await self._update_status(
                        study_set_id,
                        StudySetStatus.PROCESSING,
                        overall_progress,
                        step,
                    )

                questions = await self.question_extractor.extract_questions(
                    full_text,
                    on_progress=progress_callback,
                )

            elif self.EXTRACTION_METHOD == "vision":
                # ===== VISION-BASED EXTRACTION (Multimodal) =====
                logger.info("🎨 Using Vision-based extraction (Multimodal)")

                await self._update_status(
                    study_set_id,
                    StudySetStatus.PROCESSING,
                    20,
                    "이미지 변환 및 분석 중...",
                )

                # Extract questions directly from PDF images
                async def progress_callback(progress: int, step: str):
                    # Map extraction progress (0-100) to overall progress (20-90)
                    overall_progress = 20 + int(progress * 0.7)
                    await self._update_status(
                        study_set_id,
                        StudySetStatus.PROCESSING,
                        overall_progress,
                        step,
                    )

                questions = await self.vision_extractor.extract_questions(
                    pdf_content,
                    on_progress=progress_callback,
                )

            else:
                # ===== UPSTAGE OCR + TEXT EXTRACTION =====
                logger.info("📝 Using Upstage OCR + text extraction")

                await self._update_status(
                    study_set_id,
                    StudySetStatus.PARSING,
                    20,
                    "문서 구조 분석 중...",
                )

                # Step 3: Parse with Upstage
                parse_result = await self.upstage_parser.parse_document(pdf_content)
                full_text = self.upstage_parser.extract_full_text(parse_result)

                logger.info(
                    f"🔍 Upstage parsing: {parse_result.total_pages} pages, "
                    f"{len(parse_result.elements)} elements, "
                    f"{len(full_text)} characters total"
                )
                logger.info(f"🔍 Full text preview (first 1000 chars):\n{full_text[:1000]}")
                logger.info(f"🔍 Full text preview (last 500 chars):\n{full_text[-500:]}")

                # Save OCR result to text file for debugging
                import os
                debug_dir = "debug_ocr"
                os.makedirs(debug_dir, exist_ok=True)
                debug_file = f"{debug_dir}/ocr_result_{study_set_id}.txt"
                with open(debug_file, "w", encoding="utf-8") as f:
                    f.write(f"=== OCR Result for Study Set: {study_set_id} ===\n")
                    f.write(f"Total Pages: {parse_result.total_pages}\n")
                    f.write(f"Total Elements: {len(parse_result.elements)}\n")
                    f.write(f"Total Characters: {len(full_text)}\n")
                    f.write("="*50 + "\n\n")
                    f.write(full_text)
                logger.info(f"📝 OCR result saved to: {debug_file}")

                await self._update_status(
                    study_set_id,
                    StudySetStatus.PROCESSING,
                    40,
                    "문제 추출 중...",
                )

                # Step 4: Extract questions with Claude
                async def progress_callback(progress: int, step: str):
                    # Map extraction progress (0-100) to overall progress (40-90)
                    overall_progress = 40 + int(progress * 0.5)
                    await self._update_status(
                        study_set_id,
                        StudySetStatus.PROCESSING,
                        overall_progress,
                        step,
                    )

                questions = await self.question_extractor.extract_questions(
                    full_text,
                    on_progress=progress_callback,
                )

            logger.info(f"Extracted {len(questions)} questions")

            await self._update_status(
                study_set_id,
                StudySetStatus.PROCESSING,
                92,
                "데이터베이스 저장 중...",
            )

            # Step 5: Save questions to database
            await self._save_questions(study_set_id, questions)

            # Step 6: Mark as ready
            await self._update_status(
                study_set_id,
                StudySetStatus.READY,
                100,
                "완료!",
            )

            return True

        except Exception as e:
            logger.error(f"Pipeline failed for {study_set_id}: {e}")
            await self._update_status(
                study_set_id,
                StudySetStatus.FAILED,
                0,
                f"처리 실패: {str(e)[:100]}",
            )
            return False

    async def _update_status(
        self,
        study_set_id: str,
        status: StudySetStatus,
        progress: int,
        current_step: str,
    ):
        """Update study set status in database."""
        await self.repo.update_status(
            study_set_id,
            status,
            progress,
            current_step,
        )

    async def _download_pdf(self, pdf_path: str) -> bytes:
        """Download PDF from storage (Mock or Supabase)."""
        # Use Mock storage in dev mode if available
        if self.storage:
            return await self.storage.download(pdf_path)

        # Production: Download from Supabase
        storage_url = (
            f"{self.settings.supabase_url}/storage/v1/object/pdfs/{pdf_path}"
        )

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.get(
                storage_url,
                headers={
                    "apikey": self.settings.supabase_service_key,
                    "Authorization": f"Bearer {self.settings.supabase_service_key}",
                },
            )
            response.raise_for_status()
            return response.content

    async def _save_questions(
        self,
        study_set_id: str,
        questions: list,
    ):
        """Save extracted questions to database (Mock or Supabase)."""
        if not questions:
            return

        now = datetime.utcnow().isoformat()
        db_questions = []

        for q in questions:
            db_q = {
                "id": str(uuid.uuid4()),
                "study_set_id": study_set_id,
                "question_number": q.question_number,
                "question_text": q.question_text,
                "options": [{"number": opt.number, "text": opt.text} for opt in q.options],
                "correct_answer": q.correct_answer,
                "explanation": q.explanation,
                "subject": q.subject,
                "topic": q.topic,
                "created_at": now,
            }
            db_questions.append(db_q)

        # Check if we're using Mock repository
        if hasattr(self.repo, 'bulk_create'):
            # Mock mode: use bulk_create from MockQuestionRepository
            from app.repositories.mock_question import MockQuestionRepository
            question_repo = MockQuestionRepository()
            await question_repo.bulk_create(study_set_id, db_questions)
            logger.info(f"Saved {len(db_questions)} questions to Mock repository for study set {study_set_id}")

            # Update question count in study set
            await self.repo.update_status(
                study_set_id,
                status=None,  # Don't change status
                question_count=len(db_questions),
            )
            return

        # Production mode: Insert to Supabase
        batch_size = 50
        headers = {
            "apikey": self.settings.supabase_service_key,
            "Authorization": f"Bearer {self.settings.supabase_service_key}",
            "Content-Type": "application/json",
            "Prefer": "return=minimal",
        }

        async with httpx.AsyncClient() as client:
            for i in range(0, len(db_questions), batch_size):
                batch = db_questions[i:i + batch_size]
                response = await client.post(
                    f"{self.settings.supabase_url}/rest/v1/questions",
                    headers=headers,
                    json=batch,
                )
                response.raise_for_status()

        logger.info(f"Saved {len(db_questions)} questions to Supabase for study set {study_set_id}")
