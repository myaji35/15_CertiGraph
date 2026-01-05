#!/usr/bin/env python3
"""Check study sets for a specific user."""
from supabase import create_client
import os
from dotenv import load_dotenv

load_dotenv()

supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_SERVICE_KEY")

supabase = create_client(supabase_url, supabase_key)

print("=" * 80)
print("📚 승식 회원의 문제집 리스트")
print("=" * 80)

# Search for user with "승식" in email or name
try:
    # First, try to find user by email containing "승식" or similar patterns
    users = supabase.table("user_profiles") \
        .select("*") \
        .execute()

    print(f"\n전체 사용자 수: {len(users.data)}")

    # Show all users to find the right one
    print("\n등록된 사용자 목록:")
    for user in users.data:
        print(f"  - Email: {user['email']}, Clerk ID: {user['clerk_id']}")

    # Try to find study sets for all users
    print("\n\n📋 모든 사용자의 문제집:")
    for user in users.data:
        study_sets = supabase.table("study_sets") \
            .select("*") \
            .eq("clerk_id", user['clerk_id']) \
            .execute()

        if study_sets.data:
            print(f"\n👤 {user['email']}:")
            for ss in study_sets.data:
                print(f"   📚 {ss.get('title', 'N/A')}")
                print(f"      - ID: {ss['id']}")
                print(f"      - 생성일: {ss.get('created_at', 'N/A')}")
                print(f"      - 문제 수: {ss.get('total_questions', 0)}")
                print()

except Exception as e:
    print(f"\n❌ Error: {e}")

print("=" * 80)
