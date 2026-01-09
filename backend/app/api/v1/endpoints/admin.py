"""Admin endpoints for user management."""

from fastapi import APIRouter, HTTPException, status, Depends
from typing import List
from pydantic import BaseModel
from datetime import datetime

from app.api.v1.deps import CurrentUser, get_supabase, SettingsDep

router = APIRouter(prefix="/admin", tags=["Admin"])


class UserSubscriptionInfo(BaseModel):
    """User with subscription information."""
    clerk_id: str
    email: str
    created_at: str
    subscription_count: int
    has_active_subscription: bool
    latest_subscription: dict | None


class UsersListResponse(BaseModel):
    """Response for users list."""
    users: List[UserSubscriptionInfo]
    total_count: int


@router.get("/users", response_model=UsersListResponse)
async def get_all_users(
    current_user: CurrentUser,
    settings: SettingsDep,
    supabase=Depends(get_supabase)
):
    """
    Get all users with their subscription information.

    Admin endpoint to list all users and their subscription status.
    This helps identify users who need promotional subscriptions.
    """

    # In dev mode, return mock data
    if settings.dev_mode:
        from datetime import datetime, timedelta
        mock_users = [
            UserSubscriptionInfo(
                clerk_id="dev_user_001",
                email="alice@example.com",
                created_at=datetime.utcnow().isoformat(),
                subscription_count=2,
                has_active_subscription=True,
                latest_subscription={
                    "id": "sub_001",
                    "certification_name": "정보처리기사",
                    "exam_date": (datetime.utcnow() + timedelta(days=30)).isoformat(),
                    "payment_amount": 10000,
                    "payment_method": "card",
                    "created_at": datetime.utcnow().isoformat(),
                }
            ),
            UserSubscriptionInfo(
                clerk_id="dev_user_002",
                email="bob@example.com",
                created_at=datetime.utcnow().isoformat(),
                subscription_count=1,
                has_active_subscription=False,
                latest_subscription={
                    "id": "sub_002",
                    "certification_name": "SQLD",
                    "exam_date": (datetime.utcnow() - timedelta(days=10)).isoformat(),
                    "payment_amount": 10000,
                    "payment_method": "admin_promotional",
                    "created_at": datetime.utcnow().isoformat(),
                }
            ),
            UserSubscriptionInfo(
                clerk_id="dev_user_003",
                email="charlie@example.com",
                created_at=datetime.utcnow().isoformat(),
                subscription_count=0,
                has_active_subscription=False,
                latest_subscription=None
            ),
        ]
        return UsersListResponse(users=mock_users, total_count=len(mock_users))

    try:
        # Get all users from user_profiles table
        users_response = supabase.table("user_profiles") \
            .select("clerk_id, email, created_at") \
            .order("created_at", desc=True) \
            .execute()

        if not users_response.data:
            return UsersListResponse(users=[], total_count=0)

        users_with_subscriptions = []

        for user in users_response.data:
            # Get user's subscriptions
            subscriptions_response = supabase.table("subscriptions") \
                .select("*, certifications(name), exam_dates(exam_date)") \
                .eq("clerk_id", user["clerk_id"]) \
                .order("created_at", desc=True) \
                .execute()

            subscriptions = subscriptions_response.data or []

            # Check if user has active subscription
            has_active = False
            latest_sub = None

            if subscriptions:
                latest_sub = subscriptions[0]
                # Check if subscription is still active (exam date not passed)
                exam_date_str = latest_sub.get("exam_dates", {}).get("exam_date")
                if exam_date_str:
                    exam_date = datetime.fromisoformat(exam_date_str.replace("Z", "+00:00"))
                    has_active = exam_date > datetime.now(exam_date.tzinfo)

                # Format latest subscription info
                latest_sub = {
                    "id": latest_sub.get("id"),
                    "certification_name": latest_sub.get("certifications", {}).get("name"),
                    "exam_date": exam_date_str,
                    "payment_amount": latest_sub.get("payment_amount"),
                    "payment_method": latest_sub.get("payment_method"),
                    "created_at": latest_sub.get("created_at"),
                }

            users_with_subscriptions.append(
                UserSubscriptionInfo(
                    clerk_id=user["clerk_id"],
                    email=user["email"],
                    created_at=user["created_at"],
                    subscription_count=len(subscriptions),
                    has_active_subscription=has_active,
                    latest_subscription=latest_sub,
                )
            )

        return UsersListResponse(
            users=users_with_subscriptions,
            total_count=len(users_with_subscriptions)
        )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch users: {str(e)}"
        )


