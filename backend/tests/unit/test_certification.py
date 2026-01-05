import pytest
from datetime import date, timedelta
from app.services.data_loader import CertificationDataLoader
from app.models.certification import ExamType

@pytest.fixture
def data_loader():
    return CertificationDataLoader()

def test_get_upcoming_exams(data_loader):
    """다가오는 시험 조회 테스트"""
    # Mock data inside data_loader if needed, or rely on hardcoded POPULAR_CERTIFICATIONS
    # Assuming POPULAR_CERTIFICATIONS has future dates (2025/2026)
    
    upcoming = data_loader.get_upcoming_exams(days=365)
    
    assert isinstance(upcoming, list)
    if upcoming:
        first_exam = upcoming[0]
        assert "exam_date" in first_exam
        assert first_exam["exam_date"] >= date.today()

def test_get_nearest_exam_logic(data_loader):
    """시험일 추천 로직 테스트"""
    # Create dummy data
    today = date.today()
    future_date = today + timedelta(days=30)
    
    mock_schedule = {
        "exam_type": ExamType.WRITTEN,
        "round": 1,
        "exam_date": future_date,
        "application_start": today,
        "application_end": today,
        "result_date": future_date
    }
    
    mock_cert = {
        "id": "test-cert",
        "name": "테스트 자격증",
        "schedules_2025": [mock_schedule],
        "category": "private",
        "organization": "Test Org"
    }
    
    # Inject mock data
    data_loader._certifications = [mock_cert]
    
    upcoming = data_loader.get_upcoming_exams(days=100)
    target_exams = [e for e in upcoming if e["certification_id"] == "test-cert"]
    
    assert len(target_exams) == 1
    assert target_exams[0]["days_until"] == 30
