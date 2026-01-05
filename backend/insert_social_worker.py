#!/usr/bin/env python3
"""Insert 사회복지사 1급 certification and 2026-01-17 exam date."""
from supabase import create_client
import os
from dotenv import load_dotenv

load_dotenv()

supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_SERVICE_KEY")

supabase = create_client(supabase_url, supabase_key)

# Insert 사회복지사 1급 certification
cert_data = {
    "id": "d1e1f1a1-4444-4444-4444-444444444444",
    "name": "사회복지사 1급",
    "description": "사회복지 분야 국가자격증",
    "provider": "한국산업인력공단"
}

try:
    # Upsert certification
    cert_result = supabase.table("certifications").upsert(cert_data).execute()
    print(f"✅ Certification inserted/updated: {cert_result.data}")

    # Insert exam date for 2026-01-17
    exam_date_data = {
        "certification_id": "d1e1f1a1-4444-4444-4444-444444444444",
        "exam_date": "2026-01-17",
        "registration_start": "2025-11-15",
        "registration_end": "2025-12-15"
    }

    exam_date_result = supabase.table("exam_dates").insert(exam_date_data).execute()
    print(f"✅ Exam date inserted: {exam_date_result.data}")

    # Verify
    verify_result = supabase.table("certifications") \
        .select("*, exam_dates(*)") \
        .eq("name", "사회복지사 1급") \
        .execute()

    print("\n📋 Verification:")
    for cert in verify_result.data:
        print(f"  - 자격증: {cert['name']}")
        print(f"  - 제공기관: {cert['provider']}")
        print(f"  - 시험일정:")
        for exam in cert.get('exam_dates', []):
            print(f"    • {exam['exam_date']} (접수: {exam['registration_start']} ~ {exam['registration_end']})")

except Exception as e:
    print(f"❌ Error: {e}")