@router.post("/users/{clerk_id}/force-subscription")
async def create_force_subscription_for_user(
    clerk_id: str,
    certification_id: str,
    exam_date_id: str,
    current_user: CurrentUser,
    supabase=Depends(get_supabase)
):
    """
    Create a force subscription for a specific user (for promotional purposes).

    This endpoint allows admins to grant subscriptions to users without payment,
    useful for marketing campaigns, sponsorships, or user retention.
    """

    try:
        # Verify user exists
        user_response = supabase.table("user_profiles") \
            .select("clerk_id, email") \
            .eq("clerk_id", clerk_id) \
            .execute()

        if not user_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User {clerk_id} not found"
            )

        # Verify certification and exam date exist
        cert_response = supabase.table("certifications") \
            .select("id, name") \
            .eq("id", certification_id) \
            .execute()

        if not cert_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Certification {certification_id} not found"
            )

        exam_date_response = supabase.table("exam_dates") \
            .select("id, exam_date") \
            .eq("id", exam_date_id) \
            .eq("certification_id", certification_id) \
            .execute()

        if not exam_date_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Exam date {exam_date_id} not found for this certification"
            )

        exam_date = exam_date_response.data[0]["exam_date"]

        # Check if user already has subscription for this certification and exam date
        existing_sub = supabase.table("subscriptions") \
            .select("id") \
            .eq("clerk_id", clerk_id) \
            .eq("certification_id", certification_id) \
            .eq("exam_date_id", exam_date_id) \
            .execute()

        if existing_sub.data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User already has a subscription for this certification and exam date"
            )

        # Create subscription
        subscription_data = {
            "clerk_id": clerk_id,
            "certification_id": certification_id,
            "exam_date_id": exam_date_id,
            "payment_amount": 0,  # Free promotional subscription
            "payment_method": "admin_promotional",
            "payment_status": "completed",
            "created_at": datetime.utcnow().isoformat(),
        }

        result = supabase.table("subscriptions").insert(subscription_data).execute()

        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create subscription"
            )

        return {
            "success": True,
            "message": f"Promotional subscription created for user {user_response.data[0]['email']}",
            "subscription": result.data[0],
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create promotional subscription: {str(e)}"
        )


@router.get("/users/{email}/study-sets")
async def get_user_study_sets(
    email: str,
    settings: SettingsDep,
    supabase=Depends(get_supabase)
):
    """
    Get study sets for a specific user by email.

    Temporary admin endpoint to check user's study sets.
    """
    try:
        # Find user by email
        user_response = supabase.table("user_profiles") \
            .select("clerk_id, email") \
            .eq("email", email) \
            .execute()

        if not user_response.data:
            return {
                "success": False,
                "message": f"User {email} not found",
                "study_sets": []
            }

        user = user_response.data[0]
        clerk_id = user["clerk_id"]

        # Get study sets for this user
        study_sets_response = supabase.table("study_sets") \
            .select("*") \
            .eq("user_id", clerk_id) \
            .execute()

        study_sets = study_sets_response.data or []

        return {
            "success": True,
            "user": {
                "email": email,
                "clerk_id": clerk_id
            },
            "study_sets": study_sets,
            "total_count": len(study_sets)
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch study sets: {str(e)}"
        )


