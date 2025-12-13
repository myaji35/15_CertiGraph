"""Exam prediction service.

Predicts exam pass probability based on user's test history.
Implements 사회복지사 1급 exam rules:
- 3 subjects (교시)
- 과락 기준: 각 과목 40점 미만 (40% 미만)
- 합격 기준: 전 과목 평균 60점 이상 (60% 이상)
"""

from typing import Any
from collections import defaultdict
from dataclasses import dataclass
import httpx

from app.core.config import get_settings


# 사회복지사 1급 과목 구성
EXAM_SUBJECTS = {
    "1교시": {
        "name": "사회복지기초",
        "topics": ["인간행동과사회환경", "사회복지조사론"],
        "question_count": 50,
    },
    "2교시": {
        "name": "사회복지실천",
        "topics": ["사회복지실천론", "사회복지실천기술론", "지역사회복지론"],
        "question_count": 75,
    },
    "3교시": {
        "name": "사회복지정책과제도",
        "topics": ["사회복지정책론", "사회복지행정론", "사회복지법제론"],
        "question_count": 75,
    },
}

# 합격 기준
CUTOFF_SCORE = 40  # 과목별 과락 기준 (40점 미만이면 과락)
PASS_AVERAGE = 60  # 전체 평균 합격 기준


@dataclass
class SubjectScore:
    """과목별 점수 정보"""
    subject_id: str
    name: str
    score: float  # 백분율 (0-100)
    correct_count: int
    total_count: int
    is_cutoff: bool  # 과락 여부
    topics: list[dict]  # 세부 주제별 점수


@dataclass
class ExamPrediction:
    """시험 예측 결과"""
    predicted_score: float  # 예상 점수 (100점 만점)
    pass_probability: str  # 합격 가능성: high, medium, low, danger
    is_passing: bool  # 현재 합격 기준 충족 여부
    cutoff_subjects: list[str]  # 과락 과목 목록
    subject_scores: list[SubjectScore]
    recommendation: str  # 학습 추천 메시지
    total_questions: int
    total_correct: int


