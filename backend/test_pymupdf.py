"""Test PyMuPDF text extraction with existing PDF file."""

import asyncio
from app.services.parser.pymupdf_extractor import PyMuPDFTextExtractor
from app.services.parser.question_extractor import QuestionExtractor

async def test_pymupdf():
    pdf_path = "mock_storage/mock/dev_user_123/1fca940c-e85a-4303-9a46-f20692b5adc6.pdf"

    print(f"📄 Testing PyMuPDF extraction")
    print(f"📄 Reading PDF: {pdf_path}")

    # Read PDF file
    with open(pdf_path, "rb") as f:
        pdf_content = f.read()

    print(f"📦 PDF size: {len(pdf_content)} bytes")

    # Extract text with PyMuPDF
    extractor = PyMuPDFTextExtractor()

    try:
        print("📄 Extracting text with PyMuPDF...")
        full_text = await extractor.extract_text(pdf_content)

        print(f"✅ Success!")
        print(f"📊 Total characters: {len(full_text)}")

        # Save to file
        output_file = "pymupdf_result.txt"
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(f"=== PyMuPDF Text Extraction Result ===\n")
            f.write(f"Total Characters: {len(full_text)}\n")
            f.write("="*50 + "\n\n")
            f.write(full_text)

        print(f"📝 Text saved to: {output_file}")

        # Show first 2000 characters
        print("\n" + "="*50)
        print("First 2000 characters of extracted text:")
        print("="*50)
        print(full_text[:2000])

        # Try to extract questions
        print("\n" + "="*50)
        print("Testing question extraction with Gemini...")
        print("="*50)

        question_extractor = QuestionExtractor()
        questions = await question_extractor.extract_questions(full_text)

        print(f"\n✅ Extracted {len(questions)} questions!")

        # Show first 3 questions
        for i, q in enumerate(questions[:3], 1):
            print(f"\n--- Question {q.question_number} ---")
            print(f"Text: {q.question_text[:200]}...")
            print(f"Options: {len(q.options)} choices")
            if q.correct_answer:
                print(f"Answer: {q.correct_answer}")

        # Save questions to JSON
        import json
        questions_json = []
        for q in questions:
            questions_json.append({
                'number': q.question_number,
                'text': q.question_text,
                'options': [{'number': opt.number, 'text': opt.text} for opt in q.options],
                'correct_answer': q.correct_answer,
                'explanation': q.explanation,
                'subject': q.subject,
                'topic': q.topic
            })

        with open('extracted_questions.json', 'w', encoding='utf-8') as f:
            json.dump(questions_json, f, ensure_ascii=False, indent=2)

        print(f"\n📝 {len(questions)} questions saved to: extracted_questions.json")

    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_pymupdf())