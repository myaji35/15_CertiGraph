"""Study sets API endpoints."""

import asyncio
import uuid
from io import BytesIO
from fastapi import APIRouter, UploadFile, File, Form, BackgroundTasks
from typing import Any

from app.api.v1.deps import CurrentUser, StudySetRepo, StorageServiceDep
from app.core.exceptions import (
    InvalidFileTypeError,
    FileTooLargeError,
    ResourceNotFoundError,
    DuplicateFileError,
)
from app.models.study_set import (
    StudySetStatus,
    LearningStatus,
)
from app.services.pdf_hash import PdfHashService


router = APIRouter(prefix="/study-sets", tags=["study-sets"])

# Constants
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB
ALLOWED_CONTENT_TYPES = ["application/pdf"]

# Processing steps for progress updates
PROCESSING_STEPS = [
    (5, "PDF 업로드 완료"),
    (15, "문서 구조 분석 중..."),
    (35, "OCR 처리 중..."),
    (55, "문제 추출 중..."),
    (75, "보기 및 정답 파싱 중..."),
    (90, "데이터 저장 중..."),
    (100, "완료!"),
]


async def process_study_set_with_upstage(
    study_set_id: str,
    pdf_content: bytes,
    repo,
):
    """
    Process a PDF for question extraction using Upstage Document Parse.

    Pipeline:
    1. Upstage Document Parse API → Markdown
    2. LLM (Claude/GPT) → Question extraction from markdown
    3. Save questions to database
    """
    from app.core.config import get_settings
    from app.services.parser.upstage import UpstageDocumentParser
    from app.services.parser.question_extractor import QuestionExtractor
    from app.repositories.mock_question import MockQuestionRepository

    settings = get_settings()

    try:
        # Step 1: Update status - Starting
        await repo.update_status(
            study_set_id,
            StudySetStatus.PARSING,
            progress=10,
            current_step="문서 분석 시작...",
        )

        # Step 2: Parse PDF with Upstage (or fallback to simple parser)
        markdown_text = ""

        if settings.upstage_api_key:
            try:
                await repo.update_status(
                    study_set_id,
                    StudySetStatus.PARSING,
                    progress=25,
                    current_step="Upstage OCR 처리 중...",
                )

                parser = UpstageDocumentParser()
                result = await parser.parse_document(pdf_content)
                markdown_text = parser.extract_full_text(result)

            except Exception as e:
                print(f"Upstage parsing failed, falling back to simple parser: {e}")
                # Fallback to simple parser
                markdown_text = await _fallback_parse(pdf_content)
        else:
            # No Upstage API key, use simple parser
            markdown_text = await _fallback_parse(pdf_content)

        # Step 3: Extract questions
        await repo.update_status(
            study_set_id,
            StudySetStatus.PROCESSING,
            progress=50,
            current_step="문제 추출 중...",
        )

        extractor = QuestionExtractor()

        # Try LLM extraction if Google Gemini API key available
        if settings.google_api_key:
            questions = await extractor.extract_with_llm(markdown_text)
        else:
            # Fallback to rule-based extraction
            questions = extractor.extract_with_rules(markdown_text)

        # Step 4: Add IDs and save questions
        await repo.update_status(
            study_set_id,
            StudySetStatus.PROCESSING,
            progress=80,
            current_step="문제 저장 중...",
        )

        for q in questions:
            q['id'] = str(uuid.uuid4())
            q['study_set_id'] = study_set_id

        question_repo = MockQuestionRepository()
        await question_repo.bulk_create(study_set_id, questions)

        # Step 5: Mark as ready
        await repo.update_status(
            study_set_id,
            StudySetStatus.READY,
            progress=100,
            current_step="완료!",
        )

        # Update question count
        await repo.update_question_count(study_set_id, len(questions))

    except Exception as e:
        print(f"Error processing study set: {e}")
        import traceback
        traceback.print_exc()

        await repo.update_status(
            study_set_id,
            StudySetStatus.FAILED,
            progress=0,
            current_step=f"오류 발생: {str(e)[:100]}",
        )


