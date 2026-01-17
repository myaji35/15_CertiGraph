# Epic 5: Content Structuring - Implementation Documentation

## Overview

Epic 5 implements a comprehensive content structuring system for the Certi-Graph platform, including:
- **Automatic Content Classification**: AI-powered categorization and difficulty assessment
- **Tagging System**: Flexible tag management with contexts and relevance scores
- **Metadata Extraction**: Automatic extraction of document statistics and exam information
- **Full API**: RESTful endpoints for all content structuring operations

## Implementation Status: 100% Complete

### Success Criteria
- ✅ Tag and Tagging models created with full associations
- ✅ Automatic classification algorithm (AI-powered, 80%+ accuracy potential)
- ✅ Automatic tag generation (keyword + AI-based)
- ✅ 12+ API endpoints implemented
- ✅ StudyMaterial extended with category, difficulty, content_metadata fields
- ✅ All database migrations completed
- ✅ Comprehensive test coverage

---

## Database Schema

### Tags Table
```ruby
create_table :tags do |t|
  t.string :name, null: false              # Normalized tag name (lowercase)
  t.string :category                       # Tag category (topic, difficulty, etc.)
  t.integer :usage_count, default: 0      # Counter cache for taggings
  t.json :metadata, default: {}           # Extensible metadata
  t.timestamps
end

# Indexes
add_index :tags, :name, unique: true
add_index :tags, :category
add_index :tags, :usage_count
```

### Taggings Table
```ruby
create_table :taggings do |t|
  t.references :tag, null: false, foreign_key: true
  t.references :taggable, polymorphic: true, null: false  # Polymorphic for extensibility
  t.string :context                        # Tag context (topic, difficulty, year, etc.)
  t.integer :relevance_score, default: 100 # Relevance score (0-100)
  t.timestamps
end

# Indexes
add_index :taggings, [:taggable_type, :taggable_id, :tag_id], unique: true
add_index :taggings, :context
```

### StudyMaterials Extensions
```ruby
add_column :study_materials, :category, :string
add_column :study_materials, :difficulty, :integer, default: 3
add_column :study_materials, :content_metadata, :json, default: {}

add_index :study_materials, :category
add_index :study_materials, :difficulty
```

---

## Models

### Tag Model
**Location**: `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/app/models/tag.rb`

#### Associations
```ruby
has_many :taggings, dependent: :destroy
has_many :study_materials, through: :taggings, source: :taggable, source_type: 'StudyMaterial'
```

#### Validations
- `name`: Required, unique (case-insensitive)
- `usage_count`: Non-negative integer

#### Key Methods
- `self.find_or_create_by_name(name, attributes = {})` - Normalized tag creation
- `self.most_used(limit = 10)` - Get most popular tags
- `self.for_context(context)` - Filter tags by context
- `increment_usage!` / `decrement_usage!` - Manage usage count
- `display_name` - Titleized display name
- `tagging_stats` - Comprehensive statistics

#### Scopes
```ruby
scope :popular        # Tags with usage > 0, ordered by usage
scope :by_category    # Filter by category
scope :recent         # Ordered by creation date
scope :alphabetical   # Ordered by name
```

### Tagging Model
**Location**: `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/app/models/tagging.rb`

#### Associations
```ruby
belongs_to :tag, counter_cache: :usage_count
belongs_to :taggable, polymorphic: true
```

#### Validations
- `tag_id`: Unique per taggable
- `relevance_score`: 0-100 (if provided)

#### Key Methods
- `high_relevance?` - Score >= 75
- `medium_relevance?` - Score 50-74
- `low_relevance?` - Score < 50
- `relevance_label` - String label (high/medium/low/unknown)

#### Scopes
```ruby
scope :by_context        # Filter by context
scope :relevant          # Relevance >= 50, ordered by relevance
scope :for_study_materials  # Only study material taggings
```

### StudyMaterial Extensions
**Location**: `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/app/models/study_material.rb`

#### New Associations
```ruby
has_many :taggings, as: :taggable, dependent: :destroy
has_many :tags, through: :taggings
```

#### Content Structuring Methods
```ruby
# Classification
auto_classify!              # Run AI classification
category_display           # Human-readable category
difficulty_display         # Human-readable difficulty

# Metadata
extract_metadata!          # Extract metadata from content
exam_year                  # Extracted exam year
exam_round                 # Extracted exam round
certification_name         # Extracted certification
complexity_score           # Calculated complexity (0-100)

# Tagging
auto_tag!                  # Generate tags automatically
add_tag(name, context:, relevance_score:)  # Manual tag addition
remove_tag(name)           # Remove tag by name
tag_names                  # Array of tag names
tags_by_context(context)   # Tags filtered by context

# Full Pipeline
structure_content!         # Run all structuring steps
```

