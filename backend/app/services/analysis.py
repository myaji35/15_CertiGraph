"""Analysis services for dashboard stats and exam predictions."""

from typing import Any
from datetime import datetime, timedelta


class DashboardService:
    """Service for aggregating dashboard statistics."""

    async def get_stats(self, clerk_id: str) -> dict[str, Any]:
        """
        Get dashboard statistics for a user.

        Returns:
            - study_set_count: Number of study sets
            - total_questions: Total questions across all study sets
            - test_count: Number of completed tests
            - avg_accuracy: Average accuracy across all tests
            - recent_activity: Recent test sessions
            - has_data: Whether user has any data
        """
        from app.repositories.mock_study_set import MockStudySetRepository
        from app.repositories.mock_test_session import MockTestSessionRepository

        study_set_repo = MockStudySetRepository()
        test_session_repo = MockTestSessionRepository()

        # Get all study sets for user
        study_sets = await study_set_repo.find_all_by_user(clerk_id)

        # Calculate total questions
        total_questions = sum(ss.get("total_questions", 0) for ss in study_sets)

        # Get all test sessions
        test_sessions = await test_session_repo.get_user_sessions(clerk_id)
        completed_sessions = [
            s for s in test_sessions
            if s.get("status") == "completed"
        ]

        # Calculate average accuracy
        avg_accuracy = 0
        if completed_sessions:
            accuracies = []
            for s in completed_sessions:
                total = s.get("total_questions", 0)
                score = s.get("score", 0)
                if total > 0 and score is not None:
                    accuracies.append((score / total) * 100)
            if accuracies:
                avg_accuracy = round(sum(accuracies) / len(accuracies), 1)

        # Get recent activity (last 5 sessions)
        recent_activity = []
        for session in sorted(
            completed_sessions,
            key=lambda x: x.get("completed_at", ""),
            reverse=True
        )[:5]:
            study_set_id = session.get("study_set_id")
            study_set = await study_set_repo.find_by_id(study_set_id)

            total = session.get("total_questions", 0)
            score = session.get("score", 0)
            if score is None:
                score = 0
            percentage = round((score / total * 100) if total > 0 else 0, 1)

            recent_activity.append({
                "session_id": session.get("id"),
                "study_set_name": study_set.get("name", "Unknown") if study_set else "Unknown",
                "score": score,
                "total": total,
                "percentage": percentage,
                "completed_at": session.get("completed_at", ""),
            })

        has_data = len(study_sets) > 0 or len(completed_sessions) > 0

        return {
            "study_set_count": len(study_sets),
            "total_questions": total_questions,
            "test_count": len(completed_sessions),
            "avg_accuracy": avg_accuracy,
            "recent_activity": recent_activity,
            "has_data": has_data,
        }


class ExamPredictionService:
    """Service for predicting exam pass probability."""

    async def predict(self, clerk_id: str) -> dict[str, Any]:
        """
        Predict exam pass probability based on test history.

        Returns:
            - predicted_score: Predicted exam score (0-100)
            - pass_probability: Risk level (high/medium/low/danger/unknown)
            - is_passing: Whether predicted to pass
            - cutoff_subjects: List of subjects at risk of 과락
        """
        from app.repositories.mock_test_session import MockTestSessionRepository

        test_session_repo = MockTestSessionRepository()

        # Get all completed test sessions
        test_sessions = await test_session_repo.get_user_sessions(clerk_id)
        completed_sessions = [
            s for s in test_sessions
            if s.get("status") == "completed"
        ]

        if not completed_sessions:
            return {
                "predicted_score": 0,
                "pass_probability": "unknown",
                "is_passing": False,
                "cutoff_subjects": [],
            }

        # Calculate weighted average (recent tests weighted more)
        recent_sessions = sorted(
            completed_sessions,
            key=lambda x: x.get("completed_at", ""),
            reverse=True
        )[:10]  # Last 10 tests

        weighted_scores = []
        weights = []
        for i, session in enumerate(recent_sessions):
            total = session.get("total_questions", 0)
            score = session.get("score", 0)
            if score is None:
                score = 0
            if total > 0:
                percentage = (score / total) * 100
                weight = 1.0 + (i * 0.1)  # More recent = higher weight
                weighted_scores.append(percentage * weight)
                weights.append(weight)

        if not weighted_scores:
            predicted_score = 0
        else:
            predicted_score = round(sum(weighted_scores) / sum(weights), 1)

        # Determine pass probability
        if predicted_score >= 75:
            pass_probability = "high"
        elif predicted_score >= 65:
            pass_probability = "medium"
        elif predicted_score >= 55:
            pass_probability = "low"
        else:
            pass_probability = "danger"

        is_passing = predicted_score >= 60  # Assuming 60 is passing

        # TODO: Implement per-subject analysis for 과락 detection
        # For now, return empty list
        cutoff_subjects = []

        # Mock cutoff detection based on overall score
        if predicted_score < 50:
            cutoff_subjects = ["전체 과목"]

        return {
            "predicted_score": predicted_score,
            "pass_probability": pass_probability,
            "is_passing": is_passing,
            "cutoff_subjects": cutoff_subjects,
        }


class WeaknessAnalyzer:
    """Service for analyzing weak concepts from test history."""

    async def analyze(self, clerk_id: str) -> dict[str, Any]:
        """
        Analyze user's weak concepts based on test history.

        Returns concept-level weakness analysis with recommendations.
        """
        from app.repositories.mock_test_session import MockTestSessionRepository

        test_session_repo = MockTestSessionRepository()

        # Get all completed test sessions
        test_sessions = await test_session_repo.get_user_sessions(clerk_id)
        completed_sessions = [
            s for s in test_sessions
            if s.get("status") == "completed"
        ]

        if not completed_sessions:
            return {
                "weak_concepts": [],
                "strong_concepts": [],
                "recommendations": [],
            }

        # TODO: Implement concept-level analysis using test answers
        # For now, return mock data

        return {
            "weak_concepts": [],
            "strong_concepts": [],
            "recommendations": [
                "더 많은 문제를 풀어보세요.",
                "틀린 문제를 복습하세요.",
            ],
        }
