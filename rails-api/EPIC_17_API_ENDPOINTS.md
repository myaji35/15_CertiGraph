# Epic 17: Marketplace & Reviews - API Endpoints Reference

## Marketplace Endpoints (15)

### 1. Browse Marketplace
```
GET /marketplace
GET /marketplace?page=1&per_page=20&sort_by=popular
```
**Query Parameters:**
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 20, max: 100)
- `sort_by` - popular|recent|price_low|price_high|rating|sales|name

**Response:** List of published materials with pagination

---

### 2. Advanced Search
```
GET /marketplace/search?q=검색어&category=정보처리기사&min_rating=4
```
**Query Parameters:**
- `q` - Search query (name, description, tags)
- `category` - Category filter
- `difficulty` - beginner|intermediate|advanced|expert
- `certification` - Certification name
- `price_type` - free|paid
- `min_price` - Minimum price
- `max_price` - Maximum price
- `min_rating` - Minimum rating (1-5)
- `min_questions` - Minimum question count
- `max_questions` - Maximum question count
- `tags[]` - Array of tags
- `exclude_own` - true|false
- `sort_by` - Sorting option
- `page` - Page number
- `per_page` - Items per page

**Response:** Filtered materials list with count

---

### 3. Get Facets (Filters & Statistics)
```
GET /marketplace/facets
```
**Response:**
```json
{
  "categories": {"정보처리기사": 45, "네트워크관리사": 23},
  "difficulty_levels": {"beginner": 12, "intermediate": 34, "advanced": 15},
  "certifications": {"정보처리기사": 45, "빅데이터분석기사": 28},
  "price_ranges": {
    "free": 23,
    "under_10000": 34,
    "10000_to_30000": 45,
    "30000_to_50000": 12,
    "over_50000": 3
  },
  "rating_distribution": {"1": 2, "2": 5, "3": 15, "4": 45, "5": 67},
  "total_count": 145
}
```

---

### 4. View Material Detail
```
GET /marketplace/:id
```
**Response:** Full material details including:
- Basic info (name, price, category, etc.)
- Statistics (sales, ratings, reviews)
- Reviews (latest 10)
- Purchase status (if authenticated)
- Review status (if authenticated)

---

### 5. Popular Materials
```
GET /marketplace/popular?limit=10
```
**Query Parameters:**
- `limit` - Number of items (default: 10)

**Response:** Top materials by sales_count + avg_rating

---

### 6. Top Rated Materials
```
GET /marketplace/top_rated?limit=10
```
**Query Parameters:**
- `limit` - Number of items (default: 10)

**Response:** Materials with avg_rating >= 4.0, sorted by rating

---

### 7. Recent Materials
```
GET /marketplace/recent?limit=10
```
**Query Parameters:**
- `limit` - Number of items (default: 10)

**Response:** Recently published materials

---

### 8. List Categories
```
GET /marketplace/categories
```
**Response:**
```json
{
  "categories": ["정보처리기사", "빅데이터분석기사", "네트워크관리사", ...]
}
```

---

### 9. My Materials (Authenticated)
```
GET /marketplace/my_materials
Authorization: Bearer <token>
```
**Response:** List of user's own study materials

---

### 10. Purchased Materials (Authenticated)
```
GET /marketplace/purchased
Authorization: Bearer <token>
```
**Response:**
```json
[
  {
    "id": 1,
    "material": {...},
    "purchased_at": "2024-01-15T10:30:00Z",
    "price": 5000,
    "download_count": 2,
    "download_limit": 5,
    "remaining_downloads": 3,
    "expires_at": null,
    "can_download": true
  }
]
```

---

### 11. Purchase Material (Authenticated)
```
POST /marketplace/:id/purchase
Authorization: Bearer <token>
Content-Type: application/json

{
  "payment_id": 123  // Optional, for paid materials
}
```
**Response:**
```json
{
  "message": "구매가 완료되었습니다",
  "purchase": {...}
}
```

---

### 12. Toggle Publish (Authenticated, Owner Only)
```
POST /marketplace/:id/toggle_publish
Authorization: Bearer <token>
```
**Response:**
```json
{
  "message": "자료를 마켓플레이스에 공개했습니다",
  "material": {...}
}
```

---

### 13. Update Listing (Authenticated, Owner Only)
```
PATCH /marketplace/:id/update_listing
Authorization: Bearer <token>
Content-Type: application/json

{
  "material": {
    "price": 5000,
    "category": "정보처리기사",
    "difficulty_level": "intermediate",
    "tags": ["기출문제", "2024", "필기"]
  }
}
```
**Response:**
```json
{
  "message": "자료 정보가 업데이트되었습니다",
  "material": {...}
}
```

---

