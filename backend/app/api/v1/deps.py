"""FastAPI dependencies for authentication and common resources."""

from typing import Annotated

from fastapi import Depends, Header
from supabase import create_client, Client

from app.core import get_settings, Settings
from app.core.security import verify_clerk_token, ClerkUser
from app.core.exceptions import AuthMissingTokenError
from app.repositories.study_set import StudySetRepository
from app.repositories.mock_study_set import MockStudySetRepository
from app.services.storage import StorageService
from app.services.mock_storage import MockStorageService


# Settings dependency
SettingsDep = Annotated[Settings, Depends(get_settings)]


async def get_current_user(
    authorization: str | None = Header(default=None, alias="Authorization"),
    settings: Settings = Depends(get_settings)
) -> ClerkUser:
    """
    Dependency to get the current authenticated user from Clerk JWT.

    Args:
        authorization: The Authorization header value (Bearer <token>)
        settings: Application settings

    Returns:
        ClerkUser object with user information

    Raises:
        AuthMissingTokenError: If no token provided
        AuthInvalidTokenError: If token is invalid
        AuthExpiredTokenError: If token has expired
    """
    # Development mode bypass
    if settings.dev_mode:
        return ClerkUser({
            "sub": "dev_user_123",
            "email": "dev@example.com"
        })

    if not authorization:
        raise AuthMissingTokenError()

    # Extract token from "Bearer <token>"
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise AuthMissingTokenError()

    token = parts[1]

    # Verify token and get payload
    payload = await verify_clerk_token(token)

    clerk_user = ClerkUser(payload)

    # Auto-register user in user_profiles table if not exists
    try:
        supabase = create_client(settings.supabase_url, settings.supabase_service_key)

        # Check if user exists
        existing_user = supabase.table("user_profiles") \
            .select("clerk_id") \
            .eq("clerk_id", clerk_user.clerk_id) \
            .execute()

        # If user doesn't exist, create profile
        if not existing_user.data:
            from datetime import datetime
            supabase.table("user_profiles").insert({
                "clerk_id": clerk_user.clerk_id,
                "email": clerk_user.email,
                "created_at": datetime.utcnow().isoformat(),
            }).execute()
    except Exception as e:
        # Log error but don't fail authentication
        print(f"Failed to auto-register user {clerk_user.email}: {e}")

    return clerk_user


# Type alias for dependency injection
CurrentUser = Annotated[ClerkUser, Depends(get_current_user)]


async def get_current_user_id(current_user: CurrentUser) -> str:
    """
    Dependency to get just the current user ID.

    Args:
        current_user: The current authenticated user

    Returns:
        User ID string
    """
    return current_user.clerk_id


# Repository dependency - returns Mock in dev mode, real repo in production
def get_study_set_repository(settings: Settings = Depends(get_settings)):
    """Get study set repository (mock in dev mode, real in production)."""
    # Check if USE_POSTGRES env var is set to force PostgreSQL usage
    import os
    use_postgres = os.getenv("USE_POSTGRES", "false").lower() == "true"

    if use_postgres:
        # Use real PostgreSQL repository
        return StudySetRepository()
    elif settings.dev_mode:
        # Singleton instance for dev mode
        if not hasattr(get_study_set_repository, "_mock_instance"):
            get_study_set_repository._mock_instance = MockStudySetRepository()
        return get_study_set_repository._mock_instance
    return StudySetRepository()


StudySetRepo = Annotated[
    StudySetRepository | MockStudySetRepository, Depends(get_study_set_repository)
]


# Storage dependency
def get_storage_service(settings: Settings = Depends(get_settings)):
    """Get storage service (mock in dev mode, real in production)."""
    if settings.dev_mode:
        # Singleton instance for dev mode to persist uploaded files in memory
        if not hasattr(get_storage_service, "_mock_instance"):
            get_storage_service._mock_instance = MockStorageService()
        return get_storage_service._mock_instance
    return StorageService()


StorageServiceDep = Annotated[
    StorageService | MockStorageService, Depends(get_storage_service)
]


# Supabase dependency
def get_supabase(settings: Settings = Depends(get_settings)) -> Client:
    """Get Supabase client."""
    return create_client(settings.supabase_url, settings.supabase_service_role_key)
