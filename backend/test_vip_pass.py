"""Test VIP Pass functionality"""

import requests
import json
from datetime import datetime

# VIP user Clerk ID
VIP_CLERK_ID = "user_36T9Qa8HsuaM1fMjTisw4frRH1Z"

# Create a mock JWT token with the VIP Clerk ID
# This simulates what Clerk would send
mock_jwt_payload = {
    "azp": "http://localhost:3030",
    "exp": 1767856518,
    "fva": [1272, -1],
    "iat": 1767856458,
    "iss": "https://strong-weevil-96.clerk.accounts.dev",
    "nbf": 1767856448,
    "sid": "sess_37vOSzID31jmAw95Ku50A2mfGxl",
    "sts": "active",
    "sub": VIP_CLERK_ID,
    "v": 2
}

def test_vip_pass():
    """Test the VIP pass endpoint"""

    print("=" * 50)
    print("Testing VIP Pass for user:", VIP_CLERK_ID)
    print("=" * 50)

    # First, let's test if the server is running
    try:
        response = requests.get("http://localhost:8000/docs")
        if response.status_code == 200:
            print("✅ Backend server is running")
        else:
            print("❌ Backend server returned:", response.status_code)
    except Exception as e:
        print("❌ Cannot connect to backend:", str(e))
        return

    # Test the my-subscriptions endpoint
    # Note: This will fail with auth error but we can see if the endpoint exists
    try:
        response = requests.get(
            "http://localhost:8000/api/v1/subscriptions/my-subscriptions",
            headers={
                "Content-Type": "application/json",
                # We can't create a valid JWT without the secret,
                # but we can test if the endpoint exists
                "Authorization": "Bearer test-token"
            }
        )

        print("\nAPI Response:")
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")

        # Expected: 401 Unauthorized (because we don't have a valid JWT)
        # But this confirms the endpoint exists

        if response.status_code == 401:
            error_data = response.json()
            print("\n✅ Endpoint exists (auth error expected without valid JWT)")
            print("Error details:", json.dumps(error_data, indent=2))
        elif response.status_code == 200:
            data = response.json()
            print("\n✅ Success! Response data:")
            print(json.dumps(data, indent=2, default=str))

            # Check for VIP pass
            if data.get("subscriptions"):
                vip_pass = next((s for s in data["subscriptions"] if s["id"] == "vip-pass"), None)
                if vip_pass:
                    print("\n🎉 VIP Pass Found!")
                    print(f"  - Name: {vip_pass['certification_name']}")
                    print(f"  - Status: {vip_pass['status']}")
                    print(f"  - Days Remaining: {vip_pass['days_remaining']}")
        else:
            print("\n❌ Unexpected response")

    except Exception as e:
        print(f"\n❌ Error testing endpoint: {str(e)}")

    print("\n" + "=" * 50)
    print("Test Complete")
    print("=" * 50)

if __name__ == "__main__":
    test_vip_pass()