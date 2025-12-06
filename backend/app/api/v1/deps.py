"""FastAPI dependencies for authentication and common resources."""

from typing import Annotated

from fastapi import Depends, Header

from app.core import get_settings, Settings
from app.core.security import verify_clerk_token, ClerkUser
from app.core.exceptions import AuthMissingTokenError


# Settings dependency
SettingsDep = Annotated[Settings, Depends(get_settings)]


async def get_current_user(
    authorization: str | None = Header(default=None, alias="Authorization")
) -> ClerkUser:
    """
    Dependency to get the current authenticated user from Clerk JWT.

    Args:
        authorization: The Authorization header value (Bearer <token>)

    Returns:
        ClerkUser object with user information

    Raises:
        AuthMissingTokenError: If no token provided
        AuthInvalidTokenError: If token is invalid
        AuthExpiredTokenError: If token has expired
    """
    if not authorization:
        raise AuthMissingTokenError()

    # Extract token from "Bearer <token>"
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise AuthMissingTokenError()

    token = parts[1]

    # Verify token and get payload
    payload = await verify_clerk_token(token)

    return ClerkUser(payload)


# Type alias for dependency injection
CurrentUser = Annotated[ClerkUser, Depends(get_current_user)]