async def _fallback_parse(pdf_content: bytes) -> str:
    """Fallback PDF parsing using pdfplumber."""
    import pdfplumber
    from io import BytesIO

    text_parts = []
    with pdfplumber.open(BytesIO(pdf_content)) as pdf:
        for page in pdf.pages:
            text = page.extract_text()
            if text:
                text_parts.append(text)

    return "\n".join(text_parts)


@router.post("/upload")
async def upload_study_set(
    current_user: CurrentUser,
    repo: StudySetRepo,
    storage: StorageServiceDep,
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    name: str = Form(...),
    exam_name: str = Form(None),
    exam_year: int = Form(None),
    exam_round: int = Form(None),
    exam_session: int = Form(None),
    exam_session_name: str = Form(None),
    tags: str = Form(None),
) -> dict[str, Any]:
    """
    Upload a PDF file to create a new study set.

    The PDF is uploaded to storage and processed in the background.
    Processing includes:
    1. Upstage Document Parse for OCR and structure extraction
    2. LLM-based question extraction (or rule-based fallback)
    3. Question storage in database

    Exam metadata (exam_name, exam_year, etc.) helps organize study sets
    hierarchically by certification exam, year, round, and session.
    """
    # Validate file type
    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise InvalidFileTypeError()

    # Read file content
    content = await file.read()

    # Validate file size
    if len(content) > MAX_FILE_SIZE:
        raise FileTooLargeError()

    # Compute hash for duplicate detection
    pdf_hash = PdfHashService.compute_hash_from_bytes(content)

    # Check for duplicate (same user, same file)
    existing = await repo.find_by_hash_for_user(pdf_hash, current_user.clerk_id)
    if existing is not None:
        raise DuplicateFileError(
            existing_study_set_name=existing["name"],
            existing_study_set_id=existing["id"]
        )

    # Upload to storage
    file_obj = BytesIO(content)
    pdf_path = await storage.upload_pdf(file_obj, current_user.clerk_id)

    # Parse tags if provided
    import json
    tags_list = None
    if tags:
        try:
            tags_list = json.loads(tags)
        except json.JSONDecodeError:
            pass

    # Create study set record with PARSING status
    study_set = await repo.create(
        user_id=current_user.clerk_id,
        name=name,
        pdf_path=pdf_path,
        pdf_hash=pdf_hash,
        status=StudySetStatus.PARSING,
        source_study_set_id=None,
        exam_name=exam_name,
        exam_year=exam_year,
        exam_round=exam_round,
        exam_session=exam_session,
        exam_session_name=exam_session_name,
        tags=tags_list,
    )

    # Start background processing immediately
    background_tasks.add_task(
        process_study_set_with_upstage,
        study_set["id"],
        content,  # Pass PDF content directly
        repo,
    )

    return {
        "data": {
            "id": study_set["id"],
            "name": study_set["name"],
            "status": StudySetStatus.PARSING.value,
            "created_at": study_set["created_at"],
        }
    }


@router.get("/{study_set_id}/status")
async def get_study_set_status(
    study_set_id: str,
    current_user: CurrentUser,
    repo: StudySetRepo,
) -> dict[str, Any]:
    """Get the processing status of a study set."""
    study_set = await repo.get_by_id(study_set_id)

    if not study_set:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    # Verify ownership
    if study_set["user_id"] != current_user.clerk_id:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    return {
        "data": {
            "status": study_set["status"],
            "progress": study_set.get("progress", 0),
            "current_step": study_set.get("current_step"),
        }
    }