### 14. Download Material (Authenticated, Purchased)
```
GET /marketplace/:id/download
Authorization: Bearer <token>
```
**Response:** Redirects to PDF file or returns error

---

### 15. Marketplace Statistics
```
GET /marketplace/stats
Authorization: Bearer <token>
```
**Response:**
```json
{
  "total_materials": 145,
  "free_materials": 45,
  "paid_materials": 100,
  "total_sales": 1234,
  "total_revenue": 12340000,
  "avg_rating": 4.2,
  "categories_count": 15
}
```

---

## Review Endpoints (8)

### 1. List Reviews for Material
```
GET /study_materials/:id/reviews
GET /study_materials/:id/reviews?rating=5&verified=true&sort_by=helpful
```
**Query Parameters:**
- `rating` - Filter by rating (1-5)
- `verified` - true|false (verified purchases only)
- `sort_by` - helpful|rating_high|rating_low|recent
- `page` - Page number
- `per_page` - Items per page

**Response:**
```json
{
  "reviews": [...],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 45
  },
  "summary": {
    "avg_rating": 4.5,
    "total_reviews": 45,
    "rating_distribution": {"1": 2, "2": 3, "3": 5, "4": 10, "5": 25}
  }
}
```

---

### 2. Create Review (Authenticated, Purchased)
```
POST /study_materials/:id/reviews
Authorization: Bearer <token>
Content-Type: application/json

{
  "review": {
    "rating": 5,
    "comment": "매우 유용한 자료입니다!"
  }
}
```
**Requirements:**
- Must have purchased the material (for paid materials)
- Cannot review the same material twice

**Response:**
```json
{
  "message": "리뷰가 작성되었습니다",
  "review": {...}
}
```

---

### 3. Get Review Detail
```
GET /reviews/:id
Authorization: Bearer <token>
```
**Response:** Full review details including vote status

---

### 4. Update Review (Authenticated, Owner Only)
```
PATCH /reviews/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "review": {
    "rating": 4,
    "comment": "업데이트된 리뷰 내용"
  }
}
```
**Response:**
```json
{
  "message": "리뷰가 수정되었습니다",
  "review": {...}
}
```

---

### 5. Delete Review (Authenticated, Owner or Admin)
```
DELETE /reviews/:id
Authorization: Bearer <token>
```
**Response:**
```json
{
  "message": "리뷰가 삭제되었습니다"
}
```

---

### 6. Vote on Review (Authenticated)
```
POST /reviews/:id/vote?helpful=true
Authorization: Bearer <token>
```
**Query Parameters:**
- `helpful` - true|false

**Response:**
```json
{
  "message": "투표가 완료되었습니다",
  "review": {
    "id": 1,
    "helpful_count": 24,
    "not_helpful_count": 2,
    "helpful_percentage": 92.3,
    ...
  }
}
```

---

### 7. Remove Vote (Authenticated)
```
DELETE /reviews/:id/remove_vote
Authorization: Bearer <token>
```
**Response:**
```json
{
  "message": "투표가 취소되었습니다",
  "review": {...}
}
```

---

### 8. My Reviews (Authenticated)
```
GET /reviews/my_reviews?page=1&per_page=20
Authorization: Bearer <token>
```
**Query Parameters:**
- `page` - Page number
- `per_page` - Items per page

**Response:**
```json
{
  "reviews": [...],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 12
  }
}
```

---

## Authentication

Most endpoints require Bearer token authentication:

```
Authorization: Bearer <your_jwt_token>
```

### Getting a Token:
```
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {...}
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "error": "Invalid parameters",
  "details": ["Price must be greater than 0"]
}
```

### 401 Unauthorized
```json
{
  "error": "Authentication required"
}
```

### 403 Forbidden
```json
{
  "error": "접근 권한이 없습니다"
}
```

### 404 Not Found
```json
{
  "error": "자료를 찾을 수 없습니다"
}
```

### 422 Unprocessable Entity
```json
{
  "errors": ["이미 이 자료에 대한 리뷰를 작성하셨습니다"]
}
```

---

## Testing

Use the provided test script:
```bash
chmod +x test_epic17_marketplace.sh
./test_epic17_marketplace.sh
```

Or test individual endpoints with curl:
```bash
# Get marketplace stats
curl http://localhost:3000/marketplace/stats

# Search with filters
curl "http://localhost:3000/marketplace/search?q=정보처리기사&min_rating=4&price_type=free"

# Create review (with authentication)
curl -X POST http://localhost:3000/study_materials/1/reviews \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"review": {"rating": 5, "comment": "Great material!"}}'
```

---

## Summary

- **Total Endpoints:** 23
- **Marketplace:** 15 endpoints
- **Reviews:** 8 endpoints
- **Authentication Required:** 18 endpoints
- **Public Access:** 5 endpoints

All endpoints support JSON request/response format and follow RESTful conventions.
