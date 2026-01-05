"""Questions API endpoints - View extracted questions from study materials."""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from app.api.v1.deps import CurrentUser

router = APIRouter(prefix="/questions", tags=["Questions"])


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
