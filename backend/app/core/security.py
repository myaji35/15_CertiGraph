"""Clerk JWT verification for FastAPI."""

import httpx
from jose import jwt, JWTError
from jose.exceptions import JWKError
from functools import lru_cache
from typing import Any
import time

from app.core.config import get_settings
from app.core.exceptions import AuthInvalidTokenError, AuthExpiredTokenError, AuthMissingTokenError


# Cache JWKS for 1 hour
_jwks_cache: dict[str, Any] = {}
_jwks_cache_time: float = 0
JWKS_CACHE_TTL = 3600  # 1 hour


async def get_jwks() -> dict[str, Any]:
    """Fetch and cache Clerk JWKS."""
    global _jwks_cache, _jwks_cache_time

    current_time = time.time()

    # Return cached JWKS if still valid
    if _jwks_cache and (current_time - _jwks_cache_time) < JWKS_CACHE_TTL:
        return _jwks_cache

    settings = get_settings()

    async with httpx.AsyncClient() as client:
        response = await client.get(settings.clerk_jwks_url)
        response.raise_for_status()
        _jwks_cache = response.json()
        _jwks_cache_time = current_time

    return _jwks_cache


def get_signing_key(jwks: dict[str, Any], token: str) -> dict[str, Any]:
    """Get the signing key from JWKS that matches the token's kid."""
    unverified_header = jwt.get_unverified_header(token)
    kid = unverified_header.get("kid")

    for key in jwks.get("keys", []):
        if key.get("kid") == kid:
            return key

    raise AuthInvalidTokenError()


async def verify_clerk_token(token: str) -> dict[str, Any]:
    """
    Verify a Clerk JWT token and return the payload.

    Args:
        token: The JWT token from Authorization header

    Returns:
        The decoded token payload containing user info

    Raises:
        AuthInvalidTokenError: If token is invalid
        AuthExpiredTokenError: If token has expired
    """
    try:
        # Get JWKS
        jwks = await get_jwks()

        # Get the signing key
        signing_key = get_signing_key(jwks, token)

        # Verify and decode the token
        payload = jwt.decode(
            token,
            signing_key,
            algorithms=["RS256"],
            options={
                "verify_aud": False,  # Clerk doesn't always set audience
                "verify_iss": False,  # We trust our JWKS URL
            }
        )

        return payload

    except jwt.ExpiredSignatureError:
        raise AuthExpiredTokenError()
    except (JWTError, JWKError, KeyError):
        raise AuthInvalidTokenError()


class ClerkUser:
    """Represents an authenticated Clerk user."""

    def __init__(self, payload: dict[str, Any]):
        self.clerk_id: str = payload.get("sub", "")
        self.email: str | None = payload.get("email")
        self.session_id: str | None = payload.get("sid")
        self.raw_payload = payload

    def __repr__(self) -> str:
        return f"ClerkUser(clerk_id={self.clerk_id}, email={self.email})"
