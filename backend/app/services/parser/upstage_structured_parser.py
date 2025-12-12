"""Upstage API를 활용한 구조화된 PDF 파서"""

import re
import requests
import json
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


class UpstageStructuredParser:
    """Upstage API를 활용한 구조화된 PDF 파서"""

    def __init__(self, pdf_path: str, api_key: str):
        self.pdf_path = pdf_path
        self.api_key = api_key
        self.api_url = "https://api.upstage.ai/v1/document-ai/document-parse"

        # 지문 관련 패턴
        self.passage_patterns = {
            'case': [r'<사례>', r'\[사례\]', r'※\s*사례'],
            'table': [r'표\s*\d+', r'다음\s+표'],
            'passage': [r'\[보류문제\]', r'※\s*다음', r'다음.*?읽고'],
            'data': [r'다음\s+자료', r'아래\s+자료']
        }

    def extract_questions(self) -> List[Dict[str, Any]]:
        """PDF에서 구조화된 문제 추출"""

        # Upstage API로 문서 파싱
        parsed_content = self._parse_with_upstage()

        if not parsed_content:
            return []

        # 파싱된 내용에서 구조화된 문제 추출
        questions = self._extract_structured_questions(parsed_content)

        return questions

    def _parse_with_upstage(self) -> Optional[Dict[str, Any]]:
        """Upstage API를 사용하여 PDF 파싱"""
        try:
            headers = {
                "Authorization": f"Bearer {self.api_key}"
            }

            with open(self.pdf_path, 'rb') as f:
                files = {'document': f}
                data = {
                    'ocr': 'auto',  # PDF는 auto, 스캔본은 force
                    'output_formats': '["text", "html", "markdown"]',
                    'coordinates': 'true',  # 좌표 정보 포함
                    'layout_analysis': 'true',  # 레이아웃 분석
                    'table_extraction': 'true'  # 표 추출 강화
                }

                print("🔍 Upstage API로 문서 분석 중...")

                response = requests.post(
                    self.api_url,
                    headers=headers,
                    files=files,
                    data=data,
                    timeout=120
                )

                if response.status_code == 200:
                    result = response.json()

                    # 결과 구조 분석
                    parsed_data = {
                        'text': '',
                        'markdown': '',
                        'html': '',
                        'tables': [],
                        'layout': []
                    }

                    # 컨텐츠 추출
                    if 'content' in result:
                        content = result['content']
                        if isinstance(content, dict):
                            parsed_data['text'] = content.get('text', '')
                            parsed_data['markdown'] = content.get('markdown', '')
                            parsed_data['html'] = content.get('html', '')
                        elif isinstance(content, str):
                            parsed_data['text'] = content

                    # 레이아웃 정보
                    if 'layout' in result:
                        parsed_data['layout'] = result['layout']

                    # 표 정보
                    if 'tables' in result:
                        parsed_data['tables'] = result['tables']

                    print(f"✅ Upstage API 파싱 완료")
                    return parsed_data

                else:
                    print(f"❌ Upstage API Error ({response.status_code}): {response.text}")
                    return None

        except Exception as e:
            print(f"❌ Error calling Upstage API: {e}")
            return None

    def _extract_structured_questions(self, parsed_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Upstage 파싱 결과에서 구조화된 문제 추출"""
        questions = []

        # Markdown 우선 사용 (표 형식이 보존됨)
        content = parsed_data.get('markdown', '') or parsed_data.get('text', '')

        if not content:
            return []

        # 문제 번호로 분리
        question_pattern = r'\n(\d{1,3})\.\s+'
        splits = re.split(question_pattern, content)

        # 레이아웃 정보 활용 (있는 경우)
        layout_info = parsed_data.get('layout', [])

        for i in range(1, len(splits), 2):
            if i + 1 < len(splits):
                question_number = int(splits[i])
                question_content = splits[i + 1]

                # 구조화된 문제 생성
                structured = self._create_structured_question(
                    question_number,
                    question_content,
                    layout_info
                )

                if structured:
                    questions.append(self._structured_to_dict(structured))

        return questions

    def _create_structured_question(
        self,
        question_number: int,
        content: str,
        layout_info: List[Dict] = None
    ) -> Optional[StructuredQuestion]:
        """구조화된 문제 생성"""

        # 선택지 분리
        option_pattern = r'[①②③④⑤]'
        parts = re.split(f'({option_pattern})', content)

        if len(parts) < 3:
            return None

        full_text = parts[0].strip()

        # Upstage가 이미 마크다운 표로 변환했는지 확인
        has_markdown_table = '|' in full_text and '---' in full_text

        # 문제 유형 및 지문 분리
        if has_markdown_table:
            # 표가 포함된 경우
            question_type = 'table_based'

            # 표와 질문 분리
            lines = full_text.split('\n')
            table_lines = []
            question_lines = []
            in_table = False

            for line in lines:
                if '|' in line:
                    in_table = True
                    table_lines.append(line)
                elif in_table and '|' not in line and line.strip():
                    # 표가 끝나고 새로운 내용 시작
                    in_table = False
                    question_lines.append(line)
                elif not in_table:
                    question_lines.append(line)

            passage = '\n'.join(table_lines) if table_lines else None
            question = '\n'.join(question_lines).strip()

        else:
            # 일반 텍스트 분석
            question_type, passage, question = self._analyze_text_structure(full_text)

        # 선택지 추출
        options = self._extract_options(parts)

        if len(options) < 2:
            return None

        # 정답 (실제 구현 시 정답 페이지에서 추출)
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

    def _analyze_text_structure(self, text: str) -> Tuple[str, Optional[str], str]:
        """텍스트 구조 분석 (지문/질문 분리)"""
        question_type = 'simple'
        passage = None
        question = text

        # 패턴 매칭으로 지문 추출
        for pattern_type, patterns in self.passage_patterns.items():
            for pattern in patterns:
                match = re.search(pattern, text, re.IGNORECASE)
                if match:
                    # 패턴 이후를 지문으로 간주
                    split_pos = match.end()

                    # "~은?", "~는?" 패턴으로 질문 찾기
                    q_pattern = r'[가-힣]+(?:은|는|이|가|을|를)(?:\s+무엇|\s+어느|\s+옳[은지]|\s+적절한).*?\?'
                    q_match = re.search(q_pattern, text[split_pos:])

                    if q_match:
                        passage_end = split_pos + q_match.start()
                        passage = text[split_pos:passage_end].strip()
                        question = text[passage_end:].strip()
                        question_type = f'{pattern_type}_based'
                    break

            if passage:
                break

        return question_type, passage, question

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
                    option_text = re.sub(r'([ㄱ-ㅎ]):', r'\n\1:', option_text).strip()

                    options.append({
                        "number": option_number,
                        "text": option_text
                    })

        return options

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


def parse_pdf_with_upstage(pdf_path: str, api_key: str) -> List[Dict[str, Any]]:
    """Upstage API를 사용한 구조화된 PDF 파싱"""
    parser = UpstageStructuredParser(pdf_path, api_key)
    return parser.extract_questions()