class ExamPredictionService:
    """시험 합격 예측 서비스"""

    def __init__(self):
        self.settings = get_settings()
        self.base_url = f"{self.settings.supabase_url}/rest/v1"
        self.headers = {
            "apikey": self.settings.supabase_service_key,
            "Authorization": f"Bearer {self.settings.supabase_service_key}",
            "Content-Type": "application/json",
        }

    async def predict(self, user_id: str) -> dict[str, Any]:
        """
        사용자의 시험 합격 가능성 예측

        Args:
            user_id: 사용자 ID

        Returns:
            예측 결과
        """
        try:
            # Get all completed sessions
            sessions = await self._get_user_sessions(user_id)
            if not sessions:
                return self._empty_result()
        except Exception as e:
            # If there's an error connecting to the database, return empty result
            return self._empty_result()

        # Get all answers with question details
        all_data = await self._get_answers_with_questions(sessions)
        if not all_data:
            return self._empty_result()

        # Aggregate by subject
        subject_stats = self._aggregate_by_subject(all_data)

        # Calculate subject scores
        subject_scores = []
        cutoff_subjects = []
        total_correct = 0
        total_questions = 0

        for subject_id, config in EXAM_SUBJECTS.items():
            stats = subject_stats.get(config["name"], {"correct": 0, "total": 0, "topics": {}})

            if stats["total"] > 0:
                score = (stats["correct"] / stats["total"]) * 100
                is_cutoff = score < CUTOFF_SCORE
            else:
                score = 0
                is_cutoff = True  # No data = assume cutoff risk

            if is_cutoff and stats["total"] > 0:
                cutoff_subjects.append(config["name"])

            # Topic breakdown
            topic_scores = []
            for topic_name, topic_stats in stats.get("topics", {}).items():
                if topic_stats["total"] > 0:
                    topic_score = (topic_stats["correct"] / topic_stats["total"]) * 100
                    topic_scores.append({
                        "name": topic_name,
                        "score": round(topic_score, 1),
                        "correct": topic_stats["correct"],
                        "total": topic_stats["total"],
                    })

            subject_scores.append(SubjectScore(
                subject_id=subject_id,
                name=config["name"],
                score=round(score, 1),
                correct_count=stats["correct"],
                total_count=stats["total"],
                is_cutoff=is_cutoff,
                topics=sorted(topic_scores, key=lambda x: x["score"]),
            ))

            total_correct += stats["correct"]
            total_questions += stats["total"]

        # Calculate overall prediction
        if total_questions > 0:
            predicted_score = (total_correct / total_questions) * 100
        else:
            predicted_score = 0

        # Determine pass probability
        is_passing = predicted_score >= PASS_AVERAGE and len(cutoff_subjects) == 0

        if predicted_score >= 70 and len(cutoff_subjects) == 0:
            pass_probability = "high"
        elif predicted_score >= 60 and len(cutoff_subjects) == 0:
            pass_probability = "medium"
        elif predicted_score >= 50 or len(cutoff_subjects) <= 1:
            pass_probability = "low"
        else:
            pass_probability = "danger"

        # Generate recommendation
        recommendation = self._generate_recommendation(
            subject_scores, cutoff_subjects, predicted_score
        )

        return {
            "predicted_score": round(predicted_score, 1),
            "pass_probability": pass_probability,
            "is_passing": is_passing,
            "cutoff_subjects": cutoff_subjects,
            "subject_scores": [
                {
                    "subject_id": s.subject_id,
                    "name": s.name,
                    "score": s.score,
                    "correct_count": s.correct_count,
                    "total_count": s.total_count,
                    "is_cutoff": s.is_cutoff,
                    "topics": s.topics,
                }
                for s in subject_scores
            ],
            "recommendation": recommendation,
            "total_questions": total_questions,
            "total_correct": total_correct,
            "pass_criteria": {
                "cutoff_score": CUTOFF_SCORE,
                "pass_average": PASS_AVERAGE,
            },
        }

    def _empty_result(self) -> dict[str, Any]:
        """Return empty result for users with no data."""
        return {
            "predicted_score": 0,
            "pass_probability": "unknown",
            "is_passing": False,
            "cutoff_subjects": [],
            "subject_scores": [],
            "recommendation": "모의고사를 응시하면 합격 예측을 받을 수 있습니다.",
            "total_questions": 0,
            "total_correct": 0,
            "pass_criteria": {
                "cutoff_score": CUTOFF_SCORE,
                "pass_average": PASS_AVERAGE,
            },
        }

    def _aggregate_by_subject(self, data: list[dict]) -> dict:
        """Aggregate answer data by subject."""
        subject_stats = defaultdict(lambda: {
            "correct": 0,
            "total": 0,
            "topics": defaultdict(lambda: {"correct": 0, "total": 0}),
        })

        for item in data:
            subject = item.get("subject") or "기타"
            topic = item.get("topic") or "기타"
            is_correct = item.get("is_correct", False)

            subject_stats[subject]["total"] += 1
            subject_stats[subject]["topics"][topic]["total"] += 1

            if is_correct:
                subject_stats[subject]["correct"] += 1
                subject_stats[subject]["topics"][topic]["correct"] += 1

        return dict(subject_stats)

    def _generate_recommendation(
        self,
        subject_scores: list[SubjectScore],
        cutoff_subjects: list[str],
        predicted_score: float,
    ) -> str:
        """Generate study recommendation."""
        if not subject_scores or all(s.total_count == 0 for s in subject_scores):
            return "더 많은 문제를 풀어 정확한 예측을 받아보세요."

        parts = []

        # Cutoff warning
        if cutoff_subjects:
            subjects_str = ", ".join(f"'{s}'" for s in cutoff_subjects)
            parts.append(f"⚠️ {subjects_str} 과목이 과락 위험입니다!")

        # Score-based recommendation
        if predicted_score >= 70:
            parts.append("현재 성적이 양호합니다. 꾸준히 유지하세요.")
        elif predicted_score >= 60:
            parts.append("합격선에 근접했습니다. 조금만 더 노력하세요!")
        elif predicted_score >= 50:
            parts.append("합격까지 추가 학습이 필요합니다.")
        else:
            parts.append("기초부터 차근차근 학습하시길 권장합니다.")

        # Find weakest subject with data
        subjects_with_data = [s for s in subject_scores if s.total_count >= 5]
        if subjects_with_data:
            weakest = min(subjects_with_data, key=lambda x: x.score)
            if weakest.score < 60:
                parts.append(f"'{weakest.name}' 과목을 집중적으로 학습하세요.")

                # Find weakest topic in that subject
                if weakest.topics:
                    weakest_topic = weakest.topics[0]  # Already sorted ascending
                    if weakest_topic["total"] >= 2:
                        parts.append(f"특히 '{weakest_topic['name']}' 영역을 보완하세요.")

        return " ".join(parts)

    async def _get_user_sessions(self, user_id: str) -> list[dict]:
        """Get user's completed test sessions."""
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

    async def _get_answers_with_questions(self, sessions: list[dict]) -> list[dict]:
        """Get all answers with question details."""
        if not sessions:
            return []

        session_ids = [s["id"] for s in sessions]
        all_data = []

        for session_id in session_ids:
            async with httpx.AsyncClient() as client:
                # Get answers
                answers_response = await client.get(
                    f"{self.base_url}/user_answers",
                    headers=self.headers,
                    params={"session_id": f"eq.{session_id}"},
                )
                answers_response.raise_for_status()
                answers = answers_response.json()

                if not answers:
                    continue

                # Get question details
                question_ids = [a["question_id"] for a in answers]
                ids_str = ",".join(set(question_ids))

                questions_response = await client.get(
                    f"{self.base_url}/questions",
                    headers=self.headers,
                    params={
                        "id": f"in.({ids_str})",
                        "select": "id,subject,topic",
                    },
                )
                questions_response.raise_for_status()
                questions = {q["id"]: q for q in questions_response.json()}

                # Combine
                for answer in answers:
                    question = questions.get(answer["question_id"], {})
                    all_data.append({
                        "is_correct": answer.get("is_correct", False),
                        "subject": question.get("subject"),
                        "topic": question.get("topic"),
                    })

        return all_data
