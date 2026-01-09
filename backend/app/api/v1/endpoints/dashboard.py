"""Dashboard endpoints for user statistics and analytics."""

from fastapi import APIRouter, Depends
from typing import List, Dict, Any
from datetime import datetime, timedelta

from app.api.v1.deps import CurrentUser, get_supabase, SettingsDep

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/stats")
async def get_dashboard_stats(
    current_user: CurrentUser,
    settings: SettingsDep,
    supabase=Depends(get_supabase)
) -> Dict[str, Any]:
    """
    Get user dashboard statistics.

    Returns:
        - total_questions: Total questions attempted
        - correct_answers: Number of correct answers
        - accuracy_percentage: Overall accuracy
        - study_days: Number of days studied
    """
    # Return mock data for now (dev/test mode)
    if settings.dev_mode or settings.test_mode:
        return {
            "total_questions": 150,
            "correct_answers": 120,
            "accuracy_percentage": 80.0,
            "study_days": 15,
            "last_study_date": datetime.utcnow().isoformat()
        }

    # TODO: Real implementation with Supabase queries
    # Query study_history table to get actual statistics
    try:
        # Placeholder for actual query
        return {
            "total_questions": 0,
            "correct_answers": 0,
            "accuracy_percentage": 0.0,
            "study_days": 0,
            "last_study_date": None
        }
    except Exception as e:
        # Return empty stats on error
        return {
            "total_questions": 0,
            "correct_answers": 0,
            "accuracy_percentage": 0.0,
            "study_days": 0,
            "error": str(e)
        }


@router.get("/recent-activity")
async def get_recent_activity(
    current_user: CurrentUser,
    settings: SettingsDep,
    supabase=Depends(get_supabase)
) -> Dict[str, List[Dict[str, Any]]]:
    """
    Get user's recent study activity.

    Returns:
        List of recent activities with type, study_set, score, date
    """
    if settings.dev_mode or settings.test_mode:
        return {
            "activities": [
                {
                    "type": "test_completed",
                    "study_set_name": "정보처리기사 - 데이터베이스",
                    "score": 85,
                    "date": (datetime.utcnow() - timedelta(hours=2)).isoformat(),
                    "questions_count": 20
                },
                {
                    "type": "test_completed",
                    "study_set_name": "정보처리기사 - 네트워크",
                    "score": 70,
                    "date": (datetime.utcnow() - timedelta(days=1)).isoformat(),
                    "questions_count": 15
                },
                {
                    "type": "study_set_created",
                    "study_set_name": "SQLD 모의고사",
                    "date": (datetime.utcnow() - timedelta(days=2)).isoformat()
                }
            ]
        }

    # TODO: Query study_history and study_sets tables
    return {"activities": []}


@router.get("/weak-concepts")
async def get_weak_concepts(
    current_user: CurrentUser,
    settings: SettingsDep,
    supabase=Depends(get_supabase)
) -> Dict[str, List[Dict[str, Any]]]:
    """
    Get user's weak concepts based on test performance.

    Returns:
        List of weak concepts with name and accuracy percentage
    """
    if settings.dev_mode or settings.test_mode:
        return {
            "weak_concepts": [
                {
                    "concept": "데이터베이스 정규화",
                    "accuracy": 45.0,
                    "questions_attempted": 10,
                    "correct_count": 4
                },
                {
                    "concept": "네트워크 프로토콜",
                    "accuracy": 60.0,
                    "questions_attempted": 15,
                    "correct_count": 9
                },
                {
                    "concept": "운영체제 스케줄링",
                    "accuracy": 55.0,
                    "questions_attempted": 8,
                    "correct_count": 4
                }
            ]
        }

    # TODO: Analyze question_attempts table grouped by concept
    return {"weak_concepts": []}


@router.get("/study-progress")
async def get_study_progress(
    current_user: CurrentUser,
    settings: SettingsDep,
    supabase=Depends(get_supabase)
) -> Dict[str, Any]:
    """
    Get user's overall study progress.

    Returns:
        Progress information including materials completed, current progress
    """
    if settings.dev_mode or settings.test_mode:
        return {
            "total_materials": 5,
            "completed_materials": 3,
            "progress_percentage": 60.0,
            "total_questions": 250,
            "attempted_questions": 150,
            "mastered_questions": 120
        }

    # TODO: Query study_sets and study_materials tables
    try:
        # Get user's study sets
        study_sets = supabase.table("study_sets") \
            .select("*") \
            .eq("user_id", current_user.clerk_id) \
            .execute()

        total_materials = len(study_sets.data) if study_sets.data else 0
        completed_materials = sum(1 for s in (study_sets.data or []) if s.get("status") == "completed")

        return {
            "total_materials": total_materials,
            "completed_materials": completed_materials,
            "progress_percentage": (completed_materials / total_materials * 100) if total_materials > 0 else 0.0,
            "total_questions": 0,  # TODO: Count questions
            "attempted_questions": 0,
            "mastered_questions": 0
        }
    except Exception as e:
        return {
            "total_materials": 0,
            "completed_materials": 0,
            "progress_percentage": 0.0,
            "error": str(e)
        }
