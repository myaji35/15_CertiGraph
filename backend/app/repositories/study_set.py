"""Repository for study set database operations."""

import uuid
from datetime import datetime
from typing import Optional, Any
import httpx

from app.core.config import get_settings
from app.models.study_set import StudySetStatus


class StudySetRepository:
    """Data access layer for study_sets and related tables."""

    def __init__(self):
        self.settings = get_settings()
        self.base_url = f"{self.settings.supabase_url}/rest/v1"
        self.headers = {
            "apikey": self.settings.supabase_service_key,
            "Authorization": f"Bearer {self.settings.supabase_service_key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        }

    async def create(
        self,
        user_id: str,
        name: str,
        pdf_path: str,
        pdf_hash: str,
        status: StudySetStatus = StudySetStatus.UPLOADING,
        source_study_set_id: Optional[str] = None,
    ) -> dict[str, Any]:
        """
        Create a new study set record.

        Args:
            user_id: Internal user ID (from users table)
            name: Name of the study set
            pdf_path: Storage path to the PDF file
            pdf_hash: SHA-256 hash of PDF content
            status: Initial processing status
            source_study_set_id: If cached, reference to the original study set

        Returns:
            Created study set record
        """
        study_set_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()

        data = {
            "id": study_set_id,
            "user_id": user_id,
            "name": name,
            "pdf_path": pdf_path,
            "pdf_hash": pdf_hash,
            "status": status.value,
            "source_study_set_id": source_study_set_id,
            "created_at": now,
            "updated_at": now,
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/study_sets",
                headers=self.headers,
                json=data,
            )
            response.raise_for_status()
            return response.json()[0]

    async def find_by_hash(self, pdf_hash: str) -> Optional[dict[str, Any]]:
        """
        Find a successfully processed study set by PDF hash.

        This is used to detect duplicates and reuse cached results.

        Args:
            pdf_hash: SHA-256 hash of PDF content

        Returns:
            Study set record if found, None otherwise
        """
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/study_sets",
                headers=self.headers,
                params={
                    "pdf_hash": f"eq.{pdf_hash}",
                    "status": f"eq.{StudySetStatus.READY.value}",
                    "source_study_set_id": "is.null",  # Only original, not cached copies
                    "limit": "1",
                },
            )
            response.raise_for_status()
            results = response.json()
            return results[0] if results else None

    async def get_by_id(self, study_set_id: str) -> Optional[dict[str, Any]]:
        """Get study set by ID."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/study_sets",
                headers=self.headers,
                params={"id": f"eq.{study_set_id}"},
            )
            response.raise_for_status()
            results = response.json()
            return results[0] if results else None

    async def get_by_user(
        self,
        user_id: str,
        limit: int = 50,
        offset: int = 0
    ) -> list[dict[str, Any]]:
        """Get all study sets for a user."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/study_sets",
                headers={
                    **self.headers,
                    "Range": f"{offset}-{offset + limit - 1}",
                },
                params={
                    "user_id": f"eq.{user_id}",
                    "order": "created_at.desc",
                },
            )
            response.raise_for_status()
            return response.json()

    async def update_status(
        self,
        study_set_id: str,
        status: StudySetStatus,
        progress: int = 0,
        current_step: Optional[str] = None,
    ) -> dict[str, Any]:
        """Update study set processing status."""
        data = {
            "status": status.value,
            "progress": progress,
            "current_step": current_step,
            "updated_at": datetime.utcnow().isoformat(),
        }

        async with httpx.AsyncClient() as client:
            response = await client.patch(
                f"{self.base_url}/study_sets",
                headers=self.headers,
                params={"id": f"eq.{study_set_id}"},
                json=data,
            )
            response.raise_for_status()
            return response.json()[0]

    async def copy_questions_from_source(
        self,
        source_study_set_id: str,
        target_study_set_id: str,
    ) -> int:
        """
        Copy questions from a source study set to a new one.

        This is used when a duplicate PDF is uploaded.

        Args:
            source_study_set_id: ID of the original study set
            target_study_set_id: ID of the new study set

        Returns:
            Number of questions copied
        """
        # First, get all questions from source
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/questions",
                headers=self.headers,
                params={"study_set_id": f"eq.{source_study_set_id}"},
            )
            response.raise_for_status()
            source_questions = response.json()

        if not source_questions:
            return 0

        # Create copies for the new study set
        now = datetime.utcnow().isoformat()
        new_questions = []
        for q in source_questions:
            new_q = {
                "id": str(uuid.uuid4()),
                "study_set_id": target_study_set_id,
                "question_number": q["question_number"],
                "question_text": q["question_text"],
                "options": q["options"],
                "correct_answer": q["correct_answer"],
                "explanation": q.get("explanation"),
                "subject": q.get("subject"),
                "topic": q.get("topic"),
                "difficulty": q.get("difficulty"),
                "created_at": now,
            }
            new_questions.append(new_q)

        # Insert all questions
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/questions",
                headers=self.headers,
                json=new_questions,
            )
            response.raise_for_status()

        return len(new_questions)

    async def get_question_count(self, study_set_id: str) -> int:
        """Get the number of questions in a study set."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/questions",
                headers={
                    **self.headers,
                    "Prefer": "count=exact",
                },
                params={
                    "study_set_id": f"eq.{study_set_id}",
                    "select": "id",
                },
            )
            response.raise_for_status()
            count_header = response.headers.get("content-range", "0-0/0")
            total = count_header.split("/")[-1]
            return int(total)

    async def delete(self, study_set_id: str) -> bool:
        """
        Delete a study set and its associated questions.

        Questions are deleted via CASCADE constraint.

        Args:
            study_set_id: ID of the study set to delete

        Returns:
            True if deletion was successful
        """
        async with httpx.AsyncClient() as client:
            response = await client.delete(
                f"{self.base_url}/study_sets",
                headers=self.headers,
                params={"id": f"eq.{study_set_id}"},
            )
            response.raise_for_status()
            return True
