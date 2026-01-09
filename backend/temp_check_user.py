"""Temporary script to check user's study sets"""
import asyncio
import os
import sys

# Set up path
sys.path.insert(0, os.path.dirname(__file__))

async def main():
    from supabase import create_client
    from dotenv import load_dotenv

    load_dotenv()

    SUPABASE_URL = os.getenv("SUPABASE_URL")
    SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

    supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

    email = "myaji35@gmail.com"

    print(f"🔍 Checking study sets for: {email}\n")

    # 1. Find user
    user_response = supabase.table("user_profiles").select("clerk_id, email").eq("email", email).execute()

    if not user_response.data:
        print(f"❌ User {email} not found")
        return

    user = user_response.data[0]
    clerk_id = user["clerk_id"]
    print(f"✅ User found")
    print(f"   Clerk ID: {clerk_id}\n")

    # 2. Check study sets
    study_sets_response = supabase.table("study_sets").select("*").eq("user_id", clerk_id).execute()

    if not study_sets_response.data:
        print(f"❌ No study sets found")
        print(f"\n📊 Database totals:")
        print(f"   Total users: {len(supabase.table('user_profiles').select('id').execute().data)}")
        print(f"   Total study sets: {len(supabase.table('study_sets').select('id').execute().data)}")
    else:
        print(f"✅ Found {len(study_sets_response.data)} study set(s):\n")
        for idx, study_set in enumerate(study_sets_response.data, 1):
            print(f"  {idx}. {study_set['name']}")
            print(f"     ID: {study_set['id']}")
            print(f"     Status: {study_set.get('status', 'N/A')}")
            print(f"     Created: {study_set['created_at']}")
            print()

if __name__ == "__main__":
    asyncio.run(main())
