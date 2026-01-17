"""
Schema Migration from Supabase to Cloud SQL
Exports schema from Supabase and applies it to Cloud SQL
"""

import os
import subprocess
from dotenv import load_dotenv
import psycopg2

load_dotenv()

def export_supabase_schema():
    """Export schema from Supabase using pg_dump"""
    supabase_url = os.getenv("SUPABASE_URL")
    if not supabase_url:
        raise ValueError("SUPABASE_URL not found in environment")

    # Extract connection details from Supabase URL
    # Format: https://xxx.supabase.co
    project_id = supabase_url.replace("https://", "").replace(".supabase.co", "")

    # Supabase connection string format
    db_host = f"db.{project_id}.supabase.co"
    db_name = "postgres"
    db_user = "postgres"
    db_password = os.getenv("SUPABASE_DB_PASSWORD")  # You need to get this from Supabase dashboard

    print(f"Exporting schema from Supabase ({db_host})...")

    # Run pg_dump to export schema only (no data)
    dump_file = "/tmp/certigraph_schema.sql"
    cmd = [
        "pg_dump",
        f"--host={db_host}",
        f"--port=5432",
        f"--username={db_user}",
        f"--dbname={db_name}",
        "--schema-only",
        "--no-owner",
        "--no-privileges",
        f"--file={dump_file}"
    ]

    env = os.environ.copy()
    env["PGPASSWORD"] = db_password

    try:
        subprocess.run(cmd, env=env, check=True)
        print(f"Schema exported to {dump_file}")
        return dump_file
    except subprocess.CalledProcessError as e:
        print(f"Error exporting schema: {e}")
        return None


def apply_schema_to_cloud_sql(schema_file):
    """Apply schema to Cloud SQL"""
    # Read Cloud SQL connection details from environment
    db_host = os.getenv("CLOUD_SQL_HOST", "localhost")  # localhost if using Cloud SQL Proxy
    db_port = os.getenv("CLOUD_SQL_PORT", "5432")
    db_name = os.getenv("CLOUD_SQL_DATABASE", "certigraph")
    db_user = os.getenv("CLOUD_SQL_USER", "certigraph_user")
    db_password = os.getenv("CLOUD_SQL_PASSWORD")

    print(f"Applying schema to Cloud SQL ({db_host}:{db_port}/{db_name})...")

    try:
        # Connect to Cloud SQL
        conn = psycopg2.connect(
            host=db_host,
            port=db_port,
            database=db_name,
            user=db_user,
            password=db_password
        )

        # Read schema file
        with open(schema_file, 'r') as f:
            schema_sql = f.read()

        # Execute schema
        cursor = conn.cursor()
        cursor.execute(schema_sql)
        conn.commit()

        print("Schema applied successfully!")

        # Verify tables
        cursor.execute("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            ORDER BY table_name
        """)

        tables = cursor.fetchall()
        print(f"\nCreated {len(tables)} tables:")
        for table in tables:
            print(f"  - {table[0]}")

        cursor.close()
        conn.close()

    except Exception as e:
        print(f"Error applying schema: {e}")
        return False

    return True


def main():
    print("=== CertiGraph Schema Migration ===\n")

    # Option 1: Export from Supabase
    print("Choose migration method:")
    print("1. Export schema from Supabase (requires SUPABASE_DB_PASSWORD)")
    print("2. Use existing schema file")
    choice = input("Enter choice (1 or 2): ").strip()

    if choice == "1":
        schema_file = export_supabase_schema()
        if not schema_file:
            print("Failed to export schema")
            return
    else:
        schema_file = input("Enter path to schema file: ").strip()
        if not os.path.exists(schema_file):
            print(f"File not found: {schema_file}")
            return

    # Apply to Cloud SQL
    success = apply_schema_to_cloud_sql(schema_file)

    if success:
        print("\n✅ Schema migration completed successfully!")
        print("\nNext steps:")
        print("  1. Run data migration: python scripts/gcp/3_migrate_data.py")
    else:
        print("\n❌ Schema migration failed")


if __name__ == "__main__":
    main()
