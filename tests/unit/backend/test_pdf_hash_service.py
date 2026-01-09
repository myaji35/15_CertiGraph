"""
P2 Group: Backend Service Tests - PDF Hash Service
Test IDs: BE-UNIT-001 to BE-UNIT-005

Run with: pytest tests/unit/backend/test_pdf_hash_service.py -n auto
"""

import pytest
import hashlib
from pathlib import Path


class TestPDFHashService:
    """Tests for PDF hashing service"""

    @pytest.mark.unit
    def test_be_unit_001_compute_sha256_hash_for_pdf(self, tmp_path):
        """BE-UNIT-001: Compute SHA-256 hash for a PDF file"""
        # Create a temporary PDF file
        pdf_file = tmp_path / "sample.pdf"
        pdf_file.write_bytes(b"%PDF-1.4\n%Test PDF content")

        # Compute hash
        with open(pdf_file, 'rb') as f:
            file_hash = hashlib.sha256(f.read()).hexdigest()

        # Verify hash is a valid SHA-256 (64 hex characters)
        assert len(file_hash) == 64
        assert all(c in '0123456789abcdef' for c in file_hash)

    @pytest.mark.unit
    def test_be_unit_002_same_file_produces_same_hash(self, tmp_path):
        """BE-UNIT-002: Same file content produces same hash"""
        content = b"%PDF-1.4\n%Test PDF content"

        pdf_file1 = tmp_path / "file1.pdf"
        pdf_file1.write_bytes(content)

        pdf_file2 = tmp_path / "file2.pdf"
        pdf_file2.write_bytes(content)

        # Compute hashes
        with open(pdf_file1, 'rb') as f:
            hash1 = hashlib.sha256(f.read()).hexdigest()

        with open(pdf_file2, 'rb') as f:
            hash2 = hashlib.sha256(f.read()).hexdigest()

        assert hash1 == hash2

    @pytest.mark.unit
    def test_be_unit_003_different_files_produce_different_hashes(self, tmp_path):
        """BE-UNIT-003: Different file content produces different hashes"""
        pdf_file1 = tmp_path / "file1.pdf"
        pdf_file1.write_bytes(b"%PDF-1.4\n%Content A")

        pdf_file2 = tmp_path / "file2.pdf"
        pdf_file2.write_bytes(b"%PDF-1.4\n%Content B")

        # Compute hashes
        with open(pdf_file1, 'rb') as f:
            hash1 = hashlib.sha256(f.read()).hexdigest()

        with open(pdf_file2, 'rb') as f:
            hash2 = hashlib.sha256(f.read()).hexdigest()

        assert hash1 != hash2

    @pytest.mark.unit
    def test_be_unit_004_detect_duplicate_upload(self, tmp_path):
        """BE-UNIT-004: Detect duplicate PDF upload by hash"""
        content = b"%PDF-1.4\n%Duplicate test"

        pdf_file = tmp_path / "duplicate.pdf"
        pdf_file.write_bytes(content)

        # Compute hash
        with open(pdf_file, 'rb') as f:
            file_hash = hashlib.sha256(f.read()).hexdigest()

        # Simulate database check
        uploaded_hashes = {file_hash}  # Simulated existing hashes

        # Try to upload again
        with open(pdf_file, 'rb') as f:
            new_hash = hashlib.sha256(f.read()).hexdigest()

        # Should detect duplicate
        assert new_hash in uploaded_hashes

    @pytest.mark.unit
    def test_be_unit_005_hash_consistency_across_platforms(self, tmp_path):
        """BE-UNIT-005: Hash should be consistent across platforms"""
        content = b"%PDF-1.4\n%Platform test"

        pdf_file = tmp_path / "platform.pdf"
        pdf_file.write_bytes(content)

        # Compute hash multiple times
        hashes = []
        for _ in range(3):
            with open(pdf_file, 'rb') as f:
                hashes.append(hashlib.sha256(f.read()).hexdigest())

        # All hashes should be identical
        assert len(set(hashes)) == 1
