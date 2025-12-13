"""Free trial and subscription related schemas."""

from datetime import datetime
from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field


class SubscriptionTier(str, Enum):
    """User subscription tiers."""
    FREE = "free"
    BASIC = "basic"
    PRO = "pro"
    ENTERPRISE = "enterprise"


class SessionType(str, Enum):
    """Practice session types."""
    PRACTICE = "practice"
    MOCK_EXAM = "mock_exam"


class PracticeSessionCreate(BaseModel):
    """Request schema for creating a practice session."""
    study_set_id: str
    session_type: SessionType = SessionType.PRACTICE


class PracticeSessionResponse(BaseModel):
    """Response schema for a practice session."""
    id: str
    study_set_id: str
    session_type: SessionType
    questions_attempted: int = 0
    questions_correct: int = 0
    started_at: datetime
    completed_at: Optional[datetime] = None
    time_spent_seconds: Optional[int] = None

    class Config:
        from_attributes = True


class PracticeSessionComplete(BaseModel):
    """Request schema for completing a practice session."""
    questions_attempted: int = Field(ge=0)
    questions_correct: int = Field(ge=0)
    time_spent_seconds: int = Field(ge=0)


class UserLimitsResponse(BaseModel):
    """Response schema for user limits and subscription info."""
    subscription_tier: SubscriptionTier
    max_pdfs_per_month: int
    max_practice_sessions_per_pdf: int
    current_month_pdfs_uploaded: int
    can_upload_pdf: bool
    subscription_end_date: Optional[datetime] = None

    class Config:
        from_attributes = True


class TrialStatusResponse(BaseModel):
    """Response schema for study set trial status."""
    study_set_id: str
    is_free_trial: bool
    practice_sessions_used: int
    practice_sessions_remaining: int
    can_start_session: bool
    requires_upgrade: bool
    upgrade_message: Optional[str] = None


class UpgradeRequiredError(BaseModel):
    """Error response when upgrade is required."""
    detail: str = "무료 체험 횟수를 모두 사용했습니다. 계속하려면 유료 플랜으로 업그레이드하세요."
    trial_status: TrialStatusResponse
    upgrade_url: str = "/pricing"
