"""Mock storage service for development mode."""

import uuid
from io import BytesIO
from pathlib import Path


class MockStorageService:
    """Mock storage that saves files to local disk for development."""

    def __init__(self):
        """Initialize mock storage with a base directory."""
        # Base directory for mock file storage
        self.base_dir = Path("mock_storage")
        self.base_dir.mkdir(exist_ok=True)

    async def upload_pdf(self, file: BytesIO, user_id: str) -> str:
        """Save PDF to local filesystem and return path."""
        filename = f"{uuid.uuid4()}.pdf"
        path = f"mock/{user_id}/{filename}"

        # Save to actual filesystem
        full_path = self.base_dir / path
        full_path.parent.mkdir(parents=True, exist_ok=True)

        file.seek(0)
        full_path.write_bytes(file.read())
        file.seek(0)

        return path

    async def download(self, path: str) -> bytes:
        """Download PDF file content from local filesystem."""
        # Read from local filesystem
        full_path = self.base_dir / path
        if not full_path.exists():
            raise FileNotFoundError(f"PDF file not found: {path}")

        return full_path.read_bytes()

    async def get_pdf_url(self, path: str) -> str:
        """Generate a fake URL."""
        return f"http://mock-storage.local/{path}"

    async def delete_pdf(self, path: str) -> bool:
        """Delete PDF file from local filesystem."""
        full_path = self.base_dir / path
        if full_path.exists():
            full_path.unlink()
        return True

    async def delete_file(self, path: str) -> bool:
        """Delete file (alias for delete_pdf)."""
        return await self.delete_pdf(path)
