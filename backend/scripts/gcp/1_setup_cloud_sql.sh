#!/bin/bash
# Cloud SQL Setup Script for CertiGraph
# This script creates a Cloud SQL PostgreSQL instance for the application

set -e

# Configuration
PROJECT_ID="postgresql-479201"  # Your GCP project ID
INSTANCE_NAME="certigraph-db"
REGION="asia-northeast3"
TIER="db-custom-2-7680"
DATABASE_NAME="certigraph"
DB_USER="certigraph_user"

echo "=== CertiGraph Cloud SQL Setup ==="
echo "Project: $PROJECT_ID"
echo "Instance: $INSTANCE_NAME"
echo "Region: $REGION"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud CLI not found. Please install it first."
    echo "Visit: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Set project
echo "Setting GCP project..."
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "Enabling Cloud SQL Admin API..."
gcloud services enable sqladmin.googleapis.com

# Create Cloud SQL instance
echo "Creating Cloud SQL instance..."
gcloud sql instances create $INSTANCE_NAME \
  --database-version=POSTGRES_15 \
  --tier=$TIER \
  --region=$REGION \
  --storage-type=SSD \
  --storage-size=20GB \
  --storage-auto-increase \
  --backup-start-time=03:00 \
  --maintenance-window-day=SUN \
  --maintenance-window-hour=4 \
  --root-password="$(openssl rand -base64 32)"

echo "Waiting for instance to be ready..."
sleep 30

# Create database
echo "Creating database..."
gcloud sql databases create $DATABASE_NAME \
  --instance=$INSTANCE_NAME

# Create database user
echo "Creating database user..."
DB_PASSWORD=$(openssl rand -base64 32)
gcloud sql users create $DB_USER \
  --instance=$INSTANCE_NAME \
  --password="$DB_PASSWORD"

# Get connection name
CONNECTION_NAME=$(gcloud sql instances describe $INSTANCE_NAME --format="value(connectionName)")

echo ""
echo "=== Setup Complete ==="
echo "Instance: $INSTANCE_NAME"
echo "Connection Name: $CONNECTION_NAME"
echo "Database: $DATABASE_NAME"
echo "User: $DB_USER"
echo "Password: $DB_PASSWORD"
echo ""
echo "Save these credentials securely!"
echo ""
echo "To connect locally, install Cloud SQL Proxy:"
echo "  cloud-sql-proxy $CONNECTION_NAME"
echo ""
echo "Next steps:"
echo "  1. Update backend/.env with these credentials"
echo "  2. Run schema migration: python scripts/gcp/2_migrate_schema.py"
