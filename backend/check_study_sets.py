"""Check study sets for myaji35@gmail.com"""
import os
import sys

# Add backend to path
sys.path.insert(0, os.path.dirname(__file__))

from supabase import create_client

# Direct credentials (from .env)
SUPABASE_URL = "https://njlcnbqpmmzyugnufzca.supabase.co"
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")

if not SUPABASE_SERVICE_KEY:
    # Try to read from .env file
    env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
    with open(env_path, 'r') as f:
        for line in f:
            if line.startswith("SUPABASE_SERVICE_KEY"):
                SUPABASE_SERVICE_KEY = line.split("=", 1)[1].strip()
                break

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

email = "myaji35@gmail.com"

print(f"🔍 Checking study sets for: {email}\n")

# 1. Find user
user_response = supabase.table("user_profiles").select("clerk_id, email").eq("email", email).execute()

if not user_response.data:
    print(f"❌ User {email} not found in user_profiles table")
    print("\n📋 All users in database:")
    all_users = supabase.table("user_profiles").select("email").execute()
    for u in all_users.data[:10]:
        print(f"  - {u['email']}")
    sys.exit(1)

user = user_response.data[0]
clerk_id = user["clerk_id"]
print(f"✅ User found: {email}")
print(f"   Clerk ID: {clerk_id}\n")

# 2. Check study sets
study_sets_response = supabase.table("study_sets").select("*").eq("user_id", clerk_id).execute()

if not study_sets_response.data:
    print(f"❌ No study sets found for this user")
    print(f"\n📚 Total study sets in database: {len(supabase.table('study_sets').select('id').execute().data)}")
else:
    print(f"✅ Found {len(study_sets_response.data)} study set(s):\n")
    for study_set in study_sets_response.data:
        print(f"  📖 {study_set['title']}")
        print(f"     ID: {study_set['id']}")
        print(f"     PDF: {study_set.get('pdf_name', 'N/A')}")
        print(f"     Created: {study_set['created_at']}")
        print(f"     Question count: {study_set.get('question_count', 0)}")
        print()
