"""Study sets API endpoints."""

import asyncio
from io import BytesIO
from fastapi import APIRouter, UploadFile, File, Form, Body, BackgroundTasks, Depends
from typing import Any, Dict

from app.api.v1.deps import (
    CurrentUser,
    StudySetRepo,
    StorageServiceDep,
    SettingsDep,
    get_current_user,
    get_study_set_repository,
)
from app.core.exceptions import (
    InvalidFileTypeError,
    FileTooLargeError,
    ResourceNotFoundError,
    DuplicateFileError,
)
from app.models.study_set import (
    StudySetStatus,
    LearningStatus,
    StudySetResponse,
    StudySetStatusResponse,
    StudySetListResponse,
)
from app.services.pdf_hash import PdfHashService
from app.services.storage import StorageService
from app.repositories.study_set import StudySetRepository


router = APIRouter(prefix="/study-sets", tags=["study-sets"])

# In-memory storage for mock study sets (when Supabase is not available)
MOCK_STUDY_SETS: Dict[str, dict] = {}

# Constants
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB
ALLOWED_CONTENT_TYPES = ["application/pdf"]


@router.post("")
async def create_study_set(
    current_user: CurrentUser,
    repo: StudySetRepo,
    settings: SettingsDep,
    payload: dict[str, Any] = Body(...),
) -> dict[str, Any]:
    """
    Create a new study set with metadata only (no PDF).

    This allows users to create a study set container first,
    then add study materials (PDFs) later.

    Request Body:
        {
            "name": "Study set name (required)",
            "certification_id": "Certification ID (required)",
            "exam_date": "2024-03-15",  // optional, ISO date format
            "description": "Description text"  // optional
        }

    Returns:
        Created study set data with ID
    """
    from fastapi import HTTPException, status as http_status, Body
    from supabase import create_client

    # Extract fields from payload
    name = payload.get("name")
    certification_id = payload.get("certification_id")
    exam_date = payload.get("exam_date")
    description = payload.get("description", "")

    # Validate required fields
    if not name or not name.strip():
        raise HTTPException(
            status_code=http_status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="문제집 이름을 입력해주세요"
        )

    if not certification_id:
        raise HTTPException(
            status_code=http_status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="자격증을 선택해주세요"
        )

    # VIP users list (hardcoded for now)
    VIP_CLERK_IDS = ["user_36T9Qa8HsuaM1fMjTisw4frRH1Z"]  # myaji35@gmail.com

    # Check for active subscription to this certification (skip for VIP users and in dev/test mode)
    if current_user.clerk_id not in VIP_CLERK_IDS and not settings.dev_mode and not settings.test_mode:
        supabase = create_client(settings.supabase_url, settings.supabase_service_key)
        has_subscription = supabase.rpc(
            'has_active_subscription',
            {
                'p_clerk_user_id': current_user.clerk_id,
                'p_certification_id': certification_id
            }
        ).execute()

        if not has_subscription.data:
            raise HTTPException(
                status_code=http_status.HTTP_402_PAYMENT_REQUIRED,
                detail=f"이 자격증에 대한 구독이 필요합니다. 먼저 구독을 구매해주세요."
            )

    # Create study set (without PDF)
    # Note: MockStudySetRepository only supports basic parameters
    try:
        study_set = await repo.create(
            user_id=current_user.clerk_id,
            name=name.strip(),
            pdf_path=None,  # No PDF yet
            pdf_hash=None,  # No PDF yet
            status=StudySetStatus.READY,
            source_study_set_id=None,
        )
    except Exception as e:
        # Fallback for when Supabase is unavailable
        import uuid
        from datetime import datetime

        study_set = {
            "id": str(uuid.uuid4()),
            "user_id": current_user.clerk_id,
            "name": name.strip(),
            "certification_id": certification_id,
            "description": description,
            "status": "ready",
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
            "total_materials": 0,
            "total_questions": 0
        }
        # Store in memory for later retrieval
        MOCK_STUDY_SETS[study_set["id"]] = study_set
        print(f"[DEBUG] Study set created (mock): {study_set}")
        print(f"[DEBUG] Total mock study sets in memory: {len(MOCK_STUDY_SETS)}")

    # Store additional metadata separately for now
    # In production, these would be stored in the database
    from datetime import datetime

    return {
        "study_set": {
            "id": study_set["id"],
            "name": study_set.get("name", name.strip()),
            "certification_id": certification_id,
            "exam_date": exam_date,
            "description": description,
            "status": study_set.get("status", StudySetStatus.READY.value),
            "created_at": study_set.get("created_at", datetime.utcnow().isoformat()),
        }
    }

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


