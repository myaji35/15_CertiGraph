#!/usr/bin/env python3
"""Check if user myaji35@gmail.com exists in the database."""
from supabase import create_client
import os
from dotenv import load_dotenv

load_dotenv()

supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_SERVICE_KEY")

supabase = create_client(supabase_url, supabase_key)

print("=" * 80)
print("👤 User Check: myaji35@gmail.com")
print("=" * 80)

# Check user_profiles
try:
    user = supabase.table("user_profiles") \
        .select("*") \
        .eq("email", "myaji35@gmail.com") \
        .execute()

    if user.data:
        print(f"\n✅ User found in user_profiles:")
        for u in user.data:
            print(f"   - Clerk ID: {u['clerk_id']}")
            print(f"   - Email: {u['email']}")
            print(f"   - Created: {u.get('created_at', 'N/A')}")
    else:
        print("\n❌ User NOT found in user_profiles table")

except Exception as e:
    print(f"\n❌ Error checking user_profiles: {e}")

# Check subscriptions for this user
try:
    # First get clerk_id if user exists
    user_result = supabase.table("user_profiles") \
        .select("clerk_id") \
        .eq("email", "myaji35@gmail.com") \
        .execute()

    if user_result.data:
        clerk_id = user_result.data[0]['clerk_id']

        subs = supabase.table("subscriptions") \
            .select("*, certifications(name), exam_dates(exam_date)") \
            .eq("user_id", clerk_id) \
            .execute()

        print(f"\n📋 Subscriptions for this user: {len(subs.data)}")
        for sub in subs.data:
            cert_name = sub.get('certifications', {}).get('name', 'N/A') if sub.get('certifications') else 'N/A'
            exam_date = sub.get('exam_dates', {}).get('exam_date', 'N/A') if sub.get('exam_dates') else 'N/A'
            print(f"   - Certification: {cert_name}")
            print(f"   - Exam Date: {exam_date}")
            print(f"   - Payment Method: {sub.get('payment_method', 'N/A')}")
            print(f"   - Created: {sub.get('created_at', 'N/A')}")
            print()

except Exception as e:
    print(f"\n❌ Error checking subscriptions: {e}")

print("=" * 80)
