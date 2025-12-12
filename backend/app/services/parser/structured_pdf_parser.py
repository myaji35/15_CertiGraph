"""구조화된 PDF 파서 - 문제/지문/보기 분리"""

import re
import pdfplumber
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass


@dataclass
class StructuredQuestion:
    """구조화된 문제 데이터"""
    question_number: int
    question: str  # 실제 질문
    passage: Optional[str]  # 지문 (표, 사례, 자료 등)
    options: List[Dict[str, Any]]  # 보기/선택지
    correct_answer: int
    explanation: str
    question_type: str  # 'simple', 'passage_based', 'table_based', 'case_based'


class StructuredPDFParser:
    """문제/지문/보기를 구조적으로 분리하는 파서"""

    def __init__(self, pdf_path: str):
        self.pdf_path = pdf_path

        # 지문 관련 패턴
        self.passage_patterns = {
            'case': [
                r'<사례>',
                r'\[사례\]',
                r'※\s*사례',
                r'다음\s+사례를\s+읽고',
            ],
            'table': [
                r'다음\s+표를\s+보고',
                r'아래\s+표를\s+참고하여',
                r'위의\s+표에서',
            ],
            'passage': [
                r'\[보류문제\]',
                r'※\s*다음.*?물음에.*?답하시오',
                r'다음.*?읽고.*?물음에.*?답하시오',
                r'다음\s+글을\s+읽고',
                r'아래\s+내용을\s+읽고',
            ],
            'data': [
                r'다음\s+자료를\s+보고',
                r'아래\s+자료를\s+분석하여',
            ]
        }

    def extract_questions(self) -> List[Dict[str, Any]]:
        """PDF에서 구조화된 문제 추출"""
        all_text = ""
        all_tables = []

        with pdfplumber.open(self.pdf_path) as pdf:
            for page in pdf.pages:
                # 텍스트 추출
                text = page.extract_text()
                if text:
                    all_text += text + "\n"

                # 표 추출
                tables = page.extract_tables()
                if tables:
                    all_tables.extend(tables)

        # 구조화된 문제 파싱
        questions = self._parse_structured_questions(all_text, all_tables)

        return questions

    def _parse_structured_questions(self, text: str, all_tables: list) -> List[Dict[str, Any]]:
        """텍스트를 구조화된 문제로 파싱"""
        questions = []

        # 문제 번호로 분리
        question_pattern = r'\n(\d{1,3})\.\s+'
        splits = re.split(question_pattern, text)

        # 표 사용 추적
        used_tables = set()

        # 지문 공유 추적 (연속된 문제가 같은 지문 사용)
        shared_passage = None
        shared_passage_range = []

        for i in range(1, len(splits), 2):
            if i + 1 < len(splits):
                question_number = int(splits[i])
                question_content = splits[i + 1]

                # 구조화된 문제 파싱
                structured = self._parse_single_structured_question(
                    question_number,
                    question_content,
                    all_tables,
                    used_tables,
                    shared_passage
                )

                if structured:
                    # 지문 공유 확인
                    if structured.passage and structured.question_type in ['passage_based', 'case_based']:
                        # "다음 문제" 패턴 확인
                        if self._is_shared_passage(question_content):
                            if not shared_passage:
                                shared_passage = structured.passage
                                shared_passage_range = [question_number]
                            else:
                                shared_passage_range.append(question_number)
                                structured.passage = shared_passage
                        else:
                            shared_passage = None
                            shared_passage_range = []

                    questions.append(self._structured_to_dict(structured))

        return questions

    def _parse_single_structured_question(
        self,
        question_number: int,
        content: str,
        all_tables: list,
        used_tables: set,
        shared_passage: Optional[str] = None
    ) -> Optional[StructuredQuestion]:
        """개별 문제를 구조화하여 파싱"""

        # 선택지 분리
        option_pattern = r'[①②③④⑤]'
        parts = re.split(f'({option_pattern})', content)

        if len(parts) < 3:
            return None

        # 문제 본문
        full_text = parts[0].strip()

        # 문제 유형 판별 및 지문 추출
        question_type, passage, question = self._extract_passage_and_question(
            full_text, all_tables, used_tables, shared_passage
        )

        # 선택지 추출
        options = self._extract_options(parts)

        if len(options) < 2:
            return None

        # 정답 (임시)
        correct_answer = ((question_number - 1) % 5) + 1

        return StructuredQuestion(
            question_number=question_number,
            question=question,
            passage=passage,
            options=options,
            correct_answer=correct_answer,
            explanation=f"문제 {question_number}번의 정답입니다.",
            question_type=question_type
        )

    def _extract_passage_and_question(
        self,
        full_text: str,
        all_tables: list,
        used_tables: set,
        shared_passage: Optional[str] = None
    ) -> Tuple[str, Optional[str], str]:
        """지문과 질문을 분리 추출"""

        question_type = 'simple'
        passage = None
        question = full_text

        # 1. 표가 있는지 확인
        table_keywords = ['(ㄱ)', '(ㄴ)', '(ㄷ)', '( ㄱ )', '( ㄴ )', '( ㄷ )', '표', '순서대로']
        has_table_hint = sum(1 for kw in table_keywords if kw in full_text) >= 2

        if has_table_hint and all_tables:
            # 적합한 표 찾기
            for idx, table in enumerate(all_tables):
                if idx in used_tables:
                    continue

                if table and len(table) > 1:
                    table_str = ' '.join([' '.join([cell or '' for cell in row]) for row in table])

                    # 표가 현재 문제와 관련 있는지 확인
                    if any(kw in table_str for kw in ['ㄱ', 'ㄴ', 'ㄷ', '대상자', '사회복지']):
                        used_tables.add(idx)

                        # 표를 지문으로 설정
                        passage = self._table_to_markdown(table)
                        question_type = 'table_based'

                        # 질문에서 표 관련 텍스트 제거
                        question = self._remove_table_text_from_question(full_text, table)
                        break

        # 2. 사례나 보류 문제 패턴 확인
        if not passage:
            for pattern_type, patterns in self.passage_patterns.items():
                for pattern in patterns:
                    match = re.search(pattern, full_text, re.IGNORECASE)
                    if match:
                        # 패턴 이후의 내용을 지문으로 추출
                        split_pos = match.end()

                        # 질문 부분 찾기 (보통 "~은?", "~는?" 패턴)
                        question_match = re.search(r'[가-힣]+(?:은|는|이|가|을|를|에|의)(?:\s+무엇|\s+어느|\s+옳[은지]|\s+적절한).*?\?',
                                                  full_text[split_pos:])

                        if question_match:
                            passage_end = split_pos + question_match.start()
                            passage = full_text[split_pos:passage_end].strip()
                            question = full_text[passage_end:].strip()
                            question_type = f'{pattern_type}_based'
                        else:
                            # 질문이 명확하지 않으면 마지막 문장을 질문으로
                            sentences = full_text[split_pos:].split('.')
                            if len(sentences) > 1:
                                passage = '.'.join(sentences[:-1]).strip()
                                question = sentences[-1].strip()
                                if not question.endswith('?'):
                                    question += '?'
                                question_type = f'{pattern_type}_based'
                        break

                if passage:
                    break

        # 3. 공유 지문이 있으면 사용
        if shared_passage and not passage:
            passage = shared_passage
            question_type = 'passage_based'
            # "위의", "위 문제", "앞의" 등의 참조 제거
            question = re.sub(r'위의?\s+|앞의?\s+|위\s+문제의?\s+', '', question)

        return question_type, passage, question

    def _remove_table_text_from_question(self, question: str, table: List[List[str]]) -> str:
        """질문에서 표 내용 제거"""
        lines = question.split('\n')
        cleaned_lines = []
        skip_mode = False

        for line in lines:
            # 표 내용이 포함된 줄 스킵
            is_table_line = False
            for row in table:
                for cell in row:
                    if cell and len(cell) > 2 and cell in line:
                        is_table_line = True
                        skip_mode = True
                        break
                if is_table_line:
                    break

            if not is_table_line:
                if skip_mode and line.strip() == '':
                    skip_mode = False
                    continue
                if not skip_mode:
                    cleaned_lines.append(line)

        return '\n'.join(cleaned_lines).strip()

    def _extract_options(self, parts: List[str]) -> List[Dict[str, Any]]:
        """선택지 추출"""
        options = []
        option_symbols = {'①': 1, '②': 2, '③': 3, '④': 4, '⑤': 5}

        for i in range(1, len(parts), 2):
            if i + 1 < len(parts):
                symbol = parts[i]
                if symbol in option_symbols:
                    option_number = option_symbols[symbol]
                    option_text = parts[i + 1].strip()

                    # 정리
                    option_text = re.sub(r'2025년도.*?교시', '', option_text)
                    option_text = re.sub(r'\s+', ' ', option_text)

                    # ㄱ:, ㄴ: 형식 정리
                    option_text = re.sub(r'([ㄱ-ㅎ]):', r'\n\1:', option_text).strip()

                    options.append({
                        "number": option_number,
                        "text": option_text
                    })

        return options

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

    def _is_shared_passage(self, content: str) -> bool:
        """다음 문제와 지문을 공유하는지 확인"""
        shared_patterns = [
            r'위\s*문제',
            r'앞\s*문제',
            r'위의?\s+',
            r'동일한?\s*지문',
            r'같은\s*사례',
        ]

        for pattern in shared_patterns:
            if re.search(pattern, content[:100], re.IGNORECASE):  # 문제 시작 부분만 확인
                return True

        return False

    def _structured_to_dict(self, structured: StructuredQuestion) -> Dict[str, Any]:
        """구조화된 문제를 딕셔너리로 변환"""
        return {
            "question_number": structured.question_number,
            "question": structured.question,  # 순수 질문
            "passage": structured.passage,  # 지문/표/사례
            "question_type": structured.question_type,
            "options": structured.options,
            "correct_answer": structured.correct_answer,
            "explanation": structured.explanation,
            # 기존 호환성을 위해 question_text도 유지
            "question_text": (
                f"{structured.passage}\n\n{structured.question}"
                if structured.passage
                else structured.question
            )
        }


def parse_pdf_structured(pdf_path: str) -> List[Dict[str, Any]]:
    """구조화된 PDF 파싱"""
    parser = StructuredPDFParser(pdf_path)
    return parser.extract_questions()