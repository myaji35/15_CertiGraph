#!/bin/bash
# CertiGraph Cloud Run Deployment Script
# Usage: ./deploy-cloudrun.sh <PROJECT_ID>

set -e

# Configuration
PROJECT_ID="${1:-}"
REGION="asia-northeast3"
REPO="certigraph"

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Usage: ./deploy-cloudrun.sh <GCP_PROJECT_ID>"
    echo "   Example: ./deploy-cloudrun.sh my-gcp-project"
    exit 1
fi

echo "🚀 Deploying CertiGraph to Cloud Run"
echo "   Project: $PROJECT_ID"
echo "   Region: $REGION"
echo ""

# Set project
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "📦 Enabling required APIs..."
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# Create Artifact Registry repository (if not exists)
echo "📦 Creating Artifact Registry repository..."
gcloud artifacts repositories create $REPO \
    --repository-format=docker \
    --location=$REGION \
    --description="CertiGraph container images" \
    2>/dev/null || echo "   Repository already exists"

# ==========================================
# Backend Deployment
# ==========================================
echo ""
echo "🔧 Building and deploying Backend..."
cd backend

# Build and push
gcloud builds submit \
    --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/backend:latest \
    --timeout=20m

# Deploy to Cloud Run
gcloud run deploy certigraph-backend \
    --image ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/backend:latest \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --port 3030 \
    --memory 512Mi \
    --cpu 1 \
    --min-instances 0 \
    --max-instances 10 \
    --set-env-vars "DEV_MODE=true" \
    --set-env-vars "CORS_ORIGINS=*"

# Get backend URL
BACKEND_URL=$(gcloud run services describe certigraph-backend --region $REGION --format='value(status.url)')
echo "✅ Backend deployed: $BACKEND_URL"

# ==========================================
# Frontend Deployment
# ==========================================
echo ""
echo "🎨 Building and deploying Frontend..."
cd ../frontend

# Build and push
gcloud builds submit \
    --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/frontend:latest \
    --timeout=20m

# Deploy to Cloud Run
gcloud run deploy certigraph-frontend \
    --image ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/frontend:latest \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --port 3000 \
    --memory 512Mi \
    --cpu 1 \
    --min-instances 0 \
    --max-instances 10 \
    --set-env-vars "NEXT_PUBLIC_API_URL=${BACKEND_URL}" \
    --set-env-vars "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_placeholder"

# Get frontend URL
FRONTEND_URL=$(gcloud run services describe certigraph-frontend --region $REGION --format='value(status.url)')
echo "✅ Frontend deployed: $FRONTEND_URL"

# ==========================================
# Summary
# ==========================================
echo ""
echo "=========================================="
echo "🎉 Deployment Complete!"
echo "=========================================="
echo ""
echo "Backend:  $BACKEND_URL"
echo "Frontend: $FRONTEND_URL"
echo ""
echo "Health Check: curl $BACKEND_URL/health"
echo "API Docs:     $BACKEND_URL/docs"
echo ""
echo "⚠️  Note: Set actual environment variables for production:"
echo "   - CLERK_JWKS_URL"
echo "   - SUPABASE_URL / SUPABASE_SERVICE_KEY"
echo "   - OPENAI_API_KEY"
echo "   - PINECONE_API_KEY"
echo ""
