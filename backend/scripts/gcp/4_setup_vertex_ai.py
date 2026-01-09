"""
Vertex AI Vector Search Setup Script
Creates and deploys a vector search index on GCP
"""

import os
from google.cloud import aiplatform
from google.cloud.aiplatform import MatchingEngineIndex, MatchingEngineIndexEndpoint
from dotenv import load_dotenv

load_dotenv()

# Configuration
PROJECT_ID = os.getenv("GCP_PROJECT_ID", "postgresql-479201")
REGION = os.getenv("GCP_REGION", "asia-northeast3")
INDEX_DISPLAY_NAME = "certigraph-questions-index"
ENDPOINT_DISPLAY_NAME = "certigraph-questions-endpoint"
DIMENSIONS = 1536  # OpenAI text-embedding-3-small dimensions

def create_index():
    """Create a Vertex AI Vector Search index"""
    print(f"Creating Vertex AI index in project {PROJECT_ID}, region {REGION}...")

    # Initialize Vertex AI
    aiplatform.init(project=PROJECT_ID, location=REGION)

    # Create index configuration
    # Using Tree-AH algorithm for better latency
    index = MatchingEngineIndex.create_tree_ah_index(
        display_name=INDEX_DISPLAY_NAME,
        contents_delta_uri=f"gs://{PROJECT_ID}-vectors/initial",  # GCS bucket for vectors
        dimensions=DIMENSIONS,
        approximate_neighbors_count=10,
        leaf_node_embedding_count=1000,
        leaf_nodes_to_search_percent=10,
        distance_measure_type="DOT_PRODUCT_DISTANCE",  # For normalized embeddings
        description="Vector search index for CertiGraph exam questions"
    )

    print(f"Index created: {index.resource_name}")
    print(f"Index ID: {index.name}")
    return index


def create_endpoint():
    """Create an index endpoint for querying"""
    print(f"Creating index endpoint...")

    aiplatform.init(project=PROJECT_ID, location=REGION)

    endpoint = MatchingEngineIndexEndpoint.create(
        display_name=ENDPOINT_DISPLAY_NAME,
        description="Endpoint for CertiGraph question search",
        public_endpoint_enabled=True  # Enable public access
    )

    print(f"Endpoint created: {endpoint.resource_name}")
    print(f"Endpoint ID: {endpoint.name}")
    return endpoint


def deploy_index(index_id, endpoint_id):
    """Deploy index to endpoint"""
    print(f"Deploying index {index_id} to endpoint {endpoint_id}...")

    aiplatform.init(project=PROJECT_ID, location=REGION)

    endpoint = MatchingEngineIndexEndpoint(endpoint_id)
    deployed_index = endpoint.deploy_index(
        index=index_id,
        deployed_index_id="deployed_certigraph_index",
        display_name="CertiGraph Questions Deployed",
        machine_type="e2-standard-2",
        min_replica_count=1,
        max_replica_count=2
    )

    print(f"Index deployed successfully!")
    return deployed_index


def setup_gcs_bucket():
    """Create GCS bucket for vector storage"""
    from google.cloud import storage

    bucket_name = f"{PROJECT_ID}-vectors"
    print(f"Creating GCS bucket: {bucket_name}")

    storage_client = storage.Client(project=PROJECT_ID)

    try:
        bucket = storage_client.create_bucket(
            bucket_name,
            location=REGION.split("-")[0]  # Extract region prefix (e.g., "asia")
        )
        print(f"Bucket {bucket.name} created successfully")

        # Create initial empty folder
        blob = bucket.blob("initial/.gitkeep")
        blob.upload_from_string("")
        print("Created initial/ folder in bucket")

    except Exception as e:
        if "already exists" in str(e):
            print(f"Bucket {bucket_name} already exists")
        else:
            raise


def main():
    print("=== Vertex AI Vector Search Setup ===\n")

    # Step 1: Create GCS bucket
    print("Step 1: Setting up GCS bucket for vectors...")
    setup_gcs_bucket()
    print()

    # Step 2: Create index
    print("Step 2: Creating Vertex AI index (this may take 30-60 minutes)...")
    index = create_index()
    print()

    # Step 3: Create endpoint
    print("Step 3: Creating index endpoint...")
    endpoint = create_endpoint()
    print()

    # Step 4: Deploy index (optional - can be done later after data migration)
    deploy_choice = input("Deploy index now? (y/n): ").strip().lower()
    if deploy_choice == 'y':
        print("Step 4: Deploying index to endpoint...")
        deploy_index(index.name, endpoint.name)
    else:
        print("Skipping deployment. You can deploy later using:")
        print(f"  python scripts/gcp/deploy_vertex_index.py {index.name} {endpoint.name}")

    print("\n✅ Vertex AI setup completed!")
    print(f"\nAdd these to your .env file:")
    print(f"VERTEX_AI_INDEX_ID={index.name}")
    print(f"VERTEX_AI_INDEX_ENDPOINT_ID={endpoint.name}")
    print(f"\nNext steps:")
    print("  1. Migrate vectors from Pinecone to Vertex AI")
    print("  2. Update backend code to use Vertex AI client")


if __name__ == "__main__":
    # Check for credentials
    if not os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
        print("Error: GOOGLE_APPLICATION_CREDENTIALS environment variable not set")
        print("Please set it to the path of your service account key JSON file")
        exit(1)

    main()
