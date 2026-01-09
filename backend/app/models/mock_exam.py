"""Mock exam related schemas."""

from datetime import datetime
from enum import Enum
from typing import Optional, List
from pydantic import BaseModel, Field


class MockExamMode(str, Enum):
    """Mock exam mode options."""
    MOCK_FULL = "mock_full"  # 전체 3교시 연속 응시 (180분)
    MOCK_SESSION = "mock_session"  # 교시별 개별 응시 (60분)
    PAST_EXAM = "past_exam"  # 특정 연도/회차 기출문제


class ExamSession(str, Enum):
    """Exam session types."""
    SESSION_1 = "session_1"  # 1교시
    SESSION_2 = "session_2"  # 2교시
    SESSION_3 = "session_3"  # 3교시
    ALL_SESSIONS = "all_sessions"  # 전체 교시


class CutoffStatus(str, Enum):
    """Cutoff (과락) status."""
    PASS = "pass"  # 합격
    FAIL = "fail"  # 불합격
    CUTOFF = "cutoff"  # 과락


class MockExamStartRequest(BaseModel):
    """Request schema for starting a mock exam."""
    mode: MockExamMode
    exam_year: Optional[int] = Field(None, ge=2019, le=2030, description="시험 년도")
    exam_round: Optional[int] = Field(None, ge=1, le=30, description="회차 (제N회)")
    session_number: Optional[ExamSession] = Field(None, description="교시 번호 (None이면 전체)")
    time_limit_enabled: bool = Field(True, description="시간 제한 활성화")
    study_set_id: Optional[str] = Field(None, description="Study set ID for past exam mode")
    material_id: Optional[str] = Field(None, description="Material ID for past exam mode")
    title: Optional[str] = Field(None, description="Title of the exam session")


class MockExamSession(BaseModel):
    """Individual exam session data."""
    session_number: int
    session_name: str  # e.g., "1교시 - 사회복지기초"
    questions: List[dict]
    time_limit_minutes: int = 60
    total_questions: int


class MockExamStartResponse(BaseModel):
    """Response schema for starting a mock exam."""
    exam_id: str
    mode: MockExamMode
    sessions: List[MockExamSession]
    total_time_minutes: int
    exam_year: Optional[int] = None
    exam_round: Optional[int] = None
    started_at: datetime


class SessionResult(BaseModel):
    """Result for individual session."""
    session_number: int
    session_name: str
    score: int
    total: int
    percentage: float
    is_cutoff: bool  # True if score < 40%
    time_taken_seconds: int


class CutoffResult(BaseModel):
    """Cutoff calculation result."""
    overall_status: CutoffStatus
    overall_score: int
    overall_total: int
    overall_percentage: float
    session_results: List[SessionResult]
    cutoff_sessions: List[int]  # List of session numbers that failed cutoff
    pass_criteria_met: bool  # True if overall >= 60%
    cutoff_criteria_met: bool  # True if all sessions >= 40%
    recommendation: str  # 맞춤형 추천 메시지


class MockExamSubmitRequest(BaseModel):
    """Request schema for submitting mock exam answers."""
    exam_id: str
    session_number: Optional[int] = None  # For session-by-session submission
    answers: List[dict]  # [{question_id: str, selected_option: int}, ...]


class MockExamSubmitResponse(BaseModel):
    """Response schema for mock exam submission."""
    exam_id: str
    cutoff_result: CutoffResult
    completed_at: datetime
    time_taken_seconds: int
    next_session: Optional[int] = None  # For multi-session exams


class MockExamResultDetail(BaseModel):
    """Detailed mock exam result for review."""
    exam_id: str
    mode: MockExamMode
    exam_year: Optional[int]
    exam_round: Optional[int]
    started_at: datetime
    completed_at: datetime
    cutoff_result: CutoffResult
    questions_by_session: dict  # {session_number: [question_results]}
    weak_topics: List[str]  # 약점 주제 목록
    study_recommendations: List[str]  # 학습 추천 사항


class PastExamInfo(BaseModel):
    """Past exam metadata."""
    exam_year: int
    exam_round: int
    exam_name: str  # e.g., "제22회 사회복지사 1급"
    total_questions: int
    available_sessions: List[int]
    tags: List[str]
    created_at: datetime


class PastExamListResponse(BaseModel):
    """Response for listing available past exams."""
    exams: List[PastExamInfo]
    total: int