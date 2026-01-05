"""Check if user exists in Supabase database."""
import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

# Check for myaji35@gmail.com
email = "myaji35@gmail.com"

print(f"🔍 Searching for user: {email}")
print(f"📍 Supabase URL: {SUPABASE_URL}")
print()

# Query user_profiles table
try:
    response = supabase.table("user_profiles").select("*").eq("email", email).execute()

    if response.data:
        print(f"✅ User found in user_profiles!")
        for user in response.data:
            print(f"\nUser details:")
            print(f"  - clerk_id: {user.get('clerk_id')}")
            print(f"  - email: {user.get('email')}")
            print(f"  - created_at: {user.get('created_at')}")
    else:
        print(f"❌ User NOT found in user_profiles table")
        print(f"\nLet's check all users in the table:")
        all_users = supabase.table("user_profiles").select("email, clerk_id").limit(10).execute()
        if all_users.data:
            print(f"\nFound {len(all_users.data)} users:")
            for u in all_users.data:
                print(f"  - {u.get('email')} (clerk_id: {u.get('clerk_id')})")
        else:
            print("  No users found in database")

except Exception as e:
    print(f"❌ Error querying database: {e}")