#### New Scopes
```ruby
scope :by_epic5_difficulty  # Filter by difficulty level
scope :by_year              # Filter by exam year
scope :with_tags            # Has at least one tag
scope :tagged_with          # Has specific tag
scope :easy                 # Difficulty 1-2
scope :medium               # Difficulty 3
scope :hard                 # Difficulty 4-5
scope :structured           # Has category and difficulty
scope :needs_structuring    # Completed but unstructured
```

---

## Services

### ContentClassificationService
**Location**: `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/app/services/content_classification_service.rb`

#### Purpose
Automatically classify study materials by category and difficulty using AI.

#### Categories (15 total)
```ruby
CATEGORIES = {
  'information_processing' => '정보처리',
  'electrical' => '전기',
  'architecture' => '건축',
  'fire_safety' => '소방',
  'hazardous_materials' => '위험물',
  'accounting' => '회계',
  'taxation' => '세무',
  'finance' => '금융',
  'real_estate' => '부동산',
  'construction' => '건설',
  'environment' => '환경',
  'safety' => '안전',
  'quality' => '품질',
  'logistics' => '물류',
  'other' => '기타'
}
```

#### Difficulty Levels
```ruby
DIFFICULTY_LEVELS = {
  1 => '매우 쉬움',
  2 => '쉬움',
  3 => '보통',
  4 => '어려움',
  5 => '매우 어려움'
}
```

#### Usage
```ruby
service = ContentClassificationService.new(study_material)
service.classify  # Returns true/false

# Batch processing
ContentClassificationService.classify_batch(study_materials)

# Helper methods
ContentClassificationService.category_name('information_processing')  # => '정보처리'
ContentClassificationService.difficulty_name(3)  # => '보통'
ContentClassificationService.suggest_category(text)  # Quick keyword-based suggestion
```

#### AI Integration
- Uses OpenAI GPT-4o-mini for classification
- Analyzes document title, sample questions, and metadata
- Returns category, difficulty, confidence score, reasoning, and keywords
- Updates StudyMaterial with classification results

### ContentMetadataService
**Location**: `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/app/services/content_metadata_service.rb`

#### Purpose
Extract comprehensive metadata from study materials.

#### Extracted Metadata
```ruby
{
  # Document statistics
  total_questions: 100,
  total_chunks: 50,
  total_knowledge_nodes: 75,
  has_pdf: true,
  pdf_filename: "exam.pdf",
  pdf_size_bytes: 1024000,
  pdf_content_type: "application/pdf",

  # Exam information
  exam_year: 2023,
  exam_round: 1,
  certification_name: "정보처리기사",
  exam_type: "written",
  issuing_organization: "Q-Net",

  # Content structure
  has_chapters: true,
  has_sections: true,
  has_images: false,
  has_tables: true,

  # Difficulty analysis
  estimated_difficulty: 3,
  difficulty_factors: ["long_questions", "complex_knowledge_graph"],
  avg_question_length: 150,
  knowledge_nodes_count: 75,
  knowledge_edges_count: 120,
  complexity_score: 72,

  # Metadata
  metadata_extracted_at: "2026-01-15T12:00:00Z",
  metadata_version: "1.0"
}
```

#### Usage
```ruby
service = ContentMetadataService.new(study_material)
service.extract_metadata  # Returns true/false

# Batch processing
ContentMetadataService.extract_batch(study_materials)

# Regenerate all
ContentMetadataService.regenerate_all
```

### AutoTaggingService
**Location**: `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/app/services/auto_tagging_service.rb`

#### Purpose
Automatically generate relevant tags using AI and keyword analysis.

#### Tag Sources
1. **AI-based tagging**: Uses OpenAI to analyze content and suggest tags
2. **Keyword-based tagging**: Pattern matching against predefined topics
3. **Metadata-based tagging**: Extracts tags from difficulty, year, category

#### Topic Keywords (14 topics)
```ruby
TOPIC_KEYWORDS = {
  '알고리즘' => ['알고리즘', '정렬', '탐색', '재귀'],
  '네트워크' => ['네트워크', 'tcp', 'ip', '프로토콜', 'osi'],
  '데이터베이스' => ['데이터베이스', 'sql', '정규화', '트랜잭션'],
  '운영체제' => ['운영체제', '프로세스', '스레드', '메모리'],
  '자료구조' => ['자료구조', '스택', '큐', '트리', '그래프'],
  # ... 9 more topics
}
```

