"""Scoring service for test submissions."""

from datetime import datetime
from typing import Any

from app.repositories.test_session import TestSessionRepository
from app.repositories.question import QuestionRepository


class ScoringService:
    """Service for scoring test submissions."""

    def __init__(self):
        self.session_repo = TestSessionRepository()
        self.question_repo = QuestionRepository()

    async def submit_and_score(
        self,
        session_id: str,
        answers: list[dict[str, Any]],
    ) -> dict[str, Any]:
        """
        Score submitted answers and save results.

        Args:
            session_id: Test session ID
            answers: List of {question_id, selected_option}

        Returns:
            Scoring result with score, total, percentage
        """
        session = await self.session_repo.get_session(session_id)
        if not session:
            raise ValueError("Session not found")

        # Get all questions for this session
        question_ids = [a["question_id"] for a in answers]
        questions = await self.question_repo.get_by_ids(question_ids)
        question_map = {q["id"]: q for q in questions}

        # Score each answer
        scored_answers = []
        correct_count = 0

        for ans in answers:
            question = question_map.get(ans["question_id"])
            if not question:
                continue

            is_correct = ans["selected_option"] == question["correct_answer"]
            if is_correct:
                correct_count += 1

            scored_answers.append({
                "question_id": ans["question_id"],
                "selected_option": ans["selected_option"],
                "is_correct": is_correct,
            })

        # Save answers
        await self.session_repo.save_answers(session_id, scored_answers)

        # Complete session
        await self.session_repo.complete_session(session_id, correct_count)

        # Calculate time taken
        started_at = datetime.fromisoformat(
            session["started_at"].replace("Z", "+00:00")
        )
        time_taken = int((datetime.utcnow() - started_at.replace(tzinfo=None)).total_seconds())

        total = len(scored_answers)
        percentage = round((correct_count / total * 100), 1) if total > 0 else 0

        return {
            "score": correct_count,
            "total": total,
            "percentage": percentage,
            "time_taken_seconds": time_taken,
        }

    async def get_result(
        self,
        session_id: str,
    ) -> dict[str, Any]:
        """
        Get detailed test results for review.

        Args:
            session_id: Test session ID

        Returns:
            Full result with question details
        """
        session = await self.session_repo.get_session(session_id)
        if not session:
            raise ValueError("Session not found")

        # Get study set name
        from app.repositories.study_set import StudySetRepository
        from app.core.config import get_settings
        study_set_repo = StudySetRepository(get_settings())
        study_set = await study_set_repo.get_by_id(session["study_set_id"])
        study_set_name = study_set["name"] if study_set else "Unknown"

        # Get answers
        answers = await self.session_repo.get_session_answers(session_id)
        answer_map = {a["question_id"]: a for a in answers}

        # Get questions
        question_ids = [a["question_id"] for a in answers]
        questions = await self.question_repo.get_by_ids(question_ids)

        # Build question results
        question_results = []
        for q in questions:
            answer = answer_map.get(q["id"], {})
            question_results.append({
                "id": q["id"],
                "question_number": q["question_number"],
                "question_text": q["question_text"],
                "options": q["options"],
                "correct_answer": q["correct_answer"],
                "selected_answer": answer.get("selected_option"),
                "is_correct": answer.get("is_correct", False),
                "explanation": q.get("explanation"),
            })

        # Sort by question number
        question_results.sort(key=lambda x: x["question_number"])

        # Calculate time taken
        started_at = datetime.fromisoformat(
            session["started_at"].replace("Z", "+00:00")
        )
        completed_at = session.get("completed_at")
        if completed_at:
            completed_at = datetime.fromisoformat(
                completed_at.replace("Z", "+00:00")
            )
            time_taken = int((completed_at - started_at).total_seconds())
        else:
            time_taken = 0

        total = session["total_questions"]
        score = session.get("score", 0)
        percentage = round((score / total * 100), 1) if total > 0 else 0

        return {
            "session_id": session_id,
            "study_set_id": session["study_set_id"],
            "study_set_name": study_set_name,
            "score": score,
            "total": total,
            "percentage": percentage,
            "time_taken_seconds": time_taken,
            "completed_at": session.get("completed_at"),
            "questions": question_results,
        }
