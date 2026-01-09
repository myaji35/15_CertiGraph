"""
Upstage Document Parse API Client for PDF Processing

This service handles communication with Upstage Document Parse API,
providing OCR and document parsing capabilities for Korean text PDFs.
"""

import asyncio
import httpx
import logging
from typing import Optional, Dict, Any, List
from dataclasses import dataclass

from app.core.config import get_settings

logger = logging.getLogger(__name__)

UPSTAGE_API_URL = "https://api.upstage.ai/v1/document-ai/document-parse"
UPSTAGE_TIMEOUT = 120.0  # 2 minutes timeout for large PDFs


@dataclass
class ParsedContent:
    """Represents parsed content from Upstage API"""
    text: str
    markdown: str
    total_pages: int
    elements: List[Dict[str, Any]]
    raw_response: Dict[str, Any]


class UpstageClient:
    """
    Client for Upstage Document Parse API.

    Handles:
    - PDF to text/markdown conversion with OCR
    - Korean text recognition
    - Document structure preservation
    - Retry logic for API failures
    - Mock fallback when API is unavailable
    """

    MAX_RETRIES = 3
    RETRY_DELAY = 2  # seconds

    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize Upstage client.

        Args:
            api_key: Upstage API key (defaults to settings if not provided)
        """
        settings = get_settings()
        self.api_key = api_key or settings.upstage_api_key
        self.use_mock = not self.api_key or settings.dev_mode

        if self.use_mock:
            logger.warning("⚠️ Upstage API key not configured - using MOCK mode")
        else:
            logger.info("✅ Upstage client initialized with API key")

    async def parse_pdf(
        self,
        pdf_content: bytes,
        filename: str = "document.pdf",
        force_ocr: bool = True,
    ) -> ParsedContent:
        """
        Parse PDF document using Upstage Document Parse API.

        Args:
            pdf_content: PDF file content as bytes
            filename: Original filename for logging
            force_ocr: Force OCR even for text-based PDFs (recommended for Korean)

        Returns:
            ParsedContent with text, markdown, and metadata

        Raises:
            Exception: If parsing fails after all retries
        """
        if self.use_mock:
            return await self._mock_parse(pdf_content, filename)

        logger.info(f"📄 Parsing PDF: {filename} ({len(pdf_content)} bytes)")

        last_error = None
        for attempt in range(self.MAX_RETRIES):
            try:
                result = await self._call_api(pdf_content, filename, force_ocr)
                parsed = self._process_response(result)
                logger.info(f"✅ Successfully parsed {filename} - {parsed.total_pages} pages")
                return parsed

            except httpx.HTTPStatusError as e:
                last_error = e
                status = e.response.status_code
                logger.warning(f"Upstage API HTTP error (attempt {attempt + 1}/{self.MAX_RETRIES}): {status}")

                if status == 429:  # Rate limited
                    await asyncio.sleep(self.RETRY_DELAY * (attempt + 1) * 2)
                elif status >= 500:  # Server error
                    await asyncio.sleep(self.RETRY_DELAY * (attempt + 1))
                else:
                    raise Exception(f"Upstage API error: HTTP {status}")

            except httpx.RequestError as e:
                last_error = e
                logger.warning(f"Upstage API request error (attempt {attempt + 1}/{self.MAX_RETRIES}): {e}")
                await asyncio.sleep(self.RETRY_DELAY * (attempt + 1))

            except Exception as e:
                last_error = e
                logger.error(f"Unexpected error during Upstage API call: {e}")
                if attempt < self.MAX_RETRIES - 1:
                    await asyncio.sleep(self.RETRY_DELAY * (attempt + 1))

        # All retries failed
        logger.error(f"❌ Failed to parse PDF after {self.MAX_RETRIES} attempts: {last_error}")
        raise Exception(f"Upstage API parsing failed: {last_error}")

    async def _call_api(
        self,
        pdf_content: bytes,
        filename: str,
        force_ocr: bool,
    ) -> Dict[str, Any]:
        """Make HTTP request to Upstage Document Parse API"""
        async with httpx.AsyncClient(timeout=UPSTAGE_TIMEOUT) as client:
            response = await client.post(
                UPSTAGE_API_URL,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                },
                files={
                    "document": (filename, pdf_content, "application/pdf"),
                },
                data={
                    "ocr": "force" if force_ocr else "auto",
                    "output_formats": "text,markdown",
                },
            )
            response.raise_for_status()
            return response.json()

    def _process_response(self, response: Dict[str, Any]) -> ParsedContent:
        """Process Upstage API response into ParsedContent object"""
        # Extract content
        content = response.get("content", {})
        text = content.get("text", "")
        markdown = content.get("markdown", "")

        # Extract elements
        elements = response.get("elements", [])

        # Get page count
        total_pages = response.get("num_pages", 0)

        # Log extraction stats
        logger.debug(f"Extracted {len(elements)} elements, {len(text)} chars text, {len(markdown)} chars markdown")

        return ParsedContent(
            text=text,
            markdown=markdown,
            total_pages=total_pages,
            elements=elements,
            raw_response=response,
        )

    async def _mock_parse(self, pdf_content: bytes, filename: str) -> ParsedContent:
        """
        Mock parsing for development/testing.
        Returns sample Korean exam questions.
        """
        logger.warning(f"🔧 MOCK: Parsing {filename} with mock data")

        # Simulate API delay
        await asyncio.sleep(1.0)

        mock_text = """
