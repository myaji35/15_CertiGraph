"""Payment service using Toss Payments API."""

import httpx
import base64
import json
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import os

class PaymentService:
    """Toss Payments integration service."""

    def __init__(self):
        self.base_url = "https://api.tosspayments.com/v1"
        self.client_key = os.getenv('TOSS_CLIENT_KEY', "test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq")  # 테스트 키
        self.secret_key = os.getenv('TOSS_SECRET_KEY', "test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R")  # 테스트 키
        self.frontend_url = os.getenv('FRONTEND_URL', 'http://localhost:3000')

        # Base64 encode secret key for authorization
        auth_string = f"{self.secret_key}:"
        self.auth_header = base64.b64encode(auth_string.encode()).decode()

    async def create_payment(
        self,
        user_id: str,
        exam_date: str,
        amount: int = 10000,
        order_name: str = "사회복지사 1급 시험 대비"
    ) -> Dict[str, Any]:
        """
        Create a payment request.

        Args:
            user_id: User's ID
            exam_date: Exam date (YYYY-MM-DD)
            amount: Payment amount (default: 10,000 won)
            order_name: Order description

        Returns:
            Payment creation response
        """
        order_id = f"ORDER_{user_id}_{exam_date}_{datetime.now().strftime('%Y%m%d%H%M%S')}"

        payment_data = {
            "amount": amount,
            "orderId": order_id,
            "orderName": f"{order_name} ({exam_date})",
            "successUrl": f"{self.frontend_url}/payment/success",
            "failUrl": f"{self.frontend_url}/payment/fail",
            "customerName": user_id,
            "customerEmail": f"{user_id}@examsgraph.com",  # Placeholder
        }

        return {
            "payment_key": order_id,
            "client_key": self.client_key,
            "order_id": order_id,
            "amount": amount,
            "order_name": payment_data["orderName"],
            "customer_name": user_id,
            "success_url": payment_data["successUrl"],
            "fail_url": payment_data["failUrl"],
            "created_at": datetime.now().isoformat()
        }

    async def confirm_payment(
        self,
        payment_key: str,
        order_id: str,
        amount: int
    ) -> Dict[str, Any]:
        """
        Confirm a payment after user approval.

        Args:
            payment_key: Payment key from Toss
            order_id: Order ID
            amount: Payment amount

        Returns:
            Payment confirmation response
        """
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{self.base_url}/payments/confirm",
                    headers={
                        "Authorization": f"Basic {self.auth_header}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "paymentKey": payment_key,
                        "orderId": order_id,
                        "amount": amount
                    }
                )

                if response.status_code == 200:
                    return response.json()
                else:
                    return {
                        "error": True,
                        "message": response.text,
                        "status_code": response.status_code
                    }

            except Exception as e:
                return {
                    "error": True,
                    "message": str(e)
                }

    async def cancel_payment(
        self,
        payment_key: str,
        cancel_reason: str = "고객 요청"
    ) -> Dict[str, Any]:
        """
        Cancel a payment.

        Args:
            payment_key: Payment key to cancel
            cancel_reason: Reason for cancellation

        Returns:
            Cancellation response
        """
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{self.base_url}/payments/{payment_key}/cancel",
                    headers={
                        "Authorization": f"Basic {self.auth_header}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "cancelReason": cancel_reason
                    }
                )

                return response.json()

            except Exception as e:
                return {
                    "error": True,
                    "message": str(e)
                }

    async def get_payment_status(self, payment_key: str) -> Dict[str, Any]:
        """
        Get payment status.

        Args:
            payment_key: Payment key to check

        Returns:
            Payment status information
        """
        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(
                    f"{self.base_url}/payments/{payment_key}",
                    headers={
                        "Authorization": f"Basic {self.auth_header}"
                    }
                )

                return response.json()

            except Exception as e:
                return {
                    "error": True,
                    "message": str(e)
                }

payment_service = PaymentService()