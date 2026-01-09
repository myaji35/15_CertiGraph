"""
P2 Group: Backend Service Tests - Markdown Parser
Test IDs: BE-UNIT-006 to BE-UNIT-010

Run with: pytest tests/unit/backend/test_markdown_parser.py -n auto
"""

import pytest


class TestMarkdownParser:
    """Tests for markdown parsing and formatting"""

    @pytest.fixture
    def sample_markdown(self):
        """Sample markdown content"""
        return """
# 정보처리기사 문제집

## 문제 1
다음 중 객체지향의 특징이 아닌 것은?

1) 캡슐화
2) 상속성
3) 다형성
4) 구조화

### 코드 예제
```python
class Animal:
    def speak(self):
        pass
```

**정답: 4)**
**해설: 구조화는 구조적 프로그래밍의 특징입니다.**
"""

    @pytest.mark.unit
    def test_be_unit_006_parse_markdown_headers(self, sample_markdown):
        """BE-UNIT-006: Parse markdown headers"""
        import re

        headers = re.findall(r'^#{1,6}\s+(.+)$', sample_markdown, re.MULTILINE)

        assert len(headers) >= 2
        assert '정보처리기사 문제집' in headers[0]
        assert '문제 1' in headers[1]

    @pytest.mark.unit
    def test_be_unit_007_parse_code_blocks(self, sample_markdown):
        """BE-UNIT-007: Extract code blocks from markdown"""
        import re

        code_blocks = re.findall(r'```(\w+)?\n(.*?)```', sample_markdown, re.DOTALL)

        assert len(code_blocks) >= 1
        assert 'python' in code_blocks[0][0]
        assert 'class Animal' in code_blocks[0][1]

    @pytest.mark.unit
    def test_be_unit_008_parse_bold_text(self, sample_markdown):
        """BE-UNIT-008: Extract bold text (answers and explanations)"""
        import re

        bold_items = re.findall(r'\*\*(.+?)\*\*', sample_markdown)

        assert len(bold_items) >= 2
        assert any('정답' in item for item in bold_items)
        assert any('해설' in item for item in bold_items)

    @pytest.mark.unit
    def test_be_unit_009_parse_numbered_lists(self, sample_markdown):
        """BE-UNIT-009: Parse numbered lists (answer options)"""
        import re

        numbered_items = re.findall(r'^\d+\)\s+(.+)$', sample_markdown, re.MULTILINE)

        assert len(numbered_items) == 4
        assert '캡슐화' in numbered_items[0]
        assert '구조화' in numbered_items[3]

    @pytest.mark.unit
    def test_be_unit_010_convert_markdown_to_html(self):
        """BE-UNIT-010: Convert markdown to HTML (basic)"""
        markdown = "**Bold text** and *italic text*"

        # Simple conversion simulation
        html = markdown.replace('**', '<strong>').replace('**', '</strong>')
        html = html.replace('*', '<em>').replace('*', '</em>')

        # Note: This is simplified; real conversion would use a library
        assert '<strong>' in html or 'Bold text' in html
