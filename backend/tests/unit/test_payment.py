import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime

from app.services.payment import PaymentService
from app.repositories.payment import PaymentRepository

@pytest.fixture
def payment_service():
    return PaymentService(client_key="test_key", secret_key="test_secret")

@pytest.fixture
def mock_payment_repo():
    return AsyncMock(spec=PaymentRepository)

@pytest.mark.asyncio
async def test_create_payment(payment_service):
    """결제 요청 생성 테스트"""
    user_id = "test_user"
    exam_date = "2025-03-01"
    
    result = await payment_service.create_payment(user_id, exam_date)
    
    assert result["amount"] == 10000
    assert result["customer_name"] == user_id
    assert "ORDER_" in result["order_id"]
    assert result["success_url"] == "http://localhost:3000/payment/success"

@pytest.mark.asyncio
async def test_confirm_payment_success(payment_service, mock_payment_repo):
    """결제 승인 성공 테스트"""
    payment_key = "test_payment_key"
    order_id = "ORDER_test_user_12345"
    amount = 10000
    
    # Mock repository
    payment_service.repository = mock_payment_repo
    
    # Mock httpx client
    with patch("httpx.AsyncClient.post") as mock_post:
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "status": "DONE",
            "method": "카드",
            "totalAmount": 10000
        }
        mock_post.return_value = mock_response
        
        result = await payment_service.confirm_payment(payment_key, order_id, amount, user_id="test_user")
        
        # Check API call
        assert result["status"] == "DONE"
        
        # Check DB update was called
        mock_payment_repo.update_user_payment_status.assert_called_once_with(
            user_id="test_user",
            is_paid=True,
            payment_key=payment_key,
            amount=amount
        )

# Payment Repository Tests (Mocking Supabase)
@pytest.mark.asyncio
async def test_repo_update_status():
    """리포지토리 상태 업데이트 테스트"""
    repo = PaymentRepository()
    
    with patch("httpx.AsyncClient.patch") as mock_patch:
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = [{"id": "user_1", "is_paid": True}]
        mock_patch.return_value = mock_response
        
        result = await repo.update_user_payment_status("user_1", True, "pay_key", 10000)
        
        assert result["is_paid"] is True
        assert result["id"] == "user_1"
