#!/usr/bin/env python3
"""Check exam dates in the database."""
from supabase import create_client
import os
from dotenv import load_dotenv

load_dotenv()

supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_SERVICE_KEY")

supabase = create_client(supabase_url, supabase_key)

print("=" * 80)
print("📅 Exam Dates in Database")
print("=" * 80)

try:
    # Get all certifications with exam dates
    result = supabase.table("certifications") \
        .select("id, name, exam_dates(id, exam_date, registration_start, registration_end)") \
        .execute()

    if result.data:
        for cert in result.data:
            print(f"\n📌 {cert['name']}")
            print(f"   ID: {cert['id']}")

            exam_dates = cert.get('exam_dates', [])
            if exam_dates:
                print(f"   시험일 ({len(exam_dates)}개):")
                for ed in exam_dates:
                    print(f"      - {ed['exam_date']} (ID: {ed['id']})")
                    if ed.get('registration_start'):
                        print(f"        접수: {ed['registration_start']} ~ {ed['registration_end']}")
            else:
                print("   ⚠️  등록된 시험일 없음")
    else:
        print("\n❌ No certifications found")

except Exception as e:
    print(f"\n❌ Error: {e}")

print("\n" + "=" * 80)
