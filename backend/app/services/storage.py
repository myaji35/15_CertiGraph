"""Supabase Storage service for file operations."""

import uuid
from typing import BinaryIO
import httpx

from app.core.config import get_settings


class StorageService:
    """Service for managing files in Supabase Storage."""

    BUCKET_NAME = "pdfs"

    def __init__(self):
        self.settings = get_settings()
        self.base_url = f"{self.settings.supabase_url}/storage/v1"
        self.headers = {
            "apikey": self.settings.supabase_service_key,
            "Authorization": f"Bearer {self.settings.supabase_service_key}",
        }

    async def upload_pdf(
        self,
        file: BinaryIO,
        user_id: str,
        content_type: str = "application/pdf"
    ) -> str:
        """
        Upload PDF file to Supabase Storage.

        Args:
            file: Binary file object
            user_id: User's ID for organizing files
            content_type: MIME type of the file

        Returns:
            Storage path of the uploaded file
        """
        # Generate unique filename
        file_id = str(uuid.uuid4())
        storage_path = f"{user_id}/{file_id}.pdf"

        # Read file content
        file.seek(0)
        content = file.read()
        file.seek(0)

        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/object/{self.BUCKET_NAME}/{storage_path}",
                headers={
                    **self.headers,
                    "Content-Type": content_type,
                },
                content=content,
            )
            response.raise_for_status()

        return storage_path

    async def get_public_url(self, storage_path: str) -> str:
        """
        Get public URL for a stored file.

        Args:
            storage_path: Path to the file in storage

        Returns:
            Public URL for the file
        """
        return f"{self.base_url}/object/public/{self.BUCKET_NAME}/{storage_path}"

    async def delete_file(self, storage_path: str) -> bool:
        """
        Delete a file from storage.

        Args:
            storage_path: Path to the file in storage

        Returns:
            True if deleted successfully
        """
        async with httpx.AsyncClient() as client:
            response = await client.delete(
                f"{self.base_url}/object/{self.BUCKET_NAME}/{storage_path}",
                headers=self.headers,
            )
            return response.status_code == 200