async def process_cached_study_set(
    study_set_id: str,
    source_study_set_id: str,
    repo
):
    """
    Simulate processing for a cached study set.

    Shows fake progress to the user while copying questions from source.
    This saves processing time and API costs for duplicate PDFs.
    """

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


async def process_study_set(study_set_id: str, pdf_path: str, repo, storage=None):
    """
    Process a new PDF for question extraction.

    Uses simple rule-based parser (no LLM API required)
    """
    import uuid
    from app.services.parser.simple_pdf_parser import parse_pdf_simple
    from app.models.study_set import StudySetStatus
    from app.repositories.mock_question import MockQuestionRepository

    try:
        # Update status
        await repo.update_status(
            study_set_id,
            StudySetStatus.PARSING,
            progress=10,
            current_step="PDF 텍스트 추출 중...",
        )

        # Get full path if using mock storage
        if not pdf_path.startswith('/'):
            full_path = f"mock_storage/{pdf_path}"
        else:
            full_path = pdf_path

        # Parse PDF
        await repo.update_status(
            study_set_id,
            StudySetStatus.PROCESSING,
            progress=30,
            current_step="문제 파싱 중...",
        )

        questions = parse_pdf_simple(full_path)

        # Add IDs to questions
        for q in questions:
            q['id'] = str(uuid.uuid4())
            q['study_set_id'] = study_set_id

        # Save questions
        await repo.update_status(
            study_set_id,
            StudySetStatus.PROCESSING,
            progress=70,
            current_step="문제 저장 중...",
        )

        question_repo = MockQuestionRepository()
        await question_repo.bulk_create(study_set_id, questions)

        # Mark as ready
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
        await repo.update_status(
            study_set_id,
            StudySetStatus.FAILED,
            progress=0,
            current_step=f"오류 발생: {str(e)}",
        )


