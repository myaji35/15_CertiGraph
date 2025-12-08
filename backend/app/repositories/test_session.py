"""Repository for test session database operations."""

import uuid
from datetime import datetime
from typing import Optional, Any
import httpx

from app.core.config import get_settings
from app.models.test import TestSessionStatus, TestMode


def TestSessionRepository():
    """Factory function to return appropriate repository based on mode."""
    settings = get_settings()
    if settings.dev_mode:
        from app.repositories.mock_test_session import MockTestSessionRepository
        return MockTestSessionRepository()
    return _TestSessionRepository()


class _TestSessionRepository:
    """Data access layer for test_sessions and user_answers."""

    def __init__(self):
        self.settings = get_settings()
        self.base_url = f"{self.settings.supabase_url}/rest/v1"
        self.headers = {
            "apikey": self.settings.supabase_service_key,
            "Authorization": f"Bearer {self.settings.supabase_service_key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        }

    async def create_session(
        self,
        user_id: str,
        study_set_id: str,
        mode: TestMode,
        total_questions: int,
    ) -> dict[str, Any]:
        """Create a new test session."""
        session_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()

        data = {
            "id": session_id,
            "user_id": user_id,
            "study_set_id": study_set_id,
            "mode": mode.value,
            "total_questions": total_questions,
            "status": TestSessionStatus.IN_PROGRESS.value,
            "started_at": now,
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/test_sessions",
                headers=self.headers,
                json=data,
            )
            response.raise_for_status()
            return response.json()[0]

    async def get_session(self, session_id: str) -> Optional[dict[str, Any]]:
        """Get a test session by ID."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/test_sessions",
                headers=self.headers,
                params={"id": f"eq.{session_id}"},
            )
            response.raise_for_status()
            results = response.json()
            return results[0] if results else None

    async def complete_session(
        self,
        session_id: str,
        score: int,
    ) -> dict[str, Any]:
        """Mark a test session as completed."""
        now = datetime.utcnow().isoformat()

        data = {
            "status": TestSessionStatus.COMPLETED.value,
            "score": score,
            "completed_at": now,
        }

        async with httpx.AsyncClient() as client:
            response = await client.patch(
                f"{self.base_url}/test_sessions",
                headers=self.headers,
                params={"id": f"eq.{session_id}"},
                json=data,
            )
            response.raise_for_status()
            return response.json()[0]

    async def save_answers(
        self,
        session_id: str,
        answers: list[dict[str, Any]],
    ) -> int:
        """Save user answers for a session."""
        now = datetime.utcnow().isoformat()

        db_answers = []
        for ans in answers:
            db_answers.append({
                "id": str(uuid.uuid4()),
                "session_id": session_id,
                "question_id": ans["question_id"],
                "selected_option": ans["selected_option"],
                "is_correct": ans["is_correct"],
                "answered_at": now,
            })

        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/user_answers",
                headers=self.headers,
                json=db_answers,
            )
            response.raise_for_status()

        return len(db_answers)

    async def get_session_answers(
        self,
        session_id: str,
    ) -> list[dict[str, Any]]:
        """Get all answers for a session."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/user_answers",
                headers=self.headers,
                params={
                    "session_id": f"eq.{session_id}",
                    "order": "answered_at.asc",
                },
            )
            response.raise_for_status()
            return response.json()

    async def get_wrong_question_ids(
        self,
        user_id: str,
        study_set_id: str,
    ) -> list[str]:
        """Get question IDs that user answered incorrectly."""
        # First get all sessions for this study set
        async with httpx.AsyncClient() as client:
            sessions_response = await client.get(
                f"{self.base_url}/test_sessions",
                headers=self.headers,
                params={
                    "user_id": f"eq.{user_id}",
                    "study_set_id": f"eq.{study_set_id}",
                    "status": f"eq.{TestSessionStatus.COMPLETED.value}",
                    "select": "id",
                },
            )
            sessions_response.raise_for_status()
            sessions = sessions_response.json()

        if not sessions:
            return []

        session_ids = [s["id"] for s in sessions]

        # Get wrong answers from these sessions
        wrong_ids = set()
        for session_id in session_ids:
            async with httpx.AsyncClient() as client:
                answers_response = await client.get(
                    f"{self.base_url}/user_answers",
                    headers=self.headers,
                    params={
                        "session_id": f"eq.{session_id}",
                        "is_correct": "eq.false",
                        "select": "question_id",
                    },
                )
                answers_response.raise_for_status()
                for ans in answers_response.json():
                    wrong_ids.add(ans["question_id"])

        return list(wrong_ids)

    async def get_user_sessions(
        self,
        user_id: str,
        study_set_id: Optional[str] = None,
        limit: int = 20,
    ) -> list[dict[str, Any]]:
        """Get user's test session history."""
        params = {
            "user_id": f"eq.{user_id}",
            "order": "started_at.desc",
            "limit": str(limit),
        }
        if study_set_id:
            params["study_set_id"] = f"eq.{study_set_id}"

        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/test_sessions",
                headers=self.headers,
                params=params,
            )
            response.raise_for_status()
            return response.json()
