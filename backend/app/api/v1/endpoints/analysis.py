"""Analysis API endpoints."""

from fastapi import APIRouter
from typing import Any

from app.api.v1.deps import CurrentUser
from app.services.analysis import WeaknessAnalyzer, DashboardService, ExamPredictionService


router = APIRouter(prefix="/analysis", tags=["analysis"])


@router.get("/weak-concepts")
async def get_weak_concepts(
    current_user: CurrentUser,
) -> dict[str, Any]:
    """
    Get user's weak concept analysis.

    Analyzes test history to identify weak areas and provide
    personalized study recommendations.
    """
    analyzer = WeaknessAnalyzer()
    result = await analyzer.analyze(current_user.clerk_id)

    return {"data": result}


@router.get("/dashboard")
async def get_dashboard_stats(
    current_user: CurrentUser,
) -> dict[str, Any]:
    """
    Get aggregated dashboard statistics.

    Returns summary stats and recent activity for the user's dashboard.
    """
    service = DashboardService()
    result = await service.get_stats(current_user.clerk_id)

    return {"data": result}


@router.get("/exam-prediction")
async def get_exam_prediction(
    current_user: CurrentUser,
) -> dict[str, Any]:
    """
    Get exam pass prediction with 과락 analysis.

    Analyzes test history to predict exam pass probability,
    including per-subject cutoff (과락) risk assessment.
    """
    service = ExamPredictionService()
    result = await service.predict(current_user.clerk_id)

    return {"data": result}
