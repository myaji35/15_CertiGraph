import os
import pytest

# Set env vars for all tests
os.environ["DEV_MODE"] = "true"
os.environ["CLERK_JWKS_URL"] = "https://example.com/jwks"
os.environ["CLERK_SECRET_KEY"] = "test"
os.environ["SUPABASE_URL"] = "https://example.com"
os.environ["SUPABASE_SERVICE_KEY"] = "test"  # Matches supabase_service_key in Settings
# Optional fields
os.environ["GOOGLE_API_KEY"] = "test"
os.environ["OPENAI_API_KEY"] = "test"
os.environ["UPSTAGE_API_KEY"] = "test"
os.environ["PINECONE_API_KEY"] = "test"
