from pydantic import BaseModel
from typing import Optional

class PaymentRequest(BaseModel):
    """Payment request model."""
    exam_date: str
    amount: int = 10000
    order_name: str = "사회복지사 1급 시험 대비"

class PaymentConfirmRequest(BaseModel):
    """Payment confirmation request."""
    payment_key: str
    order_id: str
    amount: int

class PaymentResponse(BaseModel):
    """Payment response model."""
    payment_key: str
    client_key: str
    order_id: str
    amount: int
    order_name: str
    success_url: str
    fail_url: str
    created_at: str
    customer_name: str

class PaymentCancelRequest(BaseModel):
    """Payment cancel request."""
    cancel_reason: str = "고객 요청"

class PaymentStatusResponse(BaseModel):
    """Payment status response."""
    status: str
    approved_at: Optional[str] = None
    total_amount: int
    method: Optional[str] = None
