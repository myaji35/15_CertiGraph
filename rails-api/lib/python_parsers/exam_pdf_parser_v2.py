#!/usr/bin/env python3
"""
사회복지사 1급 시험 문제지 PDF 파서 v2
문제 / 지문 / 보기 형식으로 명확히 구조화
"""

import re
import json
import pdfplumber
from dataclasses import dataclass, asdict, field
from typing import List, Optional, Dict
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


@dataclass
class PassageItem:
    """지문 항목"""
    marker: str  # ○, ㄱ, ㄴ, ㄷ 등
    text: str


@dataclass
class Question:
    """문제 - 명확히 분리된 구조"""
    number: int                          # 문제 번호
    section: str                         # 과목명
    question: str                        # 질문문 (? 로 끝나는 핵심 질문)
    passage: List[PassageItem]           # 지문 (○ 항목들, ㄱ.ㄴ.ㄷ. 등)
    choices: List[Choice]                # 보기 (①②③④⑤)
    table: Optional[Table] = None        # 표 (있는 경우)


class ExamPDFParser:
    """시험 문제지 PDF 파서 v2"""

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
                tables = page.extract_tables()
                if tables:
                    self.page_tables[page_num] = tables

                text = page.extract_text()
                if text:
                    text = re.sub(
                        r'2025년도 제23회 사회복지사 1급 3교시 A형 \( 18 - \d+ \)',
                        '', text
                    )
                    full_text.append(text.strip())

        self.raw_text = '\n'.join(full_text)
        return self.raw_text

    def identify_sections(self) -> List[str]:
        """과목 식별"""
        pattern = r'사회복지정책과 제도\([^)]+\)'
        matches = re.findall(pattern, self.raw_text)
        self.sections = list(dict.fromkeys(matches))
        return self.sections

    def _clean_text(self, text: str) -> str:
        """텍스트 정리"""
        text = re.sub(r'\s+', ' ', text)
        return text.strip()

    def _extract_question_and_passage(self, text: str) -> tuple[str, List[PassageItem], str]:
        """
        텍스트에서 질문문, 지문, 나머지를 분리

        Returns:
            (질문문, 지문 리스트, 나머지 텍스트)
        """
        question = ""
        passage_items = []
        remaining = text

        # 1. 질문문 추출 (? 로 끝나는 부분)
        # "다음에서 설명하고 있는 정책결정모형은?" 같은 패턴
        question_patterns = [
            r'^(.+?것은\s*\?)',           # ~것은?
            r'^(.+?[가-힣]+은\s*\?)',      # ~은?
            r'^(.+?[가-힣]+를\s*\?)',      # ~를?
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
            first_marker = re.search(r'(○|[ㄱ-ㅎ]\.)', remaining)
            if first_marker:
                question = self._clean_text(remaining[:first_marker.start()])
                remaining = remaining[first_marker.start():]
            else:
                # 첫 번째 보기 이전까지를 질문으로
                first_choice = re.search(r'[①②③④⑤]', remaining)
                if first_choice:
                    question = self._clean_text(remaining[:first_choice.start()])
                    remaining = remaining[first_choice.start():]

        # 2. 지문 추출 (○ 항목들)
        # ○ 로 시작하는 항목들 추출
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

        pattern = r'([①②③④⑤])\s*([^①②③④⑤]+?)(?=[①②③④⑤]|$)'
        matches = re.findall(pattern, text, re.DOTALL)

        for symbol, content in matches:
            number = self.CIRCLE_NUMBERS.get(symbol, 0)
            if number > 0:
                choices.append(Choice(
                    number=number,
                    text=self._clean_text(content)
                ))

        return choices

    def _find_table_for_question(self, q_num: int, q_text: str) -> Optional[Table]:
        """문제에 해당하는 테이블 찾기"""
        table_keywords = {
            4: ['대상자', '사회복지', '주체', '권리수준'],
        }

        for page_num, tables in self.page_tables.items():
            for table_data in tables:
                if not table_data or len(table_data) < 2:
                    continue

                table_str = str(table_data)

                if q_num in table_keywords:
                    keywords = table_keywords[q_num]
                    if all(kw in table_str for kw in keywords[:3]):
                        headers = [c if c else '' for c in table_data[0]]
                        rows = [[c if c else '' for c in row] for row in table_data[1:]]
                        return Table(headers=headers, rows=rows)

                if table_data[0]:
                    header_match = sum(1 for h in table_data[0] if h and h in q_text)
                    if header_match >= 2:
                        headers = [c if c else '' for c in table_data[0]]
                        rows = [[c if c else '' for c in row] for row in table_data[1:]]
                        return Table(headers=headers, rows=rows)

        return None

    def _has_table_indicators(self, text: str) -> bool:
        """테이블 포함 여부 확인"""
        indicators = [
            r'대상자.*사회복지.*주체.*권리수준',
        ]
        return any(re.search(p, text) for p in indicators)

    def parse_questions(self) -> List[Question]:
        """전체 텍스트에서 문제 파싱"""
        if not self.raw_text:
            self.extract_text()

        if not self.sections:
            self.identify_sections()

        section_boundaries = {
            (1, 25): '사회복지정책과 제도(사회복지정책론)',
            (26, 50): '사회복지정책과 제도(사회복지행정론)',
            (51, 75): '사회복지정책과 제도(사회복지법제론)'
        }

        def get_section(q_num):
            for (start, end), section in section_boundaries.items():
                if start <= q_num <= end:
                    return section
            return "Unknown"

        # 문제 번호로 분리
        question_pattern = r'(?:^|\n)(\d{1,2})\.\s+'
        matches = list(re.finditer(question_pattern, self.raw_text))

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
            table = None
            if self._has_table_indicators(q_text):
                table = self._find_table_for_question(q_num, q_text)

            # 질문, 지문, 나머지 분리
            question_text, passage_items, remaining = self._extract_question_and_passage(q_text)

            # 보기 추출
            choices = self._extract_choices(remaining)

            # 테이블이 있고 질문에 테이블 내용이 섞여있으면 정리
            if table and question_text:
                # 테이블 셀 내용이 질문에 포함되어 있으면 제거
                for row in table.rows:
                    for cell in row:
                        if cell and len(cell) > 3:
                            cell_clean = cell.replace('\n', ' ')
                            question_text = question_text.replace(cell_clean, '')

                # 빈칸 표시 정리
                question_text = re.sub(r'\(\s*ㄱ\s*\)', '', question_text)
                question_text = re.sub(r'\(\s*ㄴ\s*\)', '', question_text)
                question_text = re.sub(r'\(\s*ㄷ\s*\)', '', question_text)
                question_text = self._clean_text(question_text)

            question = Question(
                number=q_num,
                section=current_section,
                question=question_text,
                passage=passage_items,
                choices=choices,
                table=table
            )

            self.questions.append(question)

        return self.questions

    def to_json(self, output_path: str = None) -> str:
        """JSON 형식으로 변환"""
        if not self.questions:
            self.parse_questions()

        data = {
            'exam_info': {
                'year': 2025,
                'round': 23,
                'subject': '3교시',
                'type': 'A형',
                'total_questions': len(self.questions),
                'sections': self.sections
            },
            'questions': []
        }

        for q in self.questions:
            q_dict = {
                'number': q.number,
                'section': q.section,
                'question': q.question,
                'passage': [{'marker': p.marker, 'text': p.text} for p in q.passage],
                'choices': [{'number': c.number, 'text': c.text} for c in q.choices],
                'table': q.table.to_dict() if q.table else None
            }
            data['questions'].append(q_dict)

        json_str = json.dumps(data, ensure_ascii=False, indent=2)

        if output_path:
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(json_str)

        return json_str

    def to_markdown(self, output_path: str = None) -> str:
        """마크다운 형식으로 변환"""
        if not self.questions:
            self.parse_questions()

        lines = ["# 2025년도 제23회 사회복지사 1급 3교시 A형\n"]
        current_section = ""

        for q in self.questions:
            if q.section != current_section:
                current_section = q.section
                lines.append(f"\n## {current_section}\n")

            # 문제 번호와 질문
            lines.append(f"### {q.number}. {q.question}\n")

            # 테이블 (있는 경우)
            if q.table:
                lines.append(q.table.to_markdown())
                lines.append("")

            # 지문 (있는 경우)
            if q.passage:
                for p in q.passage:
                    if p.marker == '○':
                        lines.append(f"- ○ {p.text}")
                    else:
                        lines.append(f"- {p.marker}. {p.text}")
                lines.append("")

            # 보기
            if q.choices:
                for c in q.choices:
                    circle = ['', '①', '②', '③', '④', '⑤'][c.number]
                    lines.append(f"{circle} {c.text}")
                lines.append("")

        md_str = '\n'.join(lines)

        if output_path:
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(md_str)

        return md_str

    def to_csv(self, output_path: str = None) -> str:
        """CSV 형식으로 변환"""
        if not self.questions:
            self.parse_questions()

        import csv
        from io import StringIO

        output = StringIO()
        writer = csv.writer(output)

        writer.writerow([
            '문제번호', '과목', '질문',
            '지문_○1', '지문_○2', '지문_○3',
            '지문_ㄱ', '지문_ㄴ', '지문_ㄷ', '지문_ㄹ', '지문_ㅁ',
            '보기①', '보기②', '보기③', '보기④', '보기⑤',
            '테이블'
        ])

        for q in self.questions:
            # 지문을 마커별로 분류
            circle_items = [p.text for p in q.passage if p.marker == '○']
            jamo_items = {p.marker: p.text for p in q.passage if p.marker != '○'}
            choices = {c.number: c.text for c in q.choices}
            table_md = q.table.to_markdown() if q.table else ''

            row = [
                q.number,
                q.section,
                q.question,
                circle_items[0] if len(circle_items) > 0 else '',
                circle_items[1] if len(circle_items) > 1 else '',
                circle_items[2] if len(circle_items) > 2 else '',
                jamo_items.get('ㄱ', ''),
                jamo_items.get('ㄴ', ''),
                jamo_items.get('ㄷ', ''),
                jamo_items.get('ㄹ', ''),
                jamo_items.get('ㅁ', ''),
                choices.get(1, ''),
                choices.get(2, ''),
                choices.get(3, ''),
                choices.get(4, ''),
                choices.get(5, ''),
                table_md
            ]
            writer.writerow(row)

        csv_str = output.getvalue()

        if output_path:
            with open(output_path, 'w', encoding='utf-8-sig', newline='') as f:
                f.write(csv_str)

        return csv_str


def main():
    import sys

    pdf_path = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/exam.pdf"

    print(f"PDF 파일 파싱 중: {pdf_path}")

    parser = ExamPDFParser(pdf_path)

    print("\n1. 텍스트 추출 중...")
    parser.extract_text()

    print("2. 섹션 식별 중...")
    sections = parser.identify_sections()
    print(f"   발견된 섹션: {sections}")

    print("3. 문제 파싱 중...")
    questions = parser.parse_questions()
    print(f"   파싱된 문제 수: {len(questions)}")

    output_dir = Path("/home/claude")

    json_path = output_dir / "exam_v2.json"
    parser.to_json(str(json_path))
    print(f"\n4. JSON 저장: {json_path}")

    md_path = output_dir / "exam_v2.md"
    parser.to_markdown(str(md_path))
    print(f"5. Markdown 저장: {md_path}")

    csv_path = output_dir / "exam_v2.csv"
    parser.to_csv(str(csv_path))
    print(f"6. CSV 저장: {csv_path}")

    # 샘플 출력
    print("\n" + "="*70)
    print("파싱 결과 샘플")
    print("="*70)

    for q in [questions[0], questions[3], questions[5], questions[9]]:  # 1, 4, 6, 10번
        print(f"\n[문제 {q.number}]")
        print(f"  질문: {q.question}")
        if q.table:
            print(f"  표: (있음)")
        if q.passage:
            print(f"  지문:")
            for p in q.passage[:3]:
                text_preview = p.text[:50] + "..." if len(p.text) > 50 else p.text
                print(f"    {p.marker}. {text_preview}")
        print(f"  보기: {len(q.choices)}개")


if __name__ == "__main__":
    main()