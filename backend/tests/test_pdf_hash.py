"""
PDF Hash Service 단위 테스트
테스트 ID: BE-UNIT-001 ~ BE-UNIT-005
"""
import hashlib
import pytest
from app.services.pdf_hash import calculate_pdf_hash

class TestPDFHashService:
    """PDF Hash 서비스 테스트 클래스"""

    # BE-UNIT-001: calculate_pdf_hash - 유효한 PDF
    @pytest.mark.unit
    def test_calculate_pdf_hash_valid_pdf(self):
        """유효한 PDF 바이트에 대한 해시 생성 검증"""
        # PDF 헤더로 시작하는 유효한 바이트 시뮬레이션
        pdf_bytes = b"%PDF-1.4\n%\xd3\xeb\xe9\xe1\n1 0 obj\n<</Type/Catalog>>\nendobj"
        result = calculate_pdf_hash(pdf_bytes)

        # 결과가 64자의 16진수 문자열인지 확인 (SHA256)
        assert isinstance(result, str)
        assert len(result) == 64
        assert all(c in '0123456789abcdef' for c in result.lower())

    # BE-UNIT-002: calculate_pdf_hash - 빈 바이트
    @pytest.mark.unit
    def test_calculate_pdf_hash_empty_bytes(self):
        """빈 바이트 입력 처리 검증"""
        empty_bytes = b""
        result = calculate_pdf_hash(empty_bytes)

        # 빈 바이트도 유효한 해시를 생성해야 함
        assert isinstance(result, str)
        assert len(result) == 64
        # SHA256 of empty string
        expected = hashlib.sha256(b"").hexdigest()
        assert result == expected

    # BE-UNIT-003: calculate_pdf_hash - 동일 PDF 동일 해시
    @pytest.mark.unit
    def test_calculate_pdf_hash_consistency(self):
        """동일한 PDF에 대해 동일한 해시 생성 검증"""
        pdf_bytes = b"%PDF-1.4\nTest Content\nendobj"

        hash1 = calculate_pdf_hash(pdf_bytes)
        hash2 = calculate_pdf_hash(pdf_bytes)
        hash3 = calculate_pdf_hash(pdf_bytes)

        assert hash1 == hash2
        assert hash2 == hash3
        assert hash1 == hash3

    # BE-UNIT-004: calculate_pdf_hash - 다른 PDF 다른 해시
    @pytest.mark.unit
    def test_calculate_pdf_hash_uniqueness(self):
        """다른 PDF에 대해 다른 해시 생성 검증"""
        pdf1 = b"%PDF-1.4\nContent 1\nendobj"
        pdf2 = b"%PDF-1.4\nContent 2\nendobj"
        pdf3 = b"%PDF-1.5\nContent 1\nendobj"  # 버전만 다른 경우

        hash1 = calculate_pdf_hash(pdf1)
        hash2 = calculate_pdf_hash(pdf2)
        hash3 = calculate_pdf_hash(pdf3)

        # 모든 해시가 서로 달라야 함
        assert hash1 != hash2
        assert hash2 != hash3
        assert hash1 != hash3

    # BE-UNIT-005: calculate_pdf_hash - 대용량 PDF (100MB 시뮬레이션)
    @pytest.mark.unit
    def test_calculate_pdf_hash_large_pdf(self):
        """대용량 PDF 처리 성능 검증"""
        import time

        # 100MB 크기의 PDF 시뮬레이션
        large_pdf = b"%PDF-1.4\n" + b"X" * (100 * 1024 * 1024) + b"\nendobj"

        start_time = time.time()
        result = calculate_pdf_hash(large_pdf)
        end_time = time.time()

        # 해시가 올바르게 생성되는지 확인
        assert isinstance(result, str)
        assert len(result) == 64

        # 처리 시간이 합리적인지 확인 (5초 이내)
        processing_time = end_time - start_time
        assert processing_time < 5.0, f"처리 시간이 너무 깁니다: {processing_time:.2f}초"

    # 추가 엣지 케이스 테스트
    @pytest.mark.unit
    def test_calculate_pdf_hash_with_null_bytes(self):
        """NULL 바이트가 포함된 PDF 처리 검증"""
        pdf_with_null = b"%PDF-1.4\n\x00\x00\x00Content\x00\nendobj"
        result = calculate_pdf_hash(pdf_with_null)

        assert isinstance(result, str)
        assert len(result) == 64

    @pytest.mark.unit
    def test_calculate_pdf_hash_with_unicode(self):
        """유니코드가 포함된 PDF 처리 검증"""
        pdf_with_unicode = "%PDF-1.4\n한글 테스트\nendobj".encode('utf-8')
        result = calculate_pdf_hash(pdf_with_unicode)

        assert isinstance(result, str)
        assert len(result) == 64

    @pytest.mark.unit
    def test_calculate_pdf_hash_deterministic(self):
        """해시 생성의 결정론적 특성 검증"""
        pdf_bytes = b"%PDF-1.4\nDeterministic Test\nendobj"
        expected_hash = hashlib.sha256(pdf_bytes).hexdigest()

        result = calculate_pdf_hash(pdf_bytes)
        assert result == expected_hash