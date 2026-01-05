from fastapi import APIRouter

from app.api.v1.deps import CurrentUser
from app.api.v1.endpoints import (
    study_sets_router,
    study_materials_router,
    questions_router,
    tests_router,
    analysis_router,
    certifications_router,
    external_certifications_router,
    plane_router,
    payment_router,
    trial_router,
    subscriptions_router,
    mlflow_tracking_router,
    admin_router
)

api_router = APIRouter()

# Include routers
api_router.include_router(study_sets_router)
api_router.include_router(study_materials_router)
api_router.include_router(questions_router)
api_router.include_router(tests_router)
api_router.include_router(analysis_router)
api_router.include_router(certifications_router)
api_router.include_router(external_certifications_router, prefix="/external-certifications", tags=["External Certifications"])
api_router.include_router(plane_router)
api_router.include_router(payment_router, prefix="/payment", tags=["Payment"])
api_router.include_router(trial_router, prefix="/trial", tags=["Free Trial"])
api_router.include_router(subscriptions_router, prefix="/subscriptions", tags=["Subscriptions"])
api_router.include_router(mlflow_tracking_router, prefix="/mlflow", tags=["MLflow Tracking"])
api_router.include_router(admin_router)


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
