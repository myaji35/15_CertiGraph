"""
Database session configuration for Cloud SQL PostgreSQL
Replaces Supabase client with SQLAlchemy
"""

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.core.config import get_settings

settings = get_settings()

# Database URL format: postgresql://user:password@host:port/database
# When using Cloud SQL Proxy, host will be localhost
DATABASE_URL = (
    f"postgresql://{settings.cloud_sql_user}:{settings.cloud_sql_password}"
    f"@{settings.cloud_sql_host}:{settings.cloud_sql_port}/{settings.cloud_sql_database}"
)

# Create SQLAlchemy engine
engine = create_engine(
    DATABASE_URL,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,  # Verify connections before using
    echo=settings.dev_mode  # Log SQL queries in dev mode
)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for ORM models
Base = declarative_base()


def get_db():
    """
    Dependency for getting database session.

    Usage:
        @router.get("/endpoint")
        async def endpoint(db: Session = Depends(get_db)):
            # Use db session here
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
