#!/usr/bin/env python3
"""Delete user profile to force re-creation with real email from Clerk API."""
from supabase import create_client

supabase_url = "https://ahtyeydsrndmqxlcaavm.supabase.co"
supabase_key = "sb_secret_RUgB-ojdJ4Uiyi_ZKY3GCg_1oMljnuu"

supabase = create_client(supabase_url, supabase_key)

# Delete existing user profile
result = supabase.table("user_profiles").delete().eq(
    "clerk_id", "user_36T9Qa8HsuaM1fMjTisw4frRH1Z"
).execute()

print(f"✅ Deleted user profile. Result: {result}")
print("Now log out and log back in to create a new profile with the real email!")