#### Usage
```ruby
service = AutoTaggingService.new(study_material)
service.generate_tags  # Returns true/false

# Batch processing
AutoTaggingService.tag_batch(study_materials)

# Clear and regenerate
AutoTaggingService.clear_tags(study_material)
AutoTaggingService.regenerate_tags(study_material)
AutoTaggingService.regenerate_all
```

#### Tag Contexts
- `topic`: Subject matter tags (알고리즘, 네트워크, etc.)
- `skill`: Required skills (문제해결, 논리적사고)
- `concept`: Key concepts (객체지향, 함수형프로그래밍)
- `exam_type`: Exam characteristics (단답형, 서술형)
- `difficulty`: Difficulty tags (초급, 중급, 고급)
- `year`: Year tags (2023년, 2024년)
- `category`: Category tags (정보처리, 전기, etc.)

---

## API Endpoints

### TagsController
**Location**: `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/app/controllers/tags_controller.rb`

#### Routes
**Location**: `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/config/routes.rb`

```ruby
# Main routes
resources :tags do
  collection do
    get :popular
    get :contexts
    get :search
    post :apply
    delete :remove
    post :auto_tag
    post :merge
  end
end

# API v1 routes
namespace :api do
  namespace :v1 do
    resources :tags do
      collection do
        get :popular
        get :contexts
        get :search
        post :apply
        delete :remove
        post :auto_tag
        post :merge
      end
    end

    resources :study_materials, only: [] do
      member do
        post :classify
        post :extract_metadata
        post :structure_content
        get :content_metadata
      end
    end
  end
end
```

### Endpoint Details

#### 1. GET /tags
List all tags with filtering and pagination.

**Query Parameters:**
- `category` - Filter by category
- `context` - Filter by context
- `search` - Search by name
- `sort` - Sort order (popular, recent, alphabetical)
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 50)

**Response:**
```json
{
  "tags": [
    {
      "id": 1,
      "name": "알고리즘",
      "display_name": "알고리즘",
      "category": "topic",
      "usage_count": 5,
      "created_at": "2026-01-15T12:00:00Z",
      "updated_at": "2026-01-15T12:00:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 50,
    "total": 10
  }
}
```

#### 2. GET /tags/:id
Get specific tag with detailed statistics.

**Response:**
```json
{
  "tag": {
    "id": 1,
    "name": "알고리즘",
    "display_name": "알고리즘",
    "category": "topic",
    "usage_count": 5,
    "created_at": "2026-01-15T12:00:00Z",
    "updated_at": "2026-01-15T12:00:00Z",
    "stats": {
      "total_taggings": 5,
      "study_materials_count": 3,
      "avg_relevance": 87.5,
      "contexts": ["topic", "skill"]
    }
  },
  "study_materials": [...]
}
```

#### 3. POST /tags
Create a new tag.

**Request Body:**
```json
{
  "tag": {
    "name": "머신러닝",
    "category": "topic",
    "metadata": {}
  }
}
```

**Response:**
```json
{
  "message": "Tag created successfully",
  "tag": {...}
}
```

#### 4. GET /tags/popular
Get most popular tags.

**Query Parameters:**
- `limit` - Number of tags (default: 20)

**Response:**
```json
{
  "tags": [
    {
      "id": 1,
      "name": "알고리즘",
      "usage_count": 15,
      "stats": {...}
    }
  ]
}
```

#### 5. GET /tags/contexts
Get all available tag contexts with counts.

**Response:**
```json
{
  "contexts": ["topic", "difficulty", "year"],
  "counts": [
    {"context": "topic", "count": 25},
    {"context": "difficulty", "count": 10},
    {"context": "year", "count": 5}
  ]
}
```

#### 6. POST /tags/apply
Apply tags to a study material.

**Request Body:**
```json
{
  "study_material_id": 1,
  "tags": ["알고리즘", "네트워크"],
  "context": "topic",
  "relevance_score": 90
}
```

**Response:**
```json
{
  "message": "Applied 2 tags",
  "tags": [...],
  "study_material": {...}
}
```

#### 7. DELETE /tags/remove
Remove tags from a study material.

**Request Body:**
```json
{
  "study_material_id": 1,
  "tag_ids": [1, 2, 3]
}
```

**Response:**
```json
{
  "message": "Removed 3 tags",
  "study_material": {...}
}
```

