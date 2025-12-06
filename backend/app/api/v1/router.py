from fastapi import APIRouter

from app.api.v1.deps import CurrentUser
from app.api.v1.endpoints import study_sets_router, tests_router, analysis_router

api_router = APIRouter()

# Include routers
api_router.include_router(study_sets_router)
api_router.include_router(tests_router)
api_router.include_router(analysis_router)


# Health check for API v1
@api_router.get("/health")
async def api_health():
    """API v1 health check."""
    return {"status": "healthy", "api_version": "v1"}


# Protected endpoint example
@api_router.get("/me")
async def get_current_user_info(current_user: CurrentUser):
    """Get current authenticated user info."""
    return {
        "data": {
            "clerk_id": current_user.clerk_id,
            "email": current_user.email,
        }
    }
