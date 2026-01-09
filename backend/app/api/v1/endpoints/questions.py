"""Questions API endpoints - View extracted questions from study materials."""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from app.api.v1.deps import CurrentUser, get_supabase, SettingsDep

router = APIRouter(prefix="/questions", tags=["Questions"])


@router.get("")
async def get_questions(
    material_id: Optional[str] = Query(None, description="Filter by material ID"),
    concept: Optional[str] = Query(None, description="Filter by concept"),
    difficulty: Optional[str] = Query(None, description="Filter by difficulty level"),
    limit: Optional[int] = Query(50, description="Maximum number of questions to return"),
    offset: Optional[int] = Query(0, description="Number of questions to skip"),
    current_user: CurrentUser = None,
    settings: SettingsDep = None,
    supabase=Depends(get_supabase)
):
    """
    Get questions with optional filtering.

    Supports filtering by:
    - material_id: Get questions from a specific material
    - concept: Filter by concept/topic
    - difficulty: Filter by difficulty level (easy/medium/hard)
    """
    # In dev/test mode, return mock data
    if settings and (settings.dev_mode or settings.test_mode):
        from app.repositories.mock_question import MockQuestionRepository
        question_repo = MockQuestionRepository()

        # Get mock questions (assuming study_set_id for mock)
        questions = await question_repo.get_by_study_set("mock_study_set_1")

        # Apply filters
        if material_id:
            questions = [q for q in questions if q.get("material_id") == material_id]
        if concept:
            questions = [q for q in questions if concept in (q.get("concepts") or [])]
        if difficulty:
            questions = [q for q in questions if q.get("difficulty") == difficulty]

        # Apply pagination
        total_count = len(questions)
        questions = questions[offset:offset + limit]

        return {
            "success": True,
            "questions": questions,
            "total_count": total_count,
            "returned_count": len(questions),
            "offset": offset,
            "limit": limit
        }

    # Real implementation with Supabase
    try:
        query = supabase.table("questions").select("*")

        # Apply filters
        if material_id:
            query = query.eq("material_id", material_id)
        if concept:
            query = query.contains("concepts", [concept])
        if difficulty:
            query = query.eq("difficulty", difficulty)

        # Apply pagination
        query = query.range(offset, offset + limit - 1)

        response = query.execute()

        return {
            "success": True,
            "questions": response.data or [],
            "total_count": len(response.data) if response.data else 0,
            "returned_count": len(response.data) if response.data else 0,
            "offset": offset,
            "limit": limit
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch questions: {str(e)}"
        )


@router.get("/material/{material_id}")
async def get_questions_by_material(
    material_id: str,
    current_user: CurrentUser = None,
):
    """
    Get all questions extracted from a study material.

    This allows users to view the questions that were parsed from their PDF.
    """
    from app.repositories.mock_study_material import MockStudyMaterialRepository
    from app.repositories.mock_question import MockQuestionRepository

    # Verify material exists and belongs to user
    material_repo = MockStudyMaterialRepository()
    material = await material_repo.find_by_id(material_id)

    if not material:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Study material not found"
        )

    if material["clerk_id"] != current_user.clerk_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to view these questions"
        )

    # Get questions
    question_repo = MockQuestionRepository()
    questions = await question_repo.get_by_study_set(material_id)

    return {
        "success": True,
        "material_id": material_id,
        "material_title": material.get("title"),
        "questions": questions,
        "total_count": len(questions)
    }


@router.get("/study-set/{study_set_id}")
async def get_questions_by_study_set(
    study_set_id: str,
    limit: Optional[int] = None,
    current_user: CurrentUser = None,
):
    """
    Get all questions from all materials in a study set.

    This aggregates questions across multiple PDF files uploaded to the same study set.
    """
    from app.repositories.mock_study_set import MockStudySetRepository
    from app.repositories.mock_study_material import MockStudyMaterialRepository
    from app.repositories.mock_question import MockQuestionRepository

    # Verify study set exists and belongs to user
    study_set_repo = MockStudySetRepository()
    study_set = await study_set_repo.find_by_id(study_set_id)

    if not study_set:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Study set not found"
        )

    if study_set["user_id"] != current_user.clerk_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to view these questions"
        )

    # Get all materials in this study set
    material_repo = MockStudyMaterialRepository()
    materials = await material_repo.find_by_study_set(study_set_id)

    # Get questions from all materials
    question_repo = MockQuestionRepository()
    all_questions = []

    for material in materials:
        questions = await question_repo.get_by_study_set(material["id"])
        # Add material info to each question
        for q in questions:
            q["material_title"] = material.get("title")
        all_questions.extend(questions)

    # Sort by question number
    all_questions.sort(key=lambda x: (x.get("material_id", ""), x.get("question_number", 0)))

    if limit:
        all_questions = all_questions[:limit]

    return {
        "success": True,
        "study_set_id": study_set_id,
        "study_set_name": study_set.get("name"),
        "questions": all_questions,
        "total_count": len(all_questions),
        "materials_count": len(materials)
    }
