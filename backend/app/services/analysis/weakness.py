"""Weakness analysis service.

Analyzes user's weak concepts based on test performance.
MVP version uses subject/topic fields instead of Neo4j Knowledge Graph.
"""

from typing import Any
from collections import defaultdict
import httpx

from app.core.config import get_settings


class WeaknessAnalyzer:
    """Analyzes user's weak areas based on test history."""

    def __init__(self):
        self.settings = get_settings()
        self.base_url = f"{self.settings.supabase_url}/rest/v1"
        self.headers = {
            "apikey": self.settings.supabase_service_key,
            "Authorization": f"Bearer {self.settings.supabase_service_key}",
            "Content-Type": "application/json",
        }

    async def analyze(self, user_id: str) -> dict[str, Any]:
        """
        Analyze user's weak concepts.

        Args:
            user_id: User's clerk ID

        Returns:
            Analysis results with weak concepts and recommendations
        """
        # Get all user's test sessions
        sessions = await self._get_user_sessions(user_id)
        if not sessions:
            return {
                "weak_concepts": [],
                "insight": None,
                "total_questions": 0,
                "total_correct": 0,
            }

        # Get all answers
        all_answers = []
        for session in sessions:
            answers = await self._get_session_answers(session["id"])
            all_answers.extend(answers)

        if not all_answers:
            return {
                "weak_concepts": [],
                "insight": None,
                "total_questions": 0,
                "total_correct": 0,
            }

        # Get question details
        question_ids = [a["question_id"] for a in all_answers]
        questions = await self._get_questions(question_ids)
        question_map = {q["id"]: q for q in questions}

        # Aggregate by subject/topic
        subject_stats = defaultdict(lambda: {"correct": 0, "total": 0, "questions": []})
        topic_stats = defaultdict(lambda: {"correct": 0, "total": 0, "subject": None})

        total_questions = 0
        total_correct = 0

        for answer in all_answers:
            question = question_map.get(answer["question_id"])
            if not question:
                continue

            total_questions += 1
            if answer["is_correct"]:
                total_correct += 1

            subject = question.get("subject") or "기타"
            topic = question.get("topic")

            subject_stats[subject]["total"] += 1
            if answer["is_correct"]:
                subject_stats[subject]["correct"] += 1

            if topic:
                topic_stats[topic]["total"] += 1
                topic_stats[topic]["subject"] = subject
                if answer["is_correct"]:
                    topic_stats[topic]["correct"] += 1

        # Calculate weakness scores and sort
        weak_concepts = []

        for subject, stats in subject_stats.items():
            if stats["total"] >= 2:  # Need at least 2 questions for meaningful analysis
                accuracy = stats["correct"] / stats["total"]
                weakness_score = 1 - accuracy

                if weakness_score > 0.3:  # Show concepts with >30% error rate
                    # Find weak topics within this subject
                    weak_topics = []
                    for topic, tstats in topic_stats.items():
                        if tstats["subject"] == subject and tstats["total"] >= 1:
                            topic_accuracy = tstats["correct"] / tstats["total"]
                            if topic_accuracy < 0.7:
                                weak_topics.append(topic)

                    weak_concepts.append({
                        "concept": subject,
                        "weakness_score": round(weakness_score, 2),
                        "wrong_count": stats["total"] - stats["correct"],
                        "total_count": stats["total"],
                        "accuracy_percent": round(accuracy * 100, 1),
                        "related_topics": weak_topics[:5],  # Top 5 weak topics
                    })

        # Sort by weakness score (highest first)
        weak_concepts.sort(key=lambda x: x["weakness_score"], reverse=True)

        # Generate insight
        insight = self._generate_insight(weak_concepts, total_questions, total_correct)

        return {
            "weak_concepts": weak_concepts[:10],  # Top 10
            "insight": insight,
            "total_questions": total_questions,
            "total_correct": total_correct,
            "overall_accuracy": round(total_correct / total_questions * 100, 1) if total_questions > 0 else 0,
        }

    def _generate_insight(
        self,
        weak_concepts: list,
        total_questions: int,
        total_correct: int,
    ) -> str | None:
        """Generate study recommendation insight."""
        if not weak_concepts:
            if total_questions > 0:
                accuracy = total_correct / total_questions * 100
                if accuracy >= 80:
                    return "전체적으로 우수한 성적입니다! 더 많은 문제를 풀어 실력을 유지하세요."
                else:
                    return "더 많은 문제를 풀어보면 취약점 분석이 더 정확해집니다."
            return None

        # Get top weak concept
        top_weak = weak_concepts[0]

        insight_parts = []

        if top_weak["weakness_score"] > 0.5:
            insight_parts.append(
                f"'{top_weak['concept']}' 영역에서 어려움을 겪고 있습니다. "
                f"({top_weak['total_count']}문제 중 {top_weak['wrong_count']}문제 오답)"
            )
        else:
            insight_parts.append(
                f"'{top_weak['concept']}' 영역을 조금 더 보완하면 좋겠습니다."
            )

        if top_weak["related_topics"]:
            topics = ", ".join(top_weak["related_topics"][:3])
            insight_parts.append(f"특히 '{topics}' 관련 내용을 복습해보세요.")

        if len(weak_concepts) > 1:
            other = weak_concepts[1]["concept"]
            insight_parts.append(f"'{other}' 영역도 함께 학습하시면 효과적입니다.")

        return " ".join(insight_parts)

    async def _get_user_sessions(self, user_id: str) -> list[dict]:
        """Get completed test sessions for user."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/test_sessions",
                headers=self.headers,
                params={
                    "user_id": f"eq.{user_id}",
                    "status": "eq.completed",
                    "select": "id",
                },
            )
            response.raise_for_status()
            return response.json()

    async def _get_session_answers(self, session_id: str) -> list[dict]:
        """Get answers for a session."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/user_answers",
                headers=self.headers,
                params={"session_id": f"eq.{session_id}"},
            )
            response.raise_for_status()
            return response.json()

    async def _get_questions(self, question_ids: list[str]) -> list[dict]:
        """Get questions by IDs."""
        if not question_ids:
            return []

        # Deduplicate
        unique_ids = list(set(question_ids))
        ids_str = ",".join(unique_ids)

        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/questions",
                headers=self.headers,
                params={
                    "id": f"in.({ids_str})",
                    "select": "id,subject,topic",
                },
            )
            response.raise_for_status()
            return response.json()
