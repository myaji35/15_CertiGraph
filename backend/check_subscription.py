#!/usr/bin/env python3
"""Check subscription for myaji35@gmail.com user."""
import os
import sys
from pathlib import Path

# Add parent directory to path to import app modules
sys.path.insert(0, str(Path(__file__).parent))

from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_SERVICE_KEY")

if not supabase_url or not supabase_key:
    print("❌ Missing Supabase credentials in .env")
    sys.exit(1)

supabase = create_client(supabase_url, supabase_key)

print("=" * 80)
print("🔍 Checking subscription for myaji35@gmail.com")
print("=" * 80)

# Get user's clerk_id
try:
    user_response = supabase.table("user_profiles") \
        .select("clerk_id, email") \
        .eq("email", "myaji35@gmail.com") \
        .execute()

    if not user_response.data:
        print("❌ User not found")
        sys.exit(1)

    clerk_id = user_response.data[0]["clerk_id"]
    print(f"\n✅ Found user: {clerk_id}")

except Exception as e:
    print(f"❌ Error finding user: {e}")
    sys.exit(1)

# Check subscriptions using the EXACT same query as /subscriptions/me endpoint
print(f"\n📋 Checking subscriptions (same query as /subscriptions/me)...")
try:
    response = supabase.table("subscriptions") \
        .select("id, certification_id, exam_date_id, payment_status, certifications(name), exam_dates(exam_date)") \
        .eq("clerk_id", clerk_id) \
        .eq("payment_status", "completed") \
        .order("created_at", desc=True) \
        .limit(1) \
        .execute()

    print(f"\n📊 Query result:")
    print(f"   - Records found: {len(response.data)}")

    if response.data:
        sub = response.data[0]
        print(f"\n✅ Subscription found:")
        print(f"   - ID: {sub.get('id')}")
        print(f"   - Certification ID: {sub.get('certification_id')}")
        print(f"   - Exam Date ID: {sub.get('exam_date_id')}")
        print(f"   - Payment Status: {sub.get('payment_status')}")
        print(f"   - Certification: {sub.get('certifications')}")
        print(f"   - Exam Date: {sub.get('exam_dates')}")
    else:
        print("\n❌ No subscription found with payment_status='completed'")

        # Check all subscriptions for this user
        all_subs = supabase.table("subscriptions") \
            .select("id, certification_id, exam_date_id, payment_status, payment_method") \
            .eq("clerk_id", clerk_id) \
            .execute()

        print(f"\n📋 All subscriptions for this user: {len(all_subs.data)}")
        for sub in all_subs.data:
            print(f"   - ID: {sub.get('id')}")
            print(f"   - Certification ID: {sub.get('certification_id')}")
            print(f"   - Payment Status: {sub.get('payment_status')}")
            print(f"   - Payment Method: {sub.get('payment_method')}")
            print()

except Exception as e:
    print(f"❌ Error checking subscriptions: {e}")
    import traceback
    traceback.print_exc()

print("=" * 80)