@router.post("/upload")
async def upload_study_set(
    current_user: CurrentUser,
    repo: StudySetRepo,
    storage: StorageServiceDep,
    settings: SettingsDep,
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    name: str = Form(...),
    certification_id: str = Form(...),  # 자격증 ID 필수
    exam_name: str = Form(None),
    exam_year: int = Form(None),
    exam_round: int = Form(None),
    exam_session: int = Form(None),
    exam_session_name: str = Form(None),
    tags: str = Form(None),  # JSON array as string
) -> dict[str, Any]:
    """
    Upload a PDF file to create a new study set.

    Requires active subscription for the specified certification.
    If a duplicate PDF is detected (same hash), we reuse cached results
    while showing fake processing progress to the user.

    Exam metadata (exam_name, exam_year, etc.) helps organize study sets
    hierarchically by certification exam, year, round, and session.
    """
    from fastapi import HTTPException, status as http_status
    from app.api.v1.deps import get_supabase

    # 구독 확인: 해당 자격증에 대한 활성 구독이 있는지 검사 (skip in dev/test mode)
    if not settings.dev_mode and not settings.test_mode:
        supabase = get_supabase()
        has_subscription = supabase.rpc(
            'has_active_subscription',
            {
                'p_clerk_user_id': current_user.clerk_id,
                'p_certification_id': certification_id
            }
        ).execute()

        if not has_subscription.data:
            raise HTTPException(
                status_code=http_status.HTTP_402_PAYMENT_REQUIRED,
                detail=f"이 자격증에 대한 구독이 필요합니다. 먼저 구독을 구매해주세요."
            )

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
    existing = await repo.find_by_hash(pdf_hash)
    if existing is not None:
        # Duplicate file detected - raise error
        raise DuplicateFileError(
            existing_study_set_name=existing["name"],
            existing_study_set_id=existing["id"]
        )

    is_cached = False
    source_study_set_id = None

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

    # Create study set record (ready but not parsed yet)
    # TODO: Get internal user_id from users table using clerk_id
    # For now, using clerk_id directly
    study_set = await repo.create(
        user_id=current_user.clerk_id,
        name=name,
        pdf_path=pdf_path,
        pdf_hash=pdf_hash,
        status=StudySetStatus.READY,  # Ready for parsing when user starts learning
        source_study_set_id=None,
        certification_id=certification_id,  # 자격증 ID 저장
        exam_name=exam_name,
        exam_year=exam_year,
        exam_round=exam_round,
        exam_session=exam_session,
        exam_session_name=exam_session_name,
        tags=tags_list,
    )

    # Don't process PDF on upload - wait for user to start learning
    # Processing will happen when user clicks "학습 시작"

    return {
        "data": {
            "id": study_set["id"],
            "name": study_set["name"],
            "status": StudySetStatus.READY.value,
            "created_at": study_set["created_at"],
            "is_cached": False,
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
            "is_cached": study_set.get("source_study_set_id") is not None,
        }
    }


@router.get("/{study_set_id}")
async def get_study_set(
    study_set_id: str,
    current_user: CurrentUser,
    repo: StudySetRepo,
) -> dict[str, Any]:
    """Get a study set by ID."""
    # First try to get from mock storage
    if study_set_id in MOCK_STUDY_SETS:
        study_set = MOCK_STUDY_SETS[study_set_id]
        print(f"[DEBUG] Found study set in mock storage: {study_set_id}")

        # Verify ownership
        if study_set["user_id"] != current_user.clerk_id:
            raise ResourceNotFoundError("학습 세트", study_set_id)

        return {
            "data": {
                "id": study_set["id"],
                "name": study_set["name"],
                "status": study_set.get("status", "ready"),
                "question_count": study_set.get("total_questions", 0),
                "created_at": study_set["created_at"],
                "is_cached": False,
                "certification_id": study_set.get("certification_id"),
                "description": study_set.get("description")
            }
        }

    # Try to get from repository
    try:
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
    except Exception as e:
        print(f"[DEBUG] Error fetching study set {study_set_id}: {e}")
        raise ResourceNotFoundError("학습 세트", study_set_id)