@router.get("/content")
async def get_admin_content(
    current_user: CurrentUser,
    settings: SettingsDep,
    supabase=Depends(get_supabase)
):
    """Get all official content for admin management."""

    # Mock data for testing
    if settings.dev_mode or settings.test_mode:
        return {
            "contents": [
                {
                    "id": "1",
                    "title": "2026 사회복지사1급 핵심 이론 PDF",
                    "certification_name": "사회복지사1급",
                    "content_type": "pdf",
                    "description": "2026년 시험 대비 핵심 이론 정리",
                    "file_url": "/content/social-worker-2026.pdf",
                    "page_count": 320,
                    "created_at": "2025-12-01T00:00:00Z",
                    "updated_at": "2026-01-01T00:00:00Z",
                    "views": 1542,
                    "status": "published"
                },
                {
                    "id": "2",
                    "title": "정신건강사회복지론 요약",
                    "certification_name": "사회복지사1급",
                    "content_type": "article",
                    "description": "정신건강사회복지론 핵심 개념 정리",
                    "created_at": "2025-11-15T00:00:00Z",
                    "updated_at": "2025-12-20T00:00:00Z",
                    "views": 892,
                    "status": "published"
                }
            ]
        }

    # TODO: Implement actual database query
    return {"contents": []}


@router.delete("/content/{content_id}")
async def delete_content(
    content_id: str,
    current_user: CurrentUser,
    settings: SettingsDep,
    supabase=Depends(get_supabase)
):
    """Delete content by ID."""
    # TODO: Implement actual deletion
    return {"success": True, "message": f"Content {content_id} deleted"}


@router.get("/statistics")
async def get_admin_statistics(
    current_user: CurrentUser,
    settings: SettingsDep,
    range: str = "7days",
    supabase=Depends(get_supabase)
):
    """Get system statistics and analytics."""

    # Mock data for testing
    if settings.dev_mode or settings.test_mode:
        return {
            "system_stats": {
                "total_users": 342,
                "total_subscriptions": 215,
                "total_certifications": 8,
                "total_questions": 4520,
                "total_tests_taken": 1834,
                "avg_daily_active_users": 87,
                "growth_rate": 12.5
            },
            "certification_stats": [
                {
                    "certification_name": "사회복지사1급",
                    "total_subscribers": 128,
                    "active_subscribers": 95,
                    "total_questions": 850,
                    "avg_score": 72.3,
                    "completion_rate": 68.5
                },
                {
                    "certification_name": "정보처리기사",
                    "total_subscribers": 67,
                    "active_subscribers": 48,
                    "total_questions": 620,
                    "avg_score": 78.9,
                    "completion_rate": 71.2
                }
            ],
            "daily_stats": [
                {"date": "2026-01-01", "new_users": 12, "active_users": 85, "tests_taken": 45, "questions_answered": 1234},
                {"date": "2026-01-02", "new_users": 8, "active_users": 92, "tests_taken": 52, "questions_answered": 1456},
                {"date": "2026-01-03", "new_users": 15, "active_users": 98, "tests_taken": 58, "questions_answered": 1598},
                {"date": "2026-01-04", "new_users": 10, "active_users": 88, "tests_taken": 47, "questions_answered": 1302},
                {"date": "2026-01-05", "new_users": 18, "active_users": 105, "tests_taken": 63, "questions_answered": 1789},
                {"date": "2026-01-06", "new_users": 14, "active_users": 96, "tests_taken": 55, "questions_answered": 1523}
            ]
        }

    # TODO: Implement actual statistics queries
    return {"system_stats": {}, "certification_stats": [], "daily_stats": []}


@router.get("/settings")
async def get_admin_settings(
    current_user: CurrentUser,
    settings: SettingsDep,
    supabase=Depends(get_supabase)
):
    """Get system settings."""

    # Return mock settings for testing
    return {
        "settings": {
            "site_name": "Certi-Graph",
            "site_description": "AI 자격증 마스터 - 지식 그래프 기반 학습 플랫폼",
            "admin_email": "admin@certigraph.com",
            "support_email": "support@certigraph.com",
            "max_upload_size_mb": 50,
            "session_timeout_minutes": 60,
            "enable_registration": True,
            "enable_email_notifications": True,
            "enable_analytics": True,
            "maintenance_mode": False,
            "api_rate_limit": 100,
            "default_language": "ko"
        }
    }


