"""Payment API endpoints."""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from app.api.v1.deps import get_current_user
from app.services.payment import payment_service

router = APIRouter()

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

@router.post("/create", response_model=PaymentResponse)
async def create_payment(
    request: PaymentRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Create a new payment request.

    쿠팡페이먼츠 스타일 결제 프로세스:
    1. 결제 요청 생성
    2. 클라이언트에서 결제 위젯 표시
    3. 사용자 결제 승인
    4. 결제 확인 API 호출
    """
    try:
        result = await payment_service.create_payment(
            user_id=current_user["user_id"],
            exam_date=request.exam_date,
            amount=request.amount,
            order_name=request.order_name
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/confirm")
async def confirm_payment(
    request: PaymentConfirmRequest,
    current_user: dict = Depends(get_current_user)
):
    """Confirm a payment after user approval."""
    try:
        result = await payment_service.confirm_payment(
            payment_key=request.payment_key,
            order_id=request.order_id,
            amount=request.amount
        )

        if result.get("error"):
            raise HTTPException(status_code=400, detail=result.get("message"))

        # TODO: Save payment record to database
        # TODO: Grant access to exam materials

        return {
            "success": True,
            "payment_key": request.payment_key,
            "message": "결제가 완료되었습니다."
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/cancel/{payment_key}")
async def cancel_payment(
    payment_key: str,
    current_user: dict = Depends(get_current_user)
):
    """Cancel a payment."""
    try:
        result = await payment_service.cancel_payment(payment_key)

        if result.get("error"):
            raise HTTPException(status_code=400, detail=result.get("message"))

        return {
            "success": True,
            "message": "결제가 취소되었습니다."
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/status/{payment_key}")
async def get_payment_status(
    payment_key: str,
    current_user: dict = Depends(get_current_user)
):
    """Get payment status."""
    try:
        result = await payment_service.get_payment_status(payment_key)

        if result.get("error"):
            raise HTTPException(status_code=400, detail=result.get("message"))

        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))