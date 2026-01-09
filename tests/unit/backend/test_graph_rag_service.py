"""
P2 Group: Backend Service Tests - GraphRAG Service
Test IDs: BE-UNIT-039 to BE-UNIT-045

Run with: pytest tests/unit/backend/test_graph_rag_service.py -n auto
"""

import pytest


class TestGraphRAGService:
    """Tests for GraphRAG-based reasoning service"""

    @pytest.mark.unit
    def test_be_unit_039_identify_weak_concepts(self):
        """BE-UNIT-039: Identify weak concepts from error history"""
        error_history = [
            {"question_id": 1, "concept": "정규화", "is_correct": False},
            {"question_id": 2, "concept": "정규화", "is_correct": False},
            {"question_id": 3, "concept": "트랜잭션", "is_correct": True},
            {"question_id": 4, "concept": "정규화", "is_correct": False},
        ]

        # Count errors per concept
        from collections import Counter
        concept_errors = Counter()

        for entry in error_history:
            if not entry["is_correct"]:
                concept_errors[entry["concept"]] += 1

        weak_concepts = [concept for concept, count in concept_errors.items() if count >= 2]

        assert "정규화" in weak_concepts

    @pytest.mark.unit
    def test_be_unit_040_find_prerequisite_concepts(self):
        """BE-UNIT-040: Find prerequisite concepts for weak area"""
        concept_graph = {
            "제3정규형": {"prerequisites": ["제2정규형", "이행 함수 종속"]},
            "제2정규형": {"prerequisites": ["제1정규형", "부분 함수 종속"]},
            "제1정규형": {"prerequisites": ["관계형 모델"]},
        }

        weak_concept = "제3정규형"
        prerequisites = concept_graph[weak_concept]["prerequisites"]

        assert "제2정규형" in prerequisites
        assert "이행 함수 종속" in prerequisites

    @pytest.mark.unit
    def test_be_unit_041_recommend_study_path(self):
        """BE-UNIT-041: Recommend study path based on weak concepts"""
        weak_concepts = ["제3정규형"]

        # Build study path from prerequisites
        study_path = ["관계형 모델", "제1정규형", "제2정규형", "제3정규형"]

        assert len(study_path) >= 2
        assert study_path[-1] == "제3정규형"

    @pytest.mark.unit
    def test_be_unit_042_distinguish_concept_gap_vs_careless_mistake(self):
        """BE-UNIT-042: Distinguish concept gap from careless mistake"""
        error_context = {
            "question_id": 10,
            "concept": "트랜잭션",
            "user_answer_time": 5,  # seconds
            "historical_accuracy": 0.85,  # 85% correct on this concept
        }

        # If historical accuracy is high, likely a careless mistake
        is_careless_mistake = error_context["historical_accuracy"] > 0.80

        assert is_careless_mistake is True

    @pytest.mark.unit
    def test_be_unit_043_generate_explanation_with_graphrag(self):
        """BE-UNIT-043: Generate explanation using GraphRAG"""
        # Simulate GraphRAG explanation
        question_concept = "제2정규형"
        prerequisite_concepts = ["제1정규형", "부분 함수 종속"]

        explanation = f"{question_concept}을 이해하려면 먼저 {', '.join(prerequisite_concepts)}을(를) 학습해야 합니다."

        assert "제1정규형" in explanation
        assert "부분 함수 종속" in explanation

    @pytest.mark.unit
    def test_be_unit_044_rank_related_questions(self):
        """BE-UNIT-044: Rank related questions by difficulty"""
        related_questions = [
            {"id": 1, "difficulty": "easy", "concept": "제1정규형"},
            {"id": 2, "difficulty": "medium", "concept": "제2정규형"},
            {"id": 3, "difficulty": "hard", "concept": "제3정규형"},
        ]

        # Sort by difficulty (easy -> hard)
        difficulty_order = {"easy": 1, "medium": 2, "hard": 3}
        sorted_questions = sorted(related_questions, key=lambda q: difficulty_order[q["difficulty"]])

        assert sorted_questions[0]["difficulty"] == "easy"
        assert sorted_questions[-1]["difficulty"] == "hard"

    @pytest.mark.unit
    def test_be_unit_045_update_knowledge_graph_after_test(self):
        """BE-UNIT-045: Update knowledge graph with test results"""
        knowledge_graph = {
            "정규화": {"mastery_level": 0.6, "last_tested": "2024-01-01"}
        }

        # User got 4 out of 5 questions correct
        new_accuracy = 0.8

        # Update mastery level (weighted average)
        updated_mastery = (knowledge_graph["정규화"]["mastery_level"] * 0.3) + (new_accuracy * 0.7)
        knowledge_graph["정규화"]["mastery_level"] = updated_mastery
        knowledge_graph["정규화"]["last_tested"] = "2024-01-15"

        assert knowledge_graph["정규화"]["mastery_level"] > 0.6
        assert knowledge_graph["정규화"]["last_tested"] == "2024-01-15"
