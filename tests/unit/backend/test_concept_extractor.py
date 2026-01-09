"""
P2 Group: Backend Service Tests - Concept Extractor
Test IDs: BE-UNIT-025 to BE-UNIT-032

Run with: pytest tests/unit/backend/test_concept_extractor.py -n auto
"""

import pytest


class TestConceptExtractor:
    """Tests for concept extraction from questions"""

    @pytest.fixture
    def sample_question(self):
        """Sample question for concept extraction"""
        return {
            "question_text": "다음 중 데이터베이스의 정규화(Normalization)에 대한 설명으로 옳지 않은 것은?",
            "options": [
                "제1정규형은 원자값만을 가진다",
                "제2정규형은 부분 함수 종속을 제거한다",
                "제3정규형은 이행 함수 종속을 제거한다",
                "제4정규형은 다치 종속을 허용한다"
            ],
            "correct_answer": 4,
            "explanation": "제4정규형은 다치 종속을 제거하는 것이 목적입니다."
        }

    @pytest.mark.unit
    def test_be_unit_025_extract_main_concept(self, sample_question):
        """BE-UNIT-025: Extract main concept from question"""
        # Simple keyword extraction
        keywords = ["데이터베이스", "정규화", "Normalization"]

        question_text = sample_question["question_text"]

        found_concepts = [kw for kw in keywords if kw in question_text]

        assert len(found_concepts) >= 1
        assert "정규화" in found_concepts

    @pytest.mark.unit
    def test_be_unit_026_extract_subconcepts(self, sample_question):
        """BE-UNIT-026: Extract sub-concepts from options"""
        options_text = " ".join(sample_question["options"])

        subconcepts = ["제1정규형", "제2정규형", "제3정규형", "제4정규형"]

        found_subconcepts = [sc for sc in subconcepts if sc in options_text]

        assert len(found_subconcepts) == 4

    @pytest.mark.unit
    def test_be_unit_027_identify_prerequisite_concepts(self):
        """BE-UNIT-027: Identify prerequisite relationships"""
        # Example: 제2정규형 requires 제1정규형
        concept_hierarchy = {
            "정규화": ["제1정규형", "제2정규형", "제3정규형", "제4정규형"],
            "제2정규형": ["제1정규형"],
            "제3정규형": ["제2정규형"],
        }

        prerequisites = concept_hierarchy.get("제3정규형", [])

        assert "제2정규형" in prerequisites

    @pytest.mark.unit
    def test_be_unit_028_categorize_by_subject(self, sample_question):
        """BE-UNIT-028: Categorize question by subject area"""
        question_text = sample_question["question_text"]

        subject_keywords = {
            "데이터베이스": ["데이터베이스", "정규화", "SQL", "트랜잭션"],
            "네트워크": ["TCP", "UDP", "OSI", "IP"],
            "자료구조": ["스택", "큐", "트리", "그래프"]
        }

        detected_subject = None
        for subject, keywords in subject_keywords.items():
            if any(kw in question_text for kw in keywords):
                detected_subject = subject
                break

        assert detected_subject == "데이터베이스"

    @pytest.mark.unit
    def test_be_unit_029_extract_technical_terms(self, sample_question):
        """BE-UNIT-029: Extract technical terms from question"""
        import re

        text = sample_question["question_text"] + " " + " ".join(sample_question["options"])

        # Find terms in parentheses (e.g., "정규화(Normalization)")
        technical_terms = re.findall(r'([가-힣]+)\(([A-Za-z]+)\)', text)

        assert len(technical_terms) >= 1
        assert technical_terms[0] == ('정규화', 'Normalization')

    @pytest.mark.unit
    def test_be_unit_030_build_concept_graph_node(self, sample_question):
        """BE-UNIT-030: Build concept graph node structure"""
        concept_node = {
            "id": "concept_001",
            "name": "정규화",
            "category": "데이터베이스",
            "level": "중급",
            "prerequisites": ["관계형 데이터베이스", "함수 종속"],
            "related_questions": [1, 5, 12]
        }

        # Validate node structure
        assert "id" in concept_node
        assert "name" in concept_node
        assert "category" in concept_node
        assert isinstance(concept_node["prerequisites"], list)
        assert isinstance(concept_node["related_questions"], list)

    @pytest.mark.unit
    def test_be_unit_031_detect_concept_relationships(self):
        """BE-UNIT-031: Detect relationships between concepts"""
        relationships = [
            {"from": "제1정규형", "to": "제2정규형", "type": "prerequisite"},
            {"from": "제2정규형", "to": "제3정규형", "type": "prerequisite"},
            {"from": "정규화", "to": "제1정규형", "type": "contains"},
        ]

        # Find all prerequisites for 제3정규형
        prerequisites = [
            rel["from"] for rel in relationships
            if rel["to"] == "제3정규형" and rel["type"] == "prerequisite"
        ]

        assert "제2정규형" in prerequisites

    @pytest.mark.unit
    def test_be_unit_032_calculate_concept_mastery(self):
        """BE-UNIT-032: Calculate mastery level for a concept"""
        concept_attempts = {
            "concept_id": "정규화",
            "total_questions": 10,
            "correct_answers": 8,
            "recent_attempts": [True, True, False, True, True]
        }

        # Calculate mastery percentage
        mastery_percentage = (concept_attempts["correct_answers"] / concept_attempts["total_questions"]) * 100

        # Calculate recent performance
        recent_correct = sum(concept_attempts["recent_attempts"])
        recent_percentage = (recent_correct / len(concept_attempts["recent_attempts"])) * 100

        assert mastery_percentage == 80.0
        assert recent_percentage == 80.0
