"""Simple rule-based PDF parser without LLM API"""

import re
import pdfplumber
from typing import List, Dict, Any, Optional


class SimplePDFParser:
    """규칙 기반 PDF 파서 - LLM API 없이 문제 추출"""

    def __init__(self, pdf_path: str):
        self.pdf_path = pdf_path

    def extract_questions(self) -> List[Dict[str, Any]]:
        """PDF에서 문제 추출"""
        questions = []

        with pdfplumber.open(self.pdf_path) as pdf:
            # 모든 페이지의 텍스트와 표 추출
            full_text = ""
            all_tables = []  # 모든 표를 리스트로 저장 (간단하게)

            for page_num, page in enumerate(pdf.pages):
                text = page.extract_text()
                if text:
                    full_text += text + "\n"

                # 표 추출
                tables = page.extract_tables()
                if tables:
                    all_tables.extend(tables)

            # 문제별로 분리
            questions = self._parse_questions(full_text, all_tables)

        return questions

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

        return "\n" + "\n".join(lines) + "\n"

    def _parse_questions(self, text: str, all_tables: list) -> List[Dict[str, Any]]:
        """텍스트에서 문제 파싱"""
        questions = []

        # 문제 번호로 분리 (1., 2., 3., ... 100.)
        # 패턴: 줄 시작 + 숫자 + 마침표 + 공백
        question_pattern = r'\n(\d{1,3})\.\s+'
        splits = re.split(question_pattern, text)

        # 표를 문제별로 매칭하기 위한 인덱스
        table_index = 0
        used_tables = set()  # 사용된 표 추적

        # splits[0]은 헤더, 그 이후는 [번호, 내용, 번호, 내용, ...] 형태
        for i in range(1, len(splits), 2):
            if i + 1 < len(splits):
                question_number = int(splits[i])
                question_content = splits[i + 1]

                # 다음 문제 내용도 미리 확인 (표가 다음 문제에 속할 수 있음)
                next_question_preview = ""
                if i + 3 < len(splits):
                    next_question_preview = splits[i + 3][:200]  # 다음 문제 시작 부분

                # 문제 파싱 (개선된 표 매칭)
                parsed = self._parse_single_question_improved(
                    question_number,
                    question_content,
                    all_tables,
                    used_tables,
                    next_question_preview
                )
                if parsed:
                    questions.append(parsed)

        return questions

    def _parse_single_question_improved(
        self,
        question_number: int,
        content: str,
        all_tables: list,
        used_tables: set,
        next_question_preview: str
    ) -> Optional[Dict[str, Any]]:
        """개선된 개별 문제 파싱 - 표 매칭 강화"""

        # 선택지 패턴: ①, ②, ③, ④, ⑤
        option_pattern = r'[①②③④⑤]'

        # 선택지로 분리
        parts = re.split(f'({option_pattern})', content)

        if len(parts) < 3:
            # 선택지가 없으면 스킵
            return None

        # 첫 부분이 문제 본문
        question_text = parts[0].strip()

        # 표가 있는지 더 정밀하게 확인
        if all_tables:
            # 표 관련 키워드 확장
            strong_table_keywords = ['(ㄱ)', '(ㄴ)', '(ㄷ)', '(ㄹ)', '( ㄱ )', '( ㄴ )', '( ㄷ )', '( ㄹ )']
            weak_table_keywords = ['세 단계', '표', '나열', '들어갈', '순서대로', '내용을', '다음']

            # 문제 텍스트에 강한 표 신호가 있는지 확인
            has_strong_signal = any(keyword in question_text for keyword in strong_table_keywords)
            has_weak_signal = any(keyword in question_text for keyword in weak_table_keywords)

            if has_strong_signal or (has_weak_signal and len(weak_table_keywords) >= 2):
                # 사용하지 않은 표 중에서 매칭
                for idx, table in enumerate(all_tables):
                    if idx in used_tables:
                        continue

                    if table and len(table) > 1:
                        # 표의 내용을 문자열로 변환
                        table_str = ' '.join([' '.join([cell or '' for cell in row]) for row in table])

                        # 표가 현재 문제와 관련 있는지 확인
                        # 1. 강한 신호가 표에도 있는지
                        table_has_markers = any(keyword in table_str for keyword in ['ㄱ', 'ㄴ', 'ㄷ', 'ㄹ'])

                        # 2. 표의 내용이 문제나 선택지와 연관되는지
                        table_relevant_keywords = ['대상자', '사회복지', '빈민법', '사회보험', '복지국가']
                        table_is_relevant = any(keyword in table_str for keyword in table_relevant_keywords)

                        if table_has_markers or table_is_relevant:
                            # 이 표를 사용
                            used_tables.add(idx)

                            # 원본 텍스트에서 표 내용 제거 (개선된 로직)
                            question_text = self._remove_table_text_improved(question_text, table)

                            # 마크다운 표 추가
                            table_md = self._table_to_markdown(table)
                            if table_md:
                                question_text += "\n" + table_md
                                break

        # 선택지 추출 (기존 로직 유지)
        options = []
        option_symbols = {'①': 1, '②': 2, '③': 3, '④': 4, '⑤': 5}

        for i in range(1, len(parts), 2):
            if i + 1 < len(parts):
                symbol = parts[i]
                if symbol in option_symbols:
                    option_number = option_symbols[symbol]
                    option_text = parts[i + 1].strip()

                    # 다음 선택지나 문제가 나오기 전까지의 텍스트
                    lines = option_text.split('\n')
                    cleaned_lines = []
                    for line in lines:
                        line = line.strip()
                        if line and not line.startswith('2025년도'):  # 페이지 정보 제거
                            # ㄱ:, ㄴ:, ㄷ: 형식은 줄바꿈으로 유지
                            if re.match(r'^[ㄱ-ㅎ]:', line):
                                cleaned_lines.append('\n' + line)
                            else:
                                cleaned_lines.append(line)

                    option_text = ' '.join(cleaned_lines).strip()
                    # 연속된 공백 제거
                    option_text = re.sub(r'\s+', ' ', option_text)

                    options.append({
                        "number": option_number,
                        "text": option_text
                    })

        # 최소 2개 이상의 선택지가 있어야 유효
        if len(options) < 2:
            return None

        # 정답은 모의로 설정 (실제로는 정답 페이지에서 추출해야 함)
        correct_answer = ((question_number - 1) % 5) + 1

        return {
            "question_number": question_number,
            "question_text": question_text,
            "options": options,
            "correct_answer": correct_answer,
            "explanation": f"문제 {question_number}번의 정답은 {correct_answer}번입니다.",
            "passage": None
        }

    def _remove_table_text_improved(self, question_text: str, table: List[List[str]]) -> str:
        """표 텍스트를 더 정확하게 제거"""
        lines = question_text.split('\n')
        cleaned_lines = []
        skip_mode = False
        skip_count = 0

        for line in lines:
            # 표의 각 셀이 현재 줄에 있는지 확인
            line_contains_table_cell = False
            for row in table:
                for cell in row:
                    if cell and len(cell) > 2:  # 짧은 텍스트는 제외
                        # 셀 내용이 줄에 포함되어 있으면
                        if cell in line:
                            line_contains_table_cell = True
                            break
                if line_contains_table_cell:
                    break

            if line_contains_table_cell:
                skip_mode = True
                skip_count = 0
                continue

            # 표 이후 몇 줄은 추가로 스킵 (표 관련 내용일 가능성)
            if skip_mode:
                skip_count += 1
                if skip_count > 2 or line.strip() == '':  # 빈 줄이나 충분히 떨어진 경우
                    skip_mode = False
                else:
                    continue

            cleaned_lines.append(line)

        return '\n'.join(cleaned_lines).strip()

    def _parse_single_question(
        self, question_number: int, content: str, all_tables: list = None
    ) -> Optional[Dict[str, Any]]:
        """개별 문제 파싱"""

        # 선택지 패턴: ①, ②, ③, ④, ⑤
        option_pattern = r'[①②③④⑤]'

        # 선택지로 분리
        parts = re.split(f'({option_pattern})', content)

        if len(parts) < 3:
            # 선택지가 없으면 스킵
            return None

        # 첫 부분이 문제 본문
        question_text = parts[0].strip()

        # 표가 있는지 확인하고 마크다운으로 변환
        # 조건: 문제 텍스트에 이미 표 관련 키워드가 있고, 실제 표 데이터도 관련 있을 때만
        if all_tables:
            # 문제 텍스트에 표 관련 키워드가 있는지 먼저 확인
            table_keywords = ['( ㄱ )', '( ㄴ )', '( ㄷ )', '세 단계', '표', '나열', '들어갈']
            has_table_hint = any(keyword in question_text for keyword in table_keywords)

            if has_table_hint:
                for table in all_tables:
                    if table and len(table) > 1:
                        # 표의 내용을 문자열로 변환
                        table_str = ' '.join([' '.join([cell or '' for cell in row]) for row in table])

                        # 표 안에 문제 관련 키워드가 있는지 확인
                        # "( ㄱ )", "( ㄴ )", "( ㄷ )" 등
                        table_match_keywords = ['( ㄱ )', '( ㄴ )', '( ㄷ )']
                        if any(keyword in table_str for keyword in table_match_keywords):
                            # 이 표가 현재 문제와 관련있음
                            # 원본 텍스트에서 표 관련 내용 제거
                            # 표의 첫 행이나 주요 키워드 이후부터 선택지 전까지를 제거
                            lines = question_text.split('\n')
                            cleaned_lines = []
                            skip_mode = False

                            for line in lines:
                                # 표 구조의 시작을 감지 (대상자, 사회복지 주체 등)
                                if any(keyword in line for keyword in ['대상자', '사회복지 주체', '권리수준']):
                                    skip_mode = True
                                    continue
                                # 표 내용 감지 (빈민법, 사회보험, 복지국가 등)
                                if skip_mode and any(keyword in line for keyword in ['빈민법', '사회보험', '복지국가', '( ㄱ )', '( ㄴ )', '( ㄷ )']):
                                    continue
                                # 선택지나 다른 내용이 나오면 skip 모드 종료
                                if skip_mode and (line.strip() == '' or not any(keyword in line for keyword in ['걸인', '부랑인', '노동자', '시민', '국가', '재량', '계급', '단체'])):
                                    skip_mode = False

                                if not skip_mode:
                                    cleaned_lines.append(line)

                            question_text = '\n'.join(cleaned_lines).strip()

                            # 마크다운 표 추가
                            table_md = self._table_to_markdown(table)
                            if table_md:
                                question_text += "\n" + table_md
                                break

        # 선택지 추출
        options = []
        option_symbols = {'①': 1, '②': 2, '③': 3, '④': 4, '⑤': 5}

        for i in range(1, len(parts), 2):
            if i + 1 < len(parts):
                symbol = parts[i]
                if symbol in option_symbols:
                    option_number = option_symbols[symbol]
                    option_text = parts[i + 1].strip()

                    # 다음 선택지나 문제가 나오기 전까지의 텍스트
                    # 개행 및 과도한 공백 정리하되, "ㄱ:", "ㄴ:" 등은 유지
                    lines = option_text.split('\n')
                    cleaned_lines = []
                    for line in lines:
                        line = line.strip()
                        if line and not line.startswith('2025년도'):  # 페이지 정보 제거
                            # ㄱ:, ㄴ:, ㄷ: 형식은 줄바꿈으로 유지
                            if re.match(r'^[ㄱ-ㅎ]:', line):
                                cleaned_lines.append('\n' + line)
                            else:
                                cleaned_lines.append(line)

                    option_text = ' '.join(cleaned_lines).strip()
                    # 연속된 공백 제거
                    option_text = re.sub(r'\s+', ' ', option_text)

                    options.append({
                        "number": option_number,
                        "text": option_text
                    })

        # 최소 2개 이상의 선택지가 있어야 유효
        if len(options) < 2:
            return None

        # 정답은 모의로 설정 (실제로는 정답 페이지에서 추출해야 함)
        # 여기서는 간단하게 순환하도록
        correct_answer = ((question_number - 1) % 5) + 1

        return {
            "question_number": question_number,
            "question_text": question_text,
            "options": options,
            "correct_answer": correct_answer,
            "explanation": f"문제 {question_number}번의 정답은 {correct_answer}번입니다.",
            "passage": None  # 지문은 별도 로직 필요
        }


def parse_pdf_simple(pdf_path: str) -> List[Dict[str, Any]]:
    """PDF 파싱 간편 함수"""
    parser = SimplePDFParser(pdf_path)
    return parser.extract_questions()
