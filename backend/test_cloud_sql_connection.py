#!/usr/bin/env python3
"""Test Cloud SQL connection"""
import sys
import os

# Add backend directory to path
sys.path.insert(0, os.path.dirname(__file__))

from app.core.config import get_settings
from app.db.session import get_db

async def test_connection():
    """Test database connection"""
    settings = get_settings()

    print(f"\n=== Cloud SQL Configuration ===")
    print(f"USE_CLOUD_SQL: {settings.use_cloud_sql}")
    print(f"Host: {settings.cloud_sql_host}")
    print(f"Port: {settings.cloud_sql_port}")
    print(f"Database: {settings.cloud_sql_database}")
    print(f"User: {settings.cloud_sql_user}")
    print(f"Connection Name: {settings.cloud_sql_connection_name}")

    if not settings.use_cloud_sql:
        print("\n❌ ERROR: USE_CLOUD_SQL is False!")
        print("Please set USE_CLOUD_SQL=true in .env file")
        return False

    print("\n=== Testing Database Connection ===")

    try:
        # Get database session
        db_gen = get_db()
        db = next(db_gen)

        # Test query
        result = db.execute("SELECT 1 as test")
        row = result.fetchone()

        if row and row[0] == 1:
            print("✅ Database connection successful!")

            # List tables
            result = db.execute("""
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
                ORDER BY table_name
            """)
            tables = result.fetchall()

            print(f"\n📊 Found {len(tables)} tables:")
            for table in tables:
                print(f"  - {table[0]}")

            return True
        else:
            print("❌ Unexpected query result")
            return False

    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        try:
            db_gen.close()
        except:
            pass

if __name__ == "__main__":
    import asyncio
    result = asyncio.run(test_connection())
    sys.exit(0 if result else 1)
