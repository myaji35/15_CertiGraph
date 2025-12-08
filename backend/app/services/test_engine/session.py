"""Test session service."""

from typing import Any

from app.models.test import TestMode, QuestionForTest
from app.repositories.test_session import TestSessionRepository
from app.repositories.question import QuestionRepository


class TestSessionService:
    """Service for managing test sessions."""

    def __init__(self):
        self.session_repo = TestSessionRepository()
        self.question_repo = QuestionRepository()

    async def start_session(
        self,
        user_id: str,
        study_set_id: str,
        mode: TestMode,
        question_count: int | None = None,
        shuffle_options: bool = False,
    ) -> dict[str, Any]:
        """
        Start a new test session.

        Args:
            user_id: User's clerk ID
            study_set_id: Study set to test from
            mode: Test mode (all, random, wrong_only)
            question_count: Number of questions for random mode

        Returns:
            Dict with session_id and questions
        """
        # Get questions based on mode
        if mode == TestMode.WRONG_ONLY:
            # Get previously wrong questions
            wrong_ids = await self.session_repo.get_wrong_question_ids(
                user_id, study_set_id
            )
            if wrong_ids:
                questions = await self.question_repo.get_by_ids(wrong_ids)
            else:
                # No wrong questions, get all
                questions = await self.question_repo.get_by_study_set(study_set_id)

        elif mode == TestMode.RANDOM:
            count = question_count or 20
            questions = await self.question_repo.get_by_study_set(
                study_set_id,
                limit=count,
                randomize=True,
            )

        else:  # ALL
            questions = await self.question_repo.get_by_study_set(study_set_id)

        # Create session
        session = await self.session_repo.create_session(
            user_id=user_id,
            study_set_id=study_set_id,
            mode=mode,
            total_questions=len(questions),
        )

        # Format questions for response
        import random
        formatted_questions = []
        for q in questions:
            options = q["options"]
            # Shuffle options if requested
            if shuffle_options and options:
                options = list(options)  # Make a copy
                random.shuffle(options)

            formatted_questions.append(
                QuestionForTest(
                    id=q["id"],
                    question_number=q["question_number"],
                    question_text=q["question_text"],
                    options=options,
                    passage=q.get("passage"),
                )
            )

        return {
            "session_id": session["id"],
            "questions": formatted_questions,
            "total_questions": len(questions),
            "time_limit_minutes": None,
        }

    async def get_session(self, session_id: str) -> dict[str, Any] | None:
        """Get session details."""
        return await self.session_repo.get_session(session_id)

    async def get_session_history(
        self,
        user_id: str,
        study_set_id: str | None = None,
        limit: int = 20,
    ) -> list[dict[str, Any]]:
        """Get user's test session history with study set names."""
        sessions = await self.session_repo.get_user_sessions(
            user_id, study_set_id, limit
        )

        # Get study set names using factory pattern
        from app.api.v1.deps import get_study_set_repository
        from app.core import get_settings
        study_set_repo = get_study_set_repository(get_settings())

        study_set_ids = list(set(s["study_set_id"] for s in sessions))
        study_sets = {}
        for ss_id in study_set_ids:
            ss = await study_set_repo.get_by_id(ss_id)
            if ss:
                study_sets[ss_id] = ss["name"]

        # Enrich with study set name and percentage
        result = []
        for session in sessions:
            score = session.get("score", 0) or 0
            total = session.get("total_questions", 0) or 0
            percentage = round(score / total * 100, 1) if total > 0 else 0

            result.append({
                **session,
                "study_set_name": study_sets.get(session["study_set_id"], "Unknown"),
                "percentage": percentage,
            })

        return result
