"""Study materials endpoints - PDF files within study sets."""

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from typing import List
from datetime import datetime

from app.api.v1.deps import CurrentUser
from app.core import get_settings

router = APIRouter(prefix="/study-materials", tags=["Study Materials"])


@router.post("/{study_set_id}/upload")
async def upload_study_material(
    study_set_id: str,
    title: str = Form(...),
    file: UploadFile = File(...),
    current_user: CurrentUser = None,
):
    """
    Upload a PDF file as a study material to a study set.

    This creates a new study_material record and starts processing.
    Multiple materials can be uploaded to the same study set.
    """
    from app.repositories.mock_study_material import MockStudyMaterialRepository
    from app.repositories.mock_study_set import MockStudySetRepository
    import hashlib

    settings = get_settings()

    # Validate file type
    if file.content_type != "application/pdf":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only PDF files are allowed"
        )

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
            detail="You don't have permission to add materials to this study set"
        )

    # Read file content
    file_content = await file.read()
    file_size = len(file_content)

    # Calculate hash
    pdf_hash = hashlib.sha256(file_content).hexdigest()

    # Save file to disk
    import os
    # Go up 5 levels: endpoints -> v1 -> api -> app -> backend
    backend_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))))
    uploads_dir = os.path.join(backend_dir, "uploads", "materials")
    os.makedirs(uploads_dir, exist_ok=True)

    file_path = os.path.join(uploads_dir, f"{pdf_hash}.pdf")
    with open(file_path, "wb") as f:
        f.write(file_content)

    pdf_url = f"/uploads/materials/{pdf_hash}.pdf"

    # Create material record
    material_repo = MockStudyMaterialRepository()
    material = await material_repo.create(
        study_set_id=study_set_id,
        clerk_id=current_user.clerk_id,
        title=title,
        pdf_url=pdf_url,
        pdf_hash=pdf_hash,
        file_size_bytes=file_size,
    )

    # Update study set counts
    material_count = await material_repo.count_by_study_set(study_set_id)
    total_questions = await material_repo.get_total_questions(study_set_id)
    await study_set_repo.update_material_counts(
        study_set_id,
        material_count,
        total_questions
    )

    # Trigger background processing
    from fastapi import BackgroundTasks
    from app.services.pdf_processor import SimplePDFProcessor
    from app.repositories.mock_question import MockQuestionRepository

    async def process_pdf_background():
        """Background task to process PDF."""
        processor = SimplePDFProcessor()
        question_repo = MockQuestionRepository()

        async def update_progress(status, progress, message):
            """Update material processing status."""
            await material_repo.update_status(
                material["id"],
                status=status,
                processing_progress=progress,
                log_message=message  # 로그 메시지 추가
            )
            logger.info(f"📊 Progress update: {progress}% - {message}")

        # Process the PDF
        result = await processor.process_pdf(
            material["id"],
            file_content,
            title,
            update_progress
        )

        if result["success"]:
            # Save questions to repository
            questions = result["questions"]
            study_set_id = material["study_set_id"]

            # Store questions grouped by material_id
            await question_repo.bulk_create(material["id"], questions)

            # Update material with question count
            await material_repo.update_status(
                material["id"],
                status="completed",
                total_questions=len(questions),
                processing_progress=100
            )

            # Update study set counts
            material_count = await material_repo.count_by_study_set(study_set_id)
            total_questions = await material_repo.get_total_questions(study_set_id)
            await study_set_repo.update_material_counts(
                study_set_id,
                material_count,
                total_questions
            )

            logger.info(f"✅ Background processing completed: {len(questions)} questions")
        else:
            await material_repo.update_status(
                material["id"],
                status="failed",
                processing_progress=0,
                processing_error=result.get("error")
            )
            logger.error(f"❌ Background processing failed: {result.get('error')}")

    # Start background processing
    import asyncio
    import logging
    logger = logging.getLogger(__name__)

    # Run in background (FastAPI will handle this)
    asyncio.create_task(process_pdf_background())

    return {
        "success": True,
        "material": material,
        "message": "학습자료가 업로드되었습니다. 문제 파싱이 시작됩니다."
    }


