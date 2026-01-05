#!/usr/bin/env python3
"""Verify that certification and exam date data exists in Supabase."""
from supabase import create_client
import os
from dotenv import load_dotenv

load_dotenv()

supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_SERVICE_KEY")

supabase = create_client(supabase_url, supabase_key)

print("=" * 80)
print("📊 Supabase Data Verification")
print("=" * 80)

# Check certifications
try:
    certs = supabase.table("certifications").select("*").execute()
    print(f"\n✅ Found {len(certs.data)} certifications:")
    for cert in certs.data:
        print(f"   - {cert['name']} (ID: {cert['id']})")
except Exception as e:
    print(f"\n❌ Error fetching certifications: {e}")

# Check exam_dates
try:
    exam_dates = supabase.table("exam_dates").select("*").execute()
    print(f"\n✅ Found {len(exam_dates.data)} exam dates:")
    for ed in exam_dates.data:
        print(f"   - Exam Date: {ed['exam_date']} (Cert ID: {ed['certification_id']})")
except Exception as e:
    print(f"\n❌ Error fetching exam_dates: {e}")

# Check with JOIN (like the API does)
try:
    print("\n📋 Testing API-style JOIN query:")
    result = supabase.table("certifications") \
        .select("id, name, exam_dates(id, exam_date, registration_start, registration_end)") \
        .execute()

    print(f"✅ JOIN query successful! Found {len(result.data)} certifications with exam dates:")
    for cert in result.data:
        print(f"\n  📌 {cert['name']}:")
        if cert.get('exam_dates'):
            for ed in cert['exam_dates']:
                print(f"     • {ed['exam_date']} (ID: {ed['id']})")
        else:
            print("     ⚠️  No exam dates")

except Exception as e:
    print(f"\n❌ Error with JOIN query: {e}")

print("\n" + "=" * 80)
