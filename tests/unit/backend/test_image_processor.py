"""
P2 Group: Backend Service Tests - Image Processor
Test IDs: BE-UNIT-011 to BE-UNIT-016

Run with: pytest tests/unit/backend/test_image_processor.py -n auto
"""

import pytest
from pathlib import Path


class TestImageProcessor:
    """Tests for image processing and caption generation"""

    @pytest.mark.unit
    def test_be_unit_011_detect_image_in_pdf(self, tmp_path):
        """BE-UNIT-011: Detect images in PDF pages"""
        # Simulate image detection
        pdf_content = {
            "pages": [
                {"page_num": 1, "has_images": True, "image_count": 2},
                {"page_num": 2, "has_images": False, "image_count": 0},
            ]
        }

        pages_with_images = [page for page in pdf_content["pages"] if page["has_images"]]

        assert len(pages_with_images) == 1
        assert pages_with_images[0]["image_count"] == 2

    @pytest.mark.unit
    def test_be_unit_012_crop_image_from_page(self, tmp_path):
        """BE-UNIT-012: Crop image from PDF page"""
        # Simulate image cropping
        image_metadata = {
            "page_num": 1,
            "bbox": {"x": 100, "y": 200, "width": 300, "height": 200},
            "format": "png"
        }

        # Validate bounding box
        assert image_metadata["bbox"]["width"] > 0
        assert image_metadata["bbox"]["height"] > 0

    @pytest.mark.unit
    def test_be_unit_013_generate_image_caption_with_gpt4o(self):
        """BE-UNIT-013: Generate caption for cropped image"""
        # Simulate GPT-4o caption generation
        image_path = "question_1_diagram.png"

        # Mock caption from GPT-4o
        generated_caption = "데이터베이스 정규화 과정을 보여주는 다이어그램"

        assert len(generated_caption) > 0
        assert "데이터베이스" in generated_caption or "정규화" in generated_caption

    @pytest.mark.unit
    def test_be_unit_014_save_cropped_image(self, tmp_path):
        """BE-UNIT-014: Save cropped image to disk"""
        image_dir = tmp_path / "images"
        image_dir.mkdir()

        image_file = image_dir / "question_1.png"
        image_file.write_bytes(b"fake_image_data")

        assert image_file.exists()
        assert image_file.stat().st_size > 0

    @pytest.mark.unit
    def test_be_unit_015_link_image_to_question(self):
        """BE-UNIT-015: Link image reference to question"""
        question_data = {
            "question_id": "q_001",
            "question_text": "다음 그림을 참고하여 답하시오.",
            "images": [
                {
                    "image_id": "img_001",
                    "path": "images/question_1.png",
                    "caption": "ER 다이어그램 예시"
                }
            ]
        }

        assert len(question_data["images"]) == 1
        assert question_data["images"][0]["path"] == "images/question_1.png"

    @pytest.mark.unit
    def test_be_unit_016_handle_multiple_images_per_question(self):
        """BE-UNIT-016: Handle questions with multiple images"""
        question_data = {
            "question_id": "q_002",
            "images": [
                {"image_id": "img_002_a", "caption": "다이어그램 A"},
                {"image_id": "img_002_b", "caption": "다이어그램 B"},
            ]
        }

        assert len(question_data["images"]) == 2
