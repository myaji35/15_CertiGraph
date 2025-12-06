"""Study sets API endpoints."""

import asyncio
from io import BytesIO
from fastapi import APIRouter, UploadFile, File, Form, BackgroundTasks
from typing import Any

from app.api.v1.deps import CurrentUser
from app.core.exceptions import (
    InvalidFileTypeError,
    FileTooLargeError,
    ResourceNotFoundError,
)
from app.models.study_set import (
    StudySetStatus,
    StudySetResponse,
    StudySetStatusResponse,
    StudySetListResponse,
)
from app.services.pdf_hash import PdfHashService
from app.services.storage import StorageService
from app.repositories.study_set import StudySetRepository


router = APIRouter(prefix="/study-sets", tags=["study-sets"])

# Constants
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB
ALLOWED_CONTENT_TYPES = ["application/pdf"]

# Fake processing steps for cached duplicates
FAKE_PROCESSING_STEPS = [
    (10, "문서 업로드 중..."),
    (25, "문서 구조 분석 중..."),
    (45, "문제 추출 중..."),
    (65, "보기 및 정답 파싱 중..."),
    (80, "해설 연결 중..."),
    (95, "최종 검증 중..."),
    (100, "완료!"),
]


async def process_cached_study_set(study_set_id: str, source_study_set_id: str):
    """
    Simulate processing for a cached study set.

    Shows fake progress to the user while copying questions from source.
    This saves processing time and API costs for duplicate PDFs.
    """
    repo = StudySetRepository()

    # Simulate processing with fake progress
    for progress, step in FAKE_PROCESSING_STEPS:
        await repo.update_status(
            study_set_id,
            StudySetStatus.PROCESSING if progress < 100 else StudySetStatus.READY,
            progress=progress,
            current_step=step,
        )
        # Add realistic delay between steps
        await asyncio.sleep(1.5 if progress < 50 else 1.0)

    # Copy questions from source study set
    await repo.copy_questions_from_source(source_study_set_id, study_set_id)

    # Mark as ready
    await repo.update_status(
        study_set_id,
        StudySetStatus.READY,
        progress=100,
        current_step="완료!",
    )


async def process_study_set(study_set_id: str, pdf_path: str):
    """
    Process a new PDF for question extraction.

    Uses the full pipeline: Upstage Document Parse → Claude Question Extraction
    """
    from app.services.parser.pipeline import PdfProcessingPipeline

    pipeline = PdfProcessingPipeline()
    await pipeline.process(study_set_id, pdf_path)


@router.post("/upload")
async def upload_study_set(
    current_user: CurrentUser,
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    name: str = Form(...),
) -> dict[str, Any]:
    """
    Upload a PDF file to create a new study set.

    If a duplicate PDF is detected (same hash), we reuse cached results
    while showing fake processing progress to the user.
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

    # Check for duplicate
    repo = StudySetRepository()
    existing = await repo.find_by_hash(pdf_hash)

    is_cached = existing is not None
    source_study_set_id = existing["id"] if existing else None

    # Upload to storage
    storage = StorageService()
    file_obj = BytesIO(content)
    pdf_path = await storage.upload_pdf(file_obj, current_user.clerk_id)

    # Create study set record
    # TODO: Get internal user_id from users table using clerk_id
    # For now, using clerk_id directly
    study_set = await repo.create(
        user_id=current_user.clerk_id,
        name=name,
        pdf_path=pdf_path,
        pdf_hash=pdf_hash,
        status=StudySetStatus.UPLOADING,
        source_study_set_id=source_study_set_id,
    )

    # Queue background processing
    if is_cached:
        # Use fake processing with cached results
        background_tasks.add_task(
            process_cached_study_set,
            study_set["id"],
            source_study_set_id,
        )
    else:
        # Process new PDF
        background_tasks.add_task(
            process_study_set,
            study_set["id"],
            pdf_path,
        )

    return {
        "data": {
            "id": study_set["id"],
            "name": study_set["name"],
            "status": StudySetStatus.PARSING.value,
            "created_at": study_set["created_at"],
            "is_cached": is_cached,
        }
    }


@router.get("/{study_set_id}/status")
async def get_study_set_status(
    study_set_id: str,
    current_user: CurrentUser,
) -> dict[str, Any]:
    """Get the processing status of a study set."""
    repo = StudySetRepository()
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
            "is_cached": study_set.get("source_study_set_id") is not None,
        }
    }


@router.get("/{study_set_id}")
async def get_study_set(
    study_set_id: str,
    current_user: CurrentUser,
) -> dict[str, Any]:
    """Get a study set by ID."""
    repo = StudySetRepository()
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
            "question_count": question_count,
            "created_at": study_set["created_at"],
            "is_cached": study_set.get("source_study_set_id") is not None,
        }
    }


@router.get("")
async def list_study_sets(
    current_user: CurrentUser,
    limit: int = 50,
    offset: int = 0,
) -> dict[str, Any]:
    """List all study sets for the current user."""
    repo = StudySetRepository()
    study_sets = await repo.get_by_user(
        current_user.clerk_id,
        limit=limit,
        offset=offset,
    )

    # Get question counts
    result = []
    for ss in study_sets:
        question_count = await repo.get_question_count(ss["id"])
        result.append({
            "id": ss["id"],
            "name": ss["name"],
            "status": ss["status"],
            "question_count": question_count,
            "created_at": ss["created_at"],
            "is_cached": ss.get("source_study_set_id") is not None,
        })

    return {
        "data": result,
        "total": len(result),
    }


@router.delete("/{study_set_id}")
async def delete_study_set(
    study_set_id: str,
    current_user: CurrentUser,
) -> dict[str, Any]:
    """Delete a study set and its associated questions."""
    repo = StudySetRepository()
    study_set = await repo.get_by_id(study_set_id)

    if not study_set:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    # Verify ownership
    if study_set["user_id"] != current_user.clerk_id:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    # Delete from storage if PDF exists
    if study_set.get("pdf_path"):
        storage = StorageService()
        await storage.delete_file(study_set["pdf_path"])

    # Delete study set (questions cascade delete via FK)
    await repo.delete(study_set_id)

    return {"data": {"deleted": True}}
