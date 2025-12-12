"""향상된 PDF 파서 - 명확한 문제/지문/보기 구조화"""

import re
import json
import uuid
import pdfplumber
from dataclasses import dataclass, asdict, field
from typing import List, Optional, Dict, Any, Tuple
from pathlib import Path


@dataclass
class Table:
    """테이블"""
    headers: List[str]
    rows: List[List[str]]

    def to_dict(self):
        return {'headers': self.headers, 'rows': self.rows}

    def to_markdown(self) -> str:
        lines = []
        lines.append('| ' + ' | '.join(h if h else '' for h in self.headers) + ' |')
        lines.append('| ' + ' | '.join(['---'] * len(self.headers)) + ' |')
        for row in self.rows:
            cleaned = [c.replace('\n', ' ') if c else '' for c in row]
            lines.append('| ' + ' | '.join(cleaned) + ' |')
        return '\n'.join(lines)


@dataclass
class Choice:
    """보기 (①②③④⑤)"""
    number: int
    text: str

    def to_dict(self):
        return {'number': self.number, 'text': self.text}


@dataclass
class PassageItem:
    """지문 항목"""
    marker: str  # ○, ㄱ, ㄴ, ㄷ 등
    text: str

    def to_dict(self):
        return {'marker': self.marker, 'text': self.text}


@dataclass
class Question:
    """문제 - 명확히 분리된 구조"""
    id: str                             # 고유 ID
    number: int                          # 문제 번호
    section: str                         # 과목명
    question: str                        # 질문문 (? 로 끝나는 핵심 질문)
    passage: List[PassageItem]           # 지문 (○ 항목들, ㄱ.ㄴ.ㄷ. 등)
    choices: List[Choice]                # 보기 (①②③④⑤)
    table: Optional[Table] = None        # 표 (있는 경우)
    correct_answer: int = 1              # 정답 (임시)
    explanation: str = ""                # 해설
    question_type: str = "simple"        # 문제 유형

    def to_dict(self):
        """API 응답용 딕셔너리 변환"""
        # 지문을 텍스트로 합치기 (마크다운 형식)
        passage_text = ""
        if self.passage:
            for item in self.passage:
                if item.marker == '○':
                    passage_text += f"○ {item.text}\n"
                else:
                    passage_text += f"{item.marker}. {item.text}\n"
            passage_text = passage_text.strip()

        # 표가 있으면 마크다운으로 변환
        table_markdown = ""
        if self.table:
            table_markdown = self.table.to_markdown()
            self.question_type = "table_based"
        elif self.passage:
            self.question_type = "passage_based"

        # 전체 텍스트 조합 (기존 호환성)
        question_text = self.question
        if table_markdown:
            question_text = f"{self.question}\n\n{table_markdown}"
        elif passage_text:
            question_text = f"{self.question}\n\n{passage_text}"

        return {
            'id': self.id,
            'question_number': self.number,
            'section': self.section,
            'question': self.question,              # 순수 질문
            'passage': table_markdown or passage_text or None,  # 지문/표
            'passage_items': [p.to_dict() for p in self.passage],  # 구조화된 지문
            'question_text': question_text,         # 전체 텍스트 (호환성)
            'question_type': self.question_type,
            'options': [c.to_dict() for c in self.choices],
            'correct_answer': self.correct_answer,
            'explanation': self.explanation or f"문제 {self.number}번의 정답은 {self.correct_answer}번입니다.",
            'table': self.table.to_dict() if self.table else None
        }


