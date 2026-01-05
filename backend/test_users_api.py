#!/usr/bin/env python3
"""Test direct Supabase query for user_profiles."""
import os
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

print("=" * 80)
print("Testing user_profiles query")
print("=" * 80)
print(f"\nSupabase URL: {SUPABASE_URL}")
print(f"Has Service Key: {bool(SUPABASE_KEY)}")

# Try using requests instead
import requests

headers = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}"
}

# Query user_profiles
url = f"{SUPABASE_URL}/rest/v1/user_profiles?select=*"
print(f"\nQuerying: {url}")

response = requests.get(url, headers=headers)
print(f"Status: {response.status_code}")
print(f"Response: {response.text[:500]}")

if response.status_code == 200:
    users = response.json()
    print(f"\n✅ Found {len(users)} users")
    for user in users:
        print(f"  - {user.get('email', 'N/A')} (clerk_id: {user.get('clerk_id', 'N/A')})")
else:
    print(f"\n❌ Error: {response.status_code}")
    print(response.text)

# Query subscriptions
print("\n" + "=" * 80)
url = f"{SUPABASE_URL}/rest/v1/subscriptions?select=*,certifications(name),exam_dates(exam_date)"
print(f"\nQuerying: {url}")

response = requests.get(url, headers=headers)
print(f"Status: {response.status_code}")
print(f"Response: {response.text[:500]}")

if response.status_code == 200:
    subs = response.json()
    print(f"\n✅ Found {len(subs)} subscriptions")
    for sub in subs:
        print(f"  - User ID: {sub.get('user_id', 'N/A')}")
        print(f"    Method: {sub.get('payment_method', 'N/A')}")
        print(f"    Cert: {sub.get('certifications', {}).get('name', 'N/A')}")
        print()
else:
    print(f"\n❌ Error: {response.status_code}")
    print(response.text)

print("=" * 80)
