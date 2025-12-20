"""Mock repository for development mode."""

import uuid
import json
import os
from datetime import datetime
from typing import Optional, Any
from app.models.study_set import StudySetStatus


# Persistent storage file
MOCK_DATA_FILE = "/tmp/certigraph_mock_data.json"


class MockStudySetRepository:
    """File-based mock repository for development."""

    def __init__(self):
        self._storage: dict[str, dict] = {}
        self._hash_index: dict[str, str] = {}
        self._load_data()

    def _load_data(self):
        """Load data from file if exists."""
        if os.path.exists(MOCK_DATA_FILE):
            try:
                with open(MOCK_DATA_FILE, 'r') as f:
                    data = json.load(f)
                    self._storage = data.get('storage', {})
                    self._hash_index = data.get('hash_index', {})
            except Exception as e:
                print(f"Failed to load mock data: {e}")

    def _save_data(self):
        """Save data to file."""
        try:
            with open(MOCK_DATA_FILE, 'w') as f:
                json.dump({
                    'storage': self._storage,
                    'hash_index': self._hash_index
                }, f)
        except Exception as e:
            print(f"Failed to save mock data: {e}")

    async def create(
        self,
        user_id: str,
        name: str,
        pdf_path: str,
        pdf_hash: str,
        status: StudySetStatus = StudySetStatus.UPLOADING,
        source_study_set_id: Optional[str] = None,
        exam_name: Optional[str] = None,
        exam_year: Optional[int] = None,
        exam_round: Optional[int] = None,
        exam_session: Optional[int] = None,
        exam_session_name: Optional[str] = None,
        tags: Optional[list[str]] = None,
    ) -> dict[str, Any]:
        """Create a new study set."""
        study_set_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()

        study_set = {
            "id": study_set_id,
            "user_id": user_id,
            "name": name,
            "pdf_path": pdf_path,
            "pdf_hash": pdf_hash,
            "status": status.value,
            "source_study_set_id": source_study_set_id,
            "is_cached": source_study_set_id is not None,
            "question_count": 0,
            "exam_name": exam_name,
            "exam_year": exam_year,
            "exam_round": exam_round,
            "exam_session": exam_session,
            "exam_session_name": exam_session_name,
            "tags": tags or [],
            "learning_status": "not_learned",
            "created_at": now,
            "updated_at": now,
        }

        self._storage[study_set_id] = study_set
        self._hash_index[pdf_hash] = study_set_id
        self._save_data()
        return study_set

    async def find_by_hash(self, pdf_hash: str) -> Optional[dict[str, Any]]:
        """Find study set by PDF hash."""
        study_set_id = self._hash_index.get(pdf_hash)
        if study_set_id:
            return self._storage.get(study_set_id)
        return None

    async def find_by_hash_for_user(self, pdf_hash: str, user_id: str) -> Optional[dict[str, Any]]:
        """Find study set by PDF hash for a specific user."""
        for study_set in self._storage.values():
            if study_set.get("pdf_hash") == pdf_hash and study_set.get("user_id") == user_id:
                return study_set
        return None

    async def find_by_id(self, study_set_id: str) -> Optional[dict[str, Any]]:
        """Find study set by ID."""
        return self._storage.get(study_set_id)

    async def find_all_by_user(
        self,
        user_id: str,
        skip: int = 0,
        limit: int = 100,
    ) -> list[dict[str, Any]]:
        """Find all study sets for a user."""
        user_sets = [s for s in self._storage.values() if s["user_id"] == user_id]
        return sorted(user_sets, key=lambda x: x["created_at"], reverse=True)[
            skip : skip + limit
        ]

    async def update_status(
        self,
        study_set_id: str,
        status: StudySetStatus,
        question_count: int = 0,
        progress: int = 0,
        current_step: str = None,
    ) -> Optional[dict[str, Any]]:
        """Update study set status."""
        study_set = self._storage.get(study_set_id)
        if not study_set:
            return None

        study_set["status"] = status.value
        study_set["question_count"] = question_count
        study_set["progress"] = progress
        if current_step:
            study_set["current_step"] = current_step
        study_set["updated_at"] = datetime.utcnow().isoformat()
        self._save_data()
        return study_set

    async def update_learning_status(
        self, study_set_id: str, learning_status: str
    ) -> Optional[dict[str, Any]]:
        """Update learning status."""
        study_set = self._storage.get(study_set_id)
        if not study_set:
            return None

        study_set["learning_status"] = learning_status
        study_set["updated_at"] = datetime.utcnow().isoformat()
        if learning_status == "reset":
            study_set["last_studied_at"] = None
        else:
            study_set["last_studied_at"] = datetime.utcnow().isoformat()
        self._save_data()
        return study_set

    async def delete(self, study_set_id: str) -> bool:
        """Delete a study set."""
        study_set = self._storage.get(study_set_id)
        if not study_set:
            return False

        # Remove from hash index
        if study_set["pdf_hash"] in self._hash_index:
            del self._hash_index[study_set["pdf_hash"]]

        del self._storage[study_set_id]
        self._save_data()
        return True

    async def copy_questions_from_source(
        self, source_study_set_id: str, target_study_set_id: str
    ) -> bool:
        """Copy questions from source to target study set (mock implementation)."""
        # In dev mode, we just simulate this by setting question count
        target = self._storage.get(target_study_set_id)
        source = self._storage.get(source_study_set_id)
        if target and source:
            target["question_count"] = source.get("question_count", 10)
            self._save_data()
            return True
        return False

    async def get_question_count(self, study_set_id: str) -> int:
        """Get the number of questions in a study set."""
        study_set = self._storage.get(study_set_id)
        return study_set.get("question_count", 0) if study_set else 0

    async def update_question_count(self, study_set_id: str, count: int) -> bool:
        """Update the question count for a study set."""
        study_set = self._storage.get(study_set_id)
        if not study_set:
            return False
        study_set["question_count"] = count
        study_set["updated_at"] = datetime.utcnow().isoformat()
        self._save_data()
        return True

    async def get_by_id(self, study_set_id: str) -> Optional[dict[str, Any]]:
        """Get a study set by ID (alias for find_by_id)."""
        return await self.find_by_id(study_set_id)

    async def get(self, study_set_id: str) -> Optional[dict[str, Any]]:
        """Get a study set by ID (alias for find_by_id)."""
        return await self.find_by_id(study_set_id)

    async def get_questions(self, study_set_id: str) -> list[dict[str, Any]]:
        """Get all questions for a study set."""
        # Use MockQuestionRepository to get actual saved questions
        from app.repositories.mock_question import MockQuestionRepository

        study_set = self._storage.get(study_set_id)
        if not study_set:
            return []

        question_repo = MockQuestionRepository()
        questions = await question_repo.get_by_study_set(study_set_id)

        return questions
