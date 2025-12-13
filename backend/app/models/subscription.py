"""Subscription models for certification-based subscriptions."""

from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, Field
from enum import Enum


class SubscriptionStatus(str, Enum):
    """구독 상태"""
    ACTIVE = "active"
    EXPIRED = "expired"
    CANCELLED = "cancelled"


class SubscriptionCreate(BaseModel):
    """구독 생성 요청"""
    certification_id: str = Field(..., description="자격증 ID")
    exam_date: date = Field(..., description="시험 날짜")
    payment_key: Optional[str] = Field(None, description="토스 결제 키")
    order_id: str = Field(..., description="주문 ID")
    amount: int = Field(..., description="결제 금액", ge=0)


class SubscriptionResponse(BaseModel):
    """구독 정보 응답"""
    id: str
    clerk_user_id: str
    certification_id: str
    certification_name: str
    exam_date: date
    subscription_start_date: datetime
    subscription_end_date: datetime
    days_remaining: int
    status: SubscriptionStatus
    amount: int
    created_at: datetime

    class Config:
        from_attributes = True


class UserSubscriptionsResponse(BaseModel):
    """사용자 구독 목록 응답"""
    subscriptions: list[SubscriptionResponse]
    total_count: int


class SubscriptionCheckResponse(BaseModel):
    """구독 확인 응답"""
    has_subscription: bool
    certification_id: Optional[str] = None
    certification_name: Optional[str] = None
    days_remaining: Optional[int] = None
    subscription_end_date: Optional[datetime] = None


class CertificationWithSubscription(BaseModel):
    """자격증 정보 + 구독 여부"""
    id: str
    name: str
    is_subscribed: bool
    subscription_end_date: Optional[date] = None
    days_remaining: Optional[int] = None
