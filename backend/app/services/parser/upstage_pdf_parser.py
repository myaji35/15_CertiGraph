"""Upstage Document Parse API를 사용한 PDF 파서"""

import re
import requests
from typing import List, Dict, Any, Optional


class UpstagePDFParser:
    """Upstage Document Parse API 기반 PDF 파서"""

    def __init__(self, pdf_path: str, api_key: str):
        self.pdf_path = pdf_path
        self.api_key = api_key
        self.api_url = "https://api.upstage.ai/v1/document-ai/document-parse"

    def extract_questions(self) -> List[Dict[str, Any]]:
        """PDF에서 문제 추출"""
        # Upstage API로 PDF 파싱
        parsed_content = self._parse_pdf_with_upstage()

        if not parsed_content:
            return []

        # 파싱된 텍스트에서 문제 추출
        questions = self._parse_questions(parsed_content)

        return questions

    def _parse_pdf_with_upstage(self) -> Optional[str]:
        """Upstage Document Parse API를 사용하여 PDF 파싱"""
        try:
            headers = {
                "Authorization": f"Bearer {self.api_key}"
            }

            with open(self.pdf_path, 'rb') as f:
                files = {
                    'document': f
                }
                data = {
                    'ocr': 'auto',  # PDF는 auto, 스캔본은 force
                    'output_formats': '["text"]'
                }

                response = requests.post(
                    self.api_url,
                    headers=headers,
                    files=files,
                    data=data,
                    timeout=120
                )

                if response.status_code == 200:
                    result = response.json()

                    # API 응답 구조에 따라 텍스트 추출
                    if 'content' in result:
                        content = result['content']
                        if isinstance(content, dict) and 'text' in content:
                            return content['text']
                        elif isinstance(content, str):
                            return content

                    # 다른 가능한 구조
                    if 'text' in result:
                        return result['text']

                    print(f"⚠️ Unexpected response structure: {list(result.keys())}")
                    return None

                else:
                    print(f"❌ Upstage API Error ({response.status_code}): {response.text}")
                    return None

        except Exception as e:
            print(f"❌ Error parsing PDF with Upstage: {e}")
            return None

    def _parse_questions(self, text: str) -> List[Dict[str, Any]]:
        """텍스트에서 문제 파싱"""
        questions = []

        # 문제 번호로 분리 (1., 2., 3., ... 100.)
        question_pattern = r'\n(\d{1,3})\.\s+'
        splits = re.split(question_pattern, text)

        # splits[0]은 헤더, 그 이후는 [번호, 내용, 번호, 내용, ...] 형태
        for i in range(1, len(splits), 2):
            if i + 1 < len(splits):
                question_number = int(splits[i])
                question_content = splits[i + 1]

                # 문제 파싱
                parsed = self._parse_single_question(question_number, question_content)
                if parsed:
                    questions.append(parsed)

        return questions

    def _parse_single_question(
        self, question_number: int, content: str
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

        # Upstage는 마크다운 형식으로 표를 반환할 수 있음
        # 이미 마크다운 표가 포함되어 있을 가능성이 높음

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
                    # 개행 및 과도한 공백 정리
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
            "passage": None  # 지문은 별도 로직 필요
        }


def parse_pdf_upstage(pdf_path: str, api_key: str) -> List[Dict[str, Any]]:
    """PDF 파싱 간편 함수 (Upstage API 사용)"""
    parser = UpstagePDFParser(pdf_path, api_key)
    return parser.extract_questions()
