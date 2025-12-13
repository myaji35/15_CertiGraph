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
