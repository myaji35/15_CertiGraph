"""Test API endpoints."""

from fastapi import APIRouter
from typing import Any

from app.api.v1.deps import CurrentUser, StudySetRepo
from app.core.exceptions import ResourceNotFoundError, ValidationFormatError
from app.models.test import (
    TestMode,
    TestStartRequest,
    TestSubmitRequest,
)
from app.services.test_engine import TestSessionService, ScoringService


router = APIRouter(prefix="/tests", tags=["tests"])


@router.post("/start")
async def start_test(
    request: TestStartRequest,
    current_user: CurrentUser,
    study_set_repo: StudySetRepo,
) -> dict[str, Any]:
    """
    Start a new test session.

    Modes:
    - all: All questions in order
    - random: Random selection of questions
    - wrong_only: Only previously incorrect questions
    """
    # Verify study set exists and belongs to user
    study_set = await study_set_repo.get_by_id(request.study_set_id)

    if not study_set:
        raise ResourceNotFoundError("학습 세트", request.study_set_id)

    if study_set["user_id"] != current_user.clerk_id:
        raise ResourceNotFoundError("학습 세트", request.study_set_id)

    if study_set["status"] != "ready":
        raise ValidationFormatError("학습 세트가 아직 준비되지 않았습니다.")

    # Validate question count for random mode
    if request.mode == TestMode.RANDOM and not request.question_count:
        raise ValidationFormatError("랜덤 모드에서는 문제 수를 지정해야 합니다.")

    # Start session
    service = TestSessionService()
    result = await service.start_session(
        user_id=current_user.clerk_id,
        study_set_id=request.study_set_id,
        mode=request.mode,
        question_count=request.question_count,
        shuffle_options=request.shuffle_options,
    )

    return {"data": result}


@router.post("/submit")
async def submit_test(
    request: TestSubmitRequest,
    current_user: CurrentUser,
) -> dict[str, Any]:
    """Submit test answers and get score."""
    # Verify session exists and belongs to user
    service = TestSessionService()
    session = await service.get_session(request.session_id)

    if not session:
        raise ResourceNotFoundError("테스트 세션", request.session_id)

    if session["user_id"] != current_user.clerk_id:
        raise ResourceNotFoundError("테스트 세션", request.session_id)

    if session["status"] != "in_progress":
        raise ValidationFormatError("이미 완료된 테스트입니다.")

    # Score and save
    scoring_service = ScoringService()
    result = await scoring_service.submit_and_score(
        session_id=request.session_id,
        answers=[a.model_dump() for a in request.answers],
    )

    return {"data": result}


@router.get("/{session_id}/result")
async def get_test_result(
    session_id: str,
    current_user: CurrentUser,
) -> dict[str, Any]:
    """Get detailed test results for review."""
    service = TestSessionService()
    session = await service.get_session(session_id)

    if not session:
        raise ResourceNotFoundError("테스트 세션", session_id)

    if session["user_id"] != current_user.clerk_id:
        raise ResourceNotFoundError("테스트 세션", session_id)

    scoring_service = ScoringService()
    result = await scoring_service.get_result(session_id)

    return {"data": result}


@router.get("/history")
async def get_test_history(
    current_user: CurrentUser,
    study_set_id: str | None = None,
    limit: int = 20,
) -> dict[str, Any]:
    """Get user's test session history."""
    service = TestSessionService()
    sessions = await service.get_session_history(
        user_id=current_user.clerk_id,
        study_set_id=study_set_id,
        limit=limit,
    )

    return {
        "data": sessions,
        "total": len(sessions),
    }
