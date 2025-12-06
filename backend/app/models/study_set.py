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


class StudySetCreate(BaseModel):
    """Request schema for creating a study set."""
    name: str = Field(..., min_length=1, max_length=200)


class StudySetResponse(BaseModel):
    """Response schema for a study set."""
    id: str
    name: str
    status: StudySetStatus
    question_count: int = 0
    created_at: datetime
    is_cached: bool = False  # True if using cached results from duplicate PDF

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
