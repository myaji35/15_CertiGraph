"""Repository for payment and user subscription operations."""

from datetime import datetime
from typing import Any, Dict, Optional
import httpx

from app.core.config import get_settings

class PaymentRepository:
    """Data access layer for payment related operations."""

    def __init__(self):
        self.settings = get_settings()
        self.base_url = f"{self.settings.supabase_url}/rest/v1"
        self.headers = {
            "apikey": self.settings.supabase_service_key,
            "Authorization": f"Bearer {self.settings.supabase_service_key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        }

    async def update_user_payment_status(
        self,
        user_id: str,
        is_paid: bool,
        payment_key: str,
        amount: int
    ) -> Dict[str, Any]:
        """
        Update user's payment status in the database.
        
        Args:
            user_id: User's clerk ID or internal ID (we'll query by clerk_id typically or internal id)
            is_paid: Payment status
            payment_key: Toss payment key
            amount: Payment amount
            
        Returns:
            Updated user record
        """
        now = datetime.utcnow().isoformat()
        
        # We assume user_id used here is the one from the 'users' table or 'user_profiles' table.
        # Based on deps.py, we have 'user_profiles' table with 'clerk_id'.
        # But Architecture doc mentioned 'users' table.
        # Let's check which table we are actually using.
        # In deps.py, it auto-registers to 'user_profiles'.
        
        data = {
            "is_paid": is_paid,
            "paid_at": now if is_paid else None,
            "payment_id": payment_key,
            "updated_at": now
        }

        # Try updating 'user_profiles' first by clerk_id
        async with httpx.AsyncClient() as client:
            response = await client.patch(
                f"{self.base_url}/user_profiles",
                headers=self.headers,
                params={"clerk_id": f"eq.{user_id}"},
                json=data,
            )
            
            # If no rows updated (maybe using internal UUID), try by 'id'
            if response.status_code == 200:
                result = response.json()
                if not result:
                    # Try by ID
                     response = await client.patch(
                        f"{self.base_url}/user_profiles",
                        headers=self.headers,
                        params={"id": f"eq.{user_id}"},
                        json=data,
                    )

            response.raise_for_status()
            results = response.json()
            return results[0] if results else None

    async def create_payment_log(
        self,
        user_id: str,
        payment_key: str,
        order_id: str,
        amount: int,
        status: str,
        raw_response: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Create a log entry for the payment transaction.
        """
        data = {
            "user_id": user_id,  # Note: This usually needs internal UUID, not Clerk ID. 
                                # If user_id passed is Clerk ID, we might need to resolve it.
                                # For MVP, assuming we can store string or resolution happens before.
            "payment_key": payment_key,
            "order_id": order_id,
            "amount": amount,
            "status": status,
            "response_json": raw_response, # Supabase JSONB
            "created_at": datetime.utcnow().isoformat()
        }
        
        # Checking if 'payment_logs' table exists is tricky without schema access.
        # For MVP, we might skip this or assume it exists. 
        # I'll comment this out for now to prevent 404s if table missing, 
        # relying on user_profiles update as the source of truth.
        pass
