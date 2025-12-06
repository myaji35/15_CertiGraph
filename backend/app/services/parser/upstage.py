"""Upstage Document Parse API integration.

Upstage Document Parse API extracts structured content from PDF documents,
including text, tables, and document structure.
"""

import asyncio
import httpx
from typing import Any, BinaryIO
from dataclasses import dataclass
import logging

from app.core.config import get_settings
from app.core.exceptions import ExternalUpstageError

logger = logging.getLogger(__name__)

UPSTAGE_API_URL = "https://api.upstage.ai/v1/document-ai/document-parse"


@dataclass
class ParsedElement:
    """Represents a parsed element from the document."""
    type: str  # "paragraph", "heading", "table", "list_item", etc.
    text: str
    page: int
    bounding_box: dict[str, float] | None = None
    confidence: float = 1.0


@dataclass
class ParseResult:
    """Result of document parsing."""
    elements: list[ParsedElement]
    total_pages: int
    raw_response: dict[str, Any]


class UpstageDocumentParser:
    """Service for parsing PDF documents using Upstage API."""

    MAX_RETRIES = 3
    RETRY_DELAY = 2  # seconds

    def __init__(self):
        self.settings = get_settings()
        self.api_key = self.settings.upstage_api_key

    async def parse_document(
        self,
        file_content: bytes,
        filename: str = "document.pdf",
    ) -> ParseResult:
        """
        Parse a PDF document using Upstage Document Parse API.

        Args:
            file_content: PDF file content as bytes
            filename: Original filename

        Returns:
            ParseResult with extracted elements

        Raises:
            ExternalUpstageError: If parsing fails after retries
        """
        last_error = None

        for attempt in range(self.MAX_RETRIES):
            try:
                result = await self._call_api(file_content, filename)
                return self._process_response(result)

            except httpx.HTTPStatusError as e:
                last_error = e
                logger.warning(
                    f"Upstage API HTTP error (attempt {attempt + 1}/{self.MAX_RETRIES}): {e}"
                )
                if e.response.status_code == 429:  # Rate limited
                    await asyncio.sleep(self.RETRY_DELAY * (attempt + 1) * 2)
                elif e.response.status_code >= 500:  # Server error
                    await asyncio.sleep(self.RETRY_DELAY * (attempt + 1))
                else:
                    raise ExternalUpstageError(f"Upstage API 오류: {e.response.status_code}")

            except httpx.RequestError as e:
                last_error = e
                logger.warning(
                    f"Upstage API request error (attempt {attempt + 1}/{self.MAX_RETRIES}): {e}"
                )
                await asyncio.sleep(self.RETRY_DELAY * (attempt + 1))

        raise ExternalUpstageError(f"Upstage API 호출 실패: {last_error}")

    async def _call_api(
        self,
        file_content: bytes,
        filename: str,
    ) -> dict[str, Any]:
        """Make API call to Upstage Document Parse."""
        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                UPSTAGE_API_URL,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                },
                files={
                    "document": (filename, file_content, "application/pdf"),
                },
                data={
                    "ocr": "auto",  # Enable OCR for scanned documents
                    "output_formats": "text",  # We mainly need text
                },
            )
            response.raise_for_status()
            return response.json()

    def _process_response(self, response: dict[str, Any]) -> ParseResult:
        """Process Upstage API response into structured result."""
        elements = []
        total_pages = response.get("num_pages", 0)

        # Process each element in the response
        for elem in response.get("elements", []):
            parsed_elem = ParsedElement(
                type=elem.get("category", "paragraph"),
                text=elem.get("text", ""),
                page=elem.get("page", 1),
                bounding_box=elem.get("bounding_box"),
                confidence=elem.get("confidence", 1.0),
            )
            elements.append(parsed_elem)

        return ParseResult(
            elements=elements,
            total_pages=total_pages,
            raw_response=response,
        )

    def extract_full_text(self, result: ParseResult) -> str:
        """
        Extract full text from parsed result, maintaining document structure.

        Args:
            result: ParseResult from parse_document

        Returns:
            Full text with basic structure preserved
        """
        text_parts = []
        current_page = 0

        for elem in result.elements:
            # Add page break marker
            if elem.page != current_page:
                if current_page > 0:
                    text_parts.append(f"\n--- 페이지 {elem.page} ---\n")
                current_page = elem.page

            # Add element text based on type
            if elem.type == "heading":
                text_parts.append(f"\n## {elem.text}\n")
            elif elem.type == "list_item":
                text_parts.append(f"• {elem.text}")
            elif elem.type == "table":
                text_parts.append(f"\n[표]\n{elem.text}\n")
            else:
                text_parts.append(elem.text)

        return "\n".join(text_parts)

    def extract_by_page(self, result: ParseResult) -> dict[int, str]:
        """
        Extract text organized by page number.

        Args:
            result: ParseResult from parse_document

        Returns:
            Dictionary mapping page numbers to text content
        """
        pages: dict[int, list[str]] = {}

        for elem in result.elements:
            if elem.page not in pages:
                pages[elem.page] = []
            pages[elem.page].append(elem.text)

        return {page: "\n".join(texts) for page, texts in pages.items()}
