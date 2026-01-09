"""Check study sets in the database."""

import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Check if using Cloud SQL or Supabase
use_cloud_sql = os.getenv("USE_CLOUD_SQL", "false").lower() == "true"
use_postgres = os.getenv("USE_POSTGRES", "false").lower() == "true"

print(f"USE_CLOUD_SQL: {use_cloud_sql}")
print(f"USE_POSTGRES: {use_postgres}")
print(f"Database configuration:")

if use_cloud_sql or use_postgres:
    # Using PostgreSQL
    print("- Using PostgreSQL")

    import psycopg2
    from psycopg2.extras import RealDictCursor

    # Database connection parameters
    db_config = {
        "host": os.getenv("CLOUD_SQL_HOST", "localhost"),
        "port": os.getenv("CLOUD_SQL_PORT", "5433"),
        "database": os.getenv("CLOUD_SQL_DATABASE", "certigraph"),
        "user": os.getenv("CLOUD_SQL_USER", "certigraph_user"),
        "password": os.getenv("CLOUD_SQL_PASSWORD", ""),
    }

    print(f"  Host: {db_config['host']}")
    print(f"  Port: {db_config['port']}")
    print(f"  Database: {db_config['database']}")
    print(f"  User: {db_config['user']}")

    try:
        # Connect to PostgreSQL
        conn = psycopg2.connect(**db_config, cursor_factory=RealDictCursor)
        cur = conn.cursor()

        # Check if study_sets table exists
        cur.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables
                WHERE table_schema = 'public'
                AND table_name = 'study_sets'
            );
        """)
        table_exists = cur.fetchone()['exists']

        if table_exists:
            print("\n✅ study_sets table exists")

            # Get total count
            cur.execute("SELECT COUNT(*) as count FROM study_sets")
            count = cur.fetchone()['count']
            print(f"\n📊 Total study sets: {count}")

            # Get all study sets with details
            cur.execute("""
                SELECT
                    id,
                    user_id,
                    name,
                    certification_id,
                    status,
                    created_at,
                    total_materials,
                    total_questions
                FROM study_sets
                ORDER BY created_at DESC
                LIMIT 10
            """)

            study_sets = cur.fetchall()

            if study_sets:
                print("\n📚 Recent study sets:")
                print("-" * 80)
                for ss in study_sets:
                    print(f"ID: {ss['id'][:8]}...")
                    print(f"  User: {ss['user_id']}")
                    print(f"  Name: {ss['name']}")
                    print(f"  Certification: {ss['certification_id']}")
                    print(f"  Status: {ss['status']}")
                    print(f"  Materials: {ss['total_materials'] or 0}")
                    print(f"  Questions: {ss['total_questions'] or 0}")
                    print(f"  Created: {ss['created_at']}")
                    print("-" * 80)
            else:
                print("\n⚠️ No study sets found in the database")

            # Check for specific user's study sets
            user_id = "user_36T9Qa8HsuaM1fMjTisw4frRH1Z"  # myaji35@gmail.com
            cur.execute("""
                SELECT COUNT(*) as count
                FROM study_sets
                WHERE user_id = %s
            """, (user_id,))
            user_count = cur.fetchone()['count']
            print(f"\n👤 Study sets for user {user_id}: {user_count}")

            if user_count > 0:
                cur.execute("""
                    SELECT id, name, created_at
                    FROM study_sets
                    WHERE user_id = %s
                    ORDER BY created_at DESC
                """, (user_id,))
                user_sets = cur.fetchall()
                for ss in user_sets:
                    print(f"  - {ss['name']} (created: {ss['created_at']})")

        else:
            print("\n❌ study_sets table does NOT exist")

            # Check what tables do exist
            cur.execute("""
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
                ORDER BY table_name
            """)
            tables = cur.fetchall()

            if tables:
                print("\n📋 Available tables:")
                for table in tables:
                    print(f"  - {table['table_name']}")
            else:
                print("\n⚠️ No tables found in the public schema")

        cur.close()
        conn.close()

    except Exception as e:
        print(f"\n❌ Database connection error: {e}")

else:
    # Using Supabase
    print("- Using Supabase")
    from supabase import create_client

    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_KEY")

    if not supabase_url or not supabase_key:
        print("❌ Supabase credentials not configured")
        sys.exit(1)

    supabase = create_client(supabase_url, supabase_key)

    try:
        # Get all study sets
        response = supabase.table("study_sets").select("*").execute()

        print(f"\n📊 Total study sets: {len(response.data)}")

        if response.data:
            print("\n📚 Study sets:")
            for ss in response.data[:10]:
                print(f"  - {ss['name']} (user: {ss['user_id']})")
        else:
            print("\n⚠️ No study sets found")

    except Exception as e:
        print(f"\n❌ Supabase error: {e}")