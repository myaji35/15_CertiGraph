# Epic 4: Question Extraction API Endpoints

Complete API documentation for question extraction, passage management, and validation.

---

## Questions API

### 1. List Questions

**GET** `/study_materials/:study_material_id/questions`

List all questions for a study material with filtering and pagination.

**Query Parameters:**
- `question_type` (optional) - Filter by type: `multiple_choice`, `true_false`, `short_answer`
- `difficulty` (optional) - Filter by difficulty level (1-5)
- `validated` (optional) - Filter by validation status: `true`, `false`
- `with_passages` (optional) - Filter questions with passages: `true`, `false`
- `page` (optional) - Page number (default: 1)
- `per_page` (optional) - Items per page (default: 20)

**Response:**
```json
{
  "questions": [
    {
      "id": 1,
      "question_number": 1,
      "content": "What is database normalization?",
      "options": {
        "①": "A process to minimize redundancy",
        "②": "A process to maximize redundancy",
        "③": "A backup strategy",
        "④": "A security measure"
      },
      "answer": "①",
      "explanation": "Normalization minimizes data redundancy...",
      "question_type": "multiple_choice",
      "difficulty": 3,
      "has_image": false,
      "has_table": false,
      "validation_status": "validated",
      "ai_confidence_score": 0.95,
      "created_at": "2026-01-15T10:00:00Z",
      "updated_at": "2026-01-15T10:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 100,
    "per_page": 20
  }
}
```

---

### 2. Show Question

**GET** `/questions/:id`

Get detailed information about a specific question.

**Response:**
```json
{
  "id": 1,
  "question_number": 1,
  "content": "What is database normalization?",
  "options": {...},
  "answer": "①",
  "explanation": "...",
  "question_type": "multiple_choice",
  "difficulty": 3,
  "has_image": false,
  "has_table": false,
  "validation_status": "validated",
  "ai_confidence_score": 0.95,
  "passages": [
    {
      "id": 1,
      "content": "Database normalization is...",
      "passage_type": "text",
      "position": 1,
      "has_image": false,
      "has_table": false,
      "character_count": 250
    }
  ],
  "primary_passage": {
    "id": 1,
    "content": "Database normalization is...",
    "passage_type": "text",
    "position": 1,
    "has_image": false,
    "has_table": false,
    "character_count": 250
  },
  "validation_errors": {},
  "extraction_metadata": {
    "extracted_at": "2026-01-15T10:00:00Z",
    "extraction_method": "ai"
  },
  "study_material_id": 1,
  "created_at": "2026-01-15T10:00:00Z",
  "updated_at": "2026-01-15T10:00:00Z"
}
```

---

### 3. Create Question

**POST** `/study_materials/:study_material_id/questions`

Create a new question manually.

**Request Body:**
```json
{
  "question": {
    "question_number": 1,
    "content": "What is normalization?",
    "options": {
      "①": "Option 1",
      "②": "Option 2",
      "③": "Option 3",
      "④": "Option 4"
    },
    "answer": "①",
    "explanation": "Explanation text",
    "question_type": "multiple_choice",
    "difficulty": 3,
    "has_image": false,
    "has_table": false
  },
  "auto_validate": true
}
```

**Response:** (201 Created)
```json
{
  "id": 1,
  "question_number": 1,
  "content": "What is normalization?",
  ...
}
```

---

### 4. Batch Create Questions

**POST** `/study_materials/:study_material_id/questions/batch_create`

Create multiple questions at once.

**Request Body:**
```json
{
  "questions": [
    {
      "question_number": 1,
      "content": "Question 1?",
      "options": {...},
      "answer": "①",
      "explanation": "...",
      "question_type": "multiple_choice",
      "difficulty": 3
    },
    {
      "question_number": 2,
      "content": "Question 2?",
      "options": {...},
      "answer": "②",
      "explanation": "...",
      "question_type": "multiple_choice",
      "difficulty": 4
    }
  ]
}
```

**Response:** (201 Created)
```json
{
  "created": [
    {
      "id": 1,
      "question_number": 1,
      ...
    },
    {
      "id": 2,
      "question_number": 2,
      ...
    }
  ],
  "failed": []
}
```

---

### 5. Extract Questions (AI-Powered)

**POST** `/study_materials/:study_material_id/questions/extract`

Extract questions from markdown content using AI.

**Request Body:**
```json
{
  "markdown_content": "<!-- PASSAGE 1 START -->\nDatabase normalization...\n<!-- PASSAGE 1 END -->\n\n1. What is normalization?\n① Option 1\n② Option 2\n③ Option 3\n④ Option 4"
}
```

