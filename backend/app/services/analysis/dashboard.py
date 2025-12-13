"""Dashboard data service.

Aggregates user statistics for the main dashboard.
"""

from typing import Any
from datetime import datetime
import httpx

from app.core.config import get_settings


class DashboardService:
    """Service for aggregating dashboard statistics."""

    def __init__(self):
        self.settings = get_settings()
        self.base_url = f"{self.settings.supabase_url}/rest/v1"
        self.headers = {
            "apikey": self.settings.supabase_service_key,
            "Authorization": f"Bearer {self.settings.supabase_service_key}",
            "Content-Type": "application/json",
        }

    async def get_stats(self, user_id: str) -> dict[str, Any]:
        """
        Get aggregated dashboard statistics.

        Args:
            user_id: User's clerk ID

        Returns:
            Dashboard statistics
        """
        try:
            # Get study sets count
            study_sets = await self._get_study_sets(user_id)
            study_set_count = len(study_sets)

            # Calculate total questions across all study sets
            total_questions = sum(
                ss.get("question_count", 0) for ss in study_sets
                if ss.get("status") == "ready"
            )

            # Get test sessions
            sessions = await self._get_test_sessions(user_id)
            test_count = len(sessions)
        except Exception as e:
            # If there's an error connecting to the database, return empty stats
            return {
                "study_set_count": 0,
                "total_questions": 0,
                "test_count": 0,
                "avg_accuracy": 0,
                "recent_activity": [],
                "has_data": False,
            }

        # Calculate average accuracy
        total_score = 0
        total_possible = 0
        for session in sessions:
            if session.get("score") is not None and session.get("total_questions"):
                total_score += session["score"]
                total_possible += session["total_questions"]

        avg_accuracy = round(total_score / total_possible * 100, 1) if total_possible > 0 else 0

        # Get recent activity
        recent_sessions = sessions[:5]  # Already sorted desc
        recent_activity = []

        for session in recent_sessions:
            # Get study set name
            study_set_name = "Unknown"
            for ss in study_sets:
                if ss["id"] == session.get("study_set_id"):
                    study_set_name = ss["name"]
                    break

            score = session.get("score", 0)
            total = session.get("total_questions", 0)
            percentage = round(score / total * 100, 1) if total > 0 else 0

            recent_activity.append({
                "session_id": session["id"],
                "study_set_name": study_set_name,
                "score": score,
                "total": total,
                "percentage": percentage,
                "completed_at": session.get("completed_at") or session.get("started_at"),
            })

        return {
            "study_set_count": study_set_count,
            "total_questions": total_questions,
            "test_count": test_count,
            "avg_accuracy": avg_accuracy,
            "recent_activity": recent_activity,
            "has_data": test_count > 0 or study_set_count > 0,
        }

    async def _get_study_sets(self, user_id: str) -> list[dict]:
        """Get user's study sets."""
        async with httpx.AsyncClient() as client:
            # First get study sets
            response = await client.get(
                f"{self.base_url}/study_sets",
                headers=self.headers,
                params={
                    "user_id": f"eq.{user_id}",
                    "select": "id,name,status",
                    "order": "created_at.desc",
                },
            )
            response.raise_for_status()
            study_sets = response.json()

            # Get question counts for each
            for ss in study_sets:
                count_response = await client.get(
                    f"{self.base_url}/questions",
                    headers={
                        **self.headers,
                        "Prefer": "count=exact",
                    },
                    params={
                        "study_set_id": f"eq.{ss['id']}",
                        "select": "id",
                    },
                )
                count_header = count_response.headers.get("content-range", "0-0/0")
                ss["question_count"] = int(count_header.split("/")[-1])

            return study_sets

    async def _get_test_sessions(self, user_id: str) -> list[dict]:
        """Get user's test sessions."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/test_sessions",
                headers=self.headers,
                params={
                    "user_id": f"eq.{user_id}",
                    "status": "eq.completed",
                    "select": "id,study_set_id,score,total_questions,started_at,completed_at",
                    "order": "completed_at.desc",
                },
            )
            response.raise_for_status()
            return response.json()