@router.get("/{study_set_id}")
async def get_study_materials(
    study_set_id: str,
    current_user: CurrentUser = None,
):
    """Get all materials for a study set."""
    from app.repositories.mock_study_material import MockStudyMaterialRepository
    from app.repositories.mock_study_set import MockStudySetRepository

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
            detail="You don't have permission to view this study set"
        )

    # Get materials
    material_repo = MockStudyMaterialRepository()
    materials = await material_repo.find_by_study_set(study_set_id)

    return {
        "materials": materials,
        "total_count": len(materials)
    }


@router.delete("/{material_id}")
async def delete_study_material(
    material_id: str,
    current_user: CurrentUser = None,
):
    """Delete a study material."""
    from app.repositories.mock_study_material import MockStudyMaterialRepository
    from app.repositories.mock_study_set import MockStudySetRepository

    material_repo = MockStudyMaterialRepository()
    material = await material_repo.find_by_id(material_id)

    if not material:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Material not found"
        )

    if material["clerk_id"] != current_user.clerk_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to delete this material"
        )

    study_set_id = material["study_set_id"]

    # Delete material
    await material_repo.delete(material_id)

    # Update study set counts
    study_set_repo = MockStudySetRepository()
    material_count = await material_repo.count_by_study_set(study_set_id)
    total_questions = await material_repo.get_total_questions(study_set_id)
    await study_set_repo.update_material_counts(
        study_set_id,
        material_count,
        total_questions
    )

    return {
        "success": True,
        "message": "학습자료가 삭제되었습니다."
    }


@router.post("/{material_id}/graphrag")
async def start_graphrag_processing(
    material_id: str,
    current_user: CurrentUser = None,
):
    """
    Start GraphRAG processing for a study material.

    This creates a knowledge graph from the questions in the material.
    """
    from app.repositories.mock_study_material import MockStudyMaterialRepository
    from app.repositories.mock_question import MockQuestionRepository
    import asyncio
    import logging

    logger = logging.getLogger(__name__)
    material_repo = MockStudyMaterialRepository()

    # Verify material exists and belongs to user
    material = await material_repo.find_by_id(material_id)

    if not material:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Material not found"
        )

    if material["clerk_id"] != current_user.clerk_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to process this material"
        )

    # Check if material has been processed (has questions)
    if material["status"] != "completed" or material["total_questions"] == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Material must be processed and have questions before GraphRAG can be generated"
        )

    # Check if already processing or completed
    if material.get("graphrag_status") == "processing":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="GraphRAG processing is already in progress"
        )

    # Start GraphRAG processing in background
    async def process_graphrag_background():
        """Background task to process GraphRAG."""
        try:
            # Update status to processing
            await material_repo.update_graphrag_status(
                material_id,
                graphrag_status="processing",
                graphrag_progress=0
            )

            logger.info(f"🧠 Starting GraphRAG processing for material {material_id}")

            # Get questions from repository
            question_repo = MockQuestionRepository()
            questions = await question_repo.get_by_material(material_id)

            if not questions:
                raise Exception("No questions found for material")

            logger.info(f"📚 Found {len(questions)} questions to analyze")

            # Simulate GraphRAG processing (in real implementation, this would:
            # 1. Extract concepts from each question
            # 2. Build relationships between concepts
            # 3. Create knowledge graph in Neo4j
            # 4. Calculate importance scores
            # For now, we'll just simulate the process
            import time
            total_steps = 5

            for step in range(total_steps):
                await asyncio.sleep(1)  # Simulate processing time
                progress = int((step + 1) / total_steps * 100)
                await material_repo.update_graphrag_status(
                    material_id,
                    graphrag_status="processing",
                    graphrag_progress=progress
                )
                logger.info(f"📊 GraphRAG progress: {progress}%")

            # Mark as completed
            await material_repo.update_graphrag_status(
                material_id,
                graphrag_status="completed",
                graphrag_progress=100
            )

            logger.info(f"✅ GraphRAG processing completed for material {material_id}")

        except Exception as e:
            logger.error(f"❌ GraphRAG processing failed: {str(e)}")
            await material_repo.update_graphrag_status(
                material_id,
                graphrag_status="failed",
                graphrag_progress=0,
                graphrag_error=str(e)
            )

    # Start background processing
    asyncio.create_task(process_graphrag_background())

    return {
        "success": True,
        "message": "지식 그래프 생성이 시작되었습니다.",
        "material_id": material_id
    }