@router.put("/settings")
async def update_admin_settings(
    settings_data: dict,
    current_user: CurrentUser,
    settings: SettingsDep,
    supabase=Depends(get_supabase)
):
    """Update system settings."""
    # TODO: Implement actual settings update
    return {"success": True, "message": "Settings updated successfully"}


@router.patch("/certifications/{cert_id}/toggle-active")
async def toggle_certification_active(
    cert_id: str,
    current_user: CurrentUser,
    settings: SettingsDep,
    supabase=Depends(get_supabase)
):
    """Toggle certification active status."""
    # TODO: Implement actual toggle
    return {"success": True, "message": f"Certification {cert_id} toggled"}


# =====================================================
# Exam Schedule Management Endpoints
# =====================================================

class ExamDateCreate(BaseModel):
    """Request model for creating exam date."""
    certification_id: str
    exam_date: str  # YYYY-MM-DD format
    registration_start: str  # YYYY-MM-DD format
    registration_end: str  # YYYY-MM-DD format


class ExamDateUpdate(BaseModel):
    """Request model for updating exam date."""
    exam_date: str | None = None
    registration_start: str | None = None
    registration_end: str | None = None


@router.get("/exam-dates")
async def get_all_exam_dates(
    current_user: CurrentUser,
    settings: SettingsDep,
    certification_id: str | None = None,
    supabase=Depends(get_supabase)
):
    """
    Get all exam dates, optionally filtered by certification.

    Admin endpoint to view and manage exam schedules.
    """
    # Mock data for testing
    if settings.dev_mode or settings.test_mode:
        mock_data = [
            {
                "id": "exam_2026_01",
                "certification_id": "cert_social_worker_1",
                "certification_name": "사회복지사1급",
                "exam_date": "2026-01-18",
                "registration_start": "2025-11-01",
                "registration_end": "2025-12-15",
                "active_subscriptions": 45,
                "created_at": "2025-10-01T00:00:00Z"
            },
            {
                "id": "exam_2026_02",
                "certification_id": "cert_social_worker_1",
                "certification_name": "사회복지사1급",
                "exam_date": "2026-06-20",
                "registration_start": "2026-04-01",
                "registration_end": "2026-05-15",
                "active_subscriptions": 12,
                "created_at": "2025-10-01T00:00:00Z"
            },
            {
                "id": "exam_2026_03",
                "certification_id": "cert_it_engineer",
                "certification_name": "정보처리기사",
                "exam_date": "2026-03-07",
                "registration_start": "2026-01-15",
                "registration_end": "2026-02-15",
                "active_subscriptions": 23,
                "created_at": "2025-10-01T00:00:00Z"
            }
        ]

        if certification_id:
            mock_data = [d for d in mock_data if d["certification_id"] == certification_id]

        return {
            "exam_dates": mock_data,
            "total_count": len(mock_data)
        }

    try:
        # Query exam dates with certification info
        query = supabase.table("exam_dates") \
            .select("*, certifications(id, name)")

        if certification_id:
            query = query.eq("certification_id", certification_id)

        response = query.order("exam_date", desc=False).execute()

        # Transform data
        exam_dates = []
        for ed in response.data:
            cert_info = ed.get("certifications", {})
            exam_dates.append({
                "id": ed["id"],
                "certification_id": ed["certification_id"],
                "certification_name": cert_info.get("name", "Unknown") if cert_info else "Unknown",
                "exam_date": ed["exam_date"],
                "registration_start": ed.get("registration_start"),
                "registration_end": ed.get("registration_end"),
                "created_at": ed.get("created_at"),
                "active_subscriptions": 0  # TODO: Count from subscriptions table
            })

        return {
            "exam_dates": exam_dates,
            "total_count": len(exam_dates)
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch exam dates: {str(e)}"
        )


