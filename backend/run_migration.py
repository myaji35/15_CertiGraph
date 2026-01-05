#!/usr/bin/env python3
"""Apply study materials migration using Supabase REST API."""
import os
import requests
from dotenv import load_dotenv

load_dotenv()

supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_SERVICE_KEY")

print("=" * 80)
print("📊 Applying Study Materials Migration via Supabase REST API")
print("=" * 80)
print(f"Supabase URL: {supabase_url}")
print()

# Read migration SQL
with open("migration_study_materials.sql", "r") as f:
    migration_sql = f.read()

print("📝 Migration SQL loaded")
print(f"📏 SQL length: {len(migration_sql)} characters")
print()
print("⚠️  NOTE: Supabase REST API doesn't support direct SQL execution.")
print("⚠️  Please follow these steps:")
print()
print("1. Go to Supabase Dashboard: https://app.supabase.com")
print("2. Select your project")
print("3. Go to 'SQL Editor' in the left sidebar")
print("4. Click 'New Query'")
print("5. Copy the contents of 'migration_study_materials.sql'")
print("6. Paste and click 'Run'")
print()
print("📋 Migration file location:")
print(f"   {os.path.abspath('migration_study_materials.sql')}")
print()
print("=" * 80)

# Alternative: Show the SQL content for easy copying
print("\n📄 SQL Content (copy this):")
print("=" * 80)
print(migration_sql)
print("=" * 80)
