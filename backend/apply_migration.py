#!/usr/bin/env python3
"""Apply study materials migration to Supabase."""
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_SERVICE_KEY")

supabase = create_client(supabase_url, supabase_key)

print("=" * 80)
print("📊 Applying Study Materials Migration")
print("=" * 80)

# Read migration SQL
with open("migration_study_materials.sql", "r") as f:
    migration_sql = f.read()

# Split into individual statements (rough split by semicolon at end of line)
statements = []
current_statement = []

for line in migration_sql.split('\n'):
    current_statement.append(line)
    if line.strip().endswith(';') and not line.strip().startswith('--'):
        statements.append('\n'.join(current_statement))
        current_statement = []

if current_statement:
    statements.append('\n'.join(current_statement))

print(f"\n📝 Found {len(statements)} SQL statements\n")

# Execute each statement
success_count = 0
error_count = 0

for i, statement in enumerate(statements, 1):
    statement = statement.strip()
    if not statement or statement.startswith('--') or statement == ';':
        continue

    # Show first 100 chars of statement
    preview = statement[:100].replace('\n', ' ')
    print(f"[{i}/{len(statements)}] Executing: {preview}...")

    try:
        # Note: Supabase Python client doesn't have direct SQL execution
        # We'll use the REST API via rpc if available, or need to use psycopg2
        print("  ⚠️  Need to apply this manually via Supabase SQL Editor")
        print(f"  Statement: {statement[:200]}")
        print()
    except Exception as e:
        print(f"  ❌ Error: {e}\n")
        error_count += 1

print("=" * 80)
print(f"✅ Migration script prepared")
print(f"⚠️  Please apply migration_study_materials.sql manually via Supabase SQL Editor")
print("=" * 80)
