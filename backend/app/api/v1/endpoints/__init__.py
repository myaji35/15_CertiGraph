"""API v1 endpoints."""

from .study_sets import router as study_sets_router
from .tests import router as tests_router
from .analysis import router as analysis_router
from .certifications import router as certifications_router
from .external_certifications import router as external_certifications_router

__all__ = ["study_sets_router", "tests_router", "analysis_router", "certifications_router", "external_certifications_router"]
