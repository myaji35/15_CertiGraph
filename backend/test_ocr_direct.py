"""Test OCR directly with existing PDF file."""

import asyncio
from app.services.parser.upstage import UpstageDocumentParser

async def test_ocr():
    pdf_path = "mock_storage/mock/dev_user_123/1fca940c-e85a-4303-9a46-f20692b5adc6.pdf"

    print(f"📄 Reading PDF: {pdf_path}")

    # Read PDF file
    with open(pdf_path, "rb") as f:
        pdf_content = f.read()

    print(f"📦 PDF size: {len(pdf_content)} bytes")

    # Parse with Upstage
    parser = UpstageDocumentParser()

    try:
        print("🔍 Parsing with Upstage API...")
        parse_result = await parser.parse_document(pdf_content)
        full_text = parser.extract_full_text(parse_result)

        print(f"✅ Success!")
        print(f"📊 Total pages: {parse_result.total_pages}")
        print(f"📊 Total elements: {len(parse_result.elements)}")
        print(f"📊 Total characters: {len(full_text)}")

        # Save to file
        output_file = "ocr_result_direct.txt"
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(f"=== OCR Result from PDF ===\n")
            f.write(f"Total Pages: {parse_result.total_pages}\n")
            f.write(f"Total Elements: {len(parse_result.elements)}\n")
            f.write(f"Total Characters: {len(full_text)}\n")
            f.write("="*50 + "\n\n")
            f.write(full_text)

        print(f"📝 OCR result saved to: {output_file}")

        # Show first 2000 characters
        print("\n" + "="*50)
        print("First 2000 characters of OCR result:")
        print("="*50)
        print(full_text[:2000])

    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_ocr())