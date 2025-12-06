"""Study set related schemas."""

from datetime import datetime
from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field


class StudySetStatus(str, Enum):
    """Study set processing status."""
    UPLOADING = "uploading"
    PARSING = "parsing"
    PROCESSING = "processing"
    READY = "ready"
    FAILED = "failed"


class LearningStatus(str, Enum):
    """Learning progress status."""
    NOT_LEARNED = "not_learned"  # 미학습
    LEARNED = "learned"  # 학습됨
    RESET = "reset"  # 초기화


class StudySetCreate(BaseModel):
    """Request schema for creating a study set."""
    name: str = Field(..., min_length=1, max_length=200)
    exam_name: Optional[str] = Field(None, max_length=100, description="자격증 시험명 (예: 사회복지사 1급)")
    exam_year: Optional[int] = Field(None, ge=2000, le=2100, description="시험 년도")
    exam_round: Optional[int] = Field(None, ge=1, le=10, description="n차 시험")
    exam_session: Optional[int] = Field(None, ge=1, le=10, description="교시")
    exam_session_name: Optional[str] = Field(None, max_length=100, description="교시 명칭 (예: 1교시 - 사회복지기초)")
    tags: Optional[list[str]] = Field(None, description="태그 배열 (예: ['기출문제', '2024년'])")


class StudySetResponse(BaseModel):
    """Response schema for a study set."""
    id: str
    name: str
    status: StudySetStatus
    question_count: int = 0
    created_at: datetime
    is_cached: bool = False  # True if using cached results from duplicate PDF
    exam_name: Optional[str] = None
    exam_year: Optional[int] = None
    exam_round: Optional[int] = None
    exam_session: Optional[int] = None
    exam_session_name: Optional[str] = None
    tags: Optional[list[str]] = None
    learning_status: LearningStatus = LearningStatus.NOT_LEARNED
    last_studied_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class StudySetStatusResponse(BaseModel):
    """Response schema for study set processing status."""
    status: StudySetStatus
    progress: int = Field(ge=0, le=100, default=0)
    current_step: Optional[str] = None
    is_cached: bool = False  # Indicates fake processing using cached results


class StudySetListResponse(BaseModel):
    """Response schema for list of study sets."""
    data: list[StudySetResponse]
    total: int
