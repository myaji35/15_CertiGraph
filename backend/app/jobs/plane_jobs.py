"""
Inngest background jobs for Plane integration
"""
from typing import Any, Dict, List, Optional
from inngest import Inngest
from app.core.inngest_client import inngest_client
from app.services.plane_integration import get_plane_integration


@inngest_client.create_function(
    fn_id="plane-create-work-item",
    trigger=inngest_client.event("plane/work-item.create"),
    retries=3,
)
async def create_work_item_job(
    ctx: Any,
    step: Any,
) -> Dict[str, Any]:
    """
    Background job to create a work item in Plane

    Event data should include:
    - title: str
    - description: str (optional)
    - priority: str (optional, default: "medium")
    - state: str (optional)
    - labels: List[str] (optional)
    - user_id: str (for tracking)
    """
    event_data = ctx.event.data

    # Extract data from event
    title = event_data.get("title")
    description = event_data.get("description", "")
    priority = event_data.get("priority", "medium")
    state = event_data.get("state")
    labels = event_data.get("labels")
    user_id = event_data.get("user_id")

    # Get Plane integration
    plane = get_plane_integration()

    # Create work item with retry logic
    result = await step.run(
        "create-work-item",
        lambda: plane.create_work_item(
            title=title,
            description=description,
            priority=priority,
            state=state,
            labels=labels
        )
    )

    return {
        "success": True,
        "work_item": result,
        "user_id": user_id
    }


@inngest_client.create_function(
    fn_id="plane-list-work-items",
    trigger=inngest_client.event("plane/work-items.list"),
    retries=3,
)
async def list_work_items_job(
    ctx: Any,
    step: Any,
) -> Dict[str, Any]:
    """
    Background job to list work items from Plane

    Event data should include:
    - per_page: int (optional, default: 20)
    - cursor: str (optional)
    - user_id: str (for tracking)
    """
    event_data = ctx.event.data

    per_page = event_data.get("per_page", 20)
    cursor = event_data.get("cursor")
    user_id = event_data.get("user_id")

    plane = get_plane_integration()

    result = await step.run(
        "list-work-items",
        lambda: plane.list_work_items(per_page=per_page, cursor=cursor)
    )

    return {
        "success": True,
        "data": result,
        "user_id": user_id
    }


@inngest_client.create_function(
    fn_id="plane-get-project-info",
    trigger=inngest_client.event("plane/project.get"),
    retries=3,
)
async def get_project_info_job(
    ctx: Any,
    step: Any,
) -> Dict[str, Any]:
    """
    Background job to get project information from Plane

    Event data should include:
    - user_id: str (for tracking)
    """
    event_data = ctx.event.data
    user_id = event_data.get("user_id")

    plane = get_plane_integration()

    result = await step.run(
        "get-project-info",
        lambda: plane.get_project_info()
    )

    return {
        "success": True,
        "project": result,
        "user_id": user_id
    }


@inngest_client.create_function(
    fn_id="plane-create-development-task",
    trigger=inngest_client.event("plane/development-task.create"),
    retries=3,
)
async def create_development_task_job(
    ctx: Any,
    step: Any,
) -> Dict[str, Any]:
    """
    Background job to create a development task in Plane

    Event data should include:
    - feature_name: str
    - description: str
    - task_type: str (optional, default: "feature")
    - user_id: str (for tracking)
    """
    event_data = ctx.event.data

    feature_name = event_data.get("feature_name")
    description = event_data.get("description")
    task_type = event_data.get("task_type", "feature")
    user_id = event_data.get("user_id")

    plane = get_plane_integration()

    result = await step.run(
        "create-development-task",
        lambda: plane.create_development_task(
            feature_name=feature_name,
            description=description,
            task_type=task_type
        )
    )

    return {
        "success": True,
        "task": result,
        "user_id": user_id
    }
