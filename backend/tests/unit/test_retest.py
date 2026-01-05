import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from app.api.v1.endpoints.tests import start_test
from app.models.test import TestMode, TestStartRequest as StartRequestModel
from app.repositories.test_session import TestSessionRepository
from app.services.test_engine import TestSessionService as SessionService

@pytest.fixture
def mock_session_repo():
    return AsyncMock()

@pytest.fixture
def mock_question_repo():
    repo = AsyncMock()
    # Mock returning questions
    repo.get_by_ids.return_value = [{"id": "q1", "question_number": 1, "question_text": "T1", "options": []}]
    repo.get_by_study_set.return_value = [{"id": "q1", "question_number": 1, "question_text": "T1", "options": []}]
    return repo

@pytest.mark.asyncio
async def test_start_session_wrong_only_mode(mock_session_repo, mock_question_repo):
    """오답 노트 모드 시작 테스트"""
    service = SessionService()
    service.session_repo = mock_session_repo
    service.question_repo = mock_question_repo
    
    user_id = "user_1"
    study_set_id = "set_1"
    
    # CASE 1: 오답이 있는 경우
    mock_session_repo.get_wrong_question_ids.return_value = ["q1"]
    mock_session_repo.create_session.return_value = {"id": "session_123"}
    
    result = await service.start_session(user_id, study_set_id, TestMode.WRONG_ONLY)
    
    # 오답 ID로 문제 조회했는지 확인
    mock_session_repo.get_wrong_question_ids.assert_called_once_with(user_id, study_set_id)
    mock_question_repo.get_by_ids.assert_called_once_with(["q1"])
    assert result["session_id"] == "session_123"

@pytest.mark.asyncio
async def test_start_session_wrong_only_empty(mock_session_repo, mock_question_repo):
    """오답이 없을 때 전체 문제로 폴백 테스트"""
    service = SessionService()
    service.session_repo = mock_session_repo
    service.question_repo = mock_question_repo
    
    # CASE 2: 오답이 없는 경우
    mock_session_repo.get_wrong_question_ids.return_value = []
    mock_session_repo.create_session.return_value = {"id": "session_456"}
    
    result = await service.start_session("user_1", "set_1", TestMode.WRONG_ONLY)
    
    # 전체 문제 조회로 폴백 확인
    mock_question_repo.get_by_study_set.assert_called_once()
    assert result["session_id"] == "session_456"

import app.repositories.test_session as test_session_repo_module

@pytest.mark.asyncio
async def test_repo_get_wrong_ids_logic():
    """Repository 오답 추출 로직 테스트 (Real Implementation)"""
    # Use the real class, not the factory (which returns Mock in dev mode)
    repo = test_session_repo_module._TestSessionRepository()
    
    # Mocking httpx.AsyncClient to handle context manager
    with patch("httpx.AsyncClient") as mock_client_cls:
        mock_client = AsyncMock()
        mock_client_cls.return_value.__aenter__.return_value = mock_client
        
        # Setup responses
        mock_response_sessions = MagicMock()
        mock_response_sessions.status_code = 200
        mock_response_sessions.json.return_value = [{"id": "sess_1"}]
        mock_response_sessions.raise_for_status = MagicMock()
        
        mock_response_answers = MagicMock()
        mock_response_answers.status_code = 200
        mock_response_answers.json.return_value = [
            {"question_id": "q1", "is_correct": False, "answered_at": "2024-01-01T10:00:00"}, # Old Attempt
            {"question_id": "q1", "is_correct": True, "answered_at": "2024-01-01T10:05:00"},  # Latest Correct -> Should be excluded
            {"question_id": "q2", "is_correct": False, "answered_at": "2024-01-01T10:00:00"}  # Incorrect -> Should be included
        ]
        mock_response_answers.raise_for_status = MagicMock()
        
        # side_effect for .get() calls
        mock_client.get.side_effect = [mock_response_sessions, mock_response_answers]
        
        ids = await repo.get_wrong_question_ids("u1", "s1")
        
        # q1 is correct in latest attempt, so exclude. q2 is wrong.
        assert "q1" not in ids
        assert "q2" in ids
