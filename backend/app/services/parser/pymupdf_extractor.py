"""PyMuPDF-based direct text extraction from PDF.

Extracts text directly from PDF without OCR API,
faster and more reliable for text-based PDFs.
"""

import logging
from typing import Optional
import pymupdf

logger = logging.getLogger(__name__)


class PyMuPDFTextExtractor:
    """Extract text directly from PDF using PyMuPDF."""

    def __init__(self):
        pass

    async def extract_text(
        self,
        pdf_content: bytes,
        on_progress: Optional[callable] = None,
    ) -> str:
        """
        Extract text directly from PDF.

        Args:
            pdf_content: PDF file content as bytes
            on_progress: Optional progress callback

        Returns:
            Full text extracted from PDF
        """
        try:
            logger.info("📄 Starting PyMuPDF text extraction...")

            # Open PDF from bytes
            doc = pymupdf.open(stream=pdf_content, filetype="pdf")

            full_text = []
            total_pages = len(doc)

            for page_num, page in enumerate(doc):
                if on_progress:
                    progress = int((page_num / total_pages) * 100)
                    await on_progress(progress, f"텍스트 추출 중... ({page_num + 1}/{total_pages})")

                # Extract text from page
                page_text = page.get_text()

                if page_text.strip():
                    # Add page separator
                    if page_num > 0:
                        full_text.append(f"\n--- 페이지 {page_num + 1} ---\n")
                    full_text.append(page_text)

                logger.info(f"✅ Page {page_num + 1}: Extracted {len(page_text)} characters")

            doc.close()

            if on_progress:
                await on_progress(100, "텍스트 추출 완료!")

            result = "\n".join(full_text)
            logger.info(f"📊 Total extracted: {len(result)} characters from {total_pages} pages")

            # Log sample for debugging
            if result:
                logger.info(f"📝 First 500 chars: {result[:500]}")
                logger.info(f"📝 Last 500 chars: {result[-500:]}")

            return result

        except Exception as e:
            logger.error(f"PyMuPDF extraction failed: {e}")
            raise