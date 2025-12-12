"""고급 PDF 파서 - 오해독 문제 해결"""

import re
import pdfplumber
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass
from collections import defaultdict


@dataclass
class QuestionBlock:
    """문제 블록 데이터"""
    number: int
    text: str
    options: List[Dict[str, Any]]
    tables: List[Any]
    page_num: int
    y_position: float


class AdvancedPDFParser:
    """고급 PDF 파서 - 레이아웃 분석 및 오해독 수정"""

    def __init__(self, pdf_path: str):
        self.pdf_path = pdf_path
        self.common_corrections = {
            # 자주 발생하는 OCR 오류 패턴
            r'\s+': ' ',  # 연속 공백 정리
            r'（\s*ㄱ\s*）': '(ㄱ)',  # 괄호 정규화
            r'（\s*ㄴ\s*）': '(ㄴ)',
            r'（\s*ㄷ\s*）': '(ㄷ)',
            r'（\s*ㄹ\s*）': '(ㄹ)',
            r'［': '[',  # 대괄호 정규화
            r'］': ']',
            r'｜': '|',  # 파이프 문자
            r'一': '-',  # 대시 정규화
        }

    def extract_questions(self) -> List[Dict[str, Any]]:
        """PDF에서 문제 추출 (레이아웃 분석 포함)"""
        all_blocks = []

        with pdfplumber.open(self.pdf_path) as pdf:
            for page_num, page in enumerate(pdf.pages):
                # 페이지별 레이아웃 분석
                blocks = self._extract_page_blocks(page, page_num)
                all_blocks.extend(blocks)

        # 블록들을 문제 단위로 조합
        questions = self._assemble_questions(all_blocks)

        # 오해독 수정 및 최종 정리
        questions = self._correct_ocr_errors(questions)

        return questions

    def _extract_page_blocks(self, page, page_num: int) -> List[QuestionBlock]:
        """페이지에서 블록 단위로 추출"""
        blocks = []

        # 텍스트 추출 (위치 정보 포함)
        words = page.extract_words(
            x_tolerance=3,
            y_tolerance=3,
            keep_blank_chars=False,
            use_text_flow=True
        )

        # 표 추출
        tables = page.extract_tables()
        table_regions = []
        for table in tables:
            if table and len(table) > 1:
                # 표의 위치 계산 (근사치)
                table_regions.append({
                    'table': table,
                    'top': min([w['top'] for w in words if any(cell in w['text'] for row in table for cell in row if cell)], default=0),
                    'bottom': max([w['bottom'] for w in words if any(cell in w['text'] for row in table for cell in row if cell)], default=page.height)
                })

        # 2단 레이아웃 감지
        page_width = page.width
        is_two_column = self._detect_two_column_layout(words, page_width)

        if is_two_column:
            # 2단 레이아웃 처리
            left_words = [w for w in words if w['x0'] < page_width / 2]
            right_words = [w for w in words if w['x0'] >= page_width / 2]

            # 왼쪽 열 먼저 처리
            blocks.extend(self._process_column(left_words, tables, page_num, 'left'))
            # 오른쪽 열 처리
            blocks.extend(self._process_column(right_words, tables, page_num, 'right'))
        else:
            # 단일 열 처리
            blocks.extend(self._process_column(words, tables, page_num, 'single'))

        return blocks

    def _detect_two_column_layout(self, words: List[Dict], page_width: float) -> bool:
        """2단 레이아웃 감지"""
        if not words:
            return False

        # X 좌표 분포 분석
        left_count = sum(1 for w in words if w['x0'] < page_width * 0.45)
        right_count = sum(1 for w in words if w['x0'] > page_width * 0.55)
        total_count = len(words)

        # 양쪽에 충분한 텍스트가 있으면 2단으로 판단
        if left_count > total_count * 0.3 and right_count > total_count * 0.3:
            return True

        return False

    def _process_column(self, words: List[Dict], tables: List, page_num: int, column: str) -> List[QuestionBlock]:
        """열 단위 처리"""
        blocks = []

        # Y 좌표로 정렬
        words = sorted(words, key=lambda w: (w['top'], w['x0']))

        # 문제 번호 패턴으로 블록 시작점 찾기
        question_pattern = re.compile(r'^(\d{1,3})\.')

        current_block = None
        current_text = []

        for word in words:
            text = word['text']

            # 문제 번호 감지
            match = question_pattern.match(text)
            if match:
                # 이전 블록 저장
                if current_block and current_text:
                    current_block.text = ' '.join(current_text)
                    # 해당 블록 영역의 표 찾기
                    for table in tables:
                        if table:
                            current_block.tables.append(table)
                    blocks.append(current_block)

                # 새 블록 시작
                question_number = int(match.group(1))
                current_block = QuestionBlock(
                    number=question_number,
                    text='',
                    options=[],
                    tables=[],
                    page_num=page_num,
                    y_position=word['top']
                )
                current_text = [text[len(match.group(0)):].strip()]
            else:
                # 현재 블록에 텍스트 추가
                if current_text is not None:
                    current_text.append(text)

        # 마지막 블록 저장
        if current_block and current_text:
            current_block.text = ' '.join(current_text)
            # 해당 블록 영역의 표 찾기
            for table in tables:
                if table:
                    current_block.tables.append(table)
            blocks.append(current_block)

        return blocks

    def _assemble_questions(self, blocks: List[QuestionBlock]) -> List[Dict[str, Any]]:
        """블록들을 문제 단위로 조합"""
        questions = []

        # 문제 번호로 정렬
        blocks = sorted(blocks, key=lambda b: b.number)

        for block in blocks:
            # 문제 텍스트와 선택지 분리
            question_text, options = self._split_question_and_options(block.text)

            # 표가 있는 경우 처리
            if block.tables:
                question_text = self._integrate_tables(question_text, block.tables)

            # 지문 연결 (보류 문제, 사례 문제 등)
            question_text = self._link_passages(question_text, block.number)

            questions.append({
                "question_number": block.number,
                "question_text": question_text,
                "options": options,
                "correct_answer": ((block.number - 1) % 5) + 1,  # 임시
                "explanation": f"문제 {block.number}번의 정답입니다.",
                "passage": None
            })

        return questions

    def _split_question_and_options(self, text: str) -> Tuple[str, List[Dict]]:
        """문제 텍스트와 선택지 분리"""
        # 선택지 패턴
        option_patterns = [
            r'([①②③④⑤])',  # 원문자
            r'(\([1-5]\))',   # (1), (2) 형식
            r'([1-5]\.)',     # 1., 2. 형식
        ]

        options = []
        question_text = text

        for pattern in option_patterns:
            parts = re.split(pattern, text)
            if len(parts) > 3:  # 선택지가 있는 경우
                question_text = parts[0].strip()

                # 선택지 매핑
                option_map = {
                    '①': 1, '②': 2, '③': 3, '④': 4, '⑤': 5,
                    '(1)': 1, '(2)': 2, '(3)': 3, '(4)': 4, '(5)': 5,
                    '1.': 1, '2.': 2, '3.': 3, '4.': 4, '5.': 5
                }

                for i in range(1, len(parts), 2):
                    if i + 1 < len(parts):
                        symbol = parts[i]
                        if symbol in option_map:
                            option_number = option_map[symbol]
                            option_text = parts[i + 1].strip()

                            # 다음 선택지 전까지의 텍스트 추출
                            next_pattern_idx = text.find(parts[i + 2]) if i + 2 < len(parts) else len(text)
                            if next_pattern_idx > 0:
                                option_text = text[text.find(symbol) + len(symbol):next_pattern_idx].strip()

                            options.append({
                                "number": option_number,
                                "text": self._clean_option_text(option_text)
                            })

                break

        return question_text, options

    def _clean_option_text(self, text: str) -> str:
        """선택지 텍스트 정리"""
        # 페이지 번호, 연도 정보 제거
        text = re.sub(r'2025년도.*?교시', '', text)
        text = re.sub(r'^\d+$', '', text)  # 단독 숫자 제거

        # ㄱ:, ㄴ:, ㄷ: 형식 정리
        text = re.sub(r'([ㄱ-ㅎ]):', r'\n\1:', text)

        # 과도한 공백 정리
        text = re.sub(r'\s+', ' ', text)

        return text.strip()

    def _integrate_tables(self, question_text: str, tables: List) -> str:
        """표를 마크다운으로 변환하여 통합"""
        for table in tables:
            if not table or len(table) < 2:
                continue

            # 표를 마크다운으로 변환
            markdown_table = self._table_to_markdown(table)

            # 표 관련 키워드가 있는 경우만 통합
            table_keywords = ['표', '다음', '아래', '위', '(ㄱ)', '(ㄴ)', '(ㄷ)']
            if any(keyword in question_text for keyword in table_keywords):
                # 중복 텍스트 제거
                for row in table:
                    for cell in row:
                        if cell and len(cell) > 3:  # 짧은 텍스트는 제외
                            question_text = question_text.replace(cell, '')

                # 마크다운 표 추가
                question_text = question_text.strip() + '\n\n' + markdown_table

        return question_text

    def _table_to_markdown(self, table: List[List[str]]) -> str:
        """표를 마크다운 형식으로 변환"""
        if not table or len(table) < 2:
            return ""

        # None 값을 빈 문자열로 변환
        table = [[cell if cell else "" for cell in row] for row in table]

        # 마크다운 테이블 생성
        lines = []
        for i, row in enumerate(table):
            lines.append("| " + " | ".join(row) + " |")
            if i == 0:  # 헤더 다음에 구분선 추가
                lines.append("| " + " | ".join(["---"] * len(row)) + " |")

        return "\n".join(lines)

    def _link_passages(self, question_text: str, question_number: int) -> str:
        """지문 연결 (보류 문제, 사례 문제 등)"""
        # [보류문제], <사례>, ※ 등의 패턴 감지
        passage_patterns = [
            r'\[보류문제\]',
            r'<사례>',
            r'※\s*다음.*?물음에.*?답하시오',
            r'다음.*?읽고.*?물음에.*?답하시오'
        ]

        for pattern in passage_patterns:
            if re.search(pattern, question_text, re.IGNORECASE):
                # 지문이 포함된 문제로 표시
                # 실제 구현에서는 지문을 별도로 추출하여 연결
                pass

        return question_text

    def _correct_ocr_errors(self, questions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """OCR 오류 수정"""
        for question in questions:
            # 문제 텍스트 수정
            question['question_text'] = self._apply_corrections(question['question_text'])

            # 선택지 수정
            for option in question['options']:
                option['text'] = self._apply_corrections(option['text'])

        return questions

    def _apply_corrections(self, text: str) -> str:
        """텍스트에 수정 규칙 적용"""
        if not text:
            return text

        # 기본 수정 규칙 적용
        for pattern, replacement in self.common_corrections.items():
            text = re.sub(pattern, replacement, text)

        # 문맥 기반 수정
        text = self._context_aware_corrections(text)

        return text.strip()

    def _context_aware_corrections(self, text: str) -> str:
        """문맥 기반 오류 수정"""
        # 사회복지 도메인 특화 수정
        corrections = {
            '사회북지': '사회복지',
            '사회볶지': '사회복지',
            '정첵': '정책',
            '졍책': '정책',
            '볍지': '복지',
            '북지': '복지',
            '국가': '국가',  # 유지
            '시민': '시민',  # 유지
        }

        for wrong, correct in corrections.items():
            text = text.replace(wrong, correct)

        # 띄어쓰기 수정
        text = re.sub(r'([가-힣])([A-Z])', r'\1 \2', text)  # 한글+영문
        text = re.sub(r'([0-9])([가-힣])', r'\1 \2', text)  # 숫자+한글

        return text


def parse_pdf_advanced(pdf_path: str) -> List[Dict[str, Any]]:
    """고급 PDF 파싱"""
    parser = AdvancedPDFParser(pdf_path)
    return parser.extract_questions()