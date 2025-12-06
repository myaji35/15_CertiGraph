"""Test session related schemas."""

from datetime import datetime
from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field


class TestMode(str, Enum):
    """Test mode options."""
    ALL = "all"
    RANDOM = "random"
    WRONG_ONLY = "wrong_only"


class TestSessionStatus(str, Enum):
    """Test session status."""
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    ABANDONED = "abandoned"


class TestStartRequest(BaseModel):
    """Request schema for starting a test."""
    study_set_id: str
    mode: TestMode = TestMode.ALL
    question_count: Optional[int] = None  # Required for random mode


class QuestionForTest(BaseModel):
    """Question format for test session."""
    id: str
    question_number: int
    question_text: str
    options: list[dict]  # [{number: 1, text: "..."}, ...]
    passage: Optional[str] = None


class TestStartResponse(BaseModel):
    """Response schema for starting a test."""
    session_id: str
    questions: list[QuestionForTest]
    total_questions: int
    time_limit_minutes: Optional[int] = None


class AnswerSubmission(BaseModel):
    """Single answer submission."""
    question_id: str
    selected_option: int  # 1-5, after shuffle mapping


class TestSubmitRequest(BaseModel):
    """Request schema for submitting test answers."""
    session_id: str
    answers: list[AnswerSubmission]


class TestSubmitResponse(BaseModel):
    """Response schema for test submission."""
    score: int
    total: int
    percentage: float
    time_taken_seconds: int


class QuestionResult(BaseModel):
    """Individual question result for review."""
    id: str
    question_number: int
    question_text: str
    options: list[dict]
    correct_answer: int
    selected_answer: Optional[int]
    is_correct: bool
    explanation: Optional[str]


class TestResultResponse(BaseModel):
    """Response schema for test results."""
    session_id: str
    score: int
    total: int
    percentage: float
    time_taken_seconds: int
    completed_at: datetime
    questions: list[QuestionResult]
