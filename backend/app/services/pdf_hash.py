"""PDF hash service for duplicate detection.

This service computes a hash of the PDF content to detect duplicates.
When a duplicate is found, we can skip actual processing and use cached results.
"""

import hashlib
from typing import Optional, BinaryIO


class PdfHashService:
    """Service for computing and managing PDF content hashes."""

    @staticmethod
    def compute_hash(file: BinaryIO, chunk_size: int = 8192) -> str:
        """
        Compute SHA-256 hash of PDF content.

        Args:
            file: Binary file object
            chunk_size: Size of chunks to read at a time

        Returns:
            Hexadecimal hash string
        """
        sha256_hash = hashlib.sha256()

        # Read file in chunks to handle large files efficiently
        file.seek(0)  # Ensure we start from the beginning
        while chunk := file.read(chunk_size):
            sha256_hash.update(chunk)

        file.seek(0)  # Reset file position for subsequent reads
        return sha256_hash.hexdigest()

    @staticmethod
    def compute_hash_from_bytes(content: bytes) -> str:
        """
        Compute SHA-256 hash from bytes.

        Args:
            content: PDF content as bytes

        Returns:
            Hexadecimal hash string
        """
        return hashlib.sha256(content).hexdigest()
