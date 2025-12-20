"""Analysis API endpoints."""

import logging
from fastapi import APIRouter
from typing import Any

from app.api.v1.deps import CurrentUser
from app.core.config import get_settings
from app.services.analysis import WeaknessAnalyzer, DashboardService, ExamPredictionService

logger = logging.getLogger(__name__)
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


@router.get("/progress")
async def get_user_progress(
    current_user: CurrentUser,
) -> dict[str, Any]:
    """
    Get user's learning progress from Knowledge Graph.

    Returns:
        - Total concepts in the system
        - Mastered concepts count
        - Weak concepts count
        - Untested concepts count
        - Weak concepts with details
    """
    settings = get_settings()

    # Default empty result
    result = {
        "total_concepts": 0,
        "mastered_count": 0,
        "weak_count": 0,
        "untested_count": 0,
        "weak_concepts": [],
    }

    # Get progress from Neo4j if configured
    if settings.neo4j_uri:
        try:
            from app.repositories.neo4j_concepts import Neo4jConceptRepository
            neo4j_repo = Neo4jConceptRepository()

            # Get overall progress
            progress = await neo4j_repo.get_user_progress(current_user.clerk_id)
            result.update(progress)

            # Get detailed weak concepts
            weak_concepts = await neo4j_repo.get_weak_concepts(
                current_user.clerk_id,
                limit=10,
            )
            result["weak_concepts"] = weak_concepts

            await neo4j_repo.close()

        except Exception as e:
            logger.error(f"Failed to get progress from Neo4j: {e}")

    return {"data": result}
