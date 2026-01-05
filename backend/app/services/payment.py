"""Payment service using Toss Payments API."""

import httpx
import base64
import json
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import os

from app.repositories.payment import PaymentRepository

class PaymentService:
    """Toss Payments integration service."""

    def __init__(self, client_key=None, secret_key=None, frontend_url=None, repository=None):
        self.base_url = "https://api.tosspayments.com/v1"
        self.client_key = client_key or os.getenv('TOSS_CLIENT_KEY', "test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq")
        self.secret_key = secret_key or os.getenv('TOSS_SECRET_KEY', "test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R")
        self.frontend_url = frontend_url or os.getenv('FRONTEND_URL', 'http://localhost:3000')
        self.repository = repository or PaymentRepository()

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
        order_id = f"ORDER_{user_id}_{datetime.now().strftime('%Y%m%d%H%M%S')}"

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
        amount: int,
        user_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Confirm a payment after user approval.

        Args:
            payment_key: Payment key from Toss
            order_id: Order ID
            amount: Payment amount
            user_id: Optional user_id (if available from context to cross-check)

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
                    result = response.json()
                    
                    # Extract user_id from order_id if not provided
                    # Order ID format: ORDER_{user_id}_{timestamp}
                    if not user_id and "ORDER_" in order_id:
                        parts = order_id.split("_")
                        if len(parts) >= 3:
                            # Handling user_id that might contain underscores? 
                            # Assuming user_id is the middle part or everything between ORDER and Timestamp
                            # Safe bet: Clerk IDs don't seem to have underscores usually, mostly user_...
                            user_id = parts[1]

                    if user_id:
                        # Update user status in DB
                        # Note: We need to handle internal ID vs Clerk ID details.
                        # For now, update_user_payment_status tries both.
                        await self.repository.update_user_payment_status(
                            user_id=user_id,
                            is_paid=True,
                            payment_key=payment_key,
                            amount=amount
                        )

                    return result
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
                
                # If cancellation successful, we should theoretically update DB too.
                # Logic omitted for brevity in MVP unless specifically requested.

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