--- 페이지 1 ---

2024년 사회복지사 1급 시험 기출문제

과목: 사회복지기초

1. 사회복지의 기본 원칙에 대한 설명으로 옳은 것은?

① 사회복지는 선별적 서비스를 원칙으로 한다
② 사회복지는 잔여적 개념에 기초한다
③ 사회복지는 보편적 서비스를 지향한다
④ 사회복지는 시장 원리에 따라 운영된다
⑤ 사회복지는 개인의 책임을 강조한다

정답: 3
해설: 현대 사회복지는 보편적 서비스를 지향하며, 모든 국민의 기본적 권리를 보장하는 것을 목표로 한다.

2. 다음 중 사회복지 실천의 가치로 적절하지 않은 것은?

① 인간의 존엄성
② 자기결정권
③ 차별과 배제
④ 사회정의
⑤ 평등

정답: 3
해설: 차별과 배제는 사회복지 실천의 가치가 아니라 극복해야 할 대상이다.

--- 페이지 2 ---

다음 지문을 읽고 물음에 답하시오.

○ 빈곤의 원인은 개인의 능력 부족에서 찾을 수 있다
○ 사회적 불평등은 개인의 노력으로 극복 가능하다
○ 복지 혜택은 근로 의욕을 감소시킨다

3. 위 지문이 설명하는 사회복지 관점은?

① 잔여적 관점
② 제도적 관점
③ 진보적 관점
④ 생태체계적 관점
⑤ 강점 관점

정답: 1
해설: 잔여적 관점은 빈곤을 개인의 문제로 보며, 복지를 최소한으로 제공해야 한다고 본다.

4. 위 지문의 관점에 대한 비판으로 적절한 것은?

① 구조적 요인을 간과한다
② 개인의 책임을 지나치게 강조한다
③ 사회적 불평등을 정당화한다
④ 모두 옳다
⑤ 모두 틀리다

정답: 4
"""

        mock_markdown = mock_text  # For simplicity, use same content

        return ParsedContent(
            text=mock_text,
            markdown=mock_markdown,
            total_pages=2,
            elements=[],
            raw_response={"mock": True, "content": {"text": mock_text, "markdown": mock_markdown}},
        )

    def extract_text_by_page(self, parsed: ParsedContent) -> Dict[int, str]:
        """
        Extract text organized by page number.

        Args:
            parsed: ParsedContent from parse_pdf

        Returns:
            Dictionary mapping page number to text content
        """
        pages: Dict[int, List[str]] = {}

        # Try to use elements if available
        for elem in parsed.elements:
            page = elem.get("page", 1)
            text = elem.get("text", "")

            if page not in pages:
                pages[page] = []
            pages[page].append(text)

        # If no elements, try to split by page markers
        if not pages:
            text = parsed.text or parsed.markdown
            page_sections = text.split("--- 페이지")
            for i, section in enumerate(page_sections[1:], start=1):  # Skip first split
                pages[i] = [section.strip()]

        return {page: "\n".join(texts) for page, texts in pages.items()}


# Singleton instance
_upstage_client: Optional[UpstageClient] = None


def get_upstage_client() -> UpstageClient:
    """Get or create singleton Upstage client instance"""
    global _upstage_client
    if _upstage_client is None:
        _upstage_client = UpstageClient()
    return _upstage_client