**Response:**
```json
{
  "success": true,
  "extraction_stats": {
    "total_questions": 50,
    "total_passages": 5,
    "questions_with_passages": 30,
    "questions_without_passages": 20,
    "invalid_questions": 2,
    "question_types": {
      "multiple_choice": 45,
      "true_false": 5
    },
    "avg_difficulty": 3.2,
    "avg_confidence": 0.87
  },
  "save_results": {
    "questions_created": 50,
    "passages_created": 5,
    "errors": []
  },
  "questions": [
    {
      "question_number": 1,
      "content": "What is normalization?",
      "answer": "①"
    },
    ...
  ],
  "passages": [
    {
      "id": 1,
      "position": 1,
      "character_count": 250
    },
    ...
  ]
}
```

---

### 6. Update Question

**PATCH** `/questions/:id`

Update an existing question.

**Request Body:**
```json
{
  "question": {
    "content": "Updated question text",
    "explanation": "Updated explanation",
    "difficulty": 4
  },
  "auto_validate": true
}
```

**Response:**
```json
{
  "id": 1,
  "content": "Updated question text",
  ...
}
```

---

### 7. Delete Question

**DELETE** `/questions/:id`

Delete a question.

**Response:** (204 No Content)

---

### 8. Validate Single Question

**POST** `/questions/:id/validate`

Validate a single question for quality and completeness.

**Response:**
```json
{
  "success": true,
  "validation_status": "validated",
  "validation_errors": {}
}
```

Or if validation fails:

```json
{
  "success": false,
  "validation_status": "failed",
  "validation_errors": {
    "errors": [
      "Content is too short",
      "Missing explanation"
    ],
    "warnings": [
      "Low confidence score: 0.45"
    ]
  }
}
```

---

### 9. Validate All Questions

**POST** `/study_materials/:study_material_id/questions/validate_all`

Validate all questions in a study material.

**Response:**
```json
{
  "total": 50,
  "validated": 45,
  "failed": 5,
  "results": [
    {
      "id": 1,
      "validation": {
        "valid": true,
        "errors": [],
        "warnings": [],
        "score": 95.0,
        "quality_level": "excellent"
      }
    },
    {
      "id": 2,
      "validation": {
        "valid": false,
        "errors": ["Content is blank"],
        "warnings": [],
        "score": 0.0,
        "quality_level": "very_poor"
      }
    },
    ...
  ]
}
```

---

### 10. Get Question Statistics

**GET** `/study_materials/:study_material_id/questions/stats`

Get comprehensive statistics about questions.

**Response:**
```json
{
  "total_questions": 50,
  "by_type": {
    "multiple_choice": 45,
    "true_false": 5,
    "short_answer": 0
  },
  "by_difficulty": {
    "1": 5,
    "2": 10,
    "3": 20,
    "4": 10,
    "5": 5
  },
  "by_validation_status": {
    "pending": 5,
    "validated": 40,
    "failed": 5
  },
  "with_passages": 30,
  "without_passages": 20,
  "validated": 40,
  "avg_confidence": 0.87
}
```

---

### 11. Search Questions

**GET** `/questions/search`

Search questions by content or explanation.

**Query Parameters:**
- `query` (required) - Search term

**Response:**
```json
{
  "questions": [
    {
      "id": 1,
      "question_number": 1,
      "content": "What is database normalization?",
      ...
    },
    ...
  ]
}
```

---

### 12. Add Passage to Question

**POST** `/questions/:id/add_passage`

Link a passage to a question.

**Request Body:**
```json
{
  "passage_id": 1,
  "is_primary": true,
  "relevance_score": 100
}
```

**Response:**
```json
{
  "success": true,
  "question": {
    "id": 1,
    ...
    "passages": [...]
  }
}
```

---

### 13. Remove Passage from Question

**DELETE** `/questions/:id/remove_passage/:passage_id`

Unlink a passage from a question.

**Response:**
```json
{
  "success": true
}
```

---

## Passages API

### 14. List Passages

**GET** `/study_materials/:study_material_id/passages`

List all passages for a study material.

**Query Parameters:**
- `with_images` (optional) - Filter passages with images: `true`, `false`
- `with_tables` (optional) - Filter passages with tables: `true`, `false`

**Response:**
```json
{
  "passages": [
    {
      "id": 1,
      "content": "Database normalization is a process...",
      "passage_type": "text",
      "position": 1,
      "has_image": false,
      "has_table": true,
      "character_count": 350,
      "summary": null,
      "metadata": {},
      "created_at": "2026-01-15T10:00:00Z",
      "updated_at": "2026-01-15T10:00:00Z"
    }
  ],
  "total": 5
}
```

---

### 15. Show Passage

**GET** `/passages/:id`

Get detailed information about a passage including linked questions.

