"""
Enhanced PDF Processing Service with Upstage Integration

Orchestrates the complete PDF processing pipeline:
1. PDF parsing with Upstage Document Parse API
2. Question extraction using LLM
3. Database storage of questions
"""

import asyncio
import uuid
import hashlib
import logging
from typing import Optional, Callable, Dict, Any, List
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.services.upstage_client import get_upstage_client
from app.services.question_extractor_v2 import get_question_extractor
from app.core.config import get_settings

logger = logging.getLogger(__name__)


class PDFProcessorV2:
    """
    Enhanced PDF processor with Upstage integration.

    Features:
    - Upstage Document Parse for OCR
    - LLM-based question extraction
    - Database integration
    - Progress tracking
    - Error handling and recovery
    """

    def __init__(self):
        self.upstage_client = get_upstage_client()
        self.question_extractor = get_question_extractor()
        self.settings = get_settings()

    async def process_pdf(
        self,
        pdf_content: bytes,
        study_set_id: str,
        filename: str = "document.pdf",
        db: Optional[Session] = None,
        progress_callback: Optional[Callable[[str, int, str], Any]] = None,
    ) -> Dict[str, Any]:
        """
        Process PDF and extract questions.

        Args:
            pdf_content: PDF file bytes
            study_set_id: Study set ID to associate questions with
            filename: Original filename
            db: Database session (optional, for saving questions)
            progress_callback: Callback for progress updates (status, progress, message)

        Returns:
            Dict with processing results:
            {
                "success": bool,
                "total_questions": int,
                "questions": List[Dict],
                "pdf_hash": str,
                "error": str (if failed)
            }
        """
        pdf_hash = self._compute_pdf_hash(pdf_content)
        logger.info(f"📄 Processing PDF: {filename} (hash: {pdf_hash[:16]}...)")

        try:
            # Step 1: Parse PDF with Upstage (0-30%)
            if progress_callback:
                await progress_callback("processing", 5, "PDF 파싱 중...")

            parsed_content = await self.upstage_client.parse_pdf(
                pdf_content=pdf_content,
                filename=filename,
            )

            if progress_callback:
                await progress_callback("processing", 30, f"{parsed_content.total_pages}페이지 파싱 완료")

            logger.info(f"✅ Parsed {parsed_content.total_pages} pages, {len(parsed_content.text)} chars")

            # Step 2: Extract questions using LLM (30-90%)
            if progress_callback:
                await progress_callback("processing", 35, "AI로 문제 추출 중...")

            async def question_progress(current: int, total: int, message: str):
                # Map 0-100% to 35-90%
                progress = 35 + int((current / max(total, 1)) * 55)
                if progress_callback:
                    await progress_callback("processing", progress, message)

            questions = await self.question_extractor.extract_questions(
                text=parsed_content.markdown or parsed_content.text,
                progress_callback=question_progress,
            )

            if progress_callback:
                await progress_callback("processing", 90, f"{len(questions)}개 문제 추출 완료")

            logger.info(f"✅ Extracted {len(questions)} questions")

            # Step 3: Save to database (90-100%)
            if db and questions:
                if progress_callback:
                    await progress_callback("processing", 95, "데이터베이스에 저장 중...")

                saved_count = await self._save_questions_to_db(
                    db=db,
                    study_set_id=study_set_id,
                    questions=questions,
                )

                logger.info(f"✅ Saved {saved_count} questions to database")

            # Final step
            if progress_callback:
                await progress_callback("completed", 100, f"처리 완료: {len(questions)}개 문제")

            return {
                "success": True,
                "total_questions": len(questions),
                "questions": [q.to_dict() for q in questions],
                "pdf_hash": pdf_hash,
                "total_pages": parsed_content.total_pages,
            }

        except Exception as e:
            logger.error(f"❌ PDF processing failed: {str(e)}", exc_info=True)

            if progress_callback:
                await progress_callback("failed", 0, f"처리 실패: {str(e)}")

            return {
                "success": False,
                "error": str(e),
                "total_questions": 0,
                "questions": [],
                "pdf_hash": pdf_hash,
            }

    async def _save_questions_to_db(
        self,
        db: Session,
        study_set_id: str,
        questions: List[Any],
    ) -> int:
        """
        Save extracted questions to database.

        Args:
            db: Database session
            study_set_id: Study set ID
            questions: List of ExtractedQuestion objects

        Returns:
            Number of questions saved
        """
        saved_count = 0

        try:
            for question in questions:
                # Convert options to JSON format
                options_json = [
                    {"number": opt.number, "text": opt.text}
                    for opt in question.options
                ]

                # Insert question
                query = text("""
                    INSERT INTO questions (
                        id, study_set_id, question_number, question_text,
                        options, correct_answer, explanation, subject, topic
                    )
                    VALUES (
                        :id, :study_set_id, :question_number, :question_text,
                        :options::jsonb, :correct_answer, :explanation, :subject, :topic
                    )
                """)

                db.execute(query, {
                    "id": str(uuid.uuid4()),
                    "study_set_id": study_set_id,
                    "question_number": question.question_number,
                    "question_text": question.question_text,
                    "options": str(options_json).replace("'", '"'),
                    "correct_answer": question.correct_answer or 0,
                    "explanation": question.explanation,
                    "subject": question.subject,
                    "topic": question.topic,
                })
                saved_count += 1

            db.commit()
            logger.info(f"✅ Committed {saved_count} questions to database")

        except Exception as e:
            db.rollback()
            logger.error(f"❌ Failed to save questions to database: {e}", exc_info=True)
            raise

        return saved_count

    def _compute_pdf_hash(self, pdf_content: bytes) -> str:
        """Compute SHA-256 hash of PDF content for duplicate detection"""
        return hashlib.sha256(pdf_content).hexdigest()

    async def check_duplicate_pdf(
        self,
        db: Session,
        pdf_hash: str,
        clerk_id: str,
    ) -> Optional[str]:
        """
        Check if PDF has been processed before.

        Args:
            db: Database session
            pdf_hash: SHA-256 hash of PDF content
            clerk_id: User's Clerk ID

        Returns:
            Study set ID if duplicate found, None otherwise
        """
        try:
            query = text("""
                SELECT id FROM study_sets
                WHERE pdf_hash = :pdf_hash
                AND status = 'ready'
                AND source_study_set_id IS NULL
                LIMIT 1
            """)

            result = db.execute(query, {"pdf_hash": pdf_hash}).fetchone()

            if result:
                logger.info(f"✅ Found duplicate PDF: {pdf_hash[:16]}... -> study_set {result[0]}")
                return str(result[0])

            return None

        except Exception as e:
            logger.error(f"Error checking duplicate PDF: {e}")
            return None

    async def copy_questions_from_source(
        self,
        db: Session,
        source_study_set_id: str,
        target_study_set_id: str,
    ) -> int:
        """
        Copy questions from source study set to target (for duplicate PDFs).

        Args:
            db: Database session
            source_study_set_id: Source study set ID
            target_study_set_id: Target study set ID

        Returns:
            Number of questions copied
        """
        try:
            query = text("""
                INSERT INTO questions (
                    id, study_set_id, question_number, question_text,
                    options, correct_answer, explanation, subject, topic
                )
                SELECT
                    uuid_generate_v4(), :target_study_set_id, question_number, question_text,
                    options, correct_answer, explanation, subject, topic
                FROM questions
                WHERE study_set_id = :source_study_set_id
            """)

            result = db.execute(query, {
                "source_study_set_id": source_study_set_id,
                "target_study_set_id": target_study_set_id,
            })

            db.commit()
            copied = result.rowcount

            logger.info(f"✅ Copied {copied} questions from {source_study_set_id} to {target_study_set_id}")
            return copied

        except Exception as e:
            db.rollback()
            logger.error(f"❌ Failed to copy questions: {e}", exc_info=True)
            raise


# Singleton instance
_pdf_processor: Optional[PDFProcessorV2] = None


def get_pdf_processor() -> PDFProcessorV2:
    """Get or create singleton PDF processor instance"""
    global _pdf_processor
    if _pdf_processor is None:
        _pdf_processor = PDFProcessorV2()
    return _pdf_processor
