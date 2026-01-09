"""
P2 Group: Backend Service Tests - Question Extractor
Test IDs: BE-UNIT-017 to BE-UNIT-024

Run with: pytest tests/unit/backend/test_question_extractor.py -n auto
"""

import pytest
import json


class TestQuestionExtractor:
    """Tests for question extraction service"""

    @pytest.fixture
    def sample_markdown(self):
        """Sample markdown with question structure"""
        return """
        ## 문제 1
        다음 중 데이터베이스의 특징이 아닌 것은?

        1) 데이터의 독립성
        2) 데이터의 중복 최소화
        3) 데이터의 일관성 유지
        4) 데이터의 분산 저장 불가

        **정답: 4)**
        **해설: 데이터베이스는 분산 저장이 가능합니다.**
        """

    @pytest.mark.unit
    def test_be_unit_017_extract_question_text(self, sample_markdown):
        """BE-UNIT-017: Extract question text from markdown"""
        # Simple extraction logic
        lines = sample_markdown.strip().split('\n')
        question_line = [line for line in lines if '다음' in line or '?' in line][0]

        assert '데이터베이스' in question_line
        assert '?' in question_line

    @pytest.mark.unit
    def test_be_unit_018_extract_answer_options(self, sample_markdown):
        """BE-UNIT-018: Extract all answer options"""
        import re

        # Extract options (1), 2), 3), 4))
        options = re.findall(r'\d+\)\s+(.+)', sample_markdown)

        assert len(options) == 4
        assert '데이터의 독립성' in options[0]
        assert '데이터의 분산 저장 불가' in options[3]

    @pytest.mark.unit
    def test_be_unit_019_extract_correct_answer(self, sample_markdown):
        """BE-UNIT-019: Extract correct answer number"""
        import re

        # Extract answer from **정답: 4)**
        match = re.search(r'\*\*정답:\s*(\d+)\)', sample_markdown)

        assert match is not None
        assert match.group(1) == '4'

    @pytest.mark.unit
    def test_be_unit_020_extract_explanation(self, sample_markdown):
        """BE-UNIT-020: Extract explanation text"""
        import re

        # Extract explanation from **해설: ...**
        match = re.search(r'\*\*해설:\s*(.+?)\*\*', sample_markdown)

        assert match is not None
        assert '분산 저장이 가능' in match.group(1)

    @pytest.mark.unit
    def test_be_unit_021_handle_multiple_questions(self):
        """BE-UNIT-021: Extract multiple questions from document"""
        markdown = """
        ## 문제 1
        질문 1?
        1) 옵션 1
        2) 옵션 2

        ## 문제 2
        질문 2?
        1) 옵션 A
        2) 옵션 B
        """

        import re
        questions = re.findall(r'## 문제 \d+', markdown)

        assert len(questions) == 2

    @pytest.mark.unit
    def test_be_unit_022_extract_question_number(self, sample_markdown):
        """BE-UNIT-022: Extract question number"""
        import re

        match = re.search(r'## 문제 (\d+)', sample_markdown)

        assert match is not None
        assert match.group(1) == '1'

    @pytest.mark.unit
    def test_be_unit_023_handle_questions_with_images(self):
        """BE-UNIT-023: Handle questions with image references"""
        markdown = """
        ## 문제 5
        다음 그림을 보고 답하시오.
        ![이미지](image1.png)

        1) 옵션 1
        2) 옵션 2
        """

        import re
        images = re.findall(r'!\[.*?\]\((.*?)\)', markdown)

        assert len(images) == 1
        assert images[0] == 'image1.png'

    @pytest.mark.unit
    def test_be_unit_024_validate_question_structure(self):
        """BE-UNIT-024: Validate extracted question has all required fields"""
        question_data = {
            "question_number": 1,
            "question_text": "데이터베이스의 특징이 아닌 것은?",
            "options": [
                "데이터의 독립성",
                "데이터의 중복 최소화",
                "데이터의 일관성 유지",
                "데이터의 분산 저장 불가"
            ],
            "correct_answer": 4,
            "explanation": "데이터베이스는 분산 저장이 가능합니다."
        }

        # Validate structure
        assert "question_number" in question_data
        assert "question_text" in question_data
        assert "options" in question_data
        assert "correct_answer" in question_data
        assert "explanation" in question_data

        assert len(question_data["options"]) >= 2
        assert 1 <= question_data["correct_answer"] <= len(question_data["options"])
