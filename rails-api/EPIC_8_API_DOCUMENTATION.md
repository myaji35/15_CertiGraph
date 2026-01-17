# Epic 8: Prerequisite Mapping - API Documentation

## Base URL
```
/api/v1
```

## Authentication
All endpoints require authentication. Include user authentication token in headers.

---

## Table of Contents
1. [Prerequisite Analysis](#1-prerequisite-analysis)
2. [Graph Data & Visualization](#2-graph-data--visualization)
3. [Node Information](#3-node-information)
4. [Graph Validation](#4-graph-validation)
5. [Learning Path Generation](#5-learning-path-generation)
6. [Learning Path Management](#6-learning-path-management)

---

## 1. Prerequisite Analysis

### 1.1 Analyze All Prerequisites

Analyze all nodes in a study material and create prerequisite relationships.

**Endpoint**: `POST /study_materials/:study_material_id/prerequisites/analyze_all`

**Parameters**:
- `study_material_id` (path) - ID of the study material

**Response** (Small Dataset - <50 nodes):
```json
{
  "message": "Prerequisites analysis completed",
  "results": {
    "total_nodes": 30,
    "analyzed": 30,
    "relationships_created": 45,
    "errors": []
  }
}
```

**Response** (Large Dataset - ≥50 nodes):
```json
{
  "message": "Analysis queued for background processing",
  "job_id": "abc-123-def-456",
  "node_count": 75
}
```

**Status Codes**:
- `200 OK` - Analysis completed synchronously
- `202 Accepted` - Analysis queued for background processing
- `404 Not Found` - Study material not found

---

### 1.2 Analyze Single Node

Analyze prerequisites for a specific node using AI.

**Endpoint**: `POST /study_materials/:study_material_id/nodes/:node_id/analyze`

**Parameters**:
- `study_material_id` (path) - ID of the study material
- `node_id` (path) - ID of the knowledge node

**Response**:
```json
{
  "node": {
    "id": 123,
    "name": "Advanced Networking Concepts",
    "level": "concept"
  },
  "prerequisites": [
    {
      "node_id": 45,
      "node_name": "Basic Network Protocols",
      "weight": 0.9,
      "strength": "mandatory",
      "reasoning": "Understanding basic protocols is essential before learning advanced concepts",
      "confidence": 0.85
    },
    {
      "node_id": 67,
      "node_name": "OSI Model",
      "weight": 0.7,
      "strength": "recommended",
      "reasoning": "OSI Model provides helpful context for advanced topics",
      "confidence": 0.78
    }
  ],
  "total_found": 2
}
```

**Status Codes**:
- `200 OK` - Analysis successful
- `404 Not Found` - Node or study material not found
- `500 Internal Server Error` - AI service error

---

### 1.3 Batch Analyze Nodes

Analyze prerequisites for multiple nodes at once.

**Endpoint**: `POST /study_materials/:study_material_id/prerequisites/batch_analyze`

**Parameters**:
- `study_material_id` (path) - ID of the study material
- `node_ids` (body) - Array of node IDs

**Request Body**:
```json
{
  "node_ids": [123, 456, 789]
}
```

**Response**:
```json
{
  "message": "Batch analysis completed",
  "results": [
    {
      "node_id": 123,
      "node_name": "Concept A",
      "prerequisites": [...]
    },
    {
      "node_id": 456,
      "node_name": "Concept B",
      "prerequisites": [...]
    }
  ],
  "analyzed_count": 3
}
```

---

## 2. Graph Data & Visualization

### 2.1 Get Graph Visualization Data

Get complete prerequisite graph data for visualization (D3.js/Three.js compatible).

**Endpoint**: `GET /study_materials/:study_material_id/prerequisites/graph_data`

**Parameters**:
- `study_material_id` (path) - ID of the study material

**Response**:
```json
{
  "graph": {
    "nodes": [
      {
        "id": 1,
        "name": "Basic Networking",
        "level": "concept",
        "difficulty": 2,
        "importance": 5,
        "depth": 0,
        "prerequisite_count": 0,
        "dependent_count": 3
      },
      {
        "id": 2,
        "name": "TCP/IP Protocol",
        "level": "concept",
        "difficulty": 3,
        "importance": 4,
        "depth": 1,
        "prerequisite_count": 1,
        "dependent_count": 2
      }
    ],
    "edges": [
      {
        "id": 10,
        "from": 1,
        "to": 2,
        "strength": "mandatory",
        "weight": 0.9,
        "depth": 1,
        "confidence": 0.85,
        "reasoning": "TCP/IP requires basic networking knowledge"
      }
    ],
    "statistics": {
      "total_nodes": 50,
      "total_edges": 75,
      "avg_prerequisites": 1.5,
      "max_depth": 5
    }
  },
  "visualization_ready": true
}
```

**Visualization Usage**:
```javascript
// D3.js Example
const simulation = d3.forceSimulation(data.graph.nodes)
  .force("link", d3.forceLink(data.graph.edges)
    .id(d => d.id)
    .distance(d => (1 - d.weight) * 100))
  .force("charge", d3.forceManyBody())
  .force("center", d3.forceCenter(width / 2, height / 2));
```

---

## 3. Node Information

### 3.1 Get Node Prerequisites

Get all prerequisites for a specific node.

**Endpoint**: `GET /study_materials/:study_material_id/nodes/:node_id/prerequisites`

**Response**:
```json
{
  "node": {
    "id": 123,
    "name": "Advanced Networking"
  },
  "direct_prerequisites": [
    {
      "id": 45,
      "name": "Basic Networking",
      "level": "concept",
      "difficulty": 2,
      "importance": 5,
      "description": "Fundamental networking concepts"
    }
  ],
  "all_prerequisites": [
    {
      "id": 45,
      "name": "Basic Networking",
      ...
    },
    {
      "id": 23,
      "name": "Computer Science Basics",
      ...
    }
  ],
  "direct_count": 1,
  "total_count": 2
}
```

---

### 3.2 Get Node Dependents

Get all nodes that depend on this node.

**Endpoint**: `GET /study_materials/:study_material_id/nodes/:node_id/dependents`

**Response**:
```json
{
  "node": {
    "id": 45,
    "name": "Basic Networking"
  },
  "direct_dependents": [
    {
      "id": 123,
      "name": "Advanced Networking",
      ...
    }
  ],
  "all_dependents": [
    {
      "id": 123,
      "name": "Advanced Networking",
      ...
    },
    {
      "id": 234,
      "name": "Network Security",
      ...
    }
  ],
  "direct_count": 1,
  "total_count": 2
}
```

---

### 3.3 Calculate Node Depth

Calculate how many prerequisite levels deep a node is.

**Endpoint**: `GET /study_materials/:study_material_id/nodes/:node_id/depth`

**Response**:
```json
{
  "node": {
    "id": 123,
    "name": "Advanced Networking"
  },
  "depth": 3,
  "interpretation": "Intermediate concept - moderate prerequisites"
}
```

**Depth Interpretations**:
- `0`: Foundation concept - no prerequisites
- `1-2`: Basic concept - few prerequisites
- `3-4`: Intermediate concept - moderate prerequisites
- `5-7`: Advanced concept - many prerequisites
- `8+`: Expert concept - extensive prerequisite chain

---

## 4. Graph Validation

### 4.1 Validate Graph

Validate the entire prerequisite graph for issues.

**Endpoint**: `GET /study_materials/:study_material_id/prerequisites/validate_graph`

**Response**:
```json
{
  "validation": {
    "valid": true,
    "errors": [],
    "warnings": [
      "Found 2 orphaned nodes (no connections)",
      "3 edges lack strength classification"
    ],
    "statistics": {
      "total_nodes": 50,
      "total_edges": 75,
      "cycles_found": 0,
      "orphaned_nodes": 2,
      "deep_nodes": 1,
      "unclassified_edges": 3
    }
  },
  "health_score": 92.5
}
```

**Health Score**:
- `90-100`: Excellent - minimal issues
- `70-89`: Good - minor issues
- `50-69`: Fair - some problems
- `<50`: Poor - significant issues

---

### 4.2 Fix Circular Dependencies

Automatically fix circular dependencies by removing weakest edges.

**Endpoint**: `POST /study_materials/:study_material_id/prerequisites/fix_cycles`

**Response**:
```json
{
  "message": "Circular dependencies fixed",
  "fixed_count": 2,
  "fixed_edges": [
    {
      "removed_edge": 45,
      "from": "Concept A",
      "to": "Concept B",
      "reason": "Weakest link in circular dependency"
    }
  ]
}
```

---

## 5. Learning Path Generation

### 5.1 Generate Path Options

Generate multiple learning path options to a target node.

**Endpoint**: `POST /study_materials/:study_material_id/nodes/:node_id/generate_paths`

**Parameters**:
- `study_material_id` (path) - ID of the study material
- `node_id` (path) - Target node ID

**Response**:
```json
{
  "target_node": {
    "id": 123,
    "name": "Advanced Networking"
  },
  "paths": [
    {
      "path_type": "shortest",
      "path_name": "Shortest Path to Advanced Networking",
      "total_nodes": 5,
      "difficulty_level": 3,
      "estimated_hours": 12,
      "priority": 7
    },
    {
      "path_type": "comprehensive",
      "path_name": "Comprehensive Path to Advanced Networking",
      "total_nodes": 12,
      "difficulty_level": 4,
      "estimated_hours": 30,
      "priority": 6
    },
    {
      "path_type": "beginner_friendly",
      "path_name": "Beginner-Friendly Path to Advanced Networking",
      "total_nodes": 8,
      "difficulty_level": 2,
      "estimated_hours": 18,
      "priority": 8
    },
    {
      "path_type": "adaptive",
      "path_name": "Personalized Path to Advanced Networking",
      "total_nodes": 6,
      "difficulty_level": 3,
      "estimated_hours": 14,
      "priority": 9
    }
  ],
  "total_options": 4
}
```

**Path Types**:
- `shortest`: Minimal nodes (BFS algorithm)
- `comprehensive`: All prerequisites (topological sort)
- `beginner_friendly`: Sorted by difficulty
- `adaptive`: Based on current mastery

---

### 5.2 Create Learning Path

Create and save a learning path.

**Endpoint**: `POST /study_materials/:study_material_id/paths`

**Request Body**:
```json
{
  "path": {
    "target_node_id": 123,
    "path_type": "adaptive",
    "path_name": "My Custom Path",
    "description": "Personalized learning journey",
    "mastery_requirement": 0.8,
    "priority": 7
  }
}
```

**Parameters**:
- `target_node_id` (required) - Target concept to reach
- `path_type` (required) - Type of path (shortest/comprehensive/beginner_friendly/adaptive)
- `path_name` (optional) - Custom name (auto-generated if not provided)
- `description` (optional) - Path description
- `mastery_requirement` (optional, default: 0.8) - Required mastery level (0.0-1.0)
- `priority` (optional) - Priority level (1-10)

**Response**:
```json
{
  "message": "Learning path created",
  "path": {
    "id": 456,
    "user_id": 1,
    "study_material_id": 10,
    "target_node_id": 123,
    "path_name": "My Custom Path",
    "path_type": "adaptive",
    "status": "active",
    "node_sequence": [45, 67, 89, 123],
    "edge_sequence": [12, 34, 56],
    "total_nodes": 4,
    "completed_nodes": 0,
    "completion_percentage": 0.0,
    "difficulty_level": 3,
    "estimated_hours": 14,
    "actual_hours": 0,
    "path_score": 0.0,
    "mastery_requirement": 0.8,
    "priority": 7,
    "started_at": "2026-01-15T10:30:00Z",
    "created_at": "2026-01-15T10:30:00Z"
  }
}
```

**Status Codes**:
- `201 Created` - Path successfully created
- `422 Unprocessable Entity` - Invalid parameters or could not generate path
- `404 Not Found` - Study material or target node not found

---

## 6. Learning Path Management

### 6.1 Get Path Details

Get complete information about a learning path.

**Endpoint**: `GET /learning_paths/:id`

**Response**:
```json
{
  "path": {
    "id": 456,
    "user_id": 1,
    "study_material_id": 10,
    "target_node_id": 123,
    "path_name": "My Custom Path",
    "path_type": "adaptive",
    "status": "active",
    "description": "Personalized learning journey",
    "node_sequence": [45, 67, 89, 123],
    "edge_sequence": [12, 34, 56],
    "total_nodes": 4,
    "completed_nodes": 2,
    "completion_percentage": 50.0,
    "difficulty_level": 3,
    "estimated_hours": 14,
    "actual_hours": 7,
    "path_score": 0.75,
    "mastery_requirement": 0.8,
    "priority": 7,
    "started_at": "2026-01-15T10:30:00Z",
    "last_activity_at": "2026-01-15T15:45:00Z",
    "estimated_completion_at": "2026-01-20T10:30:00Z",
    "mastery_checkpoints": {
      "45": {
        "completed_at": "2026-01-15T12:00:00Z",
        "mastery_level": 0.9
      },
      "67": {
        "completed_at": "2026-01-15T15:45:00Z",
        "mastery_level": 0.85
      }
    },
    "analytics": {
      "time_per_node": 3.5,
      "estimated_time_remaining": 7,
      "on_track": true,
      "average_mastery": 0.875
    }
  },
  "visualization": {
    "nodes": [
      {
        "id": 45,
        "name": "Basic Networking",
        "position": 0,
        "completed": true,
        "mastery": 0.9,
        "is_current": false
      },
      {
        "id": 67,
        "name": "Network Protocols",
        "position": 1,
        "completed": true,
        "mastery": 0.85,
        "is_current": false
      },
      {
        "id": 89,
        "name": "Routing Concepts",
        "position": 2,
        "completed": false,
        "mastery": 0.0,
        "is_current": true
      }
    ],
    "edges": [...],
    "progress": {
      "total_nodes": 4,
      "completed_nodes": 2,
      "completion_percentage": 50.0,
      "current_node": 89
    }
  }
}
```

---

### 6.2 Update Path Progress

Mark a node as completed and update progress.

**Endpoint**: `PATCH /learning_paths/:id/progress`

**Request Body**:
```json
{
  "node_id": 89
}
```

**Response** (In Progress):
```json
{
  "message": "Progress updated",
  "path": {
    "id": 456,
    "completion_percentage": 75.0,
    "completed_nodes": 3,
    "total_nodes": 4,
    "path_score": 0.82,
    "on_track": true
  },
  "next_node": 123
}
```

**Response** (Completed):
```json
{
  "message": "Path completed! Congratulations!",
  "path": {
    "id": 456,
    "status": "completed",
    "completion_percentage": 100.0,
    "completed_nodes": 4,
    "total_nodes": 4,
    "path_score": 0.88,
    "completed_at": "2026-01-16T14:20:00Z"
  },
  "next_goals": [
    {
      "node_id": 234,
      "node_name": "Network Security",
      "difficulty": 4,
      "importance": 5,
      "current_mastery": 0.0,
      "estimated_hours": 10
    }
  ]
}
```

---

### 6.3 Abandon Path

Mark a learning path as abandoned.

**Endpoint**: `POST /learning_paths/:id/abandon`

**Response**:
```json
{
  "message": "Learning path abandoned",
  "path_id": 456
}
```

---

### 6.4 Get Alternative Paths

Get alternative learning paths if current path is not suitable.

**Endpoint**: `GET /learning_paths/:id/alternatives`

**Response**:
```json
{
  "current_path": {
    "id": 456,
    "path_name": "My Current Path",
    "path_type": "adaptive",
    "status": "active",
    "total_nodes": 4,
    "difficulty_level": 3
  },
  "alternatives": [
    {
      "path_type": "shortest",
      "path_name": "Shortest Alternative",
      "total_nodes": 3,
      "difficulty_level": 4,
      "estimated_hours": 8,
      "priority": 6
    },
    {
      "path_type": "beginner_friendly",
      "path_name": "Easier Alternative",
      "total_nodes": 6,
      "difficulty_level": 2,
      "estimated_hours": 12,
      "priority": 8
    }
  ],
  "total_alternatives": 3
}
```

---

### 6.5 Get User's Learning Paths

Get all learning paths for the current user.

**Endpoint**: `GET /users/learning_paths`

**Response**:
```json
{
  "active_paths": [
    {
      "id": 456,
      "path_name": "My Current Path",
      "path_type": "adaptive",
      "status": "active",
      "total_nodes": 4,
      "completed_nodes": 2,
      "completion_percentage": 50.0,
      "difficulty_level": 3,
      "started_at": "2026-01-15T10:30:00Z",
      "last_activity_at": "2026-01-15T15:45:00Z"
    }
  ],
  "completed_paths": [
    {
      "id": 123,
      "path_name": "Basic Networking Path",
      "path_type": "comprehensive",
      "status": "completed",
      "total_nodes": 8,
      "completed_nodes": 8,
      "completion_percentage": 100.0,
      "difficulty_level": 2,
      "completed_at": "2026-01-10T18:00:00Z"
    }
  ],
  "statistics": {
    "total_paths": 5,
    "active_count": 2,
    "completed_count": 3,
    "total_nodes_completed": 25,
    "avg_completion_rate": 68.5
  }
}
```

---

## Error Responses

All endpoints may return these standard error responses:

### 401 Unauthorized
```json
{
  "error": "Authentication required"
}
```

### 404 Not Found
```json
{
  "error": "Study material not found"
}
```

### 422 Unprocessable Entity
```json
{
  "error": "Could not generate path",
  "details": "No valid path found to target node"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error",
  "message": "OpenAI API error: 503 - Service Unavailable"
}
```

---

## Rate Limiting

- AI-powered analysis endpoints are rate-limited to 10 requests/minute per user
- Standard endpoints: 100 requests/minute per user
- Background job endpoints return 202 Accepted for rate limiting

---

## Webhooks (Future)

Future versions will support webhooks for:
- Prerequisite analysis completion
- Learning path completion
- Milestone achievements
- Graph validation results

---

## SDK Examples

### JavaScript/Fetch
```javascript
// Generate learning paths
const response = await fetch(
  `/api/v1/study_materials/10/nodes/123/generate_paths`,
  {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  }
);
const data = await response.json();
```

### Python/Requests
```python
import requests

# Update path progress
response = requests.patch(
    f'/api/v1/learning_paths/456/progress',
    json={'node_id': 89},
    headers={'Authorization': f'Bearer {token}'}
)
data = response.json()
```

### Ruby
```ruby
# Get graph data
require 'net/http'
require 'json'

uri = URI("/api/v1/study_materials/10/prerequisites/graph_data")
response = Net::HTTP.get_response(uri)
data = JSON.parse(response.body)
```

---

## Support

For API support, please contact:
- Email: support@certigraph.com
- Documentation: https://docs.certigraph.com
- GitHub Issues: https://github.com/certigraph/issues
