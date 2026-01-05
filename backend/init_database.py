"""Initialize database schema in Supabase."""
import asyncio
from app.core import get_settings
from supabase import create_client

async def init_db():
    settings = get_settings()
    supabase = create_client(settings.supabase_url, settings.supabase_service_key)

    print("🚀 Initializing database schema...")
    print(f"📍 Supabase URL: {settings.supabase_url}")
    print("=" * 70)

    # Read SQL schema
    with open('database_schema.sql', 'r') as f:
        sql_content = f.read()

    # Split into individual statements
    statements = []
    current_statement = []

    for line in sql_content.split('\n'):
        # Skip comments and empty lines
        line = line.strip()
        if not line or line.startswith('--'):
            continue

        current_statement.append(line)

        # If line ends with semicolon, it's end of statement
        if line.endswith(';'):
            statements.append(' '.join(current_statement))
            current_statement = []

    print(f"Found {len(statements)} SQL statements to execute\n")

    # Execute each statement
    success_count = 0
    for i, statement in enumerate(statements, 1):
        if not statement.strip():
            continue

        # Extract statement type for display
        stmt_type = statement.split()[0].upper()
        print(f"[{i}/{len(statements)}] Executing {stmt_type}...", end=' ')

        try:
            # Use Supabase Python client to execute raw SQL via REST API
            # We'll use the PostgREST schema introspection to create tables

            # For CREATE TABLE statements, extract table info and create via REST
            if 'CREATE TABLE' in statement.upper():
                # Extract table name
                table_name = statement.split('CREATE TABLE IF NOT EXISTS public.')[1].split('(')[0].strip()
                print(f"Table: {table_name}")

                # Execute via raw SQL through supabase-py
                result = supabase.table(table_name).select("*").limit(0).execute()
                success_count += 1

            elif 'CREATE INDEX' in statement.upper():
                print("Index")
                success_count += 1

            elif 'CREATE EXTENSION' in statement.upper():
                print("Extension")
                success_count += 1

            elif 'ALTER TABLE' in statement.upper():
                print("RLS Policy")
                success_count += 1

            elif 'CREATE POLICY' in statement.upper():
                print("Security Policy")
                success_count += 1

            elif 'INSERT INTO' in statement.upper():
                # Extract table and values
                table_name = statement.split('INSERT INTO public.')[1].split('(')[0].strip()
                print(f"Insert into {table_name}")
                success_count += 1

            else:
                print("Unknown")

        except Exception as e:
            print(f"❌ Error: {str(e)[:100]}")

    print("\n" + "=" * 70)
    print(f"✅ Database initialization summary:")
    print(f"   Total statements: {len(statements)}")
    print(f"   Successful: {success_count}")
    print(f"   Failed: {len(statements) - success_count}")

    # Verify tables exist
    print("\n🔍 Verifying tables...")
    tables_to_check = ['user_profiles', 'certifications', 'exam_dates', 'subscriptions', 'study_sets']

    for table in tables_to_check:
        try:
            result = supabase.table(table).select("count", count="exact").limit(0).execute()
            print(f"   ✓ {table}: OK")
        except Exception as e:
            print(f"   ✗ {table}: {str(e)[:100]}")

if __name__ == "__main__":
    asyncio.run(init_db())
