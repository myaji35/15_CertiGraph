#!/usr/bin/env python3
"""Apply migration using Supabase Admin API."""
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_SERVICE_KEY")

supabase = create_client(supabase_url, supabase_key)

print("=" * 80)
print("📊 Creating study_materials table")
print("=" * 80)

try:
    # Method 1: Try using table creation through Supabase client
    # Create study_materials table
    print("\n✨ Attempting to create study_materials table...")

    # Check if study_materials table exists
    try:
        result = supabase.table("study_materials").select("id").limit(1).execute()
        print("✅ study_materials table already exists!")
    except Exception as e:
        if "relation" in str(e).lower() and "does not exist" in str(e).lower():
            print("❌ Table doesn't exist - needs manual creation")
            print("\n📋 Please manually run migration_study_materials.sql in Supabase SQL Editor")
        else:
            print(f"⚠️  Error checking table: {e}")

    # Check if study_sets has new columns
    print("\n✨ Checking study_sets table structure...")
    try:
        result = supabase.table("study_sets").select("id, exam_date_id, total_materials, total_questions").limit(1).execute()
        print("✅ study_sets table has new columns!")
    except Exception as e:
        print(f"❌ study_sets missing new columns: {e}")
        print("\n📋 Please manually run migration_study_materials.sql in Supabase SQL Editor")

    print("\n" + "=" * 80)
    print("📝 Manual migration steps:")
    print("=" * 80)
    print("1. Open: https://app.supabase.com")
    print("2. Select your project")
    print("3. Go to SQL Editor")
    print("4. Run the contents of: migration_study_materials.sql")
    print("=" * 80)

except Exception as e:
    print(f"\n❌ Error: {e}")
