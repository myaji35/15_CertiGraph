"""Repository for question database operations."""

from typing import Optional, Any
import httpx
import random

from app.core.config import get_settings


def QuestionRepository():
    """Factory function to return appropriate repository based on mode."""
    settings = get_settings()
    if settings.dev_mode:
        from app.repositories.mock_question import MockQuestionRepository
        return MockQuestionRepository()
    return _QuestionRepository()


class _QuestionRepository:
    """Data access layer for questions."""

    def __init__(self):
        self.settings = get_settings()
        self.base_url = f"{self.settings.supabase_url}/rest/v1"
        self.headers = {
            "apikey": self.settings.supabase_service_key,
            "Authorization": f"Bearer {self.settings.supabase_service_key}",
            "Content-Type": "application/json",
        }

    async def get_by_study_set(
        self,
        study_set_id: str,
        limit: Optional[int] = None,
        randomize: bool = False,
    ) -> list[dict[str, Any]]:
        """Get questions for a study set."""
        params = {
            "study_set_id": f"eq.{study_set_id}",
            "order": "question_number.asc",
        }

        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/questions",
                headers=self.headers,
                params=params,
            )
            response.raise_for_status()
            questions = response.json()

        if randomize:
            random.shuffle(questions)

        if limit and len(questions) > limit:
            questions = questions[:limit]

        return questions

    async def get_by_ids(
        self,
        question_ids: list[str],
    ) -> list[dict[str, Any]]:
        """Get specific questions by their IDs."""
        if not question_ids:
            return []

        # Supabase uses 'in' operator for multiple values
        ids_str = ",".join(question_ids)

        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/questions",
                headers=self.headers,
                params={
                    "id": f"in.({ids_str})",
                },
            )
            response.raise_for_status()
            return response.json()

    async def get_by_id(self, question_id: str) -> Optional[dict[str, Any]]:
        """Get a single question by ID."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/questions",
                headers=self.headers,
                params={"id": f"eq.{question_id}"},
            )
            response.raise_for_status()
            results = response.json()
            return results[0] if results else None

    async def get_count(self, study_set_id: str) -> int:
        """Get the count of questions in a study set."""
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
