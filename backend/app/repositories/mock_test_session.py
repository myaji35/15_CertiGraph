"""Mock test session repository for development mode."""

import uuid
import json
import os
from datetime import datetime
from typing import Optional, Any


# Persistent storage file
MOCK_TEST_SESSIONS_FILE = "/tmp/certigraph_mock_test_sessions.json"


class MockTestSessionRepository:
    """File-based mock repository for test sessions in development."""

    def __init__(self):
        self._storage: dict[str, dict] = {}  # session_id -> session
        self._user_sessions: dict[str, list[str]] = {}  # user_id -> [session_ids]
        self._wrong_answers: dict[str, dict[str, list[str]]] = {}  # user_id -> {study_set_id -> [question_ids]}
        self._load_data()

    def _load_data(self):
        """Load data from file if exists."""
        if os.path.exists(MOCK_TEST_SESSIONS_FILE):
            try:
                with open(MOCK_TEST_SESSIONS_FILE, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    self._storage = data.get('storage', {})
                    self._user_sessions = data.get('user_sessions', {})
                    self._wrong_answers = data.get('wrong_answers', {})
            except Exception as e:
                print(f"Failed to load mock test sessions: {e}")

    def _save_data(self):
        """Save data to file."""
        try:
            with open(MOCK_TEST_SESSIONS_FILE, 'w', encoding='utf-8') as f:
                json.dump({
                    'storage': self._storage,
                    'user_sessions': self._user_sessions,
                    'wrong_answers': self._wrong_answers,
                }, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"Failed to save mock test sessions: {e}")

    async def create_session(
        self,
        user_id: str,
        study_set_id: str,
        mode: str,
        total_questions: int,
    ) -> dict[str, Any]:
        """Create a new test session."""
        session_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()

        session = {
            "id": session_id,
            "user_id": user_id,
            "study_set_id": study_set_id,
            "mode": mode.value if hasattr(mode, 'value') else mode,
            "status": "in_progress",
            "total_questions": total_questions,
            "score": None,
            "started_at": now,
            "completed_at": None,
        }

        self._storage[session_id] = session

        # Track user sessions
        if user_id not in self._user_sessions:
            self._user_sessions[user_id] = []
        self._user_sessions[user_id].append(session_id)

        self._save_data()
        return session

    async def get_session(self, session_id: str) -> Optional[dict[str, Any]]:
        """Get a session by ID."""
        return self._storage.get(session_id)

    async def update_session_score(
        self,
        session_id: str,
        score: int,
        wrong_question_ids: list[str],
    ) -> Optional[dict[str, Any]]:
        """Update session with score and mark as completed."""
        session = self._storage.get(session_id)
        if not session:
            return None

        session["score"] = score
        session["status"] = "completed"
        session["completed_at"] = datetime.utcnow().isoformat()

        # Track wrong answers
        user_id = session["user_id"]
        study_set_id = session["study_set_id"]

        if user_id not in self._wrong_answers:
            self._wrong_answers[user_id] = {}
        if study_set_id not in self._wrong_answers[user_id]:
            self._wrong_answers[user_id][study_set_id] = []

        # Add new wrong answers (avoid duplicates)
        existing = set(self._wrong_answers[user_id][study_set_id])
        self._wrong_answers[user_id][study_set_id] = list(existing.union(set(wrong_question_ids)))

        self._save_data()
        return session

    async def get_user_sessions(
        self,
        user_id: str,
        study_set_id: Optional[str] = None,
        limit: int = 20,
    ) -> list[dict[str, Any]]:
        """Get user's test session history."""
        session_ids = self._user_sessions.get(user_id, [])
        sessions = [self._storage[sid] for sid in session_ids if sid in self._storage]

        if study_set_id:
            sessions = [s for s in sessions if s["study_set_id"] == study_set_id]

        # Sort by started_at descending
        sessions.sort(key=lambda x: x["started_at"], reverse=True)

        return sessions[:limit]

    async def get_wrong_question_ids(
        self, user_id: str, study_set_id: str
    ) -> list[str]:
        """Get IDs of questions the user got wrong in a study set."""
        if user_id not in self._wrong_answers:
            return []
        if study_set_id not in self._wrong_answers[user_id]:
            return []
        return self._wrong_answers[user_id][study_set_id]

    async def save_answers(
        self,
        session_id: str,
        answers: list[dict[str, Any]],
    ) -> int:
        """Save user answers for a session (not persisted in mock)."""
        # In mock mode, we just return the count
        return len(answers)

    async def get_session_answers(
        self,
        session_id: str,
    ) -> list[dict[str, Any]]:
        """Get all answers for a session (empty in mock)."""
        # In mock mode, we don't persist individual answers
        return []

    async def complete_session(
        self,
        session_id: str,
        score: int,
    ) -> dict[str, Any]:
        """Mark a test session as completed."""
        session = self._storage.get(session_id)
        if not session:
            return None

        session["score"] = score
        session["status"] = "completed"
        session["completed_at"] = datetime.utcnow().isoformat()

        self._save_data()
        return session
