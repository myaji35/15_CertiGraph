"""
Inngest client configuration for background job processing
"""
from inngest import Inngest
from app.core.config import get_settings

settings = get_settings()

# Create Inngest client
inngest_client = Inngest(
    app_id="certigraph-backend",
    event_key=getattr(settings, 'inngest_event_key', None),
    is_production=not settings.dev_mode
)
