from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from inngest.fast_api import serve

from app.core import get_settings
from app.api.v1.router import api_router
from app.core.inngest_client import inngest_client
# Import all inngest functions to register them
from app.jobs import plane_jobs

settings = get_settings()

app = FastAPI(
    title="CertiGraph API",
    description="AI-powered certification exam study platform API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "version": "1.0.0"}


app.include_router(api_router, prefix="/api/v1")

# Add Inngest serve endpoint
serve(
    app,
    inngest_client,
    [
        plane_jobs.create_work_item_job,
        plane_jobs.list_work_items_job,
        plane_jobs.get_project_info_job,
        plane_jobs.create_development_task_job,
    ]
)