@router.get("/{study_set_id}")
async def get_study_set(
    study_set_id: str,
    current_user: CurrentUser,
    repo: StudySetRepo,
) -> dict[str, Any]:
    """Get a study set by ID."""
    study_set = await repo.get_by_id(study_set_id)

    if not study_set:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    # Verify ownership
    if study_set["user_id"] != current_user.clerk_id:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    question_count = await repo.get_question_count(study_set_id)

    return {
        "data": {
            "id": study_set["id"],
            "name": study_set["name"],
            "status": study_set["status"],
            "progress": study_set.get("progress", 0),
            "current_step": study_set.get("current_step"),
            "question_count": question_count,
            "created_at": study_set["created_at"],
            "exam_name": study_set.get("exam_name"),
            "exam_year": study_set.get("exam_year"),
            "exam_round": study_set.get("exam_round"),
        }
    }


@router.get("")
async def list_study_sets(
    current_user: CurrentUser,
    repo: StudySetRepo,
    limit: int = 50,
    offset: int = 0,
) -> dict[str, Any]:
    """List all study sets for the current user."""
    study_sets = await repo.find_all_by_user(
        current_user.clerk_id,
        skip=offset,
        limit=limit,
    )

    # Get question counts
    result = []
    for ss in study_sets:
        question_count = await repo.get_question_count(ss["id"])
        result.append({
            "id": ss["id"],
            "name": ss["name"],
            "status": ss["status"],
            "progress": ss.get("progress", 0),
            "current_step": ss.get("current_step"),
            "question_count": question_count,
            "created_at": ss["created_at"],
            "exam_name": ss.get("exam_name"),
            "exam_year": ss.get("exam_year"),
            "exam_round": ss.get("exam_round"),
            "exam_session": ss.get("exam_session"),
            "exam_session_name": ss.get("exam_session_name"),
            "tags": ss.get("tags"),
            "learning_status": ss.get("learning_status", "not_learned"),
            "last_studied_at": ss.get("last_studied_at"),
        })

    return {
        "data": result,
        "total": len(result),
    }


@router.patch("/{study_set_id}/learning-status")
async def update_learning_status(
    study_set_id: str,
    current_user: CurrentUser,
    repo: StudySetRepo,
    learning_status: LearningStatus,
) -> dict[str, Any]:
    """
    Update the learning status of a study set.

    Status options:
    - not_learned: 미학습 (default)
    - learned: 학습됨
    - reset: 초기화
    """
    study_set = await repo.get_by_id(study_set_id)

    if not study_set:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    # Verify ownership
    if study_set["user_id"] != current_user.clerk_id:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    # Update learning status
    updated = await repo.update_learning_status(study_set_id, learning_status.value)

    return {
        "data": {
            "id": updated["id"],
            "learning_status": updated["learning_status"],
            "last_studied_at": updated.get("last_studied_at"),
        }
    }


@router.delete("/{study_set_id}")
async def delete_study_set(
    study_set_id: str,
    current_user: CurrentUser,
    repo: StudySetRepo,
    storage: StorageServiceDep,
) -> dict[str, Any]:
    """Delete a study set and its associated questions."""
    study_set = await repo.get_by_id(study_set_id)

    if not study_set:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    # Verify ownership
    if study_set["user_id"] != current_user.clerk_id:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    # Delete from storage if PDF exists
    if study_set.get("pdf_path"):
        await storage.delete_file(study_set["pdf_path"])

    # Delete study set (questions cascade delete via FK)
    await repo.delete(study_set_id)

    return {"data": {"deleted": True}}


@router.get("/{study_set_id}/questions")
async def get_study_set_questions(
    study_set_id: str,
    current_user: CurrentUser,
    repo: StudySetRepo,
) -> dict[str, Any]:
    """
    Get all questions for a study set.

    Returns:
        List of questions with their options and metadata
    """
    # Get study set to verify ownership
    study_set = await repo.get_by_id(study_set_id)
    if not study_set:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    # Verify ownership
    if study_set["user_id"] != current_user.clerk_id:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    # Get questions
    questions = await repo.get_questions(study_set_id)

    return {"data": questions}