#### 8. GET /tags/search
Search tags by name.

**Query Parameters:**
- `q` - Search query

**Response:**
```json
{
  "tags": [...],
  "query": "알고"
}
```

#### 9. POST /tags/auto_tag
Auto-generate tags for a study material.

**Request Body:**
```json
{
  "study_material_id": 1
}
```

**Response:**
```json
{
  "message": "Tags generated successfully",
  "tags": [...],
  "study_material": {...}
}
```

#### 10. POST /tags/merge (Admin only)
Merge multiple tags into one.

**Request Body:**
```json
{
  "source_tag_ids": [2, 3],
  "target_tag_id": 1
}
```

**Response:**
```json
{
  "message": "Merged 5 taggings into '알고리즘'",
  "tag": {...}
}
```

#### 11. POST /api/v1/study_materials/:id/classify
Classify study material content.

**Response:**
```json
{
  "message": "Classification successful",
  "category": "information_processing",
  "difficulty": 3,
  "confidence": 0.92
}
```

#### 12. POST /api/v1/study_materials/:id/extract_metadata
Extract metadata from study material.

**Response:**
```json
{
  "message": "Metadata extracted successfully",
  "metadata": {...}
}
```

#### 13. POST /api/v1/study_materials/:id/structure_content
Run full content structuring pipeline (classify + extract + tag).

**Response:**
```json
{
  "message": "Content structured successfully",
  "category": "information_processing",
  "difficulty": 3,
  "tags_count": 8,
  "metadata": {...}
}
```

#### 14. GET /api/v1/study_materials/:id/content_metadata
Retrieve study material metadata.

**Response:**
```json
{
  "exam_year": 2023,
  "exam_round": 1,
  "certification_name": "정보처리기사",
  "complexity_score": 72,
  "total_questions": 100,
  "metadata": {...}
}
```

---

## Usage Examples

### Complete Content Structuring Pipeline

```ruby
# 1. Create study material
study_material = StudyMaterial.create!(
  study_set: study_set,
  name: "정보처리기사 2023년 1회",
  status: "completed"
)

# 2. Run full structuring pipeline
study_material.structure_content!

# This performs:
# - Auto-classification (category + difficulty)
# - Metadata extraction (stats, exam info, complexity)
# - Auto-tagging (AI + keyword-based tags)

# 3. Access results
study_material.category          # => "information_processing"
study_material.category_display  # => "정보처리"
study_material.difficulty        # => 3
study_material.difficulty_display # => "보통"
study_material.exam_year         # => 2023
study_material.complexity_score  # => 72
study_material.tag_names         # => ["알고리즘", "네트워크", "초급", ...]

# 4. Query materials
StudyMaterial.by_category("information_processing")
StudyMaterial.medium  # difficulty = 3
StudyMaterial.tagged_with("알고리즘")
StudyMaterial.structured  # has category AND difficulty
```

### Manual Tagging

```ruby
# Add tag manually
study_material.add_tag("프로그래밍", context: "topic", relevance_score: 85)

# Remove tag
study_material.remove_tag("프로그래밍")

# Get tags by context
topic_tags = study_material.tags_by_context("topic")
difficulty_tags = study_material.tags_by_context("difficulty")
```

### Tag Management

```ruby
# Create tag
tag = Tag.find_or_create_by_name("딥러닝", category: "topic")

# Get popular tags
popular_tags = Tag.most_used(10)

# Search tags
results = Tag.where('name LIKE ?', '%알고%')

# Get tag statistics
stats = tag.tagging_stats
# => {
#   total_taggings: 10,
#   study_materials_count: 5,
#   avg_relevance: 87.5,
#   contexts: ["topic", "skill"]
# }
```

### Filtering Study Materials

```ruby
# By category
materials = StudyMaterial.by_category("information_processing")

# By difficulty
easy_materials = StudyMaterial.easy      # difficulty 1-2
medium_materials = StudyMaterial.medium  # difficulty 3
hard_materials = StudyMaterial.hard      # difficulty 4-5

# By tags
algo_materials = StudyMaterial.tagged_with("알고리즘")

# Combined filters
StudyMaterial
  .by_category("information_processing")
  .medium
  .tagged_with("알고리즘")
  .where("content_metadata->>'exam_year' = '2023'")
```

---

## Testing

### Test Files

1. **Epic 5 Model & Service Test**
   - Location: `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/test/epic5_test.rb`
   - Tests: Tag/Tagging models, all services, helper methods, scopes
   - Status: ✅ All 15 tests passing

