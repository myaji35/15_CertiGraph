"""Answer key management models."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel
from enum import Enum

class AnswerSource(str, Enum):
    """Source of answer key."""
    ADMIN = "admin"  # 관리자 입력
    CROWDSOURCED = "crowdsourced"  # 크라우드소싱
    OFFICIAL = "official"  # 공식 답안
    AI_GENERATED = "ai_generated"  # AI 생성

class AnswerStatus(str, Enum):
    """Answer verification status."""
    PENDING = "pending"  # 검증 대기
    VERIFIED = "verified"  # 검증 완료
    DISPUTED = "disputed"  # 논란 있음

class Answer(BaseModel):
    """Answer key for a question."""
    id: str
    question_id: str
    study_set_id: str
    correct_option: int  # 1-5
    source: AnswerSource
    status: AnswerStatus
    confidence_score: float  # 0.0 - 1.0
    explanation: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    verified_by_count: int = 0  # 검증한 사용자 수

class UserAnswerSubmission(BaseModel):
    """User's answer submission for crowdsourcing."""
    id: str
    user_id: str
    question_id: str
    selected_option: int
    explanation: Optional[str] = None
    submitted_at: datetime
    is_verified: bool = False

class AnswerKeyRequest(BaseModel):
    """Request to add answer key."""
    study_set_id: str
    answers: dict[str, int]  # question_id -> correct_option
    source: AnswerSource = AnswerSource.ADMIN

class CrowdsourceAnswerRequest(BaseModel):
    """Request to submit crowdsourced answer."""
    question_id: str
    selected_option: int
    explanation: Optional[str] = None

class AnswerVerificationResult(BaseModel):
    """Result of answer verification."""
    question_id: str
    is_correct: bool
    correct_answer: Optional[int] = None
    explanation: Optional[str] = None
    confidence: float