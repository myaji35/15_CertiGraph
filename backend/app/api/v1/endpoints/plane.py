"""
Plane Project Management Integration Endpoints
"""
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from app.services.plane_integration import get_plane_integration, PlaneIntegration
from app.api.v1.deps import get_current_user_id
from app.core.inngest_client import inngest_client


router = APIRouter(prefix="/plane", tags=["plane"])


class CreateWorkItemRequest(BaseModel):
    """Request model for creating a work item"""
    title: str
    description: str = ""
    priority: str = "medium"
    state: Optional[str] = None
    labels: Optional[List[str]] = None


class CreateDevelopmentTaskRequest(BaseModel):
    """Request model for creating a development task"""
    feature_name: str
    description: str
    task_type: str = "feature"


@router.post("/work-items")
async def create_work_item(
    request: CreateWorkItemRequest,
    user_id: str = Depends(get_current_user_id)
):
    """Create a new work item in Plane (triggers background job)"""
    try:
        # Send event to Inngest for background processing
        await inngest_client.send(
            inngest_client.event(
                name="plane/work-item.create",
                data={
                    "title": request.title,
                    "description": request.description,
                    "priority": request.priority,
                    "state": request.state,
                    "labels": request.labels,
                    "user_id": user_id
                }
            )
        )
        return {
            "success": True,
            "message": "Work item creation initiated",
            "status": "processing"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to trigger work item creation: {str(e)}")


@router.get("/work-items")
async def list_work_items(
    per_page: int = 20,
    cursor: Optional[str] = None,
    user_id: str = Depends(get_current_user_id),
    plane: PlaneIntegration = Depends(get_plane_integration)
):
    """List work items from Plane project (synchronous for immediate response)"""
    try:
        # Note: Keeping this synchronous as listing is a read operation
        # that users expect immediate results from
        result = await plane.list_work_items(per_page=per_page, cursor=cursor)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list work items: {str(e)}")


@router.get("/project")
async def get_project_info(
    user_id: str = Depends(get_current_user_id),
    plane: PlaneIntegration = Depends(get_plane_integration)
):
    """Get Plane project information (synchronous for immediate response)"""
    try:
        # Note: Keeping this synchronous as it's a read operation
        result = await plane.get_project_info()
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get project info: {str(e)}")


@router.post("/development-tasks")
async def create_development_task(
    request: CreateDevelopmentTaskRequest,
    user_id: str = Depends(get_current_user_id)
):
    """Create a development task for CertiGraph features (triggers background job)"""
    try:
        # Send event to Inngest for background processing
        await inngest_client.send(
            inngest_client.event(
                name="plane/development-task.create",
                data={
                    "feature_name": request.feature_name,
                    "description": request.description,
                    "task_type": request.task_type,
                    "user_id": user_id
                }
            )
        )
        return {
            "success": True,
            "message": "Development task creation initiated",
            "status": "processing"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to trigger development task creation: {str(e)}")
