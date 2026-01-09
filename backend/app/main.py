from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from app.core import get_settings
from app.api.v1.router import api_router

settings = get_settings()

app = FastAPI(
    title="CertiGraph API",
    description="AI-powered certification exam study platform API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS middleware - MUST be added before routes
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:3001", "http://localhost:3030", "*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allow_headers=["*"],
    expose_headers=["*"],
)


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "version": "1.0.0"}


app.include_router(api_router, prefix="/api/v1")

# Mount static files for uploaded PDFs
uploads_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads")
os.makedirs(uploads_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")

# Inngest disabled for now - uncomment when needed
# from inngest.fast_api import serve
# from app.core.inngest_client import inngest_client
# from app.jobs import plane_jobs
# serve(
#     app,
#     inngest_client,
#     [
#         plane_jobs.create_work_item_job,
#         plane_jobs.list_work_items_job,
#         plane_jobs.get_project_info_job,
#         plane_jobs.create_development_task_job,
#     ]
# )
