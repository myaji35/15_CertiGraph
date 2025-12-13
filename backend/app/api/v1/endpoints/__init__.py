"""API v1 endpoints."""

from .study_sets import router as study_sets_router
from .tests import router as tests_router
from .analysis import router as analysis_router
from .certifications import router as certifications_router
from .external_certifications import router as external_certifications_router
from .plane import router as plane_router
from .payment import router as payment_router
from .trial import router as trial_router
from .subscriptions import router as subscriptions_router
from .mlflow_tracking import router as mlflow_tracking_router
from .admin import router as admin_router

__all__ = ["study_sets_router", "tests_router", "analysis_router", "certifications_router", "external_certifications_router", "plane_router", "payment_router", "trial_router", "subscriptions_router", "mlflow_tracking_router", "admin_router"]
