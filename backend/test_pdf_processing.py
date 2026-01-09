"""
Test script for PDF processing services

Tests:
1. Upstage client with mock data
2. Question extractor with mock data
3. PDF processor end-to-end flow
"""

import asyncio
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(__file__))

from app.services.upstage_client import get_upstage_client
from app.services.question_extractor_v2 import get_question_extractor
from app.services.pdf_processor_v2 import get_pdf_processor


async def test_upstage_client():
    """Test Upstage client with mock data"""
    print("\n" + "="*60)
    print("TEST 1: Upstage Client")
    print("="*60)

    client = get_upstage_client()
    print(f"✓ Client initialized (mock mode: {client.use_mock})")

    # Create fake PDF content
    fake_pdf = b"fake pdf content for testing"

    try:
        result = await client.parse_pdf(fake_pdf, "test.pdf")
        print(f"✓ PDF parsed successfully")
        print(f"  - Total pages: {result.total_pages}")
        print(f"  - Text length: {len(result.text)} chars")
        print(f"  - Markdown length: {len(result.markdown)} chars")
        print(f"\n  Text preview (first 200 chars):")
        print(f"  {result.text[:200]}...")
        return True
    except Exception as e:
        print(f"✗ PDF parsing failed: {e}")
        return False


async def test_question_extractor():
    """Test question extractor with mock data"""
    print("\n" + "="*60)
    print("TEST 2: Question Extractor")
    print("="*60)

    extractor = get_question_extractor()
    print(f"✓ Extractor initialized (mock mode: {extractor.use_mock})")

    # Sample text
    sample_text = """
    2024년 사회복지사 1급 시험

    1. 사회복지의 기본 원칙은?
    ① 선별적 서비스
    ② 잔여적 개념
    ③ 보편적 서비스
    ④ 시장 원리
    ⑤ 개인 책임

    정답: 3
    """

    try:
        questions = await extractor.extract_questions(sample_text)
        print(f"✓ Extracted {len(questions)} questions")

        for i, q in enumerate(questions[:3], 1):  # Show first 3
            print(f"\n  Question {i}:")
            print(f"    Number: {q.question_number}")
            print(f"    Text: {q.question_text[:60]}...")
            print(f"    Options: {len(q.options)}")
            print(f"    Answer: {q.correct_answer}")
            print(f"    Subject: {q.subject}")

        return True
    except Exception as e:
        print(f"✗ Question extraction failed: {e}")
        import traceback
        traceback.print_exc()
        return False


async def test_pdf_processor():
    """Test PDF processor end-to-end"""
    print("\n" + "="*60)
    print("TEST 3: PDF Processor (End-to-End)")
    print("="*60)

    processor = get_pdf_processor()
    print(f"✓ Processor initialized")

    # Fake PDF content
    fake_pdf = b"fake pdf content for end-to-end test"
    study_set_id = "test-study-set-123"

    # Progress callback
    async def on_progress(status: str, progress: int, message: str):
        print(f"  [{progress:3d}%] {status}: {message}")

    try:
        result = await processor.process_pdf(
            pdf_content=fake_pdf,
            study_set_id=study_set_id,
            filename="test_exam.pdf",
            db=None,  # No DB for this test
            progress_callback=on_progress,
        )

        if result["success"]:
            print(f"\n✓ Processing succeeded!")
            print(f"  - Total questions: {result['total_questions']}")
            print(f"  - PDF hash: {result['pdf_hash'][:16]}...")
            print(f"  - Total pages: {result.get('total_pages', 0)}")

            # Show first question
            if result["questions"]:
                q = result["questions"][0]
                print(f"\n  First question:")
                print(f"    Number: {q['question_number']}")
                print(f"    Text: {q['question_text'][:80]}...")
                print(f"    Options: {len(q['options'])}")

            return True
        else:
            print(f"✗ Processing failed: {result.get('error', 'Unknown error')}")
            return False

    except Exception as e:
        print(f"✗ Processing failed with exception: {e}")
        import traceback
        traceback.print_exc()
        return False


async def main():
    """Run all tests"""
    print("\n" + "="*60)
    print("PDF PROCESSING SERVICES TEST SUITE")
    print("="*60)
    print("\nRunning tests in MOCK mode (no API keys required)")

    results = []

    # Test 1: Upstage Client
    results.append(await test_upstage_client())

    # Test 2: Question Extractor
    results.append(await test_question_extractor())

    # Test 3: PDF Processor
    results.append(await test_pdf_processor())

    # Summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    passed = sum(results)
    total = len(results)
    print(f"Tests passed: {passed}/{total}")

    if passed == total:
        print("✅ All tests passed!")
        return 0
    else:
        print("⚠️ Some tests failed")
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
