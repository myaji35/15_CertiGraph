#!/usr/bin/env python3
import sys
sys.path.insert(0, '/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/lib/python_parsers')

from exam_pdf_parser_v2 import ExamPDFParser
import json

pdf_path = '/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/제19회 사회복지사 1급_1교시_B형.pdf'

print("=" * 80)
print("🐍 Python Parser Direct Test")
print("=" * 80)
print()

parser = ExamPDFParser(pdf_path)
parser.extract_text()
parser.identify_sections()
questions = parser.parse_questions()

print(f"Total questions parsed: {len(questions)}")
print()

# Check passage extraction
with_passage = sum(1 for q in questions if q.passage)
print(f"Questions with passage: {with_passage}/{len(questions)} ({with_passage/len(questions)*100:.1f}%)")
print()

# Show first 5 questions
print("=" * 80)
print("Sample Questions (first 5)")
print("=" * 80)
print()

for q in questions[:5]:
    print(f"Q{q.number}: {q.question[:80]}")
    print(f"  Passage items: {len(q.passage)}")
    if q.passage:
        for p in q.passage[:2]:
            print(f"    {p.marker}: {p.text[:60]}...")
    print()

# Check JSON output format
print("=" * 80)
print("JSON Output Sample")
print("=" * 80)
json_output = parser.to_json()
data = json.loads(json_output)
print(f"Total in JSON: {len(data['questions'])}")
print()
print("First question JSON:")
print(json.dumps(data['questions'][0], ensure_ascii=False, indent=2))
