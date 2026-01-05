"""Mock repository for study materials (PDF files within study sets)."""

import uuid
import json
import os
from datetime import datetime
from typing import Optional, Any


# Persistent storage file
MOCK_DATA_FILE = "/tmp/certigraph_mock_materials.json"


class MockStudyMaterialRepository:
    """File-based mock repository for study materials."""

    def __init__(self):
        self._storage: dict[str, dict] = {}
        self._load_data()

    def _load_data(self):
        """Load data from file if exists."""
        if os.path.exists(MOCK_DATA_FILE):
            try:
                with open(MOCK_DATA_FILE, 'r') as f:
                    self._storage = json.load(f)
            except Exception as e:
                print(f"Failed to load mock materials data: {e}")

    def _save_data(self):
        """Save data to file."""
        try:
            with open(MOCK_DATA_FILE, 'w') as f:
                json.dump(self._storage, f)
        except Exception as e:
            print(f"Failed to save mock materials data: {e}")

    async def create(
        self,
        study_set_id: str,
        clerk_id: str,
        title: str,
        pdf_url: str,
        pdf_hash: Optional[str] = None,
        file_size_bytes: Optional[int] = None,
    ) -> dict[str, Any]:
        """Create a new study material."""
        material_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()

        material = {
            "id": material_id,
            "study_set_id": study_set_id,
            "clerk_id": clerk_id,
            "title": title,
            "pdf_url": pdf_url,
            "pdf_hash": pdf_hash,
            "file_size_bytes": file_size_bytes,
            "status": "uploaded",
            "total_questions": 0,
            "processing_progress": 0,
            "processing_error": None,
            "processing_logs": [],  # 처리 과정 상세 로그
            "graphrag_status": "not_started",
            "graphrag_progress": 0,
            "graphrag_error": None,
            "created_at": now,
            "updated_at": now,
            "processed_at": None,
        }

        self._storage[material_id] = material
        self._save_data()
        return material

    async def find_by_id(self, material_id: str) -> Optional[dict[str, Any]]:
        """Find material by ID."""
        return self._storage.get(material_id)

    async def find_by_study_set(
        self,
        study_set_id: str,
        skip: int = 0,
        limit: int = 100,
    ) -> list[dict[str, Any]]:
        """Find all materials for a study set."""
        materials = [
            m for m in self._storage.values()
            if m["study_set_id"] == study_set_id
        ]
        return sorted(materials, key=lambda x: x["created_at"], reverse=True)[
            skip : skip + limit
        ]

    async def update_status(
        self,
        material_id: str,
        status: str,
        total_questions: int = 0,
        processing_progress: int = 0,
        processing_error: Optional[str] = None,
        log_message: Optional[str] = None,
    ) -> Optional[dict[str, Any]]:
        """Update material processing status."""
        material = self._storage.get(material_id)
        if not material:
            return None

        material["status"] = status
        material["total_questions"] = total_questions
        material["processing_progress"] = processing_progress
        material["processing_error"] = processing_error
        material["updated_at"] = datetime.utcnow().isoformat()

        # 로그 추가
        if log_message:
            if "processing_logs" not in material:
                material["processing_logs"] = []
            material["processing_logs"].append({
                "timestamp": datetime.utcnow().isoformat(),
                "progress": processing_progress,
                "message": log_message,
                "status": status
            })

        if status == "completed":
            material["processed_at"] = datetime.utcnow().isoformat()

        self._save_data()
        return material

    async def count_by_study_set(self, study_set_id: str) -> int:
        """Count materials in a study set."""
        count = sum(1 for m in self._storage.values()
                   if m["study_set_id"] == study_set_id)
        return count

    async def get_total_questions(self, study_set_id: str) -> int:
        """Get total questions count for a study set."""
        materials = [m for m in self._storage.values()
                    if m["study_set_id"] == study_set_id]
        total = sum(m.get("total_questions", 0) for m in materials)
        return total

    async def delete(self, material_id: str) -> bool:
        """Delete a material."""
        if material_id in self._storage:
            del self._storage[material_id]
            self._save_data()
            return True
        return False

    async def count_by_study_set(self, study_set_id: str) -> int:
        """Count materials in a study set."""
        return len([
            m for m in self._storage.values()
            if m["study_set_id"] == study_set_id
        ])

    async def get_total_questions(self, study_set_id: str) -> int:
        """Get total questions across all materials in a study set."""
        materials = await self.find_by_study_set(study_set_id)
        return sum(m.get("total_questions", 0) for m in materials)

    async def update_graphrag_status(
        self,
        material_id: str,
        graphrag_status: str,
        graphrag_progress: int = 0,
        graphrag_error: Optional[str] = None,
    ) -> Optional[dict[str, Any]]:
        """Update material graphRAG processing status."""
        material = self._storage.get(material_id)
        if not material:
            return None

        material["graphrag_status"] = graphrag_status
        material["graphrag_progress"] = graphrag_progress
        material["graphrag_error"] = graphrag_error
        material["updated_at"] = datetime.utcnow().isoformat()

        self._save_data()
        return material