class EnhancedPDFParser:
    """향상된 시험 문제지 PDF 파서"""

    CIRCLE_NUMBERS = {'①': 1, '②': 2, '③': 3, '④': 4, '⑤': 5}

    def __init__(self, pdf_path: str):
        self.pdf_path = pdf_path
        self.raw_text = ""
        self.sections = []
        self.questions = []
        self.page_tables = {}

    def extract_text(self) -> str:
        """PDF에서 텍스트 및 테이블 추출"""
        full_text = []

        with pdfplumber.open(self.pdf_path) as pdf:
            for page_num, page in enumerate(pdf.pages):
                # 테이블 추출
                tables = page.extract_tables()
                if tables:
                    self.page_tables[page_num] = tables

                # 텍스트 추출
                text = page.extract_text()
                if text:
                    # 페이지 헤더/푸터 제거
                    text = re.sub(
                        r'2025년도.*?교시.*?\d+.*?\)',
                        '', text
                    )
                    full_text.append(text.strip())

        self.raw_text = '\n'.join(full_text)
        return self.raw_text

    def identify_sections(self) -> List[str]:
        """과목 식별"""
        patterns = [
            r'사회복지정책과 제도\([^)]+\)',
            r'사회복지실천\([^)]+\)',
            r'사회복지행정론',
            r'사회복지법제론'
        ]

        for pattern in patterns:
            matches = re.findall(pattern, self.raw_text)
            self.sections.extend(matches)

        self.sections = list(dict.fromkeys(self.sections))  # 중복 제거
        return self.sections

    def _clean_text(self, text: str) -> str:
        """텍스트 정리"""
        text = re.sub(r'\s+', ' ', text)
        return text.strip()

    def _extract_question_and_passage(self, text: str) -> Tuple[str, List[PassageItem], str]:
        """
        텍스트에서 질문문, 지문, 나머지를 분리

        Returns:
            (질문문, 지문 리스트, 나머지 텍스트)
        """
        question = ""
        passage_items = []
        remaining = text

        # 1. 질문문 추출 (? 로 끝나는 부분)
        question_patterns = [
            r'^(.+?것은\s*\?)',           # ~것은?
            r'^(.+?무엇인가\s*\?)',       # ~무엇인가?
            r'^(.+?[가-힣]+은\s*\?)',     # ~은?
            r'^(.+?[가-힣]+는\s*\?)',     # ~는?
            r'^(.+?[가-힣]+를\s*\?)',     # ~를?
            r'^(.+?\?\s*)',               # 일반 ?
        ]

        for pattern in question_patterns:
            match = re.match(pattern, text, re.DOTALL)
            if match:
                question = self._clean_text(match.group(1))
                remaining = text[match.end():]
                break

        if not question:
            # ? 가 없는 경우, 첫 번째 ○ 또는 ㄱ. 이전까지를 질문으로
            first_marker = re.search(r'(○|[ㄱ-ㅎ]\.)', text)
            if first_marker:
                question = self._clean_text(text[:first_marker.start()])
                remaining = text[first_marker.start():]
            else:
                # 첫 번째 보기 이전까지를 질문으로
                first_choice = re.search(r'[①②③④⑤]', text)
                if first_choice:
                    question = self._clean_text(text[:first_choice.start()])
                    remaining = text[first_choice.start():]
                else:
                    # 전체를 질문으로
                    question = self._clean_text(text)
                    remaining = ""

        # 2. 지문 추출 (○ 항목들)
        circle_pattern = r'○\s*([^○①②③④⑤]+?)(?=○|[①②③④⑤]|$)'
        circle_matches = re.findall(circle_pattern, remaining, re.DOTALL)

        for content in circle_matches:
            cleaned = self._clean_text(content)
            if cleaned:
                passage_items.append(PassageItem(marker='○', text=cleaned))

        # ○ 항목들 제거
        if circle_matches:
            remaining = re.sub(circle_pattern, '', remaining, flags=re.DOTALL)

        # 3. 지문 추출 (ㄱ. ㄴ. ㄷ. 항목들)
        jamo_pattern = r'([ㄱ-ㅎ])\.\s*([^ㄱ-ㅎ①②③④⑤]+?)(?=[ㄱ-ㅎ]\.|[①②③④⑤]|$)'
        jamo_matches = re.findall(jamo_pattern, remaining, re.DOTALL)

        for label, content in jamo_matches:
            cleaned = self._clean_text(content)
            if cleaned:
                passage_items.append(PassageItem(marker=label, text=cleaned))

        # ㄱ.ㄴ.ㄷ. 항목들 제거
        if jamo_matches:
            remaining = re.sub(jamo_pattern, '', remaining, flags=re.DOTALL)

        return question, passage_items, remaining

    def _extract_choices(self, text: str) -> List[Choice]:
        """보기(①②③④⑤) 추출"""
        choices = []

        # 더 정확한 패턴 - 다음 보기 번호 또는 끝까지
        pattern = r'([①②③④⑤])\s*(.*?)(?=(?:[①②③④⑤])|$)'
        matches = re.findall(pattern, text, re.DOTALL)

        for symbol, content in matches:
            number = self.CIRCLE_NUMBERS.get(symbol, 0)
            if number > 0:
                # 공백과 개행 정리
                cleaned = content.strip()

                # 페이지 정보 제거
                cleaned = re.sub(r'2025년도.*?교시.*?\d+.*?\)', '', cleaned)
                cleaned = re.sub(r'\(\s*\d+\s*-\s*\d+\s*\)', '', cleaned)  # (18 - 2) 같은 페이지 번호

                # ㄱ:, ㄴ:, ㄷ: 을 명확히 구분
                # ㄱ: ... ㄴ: ... ㄷ: ... 형식을 유지
                parts = re.split(r'([ㄱ-ㅎ])\s*:', cleaned)

                if len(parts) > 1:
                    # ㄱ: ㄴ: ㄷ: 형식으로 재조합
                    formatted_parts = []
                    for i in range(1, len(parts), 2):
                        if i < len(parts) - 1:
                            label = parts[i]
                            content = parts[i + 1].strip()
                            # 다음 라벨 전까지의 내용만
                            content = re.sub(r'\s+', ' ', content).strip()
                            formatted_parts.append(f"{label}: {content}")

                    if formatted_parts:
                        cleaned = ' '.join(formatted_parts)

                # 연속된 공백 제거
                cleaned = re.sub(r'\s+', ' ', cleaned).strip()

                choices.append(Choice(
                    number=number,
                    text=cleaned
                ))

        return choices

    def _find_table_for_question(self, q_num: int, q_text: str) -> Optional[Table]:
        """문제에 해당하는 테이블 찾기"""
        # 특정 문제 번호에 대한 테이블 키워드
        table_keywords = {
            4: ['대상자', '사회복지', '주체', '권리수준', '빈민법', '사회보험', '복지국가'],
        }

        for page_num, tables in self.page_tables.items():
            for table_data in tables:
                if not table_data or len(table_data) < 2:
                    continue

                table_str = ' '.join([' '.join([cell or '' for cell in row]) for row in table_data])

                # 특정 문제 번호 매칭
                if q_num in table_keywords:
                    keywords = table_keywords[q_num]
                    match_count = sum(1 for kw in keywords if kw in table_str)
                    if match_count >= 3:  # 3개 이상 키워드 매칭
                        headers = [c if c else '' for c in table_data[0]]
                        rows = [[c if c else '' for c in row] for row in table_data[1:]]
                        return Table(headers=headers, rows=rows)

                # 일반적인 테이블 매칭
                if '( ㄱ )' in table_str or '(ㄱ)' in table_str:
                    if '( ㄱ )' in q_text or '(ㄱ)' in q_text or '들어갈' in q_text:
                        headers = [c if c else '' for c in table_data[0]]
                        rows = [[c if c else '' for c in row] for row in table_data[1:]]
                        return Table(headers=headers, rows=rows)

        return None

    def _clean_table_from_text(self, text: str, table: Table) -> str:
        """텍스트에서 테이블 내용 제거"""
        cleaned = text

        # 테이블 셀 내용 제거
        for row in table.rows:
            for cell in row:
                if cell and len(cell) > 3:
                    cell_clean = cell.replace('\n', ' ').strip()
                    cleaned = cleaned.replace(cell_clean, '')

        # 헤더 제거
        for header in table.headers:
            if header and len(header) > 2:
                cleaned = cleaned.replace(header, '')

        # 빈칸 표시 정리
        cleaned = re.sub(r'\(\s*ㄱ\s*\)', '', cleaned)
        cleaned = re.sub(r'\(\s*ㄴ\s*\)', '', cleaned)
        cleaned = re.sub(r'\(\s*ㄷ\s*\)', '', cleaned)
        cleaned = re.sub(r'\(\s*ㄹ\s*\)', '', cleaned)

        return self._clean_text(cleaned)

    def parse_questions(self) -> List[Dict[str, Any]]:
        """전체 텍스트에서 문제 파싱하여 딕셔너리 리스트로 반환"""
        if not self.raw_text:
            self.extract_text()

        if not self.sections:
            self.identify_sections()

        # 과목 경계 설정
        section_boundaries = {
            (1, 25): '사회복지정책과 제도(사회복지정책론)',
            (26, 50): '사회복지정책과 제도(사회복지행정론)',
            (51, 75): '사회복지정책과 제도(사회복지법제론)'
        }

        def get_section(q_num):
            for (start, end), section in section_boundaries.items():
                if start <= q_num <= end:
                    return section
            return "사회복지정책과 제도"

        # 문제 번호로 분리
        question_pattern = r'(?:^|\n)(\d{1,3})\.\s+'
        matches = list(re.finditer(question_pattern, self.raw_text))

        result_questions = []

        for i, match in enumerate(matches):
            q_num = int(match.group(1))
            start_pos = match.end()
            end_pos = matches[i + 1].start() if i + 1 < len(matches) else len(self.raw_text)

            q_text = self.raw_text[start_pos:end_pos]
            current_section = get_section(q_num)

            # 섹션 제목 제거
            for section in self.sections:
                q_text = q_text.replace(section, '')
            q_text = re.sub(r'각 문제에서 요구하는 가장 적합한 답 1개만을 고르시오\.', '', q_text)

            # 테이블 확인
            table = self._find_table_for_question(q_num, q_text)

            # 테이블이 있으면 텍스트에서 제거
            if table:
                q_text = self._clean_table_from_text(q_text, table)

            # 질문, 지문, 나머지 분리
            question_text, passage_items, remaining = self._extract_question_and_passage(q_text)

            # 보기 추출
            choices = self._extract_choices(remaining)

            # 정답 설정 (임시 - 순환)
            correct_answer = ((q_num - 1) % 5) + 1

            # Question 객체 생성
            question = Question(
                id=str(uuid.uuid4()),
                number=q_num,
                section=current_section,
                question=question_text,
                passage=passage_items,
                choices=choices,
                table=table,
                correct_answer=correct_answer,
                explanation=f"문제 {q_num}번의 정답은 {correct_answer}번입니다."
            )

            # 딕셔너리로 변환하여 추가
            result_questions.append(question.to_dict())

        return result_questions


def parse_pdf_enhanced(pdf_path: str) -> List[Dict[str, Any]]:
    """향상된 PDF 파싱 - 명확한 문제/지문/보기 구조"""
    parser = EnhancedPDFParser(pdf_path)
    return parser.parse_questions()