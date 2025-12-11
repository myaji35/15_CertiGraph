"""
Plane Project Management Integration Service
Connects CertiGraph development tasks to Plane issues
"""
import httpx
from typing import Optional, Dict, Any, List
from app.core.config import get_settings


class PlaneIntegration:
    """Service for interacting with Plane API"""

    def __init__(self):
        self.settings = get_settings()
        self.base_url = self.settings.plane_api_url
        self.api_key = self.settings.plane_api_key
        self.workspace = self.settings.plane_workspace
        self.project_id = self.settings.plane_project_id

    def _get_headers(self) -> Dict[str, str]:
        """Get authentication headers for Plane API"""
        return {
            "X-API-Key": self.api_key,
            "Content-Type": "application/json"
        }

    async def create_work_item(
        self,
        title: str,
        description: str = "",
        priority: str = "medium",
        state: Optional[str] = None,
        labels: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """
        Create a new work item (issue) in Plane

        Args:
            title: Work item title
            description: Detailed description
            priority: Priority level (low, medium, high, urgent)
            state: State ID (optional)
            labels: List of label IDs (optional)

        Returns:
            Created work item data
        """
        if not self.api_key:
            raise ValueError("Plane API key not configured")

        url = f"{self.base_url}/workspaces/{self.workspace}/projects/{self.project_id}/work-items/"

        payload = {
            "name": title,
            "description_html": description,
            "priority": priority,
        }

        if state:
            payload["state_id"] = state
        if labels:
            payload["label_ids"] = labels

        async with httpx.AsyncClient() as client:
            response = await client.post(
                url,
                json=payload,
                headers=self._get_headers(),
                timeout=30.0
            )
            response.raise_for_status()
            return response.json()

    async def list_work_items(
        self,
        per_page: int = 20,
        cursor: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        List work items from the project

        Args:
            per_page: Number of items per page (max 100)
            cursor: Pagination cursor

        Returns:
            List of work items with pagination info
        """
        if not self.api_key:
            raise ValueError("Plane API key not configured")

        url = f"{self.base_url}/workspaces/{self.workspace}/projects/{self.project_id}/work-items/"
        params = {"per_page": min(per_page, 100)}

        if cursor:
            params["cursor"] = cursor

        async with httpx.AsyncClient() as client:
            response = await client.get(
                url,
                params=params,
                headers=self._get_headers(),
                timeout=30.0
            )
            response.raise_for_status()
            return response.json()

    async def get_project_info(self) -> Dict[str, Any]:
        """Get project information"""
        if not self.api_key:
            raise ValueError("Plane API key not configured")

        url = f"{self.base_url}/workspaces/{self.workspace}/projects/{self.project_id}/"

        async with httpx.AsyncClient() as client:
            response = await client.get(
                url,
                headers=self._get_headers(),
                timeout=30.0
            )
            response.raise_for_status()
            return response.json()

    async def create_development_task(
        self,
        feature_name: str,
        description: str,
        task_type: str = "feature"
    ) -> Dict[str, Any]:
        """
        Create a development task for CertiGraph features

        Args:
            feature_name: Name of the feature
            description: Technical description
            task_type: Type of task (feature, bug, enhancement)

        Returns:
            Created work item
        """
        priority_map = {
            "feature": "medium",
            "bug": "high",
            "enhancement": "low"
        }

        title = f"[{task_type.upper()}] {feature_name}"
        priority = priority_map.get(task_type, "medium")

        return await self.create_work_item(
            title=title,
            description=description,
            priority=priority
        )


# Singleton instance
_plane_integration: Optional[PlaneIntegration] = None


def get_plane_integration() -> PlaneIntegration:
    """Get or create PlaneIntegration singleton"""
    global _plane_integration
    if _plane_integration is None:
        _plane_integration = PlaneIntegration()
    return _plane_integration
