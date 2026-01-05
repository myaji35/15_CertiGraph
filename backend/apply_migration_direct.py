#!/usr/bin/env python3
"""Apply study materials migration directly to PostgreSQL."""
import os
import psycopg2
from dotenv import load_dotenv
from urllib.parse import urlparse

load_dotenv()

# Parse Supabase connection string
supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_SERVICE_KEY")

# Construct PostgreSQL connection string
# Format: postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres
# Extract project ref from SUPABASE_URL (https://[PROJECT_REF].supabase.co)
parsed = urlparse(supabase_url)
project_ref = parsed.hostname.split('.')[0]

print("=" * 80)
print("📊 Applying Study Materials Migration")
print("=" * 80)
print(f"Project: {project_ref}")
print()

# For security, ask for password
db_password = input("Enter Supabase Database Password: ")

conn_string = f"postgresql://postgres:{db_password}@db.{project_ref}.supabase.co:5432/postgres"

try:
    # Connect to database
    print("\n🔌 Connecting to database...")
    conn = psycopg2.connect(conn_string)
    conn.autocommit = False
    cursor = conn.cursor()

    # Read migration SQL
    with open("migration_study_materials.sql", "r") as f:
        migration_sql = f.read()

    print("✅ Connected successfully")
    print(f"📝 Executing migration...\n")

    # Execute migration
    cursor.execute(migration_sql)

    # Commit transaction
    conn.commit()

    print("✅ Migration applied successfully!")
    print()

    # Verify tables exist
    cursor.execute("""
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name IN ('study_materials', 'study_sets')
        ORDER BY table_name;
    """)

    tables = cursor.fetchall()
    print("📋 Verified tables:")
    for table in tables:
        print(f"  ✓ {table[0]}")

    cursor.close()
    conn.close()

    print("\n" + "=" * 80)
    print("✅ Migration completed successfully!")
    print("=" * 80)

except psycopg2.Error as e:
    print(f"\n❌ Database error: {e}")
    if 'conn' in locals():
        conn.rollback()
        conn.close()

except FileNotFoundError:
    print("\n❌ migration_study_materials.sql not found")

except Exception as e:
    print(f"\n❌ Error: {e}")
    if 'conn' in locals():
        conn.rollback()
        conn.close()