**Response:**
```json
{
  "id": 1,
  "content": "Database normalization is a process...",
  "passage_type": "text",
  "position": 1,
  "has_image": false,
  "has_table": true,
  "character_count": 350,
  "summary": null,
  "metadata": {},
  "created_at": "2026-01-15T10:00:00Z",
  "updated_at": "2026-01-15T10:00:00Z",
  "questions": [
    {
      "id": 1,
      "question_number": 1,
      "content": "What is normalization?",
      "question_type": "multiple_choice"
    },
    {
      "id": 2,
      "question_number": 2,
      "content": "List the normal forms.",
      "question_type": "multiple_choice"
    }
  ],
  "primary_questions": [1]
}
```

---

### 16. Create Passage

**POST** `/study_materials/:study_material_id/passages`

Create a new passage manually.

**Request Body:**
```json
{
  "passage": {
    "content": "Database normalization is a process to minimize redundancy...",
    "passage_type": "text",
    "position": 1,
    "summary": "Introduction to normalization",
    "metadata": {
      "source": "textbook",
      "chapter": 3
    }
  }
}
```

**Response:** (201 Created)
```json
{
  "id": 1,
  "content": "Database normalization is a process...",
  ...
}
```

---

### 17. Update Passage

**PATCH** `/passages/:id`

Update an existing passage.

**Request Body:**
```json
{
  "passage": {
    "content": "Updated passage content",
    "summary": "Updated summary"
  }
}
```

**Response:**
```json
{
  "id": 1,
  "content": "Updated passage content",
  ...
}
```

---

### 18. Delete Passage

**DELETE** `/passages/:id`

Delete a passage. This will also remove all question-passage links.

**Response:** (204 No Content)

---

## Error Responses

All endpoints return consistent error responses:

### 404 Not Found
```json
{
  "error": "Study material not found"
}
```

### 422 Unprocessable Entity
```json
{
  "errors": [
    "Content can't be blank",
    "Answer is invalid"
  ]
}
```

### 500 Internal Server Error
```json
{
  "error": "An unexpected error occurred"
}
```

---

## Authentication

All endpoints require authentication. Include the authentication token in the header:

```
Authorization: Bearer YOUR_TOKEN_HERE
```

---

## Rate Limiting

- Standard endpoints: 100 requests per minute
- AI extraction endpoint: 10 requests per minute (due to GPT-4o API limits)

---

## Code Examples

### JavaScript (Fetch API)

```javascript
// Extract questions using AI
const response = await fetch('/study_materials/1/questions/extract', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer YOUR_TOKEN'
  },
  body: JSON.stringify({
    markdown_content: '...'
  })
});

const result = await response.json();
console.log(`Created ${result.save_results.questions_created} questions`);
```

### Ruby

```ruby
# Create question with passage
question = study_material.questions.create!(
  question_number: 1,
  content: "What is normalization?",
  options: { "①" => "Option 1", "②" => "Option 2" },
  answer: "①",
  question_type: 'multiple_choice',
  difficulty: 3
)

# Add passage
passage = study_material.passages.first
question.add_passage(passage, is_primary: true)

# Validate
question.validate_question!
puts question.validation_status # => "validated"
```

### cURL

```bash
# Get questions with filters
curl -X GET "https://api.certigraph.com/study_materials/1/questions?question_type=multiple_choice&validated=true" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Extract questions
curl -X POST "https://api.certigraph.com/study_materials/1/questions/extract" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"markdown_content": "..."}'
```

---

## Best Practices

1. **Batch Operations**: Use batch_create for multiple questions to reduce API calls
2. **Pagination**: Always use pagination for large datasets
3. **Validation**: Validate questions after creation or updates
4. **Background Jobs**: Use the ExtractQuestionsJob for large extraction tasks
5. **Error Handling**: Always check the `success` field in responses
6. **Filtering**: Use query parameters to reduce payload size
7. **Caching**: Cache question statistics to reduce database load

---

## Endpoint Summary

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/study_materials/:id/questions` | GET | List questions |
| `/questions/:id` | GET | Show question |
| `/study_materials/:id/questions` | POST | Create question |
| `/study_materials/:id/questions/batch_create` | POST | Batch create |
| `/study_materials/:id/questions/extract` | POST | AI extraction |
| `/questions/:id` | PATCH | Update question |
| `/questions/:id` | DELETE | Delete question |
| `/questions/:id/validate` | POST | Validate question |
| `/study_materials/:id/questions/validate_all` | POST | Validate all |
| `/study_materials/:id/questions/stats` | GET | Get statistics |
| `/questions/search` | GET | Search questions |
| `/questions/:id/add_passage` | POST | Add passage |
| `/questions/:id/remove_passage/:pid` | DELETE | Remove passage |
| `/study_materials/:id/passages` | GET | List passages |
| `/passages/:id` | GET | Show passage |
| `/study_materials/:id/passages` | POST | Create passage |
| `/passages/:id` | PATCH | Update passage |
| `/passages/:id` | DELETE | Delete passage |

**Total: 18 Endpoints**

---

Last Updated: January 15, 2026
Version: 1.0.0
