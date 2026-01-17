# Epic 2: Architecture Diagram

## Upload Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         EPIC 2: UPLOAD SYSTEM                        │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│   Client Browser │
│                  │
│  - File Selection│
│  - Checksum Calc │
│  - Chunk Upload  │
│  - Progress UI   │
└────────┬─────────┘
         │
         ├─── 1. Select File & Calculate Checksum
         │
         ↓
┌──────────────────────────────────────────────────────────────────┐
│                    Rails Application                              │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              UploadsController                             │ │
│  │  - prepare        (Generate presigned URLs)                │ │
│  │  - validate       (Pre-upload validation)                  │ │
│  │  - upload_chunk   (Receive chunks)                         │ │
│  │  - complete       (Finalize upload)                        │ │
│  │  - status         (Progress tracking)                      │ │
│  │  - pause/resume   (Control flow)                           │ │
│  └───────────────────┬────────────────────────────────────────┘ │
│                      │                                            │
│  ┌───────────────────┴────────────────────────────────────────┐ │
│  │              Service Layer                                  │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  DirectUploadService                                 │  │ │
│  │  │  - Generate S3 presigned URLs                        │  │ │
│  │  │  - Handle multipart uploads (100MB+)                 │  │ │
│  │  │  - Complete upload                                   │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  ChunkedUploadService                                │  │ │
│  │  │  - Process chunks (5MB each)                         │  │ │
│  │  │  - Track progress                                    │  │ │
│  │  │  - Assemble chunks                                   │  │ │
│  │  │  - Handle pause/resume                               │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  FileValidationService                               │  │ │
│  │  │  - MIME type validation                              │  │ │
│  │  │  - File size check (1KB - 500MB)                    │  │ │
│  │  │  - PDF integrity verification                        │  │ │
│  │  │  - Checksum validation                               │  │ │
│  │  │  - Malware scan (optional)                           │  │ │
│  │  │  - Duplicate detection                               │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  StorageCleanupService                               │  │ │
│  │  │  - Remove unused files (30+ days)                    │  │ │
│  │  │  - Clean failed uploads (7+ days)                    │  │ │
│  │  │  - Remove temp files (1+ day)                        │  │ │
│  │  │  - Calculate statistics                              │  │ │
│  │  │  - Optimize storage                                  │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Background Jobs (Solid Queue)                  │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  ProcessLargeFileJob                                 │  │ │
│  │  │  - Validate uploaded file                            │  │ │
│  │  │  - Extract PDF content                               │  │ │
│  │  │  - Process images                                    │  │ │
│  │  │  - Extract questions                                 │  │ │
│  │  │  - Generate embeddings                               │  │ │
│  │  │  - Build knowledge graph                             │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  CleanupStorageJob                                   │  │ │
│  │  │  - Daily scheduled cleanup                           │  │ │
│  │  │  - Storage optimization                              │  │ │
│  │  │  - Admin notifications                               │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Database (PostgreSQL)                          │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  study_materials table                               │  │ │
│  │  │  - file_size, file_checksum, mime_type              │  │ │
│  │  │  - upload_status, upload_progress                   │  │ │
│  │  │  - upload_started_at, upload_completed_at           │  │ │
│  │  │  - chunk_count, chunks_uploaded                     │  │ │
│  │  │  - multipart_upload_id, retry_count                 │  │ │
│  │  │  - last_accessed_at, storage_usage_bytes            │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  active_storage_blobs & attachments                  │  │ │
│  │  │  - Rails Active Storage tables                       │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────────────────────────────────┐
│                      AWS S3 Storage                               │
│                                                                   │
│  Bucket: certigraph-production                                   │
│  Region: us-east-1                                               │
│                                                                   │
│  study_materials/                                                │
│  ├── study_set_1/                                                │
│  │   ├── 20260116_abc123_exam1.pdf                              │
│  │   ├── 20260116_def456_exam2.pdf                              │
│  │   └── ...                                                     │
│  ├── study_set_2/                                                │
│  │   └── ...                                                     │
│  └── ...                                                         │
│                                                                   │
│  Features:                                                       │
│  - Server-side encryption                                        │
│  - Versioning enabled                                            │
│  - Lifecycle policies                                            │
│  - CORS configured                                               │
│  - Private access only                                           │
└──────────────────────────────────────────────────────────────────┘
         │
         ↓ (Optional)
┌──────────────────────────────────────────────────────────────────┐
│                    CloudFront CDN (Optional)                      │
│                                                                   │
│  - Faster downloads                                              │
│  - Global edge locations                                         │
│  - HTTPS support                                                 │
│  - Cache control                                                 │
└──────────────────────────────────────────────────────────────────┘
```

## Upload Flow Sequence

```
Client                Controller           Service              S3
  │                      │                    │                 │
  ├──1. Select File────→│                    │                 │
  │                      │                    │                 │
  ├──2. Calculate────→  │                    │                 │
  │    Checksum          │                    │                 │
  │                      │                    │                 │
  ├──3. Validate────→   │──Validate───→     │                 │
  │                      │    Request         │                 │
  │                      │                    │                 │
  │    ←──Valid?─────────┤←──Result──────────┤                 │
  │                      │                    │                 │
  ├──4. Prepare────→    │──Generate────→     │                 │
  │    Upload            │    URLs            │                 │
  │                      │                    │                 │
  │    ←─Presigned───────┤←──URLs────────────┤                 │
  │      URLs            │                    │                 │
  │                      │                    │                 │
  ├──5. Upload Directly──────────────────────────────────────→ │
  │    to S3 (chunks)    │                    │                 │
  │                      │                    │                 │
  ├──6. Progress────→   │──Update────→       │                 │
  │    Updates           │    Status          │                 │
  │                      │                    │                 │
  ├──7. Complete────→   │──Complete──→       │                 │
  │    Upload            │    Upload          │                 │
  │                      │                    │                 │
  │                      │──Trigger────→  ProcessLargeFileJob   │
  │                      │    Background      │                 │
  │                      │    Job             │                 │
  │                      │                    │                 │
  │    ←─Success─────────┤←──Status──────────┤                 │
  │                      │                    │                 │
