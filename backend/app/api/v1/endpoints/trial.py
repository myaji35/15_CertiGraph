"""Free trial and subscription management endpoints."""

from datetime import datetime
from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, status
from supabase import Client

from app.api.v1.deps import get_current_user, get_supabase
from app.models.trial import (
    PracticeSessionCreate,
    PracticeSessionResponse,
    PracticeSessionComplete,
    UserLimitsResponse,
    TrialStatusResponse,
    UpgradeRequiredError,
    SubscriptionTier,
)

router = APIRouter()


@router.get("/limits", response_model=UserLimitsResponse)
async def get_user_limits(
    current_user: Annotated[dict, Depends(get_current_user)],
    supabase: Annotated[Client, Depends(get_supabase)],
):
    """
    Get current user's subscription limits and usage.

    Returns information about:
    - Subscription tier
    - PDF upload limits
    - Practice session limits
    - Current usage
    """
    clerk_user_id = current_user["sub"]

    # Get or create user limits
    result = supabase.table("user_limits").select("*").eq("clerk_user_id", clerk_user_id).execute()

    if not result.data:
        # Create default free tier limits
        default_limits = {
            "clerk_user_id": clerk_user_id,
            "subscription_tier": "free",
            "max_pdfs_per_month": 1,
            "max_practice_sessions_per_pdf": 2,
            "current_month_pdfs_uploaded": 0,
        }
        result = supabase.table("user_limits").insert(default_limits).execute()

    limits = result.data[0]

    return UserLimitsResponse(
        subscription_tier=limits["subscription_tier"],
        max_pdfs_per_month=limits["max_pdfs_per_month"],
        max_practice_sessions_per_pdf=limits["max_practice_sessions_per_pdf"],
        current_month_pdfs_uploaded=limits["current_month_pdfs_uploaded"],
        can_upload_pdf=limits["current_month_pdfs_uploaded"] < limits["max_pdfs_per_month"],
        subscription_end_date=limits.get("subscription_end_date"),
    )


@router.get("/study-sets/{study_set_id}/trial-status", response_model=TrialStatusResponse)
async def get_trial_status(
    study_set_id: str,
    current_user: Annotated[dict, Depends(get_current_user)],
    supabase: Annotated[Client, Depends(get_supabase)],
):
    """
    Get trial status for a specific study set.

    Returns:
    - Sessions used
    - Sessions remaining
    - Whether user can start new session
    - Upgrade requirement
    """
    clerk_user_id = current_user["sub"]

    # Get study set info
    study_set_result = supabase.table("study_sets").select(
        "is_free_trial, practice_sessions_used"
    ).eq("id", study_set_id).execute()

    if not study_set_result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Study set not found"
        )

    study_set = study_set_result.data[0]

    # Get user limits
    limits_result = supabase.table("user_limits").select("*").eq("clerk_user_id", clerk_user_id).execute()

    if not limits_result.data:
        # Create default limits
        limits = {
            "subscription_tier": "free",
            "max_practice_sessions_per_pdf": 2,
        }
    else:
        limits = limits_result.data[0]

    max_sessions = limits["max_practice_sessions_per_pdf"]
    sessions_used = study_set["practice_sessions_used"]
    sessions_remaining = max(0, max_sessions - sessions_used)

    # Paid users have unlimited sessions
    is_paid = limits["subscription_tier"] != "free"
    can_start = is_paid or sessions_remaining > 0
    requires_upgrade = not is_paid and sessions_remaining == 0

    upgrade_message = None
    if requires_upgrade:
        upgrade_message = f"무료 체험 {max_sessions}회를 모두 사용했습니다. 유료 플랜으로 업그레이드하여 무제한으로 학습하세요."

    return TrialStatusResponse(
        study_set_id=study_set_id,
        is_free_trial=study_set["is_free_trial"],
        practice_sessions_used=sessions_used,
        practice_sessions_remaining=sessions_remaining if not is_paid else 999,
        can_start_session=can_start,
        requires_upgrade=requires_upgrade,
        upgrade_message=upgrade_message,
    )


@router.post("/sessions", response_model=PracticeSessionResponse, status_code=status.HTTP_201_CREATED)
async def start_practice_session(
    session_data: PracticeSessionCreate,
    current_user: Annotated[dict, Depends(get_current_user)],
    supabase: Annotated[Client, Depends(get_supabase)],
):
    """
    Start a new practice session.

    Checks trial limits before allowing session to start.
    Increments session counter for free trial users.
    """
    clerk_user_id = current_user["sub"]

    # Check if user can start session using database function
    can_start_result = supabase.rpc(
        "can_start_practice_session",
        {
            "p_study_set_id": session_data.study_set_id,
            "p_clerk_user_id": clerk_user_id,
        }
    ).execute()

    if not can_start_result.data:
        # Get trial status for error message
        trial_status = await get_trial_status(session_data.study_set_id, current_user, supabase)

        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail=UpgradeRequiredError(
                trial_status=trial_status,
            ).model_dump(),
        )

    # Create practice session
    session = {
        "study_set_id": session_data.study_set_id,
        "clerk_user_id": clerk_user_id,
        "session_type": session_data.session_type,
        "started_at": datetime.utcnow().isoformat(),
    }

    result = supabase.table("practice_sessions").insert(session).execute()

    # Increment session counter
    supabase.rpc("increment_practice_session", {"p_study_set_id": session_data.study_set_id}).execute()

    return PracticeSessionResponse(**result.data[0])


@router.patch("/sessions/{session_id}/complete", response_model=PracticeSessionResponse)
async def complete_practice_session(
    session_id: str,
    completion_data: PracticeSessionComplete,
    current_user: Annotated[dict, Depends(get_current_user)],
    supabase: Annotated[Client, Depends(get_supabase)],
):
    """
    Complete a practice session with results.

    Updates session with:
    - Questions attempted
    - Questions correct
    - Time spent
    - Completion timestamp
    """
    clerk_user_id = current_user["sub"]

    # Verify session belongs to user
    session_result = supabase.table("practice_sessions").select("*").eq(
        "id", session_id
    ).eq("clerk_user_id", clerk_user_id).execute()

    if not session_result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Practice session not found"
        )

    # Update session
    update_data = {
        "questions_attempted": completion_data.questions_attempted,
        "questions_correct": completion_data.questions_correct,
        "time_spent_seconds": completion_data.time_spent_seconds,
        "completed_at": datetime.utcnow().isoformat(),
    }

    result = supabase.table("practice_sessions").update(update_data).eq("id", session_id).execute()

    return PracticeSessionResponse(**result.data[0])


@router.get("/sessions", response_model=list[PracticeSessionResponse])
async def get_user_sessions(
    current_user: Annotated[dict, Depends(get_current_user)],
    supabase: Annotated[Client, Depends(get_supabase)],
    study_set_id: str | None = None,
    limit: int = 50,
):
    """
    Get user's practice sessions history.

    Optionally filter by study_set_id.
    """
    clerk_user_id = current_user["sub"]

    query = supabase.table("practice_sessions").select("*").eq("clerk_user_id", clerk_user_id)

    if study_set_id:
        query = query.eq("study_set_id", study_set_id)

    result = query.order("created_at", desc=True).limit(limit).execute()

    return [PracticeSessionResponse(**session) for session in result.data]