2. **Epic 5 API Test**
   - Location: `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/test/epic5_api_test.rb`
   - Tests: All 12+ API endpoints, filtering, statistics
   - Status: ✅ All tests passing

### Running Tests

```bash
# Run model and service tests
ruby test/epic5_test.rb

# Run API tests
ruby test/epic5_api_test.rb
```

---

## Performance Considerations

### Counter Caching
- `Tag.usage_count` is automatically maintained via `counter_cache` on `Tagging`
- Eliminates COUNT queries when sorting by popularity

### Indexes
- All foreign keys are indexed
- Unique indexes on tag names and tagging relationships
- Composite indexes for common queries

### Batch Operations
All services support batch processing:
```ruby
ContentClassificationService.classify_batch(materials)
ContentMetadataService.extract_batch(materials)
AutoTaggingService.tag_batch(materials)
```

### Polymorphic Future-Proofing
- Taggings use polymorphic associations
- Can easily tag Questions, Users, or other models in the future

---

## Future Enhancements

### Planned Features
1. **Tag Merging UI**: Admin interface for merging duplicate tags
2. **Tag Synonyms**: Map multiple tag names to canonical tags
3. **Tag Hierarchies**: Parent-child relationships (e.g., "알고리즘" → "정렬")
4. **Smart Tag Suggestions**: ML-based tag recommendations
5. **Tag Analytics Dashboard**: Usage trends, popular combinations
6. **Bulk Tagging**: Apply tags to multiple materials at once
7. **Tag Import/Export**: CSV import for bulk tag management

### API Enhancements
1. **Pagination**: Add proper pagination to all list endpoints
2. **Filtering**: More advanced filtering options
3. **Sorting**: Multiple sort options
4. **Rate Limiting**: Protect AI-powered endpoints
5. **Caching**: Cache popular tags and statistics

---

## Migration Guide

### For Existing Data

```ruby
# Classify all completed materials
StudyMaterial.where(status: 'completed', category: nil).find_each do |material|
  ContentClassificationService.new(material).classify
end

# Extract metadata for all materials
StudyMaterial.where(status: 'completed').find_each do |material|
  ContentMetadataService.new(material).extract_metadata
end

# Auto-tag all materials
StudyMaterial.where(status: 'completed').find_each do |material|
  AutoTaggingService.new(material).generate_tags
end

# Or use the convenience method
StudyMaterial.where(status: 'completed').find_each(&:structure_content!)
```

---

## Configuration

### OpenAI API Key
Ensure OpenAI API key is configured in `OpenaiClient`:
```ruby
# config/initializers/openai.rb or environment variable
ENV['OPENAI_API_KEY'] = 'your-api-key'
```

### Classification Categories
To add new categories, update:
```ruby
# app/services/content_classification_service.rb
CATEGORIES = {
  # ... existing categories
  'new_category' => '새 카테고리'
}
```

### Topic Keywords
To add new topic keywords for auto-tagging:
```ruby
# app/services/auto_tagging_service.rb
TOPIC_KEYWORDS = {
  # ... existing keywords
  '새로운주제' => ['키워드1', '키워드2']
}
```

---

## Error Handling

All services return `true/false` and expose errors:
```ruby
service = ContentClassificationService.new(material)
if service.classify
  puts "Success!"
else
  puts "Errors: #{service.errors.join(', ')}"
end
```

Common errors:
- `"Study material is nil"` - Invalid material
- `"Study material must be in 'completed' status"` - Material not ready
- `"No content available for classification"` - Empty content
- `"Classification failed: [API error]"` - AI service error

---

## Changelog

### Version 1.0.0 (2026-01-15)
- ✅ Initial implementation
- ✅ Tag and Tagging models
- ✅ ContentClassificationService (15 categories, 5 difficulty levels)
- ✅ ContentMetadataService (document stats, exam info, complexity analysis)
- ✅ AutoTaggingService (AI + keyword-based, 14 topic categories)
- ✅ TagsController with 12+ endpoints
- ✅ StudyMaterial extensions (associations, methods, scopes)
- ✅ Database migrations
- ✅ Comprehensive test coverage
- ✅ Full documentation

---

## Contact & Support

For questions or issues related to Epic 5: Content Structuring, please refer to:
- Main Project Documentation: `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/prd.md`
- Test Files: `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/test/epic5_*.rb`
- Source Code: `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/app/`

---

**Epic 5: Content Structuring - Implementation Complete ✅**
