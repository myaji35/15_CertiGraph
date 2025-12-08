"""Mock question repository for development mode."""

import uuid
import json
import os
from typing import Optional, Any


# Persistent storage file
MOCK_QUESTIONS_FILE = "/tmp/certigraph_mock_questions.json"


class MockQuestionRepository:
    """File-based mock repository for questions in development."""

    def __init__(self):
        self._storage: dict[str, list[dict]] = {}  # study_set_id -> questions
        self._load_data()

    def _load_data(self):
        """Load data from file if exists."""
        if os.path.exists(MOCK_QUESTIONS_FILE):
            try:
                with open(MOCK_QUESTIONS_FILE, 'r', encoding='utf-8') as f:
                    self._storage = json.load(f)
            except Exception as e:
                print(f"Failed to load mock questions: {e}")

    def _save_data(self):
        """Save data to file."""
        try:
            with open(MOCK_QUESTIONS_FILE, 'w', encoding='utf-8') as f:
                json.dump(self._storage, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"Failed to save mock questions: {e}")

    def _generate_mock_questions(self, study_set_id: str, count: int = 10) -> list[dict]:
        """Generate mock questions for a study set."""
        questions = []
        for i in range(1, count + 1):
            question = {
                "id": str(uuid.uuid4()),
                "study_set_id": study_set_id,
                "question_number": i,
                "question_text": f"사회복지사 1급 모의 문제 {i}번입니다. 다음 중 옳은 설명은?",
                "options": [
                    {"number": 1, "text": f"첫 번째 선택지 {i}"},
                    {"number": 2, "text": f"두 번째 선택지 {i}"},
                    {"number": 3, "text": f"세 번째 선택지 {i}"},
                    {"number": 4, "text": f"네 번째 선택지 {i}"},
                    {"number": 5, "text": f"다섯 번째 선택지 {i}"},
                ],
                "correct_answer": (i % 5) + 1,  # Rotate between 1-5
                "explanation": f"문제 {i}번의 정답은 {(i % 5) + 1}번입니다. 이는 사회복지의 기본 원칙에 부합하는 설명입니다.",
                "passage": None if i % 3 != 0 else f"[지문 {i}] 다음은 사회복지 정책에 관한 지문입니다...",
            }
            questions.append(question)
        return questions

    async def get_by_study_set(
        self,
        study_set_id: str,
        limit: Optional[int] = None,
        randomize: bool = False,
    ) -> list[dict[str, Any]]:
        """Get questions for a study set."""
        # Return existing questions or empty list (don't auto-generate mock questions)
        questions = self._storage.get(study_set_id, [])

        if randomize:
            import random
            questions = random.sample(questions, min(len(questions), limit or len(questions)))
        elif limit:
            questions = questions[:limit]

        return questions

    async def get_by_ids(self, question_ids: list[str]) -> list[dict[str, Any]]:
        """Get questions by IDs."""
        result = []
        for questions in self._storage.values():
            for q in questions:
                if q["id"] in question_ids:
                    result.append(q)
        return result

    async def get_by_id(self, question_id: str) -> Optional[dict[str, Any]]:
        """Get a single question by ID."""
        for questions in self._storage.values():
            for q in questions:
                if q["id"] == question_id:
                    return q
        return None

    async def get_correct_answers(
        self, question_ids: list[str]
    ) -> dict[str, int]:
        """Get correct answers for questions."""
        result = {}
        for questions in self._storage.values():
            for q in questions:
                if q["id"] in question_ids:
                    result[q["id"]] = q["correct_answer"]
        return result

    async def bulk_create(self, study_set_id: str, questions: list[dict]) -> list[dict]:
        """Bulk create questions for a study set."""
        # Replace any existing questions for this study set
        self._storage[study_set_id] = questions
        self._save_data()
        return questions