@router.post("/exam-dates")
async def create_exam_date(
    exam_date_data: ExamDateCreate,
    current_user: CurrentUser,
    settings: SettingsDep,
    supabase=Depends(get_supabase)
):
    """
    Create a new exam date for a certification.

    Admin endpoint to add new exam schedules.
    """
    try:
        # Verify certification exists
        cert_response = supabase.table("certifications") \
            .select("id, name") \
            .eq("id", exam_date_data.certification_id) \
            .execute()

        if not cert_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Certification {exam_date_data.certification_id} not found"
            )

        # Check for duplicate exam date
        existing = supabase.table("exam_dates") \
            .select("id") \
            .eq("certification_id", exam_date_data.certification_id) \
            .eq("exam_date", exam_date_data.exam_date) \
            .execute()

        if existing.data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Exam date already exists for this certification"
            )

        # Create exam date
        new_exam_date = {
            "certification_id": exam_date_data.certification_id,
            "exam_date": exam_date_data.exam_date,
            "registration_start": exam_date_data.registration_start,
            "registration_end": exam_date_data.registration_end,
            "created_at": datetime.utcnow().isoformat(),
        }

        result = supabase.table("exam_dates").insert(new_exam_date).execute()

        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create exam date"
            )

        return {
            "success": True,
            "message": f"Exam date created for {cert_response.data[0]['name']}",
            "exam_date": result.data[0]
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create exam date: {str(e)}"
        )


@router.put("/exam-dates/{exam_date_id}")
async def update_exam_date(
    exam_date_id: str,
    exam_date_data: ExamDateUpdate,
    current_user: CurrentUser,
    settings: SettingsDep,
    supabase=Depends(get_supabase)
):
    """
    Update an existing exam date.

    Admin endpoint to modify exam schedules.
    """
    try:
        # Verify exam date exists
        existing = supabase.table("exam_dates") \
            .select("*") \
            .eq("id", exam_date_id) \
            .execute()

        if not existing.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Exam date {exam_date_id} not found"
            )

        # Build update data (only include provided fields)
        update_data = {}
        if exam_date_data.exam_date is not None:
            update_data["exam_date"] = exam_date_data.exam_date
        if exam_date_data.registration_start is not None:
            update_data["registration_start"] = exam_date_data.registration_start
        if exam_date_data.registration_end is not None:
            update_data["registration_end"] = exam_date_data.registration_end

        if not update_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields to update"
            )

        # Update exam date
        result = supabase.table("exam_dates") \
            .update(update_data) \
            .eq("id", exam_date_id) \
            .execute()

        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update exam date"
            )

        return {
            "success": True,
            "message": "Exam date updated successfully",
            "exam_date": result.data[0]
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update exam date: {str(e)}"
        )


@router.delete("/exam-dates/{exam_date_id}")
async def delete_exam_date(
    exam_date_id: str,
    current_user: CurrentUser,
    settings: SettingsDep,
    supabase=Depends(get_supabase)
):
    """
    Delete an exam date.

    Admin endpoint to remove exam schedules.
    Warning: This will also delete associated subscriptions due to CASCADE.
    """
    try:
        # Check if there are active subscriptions for this exam date
        subscriptions = supabase.table("subscriptions") \
            .select("id") \
            .eq("exam_date_id", exam_date_id) \
            .execute()

        if subscriptions.data and len(subscriptions.data) > 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot delete exam date with {len(subscriptions.data)} active subscriptions"
            )

        # Delete exam date
        result = supabase.table("exam_dates") \
            .delete() \
            .eq("id", exam_date_id) \
            .execute()

        return {
            "success": True,
            "message": "Exam date deleted successfully"
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete exam date: {str(e)}"
        )