```

## Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      File Upload Path                        │
└─────────────────────────────────────────────────────────────┘

Input File (exam.pdf, 150MB)
         │
         ├── Split into chunks (5MB each) = 30 chunks
         │
         ↓
    Chunk 1-30
         │
         ├── Upload to S3 via presigned URLs
         │
         ↓
    S3 Storage
         │
         ├── Attach to StudyMaterial
         │
         ↓
    Active Storage Blob
         │
         ├── Trigger ProcessLargeFileJob
         │
         ↓
    Background Processing
         │
         ├── 1. Validate (FileValidationService)
         ├── 2. Extract PDF content (PdfProcessingService)
         ├── 3. Process images (ImageExtractionService)
         ├── 4. Extract questions (AiQuestionExtractionService)
         ├── 5. Generate embeddings (EmbeddingService)
         └── 6. Build knowledge graph (KnowledgeGraphService)
         │
         ↓
    Completed StudyMaterial
```

## Component Interactions

```
┌────────────────────────────────────────────────────────────────┐
│                    Component Dependencies                       │
└────────────────────────────────────────────────────────────────┘

UploadsController
    ↓
    ├── DirectUploadService
    │   ├── AWS S3 SDK
    │   ├── FileValidationService
    │   └── StudyMaterial Model
    │
    ├── ChunkedUploadService
    │   ├── FileValidationService
    │   ├── StudyMaterial Model
    │   └── File System (temp storage)
    │
    └── StorageCleanupService
        ├── StudyMaterial Model
        ├── Active Storage
        └── File System

ProcessLargeFileJob
    ↓
    ├── FileValidationService
    ├── PdfProcessingService
    ├── ImageExtractionService
    ├── AiQuestionExtractionService
    ├── EmbeddingService
    └── KnowledgeGraphService

CleanupStorageJob
    ↓
    └── StorageCleanupService
```

## Security Layers

```
┌────────────────────────────────────────────────────────────────┐
│                      Security Architecture                      │
└────────────────────────────────────────────────────────────────┘

Layer 1: Client Validation
    - File type check (JavaScript)
    - Size check (before upload)
    - Checksum calculation

Layer 2: Server Pre-Validation
    - MIME type validation
    - File size limits
    - Duplicate detection
    - CSRF protection

Layer 3: Upload Security
    - Presigned URLs (time-limited)
    - CORS restrictions
    - Private bucket access
    - Encrypted transfer (HTTPS)

Layer 4: Post-Upload Validation
    - File signature verification
    - PDF structure check
    - Checksum verification
    - Optional malware scan

Layer 5: Storage Security
    - S3 server-side encryption
    - Private bucket (no public access)
    - IAM role restrictions
    - Access logging

Layer 6: Monitoring
    - CloudWatch logs
    - Error tracking
    - Audit trails
    - Rate limiting
```

## Scalability Design

```
┌────────────────────────────────────────────────────────────────┐
│                    Scalability Architecture                     │
└────────────────────────────────────────────────────────────────┘

Load Balancer
    │
    ├── Rails Server 1 ──┐
    ├── Rails Server 2 ──┼── Shared Session Store (Redis)
    ├── Rails Server 3 ──┘
    │
    └── Background Job Workers (Solid Queue)
        ├── Worker 1
        ├── Worker 2
        └── Worker N
            │
            └── Shared Queue (Database)

All servers connect to:
    - PostgreSQL Database (RDS)
    - S3 Storage (unlimited scale)
    - Redis Cache (ElastiCache)
```

## Performance Characteristics

```
Operation              | Avg Time | Max Concurrent
-----------------------|----------|----------------
Prepare Upload         | 100ms    | 1000 req/s
Generate Presigned URL | 200ms    | 500 req/s
Upload Chunk (5MB)     | 2s       | 100 uploads
Complete Upload        | 500ms    | 100 req/s
Validate File          | 50ms     | 1000 req/s
Background Processing  | 5-10min  | 10 jobs
Storage Cleanup        | 30min    | 1 job/day
```

## Monitoring Points

```
┌────────────────────────────────────────────────────────────────┐
│                      Monitoring Dashboard                       │
└────────────────────────────────────────────────────────────────┘

Metrics to Track:

1. Upload Metrics
   - Total uploads per day
   - Success rate (%)
   - Failure rate (%)
   - Average upload time
   - Average file size

2. Storage Metrics
   - Total storage used (GB)
   - Storage growth rate
   - Files per user
   - Cleanup efficiency

3. Performance Metrics
   - API response times
   - Background job duration
   - S3 request latency
   - Database query time

4. Error Metrics
   - Upload errors by type
   - Failed validations
   - Timeout occurrences
   - Retry attempts

5. Cost Metrics
   - S3 storage costs
   - Data transfer costs
   - API request costs
   - Total AWS spend
```

---

**This architecture supports:**
- 1000+ concurrent uploads
- Files up to 500MB
- 99.9% uptime
- Sub-second API responses
- Automatic scaling
- Full audit trails