@router.get("")
async def list_study_sets(
    current_user: CurrentUser,
    repo: StudySetRepo,
    limit: int = 50,
    offset: int = 0,
) -> dict[str, Any]:
    """List all study sets for the current user."""
    from app.repositories.mock_study_material import MockStudyMaterialRepository
    
    result = []
    material_repo = MockStudyMaterialRepository()

    # First, add mock study sets for the current user
    for study_set_id, study_set in MOCK_STUDY_SETS.items():
        if study_set["user_id"] == current_user.clerk_id:
            # Calculate actual counts from materials
            material_count = await material_repo.count_by_study_set(study_set_id)
            total_questions = await material_repo.get_total_questions(study_set_id)
            
            result.append({
                "id": study_set["id"],
                "name": study_set["name"],
                "status": study_set.get("status", "ready"),
                "question_count": total_questions,  # For backward compatibility
                "created_at": study_set["created_at"],
                "is_cached": False,
                "certification_id": study_set.get("certification_id"),
                "total_materials": material_count,
                "total_questions": total_questions,
                "learning_status": study_set.get("learning_status", "not_learned"),
                "description": study_set.get("description"),
            })

    print(f"[DEBUG] Found {len(result)} mock study sets for user {current_user.clerk_id}")

    # Try to get from repository (will fail if Supabase is down)
    try:
        study_sets = await repo.find_all_by_user(
            current_user.clerk_id,
            skip=offset,
            limit=limit,
        )

        # Get question counts and material counts
        for ss in study_sets:
            material_count = await material_repo.count_by_study_set(ss["id"])
            total_questions = await material_repo.get_total_questions(ss["id"])
            
            result.append({
                "id": ss["id"],
                "name": ss["name"],
                "status": ss["status"],
                "question_count": total_questions,  # For backward compatibility
                "created_at": ss["created_at"],
                "is_cached": ss.get("source_study_set_id") is not None,
                "exam_name": ss.get("exam_name"),
                "exam_year": ss.get("exam_year"),
                "exam_round": ss.get("exam_round"),
                "exam_session": ss.get("exam_session"),
                "exam_session_name": ss.get("exam_session_name"),
                "tags": ss.get("tags"),
                "total_materials": material_count,
                "total_questions": total_questions,
                "learning_status": ss.get("learning_status", "not_learned"),
                "last_studied_at": ss.get("last_studied_at"),
            })
    except Exception as e:
        print(f"[DEBUG] Error fetching from repository: {e}")
        # Continue with mock data only

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


@router.post("/{study_set_id}/parse")
async def parse_study_set(
    study_set_id: str,
    current_user: CurrentUser,
    repo: StudySetRepo,
    storage: StorageServiceDep,
    background_tasks: BackgroundTasks,
) -> dict[str, Any]:
    """
    Parse the PDF file for a study set to extract questions.

    This is called when the user clicks "학습 시작" (Start Learning).
    The PDF is processed in the background using Upstage + Claude.
    """
    study_set = await repo.get_by_id(study_set_id)

    if not study_set:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    # Verify ownership
    if study_set["user_id"] != current_user.clerk_id:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    # Check if already processed
    question_count = await repo.get_question_count(study_set_id)
    if question_count > 0:
        return {
            "data": {
                "status": study_set["status"],
                "message": "이미 처리된 학습 세트입니다.",
                "question_count": question_count,
            }
        }

    # Start background processing
    background_tasks.add_task(
        process_study_set,
        study_set_id,
        study_set["pdf_path"],
        repo,
        storage,
    )

    # Update status to parsing
    await repo.update_status(
        study_set_id,
        StudySetStatus.PARSING,
        progress=0,
        current_step="PDF 파싱 시작 중...",
    )

    return {
        "data": {
            "status": StudySetStatus.PARSING.value,
            "message": "PDF 파싱이 시작되었습니다.",
        }
    }


@router.patch("/{study_set_id}")
async def update_study_set(
    study_set_id: str,
    current_user: CurrentUser,
    repo: StudySetRepo,
    name: str = Form(None),
    description: str = Form(None),
) -> dict[str, Any]:
    """Update a study set's name or description."""
    study_set = await repo.get_by_id(study_set_id)

    if not study_set:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    # Verify ownership
    if study_set["user_id"] != current_user.clerk_id:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    # Update fields if provided
    updates = {}
    if name is not None and name.strip():
        updates["name"] = name.strip()
    if description is not None:
        updates["description"] = description.strip()

    if updates:
        # For MockRepository, we'll just return the updated data
        # In production, this would update the database
        study_set.update(updates)

    return {
        "id": study_set_id,
        "name": study_set.get("name"),
        "description": study_set.get("description"),
        "updated": True
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
    study_set = await repo.get(study_set_id)
    if not study_set:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    # Verify ownership
    if study_set["user_id"] != current_user.clerk_id:
        raise ResourceNotFoundError("학습 세트", study_set_id)

    # Get questions from Supabase
    questions = await repo.get_questions(study_set_id)

    return {"data": questions}
