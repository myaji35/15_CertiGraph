# Epic 14: 3D Knowledge Map Implementation

## Overview
This document describes the implementation of the 3D Knowledge Map visualization feature (Epic 14) for the Certi-Graph project. The feature provides an interactive 3D visualization of the knowledge graph using Three.js, allowing users to explore their learning progress spatially.

## Implementation Date
January 15, 2026

## Components Created

### 1. Controllers

#### KnowledgeVisualizationController (View Controller)
**Location:** `/app/controllers/knowledge_visualization_controller.rb`
**Lines of Code:** 22
**Purpose:** Handles rendering the 3D visualization view page

**Routes:**
- `GET /knowledge_map/:id` - Shows the 3D visualization page for a study material

**Key Features:**
- User authentication required
- Access control (users can only view their own study materials)
- Renders the main visualization page with Three.js

#### Api::KnowledgeVisualizationController (API Controller)
**Location:** `/app/controllers/api/knowledge_visualization_controller.rb`
**Lines of Code:** 168
**Purpose:** Provides JSON API endpoints for 3D graph data

**API Endpoints:**

1. `GET /api/knowledge_visualization/:id/graph_data`
   - Returns complete 3D graph data with nodes and edges
   - Includes 3D positions calculated by force-directed layout
   - Returns node metadata (color, mastery level, size)
   - Returns edge metadata (relationship type, strength, color)

2. `GET /api/knowledge_visualization/:id/nodes/:node_id`
   - Returns detailed information about a specific node
   - Includes mastery data
   - Lists prerequisites and dependents
   - Provides learning path recommendations

3. `GET /api/knowledge_visualization/:id/statistics`
   - Returns overall statistics for the knowledge graph
   - Breakdown by mastery status (mastered, learning, weak, untested)
   - Percentage calculations
   - Progress tracking

4. `POST /api/knowledge_visualization/:id/filter`
   - Filters nodes by criteria:
     - Difficulty (1-5)
     - Level (subject, chapter, concept, detail)
     - Mastery status
     - Color coding
   - Returns filtered graph data

**Security:**
- All endpoints require authentication
- Access control checks study material ownership
- Input validation and error handling

### 2. Service Layer

#### ThreeDGraphService
**Location:** `/app/services/three_d_graph_service.rb`
**Lines of Code:** 322
**Purpose:** Transforms knowledge graph data into 3D coordinates and visualization data

**Key Features:**

1. **Force-Directed Layout Algorithm**
   - Implements physics-based node positioning
   - Repulsion forces between all nodes
   - Attraction forces along edges (weighted by relationship strength)
   - Configurable parameters:
     - `SPHERE_RADIUS`: 100 units
     - `FORCE_ITERATIONS`: 100 iterations
     - `REPULSION_STRENGTH`: 500
     - `ATTRACTION_STRENGTH`: 0.01
     - `DAMPING`: 0.9

2. **Node Initialization**
   - Uses Fibonacci sphere algorithm for even distribution
   - Places nodes on a sphere surface initially
   - Prevents clustering at poles

3. **Color Coding**
   - Green (#00ff00): Mastered concepts (80%+ mastery)
   - Yellow (#ffff00): Learning concepts (40-80% mastery)
   - Red (#ff0000): Weak concepts (0-40% mastery)
   - Gray (#808080): Untested concepts

4. **Node Sizing**
   - Base size: 5.0 units
   - Scaled by importance (factor: 0.5)
   - Scaled by connection count (logarithmic factor: 0.3)

5. **Edge Styling**
   - Different colors for relationship types:
     - Red (#ff6b6b): Prerequisite relationships
     - Teal (#4ecdc4): Part-of (hierarchical)
     - Light Teal (#95e1d3): Related concepts
     - Yellow (#f7dc6f): Leads-to (progression)
     - Purple (#bb8fce): Examples
   - Strength calculated based on edge weight and type

6. **Alternative Layouts**
   - Hierarchical layout option
   - Y-axis positioning by ontology level
   - Circular distribution within each level

### 3. Views

#### 3D Knowledge Map View
**Location:** `/app/views/knowledge_visualization/show.html.erb`
**Lines of Code:** 579
**Purpose:** Interactive 3D visualization interface

**UI Components:**

1. **Header Bar**
   - Navigation back to dashboard
   - Study material title
   - Real-time statistics badges
   - Filter toggle button

2. **3D Canvas**
   - Full-screen Three.js renderer
   - OrbitControls for camera manipulation
   - CSS2DRenderer for node labels
   - Raycaster for node selection

3. **Control Panel (Left Sidebar)**
   - Reset Camera button
   - Toggle Labels button
   - Toggle Edges button
   - Zoom slider

4. **Legend (Bottom Left)**
   - Node color meanings
   - Edge type indicators
   - Visual reference guide

5. **Side Panel (Right - Dynamic)**
   - Shows detailed node information on click
   - Displays mastery progress
   - Lists prerequisites and dependents
   - Learning path recommendations

6. **Filter Panel (Right - Collapsible)**
   - Difficulty filter (1-5)
   - Level filter (subject/chapter/concept/detail)
   - Status filter (mastered/learning/weak/untested)
   - Color filter (multi-select checkboxes)
   - Apply/Reset buttons

**Three.js Implementation:**

- **Scene Setup:**
  - Background: #f6f7f8 (matches app design)
  - Ambient light + directional light
  - PerspectiveCamera (FOV: 75)

- **Node Rendering:**
  - SphereGeometry (32 segments)
  - MeshPhongMaterial with emissive color
  - CSS2D labels for node names
  - User data attached for click handling

- **Edge Rendering:**
  - Line geometry between connected nodes
  - Transparent material with opacity based on strength
  - Color-coded by relationship type

- **Interaction:**
  - OrbitControls for rotation, pan, zoom
  - Mouse raycasting for node selection
  - Dynamic detail panel updates
  - Smooth camera movements

- **Import Maps:**
  - Uses ES6 modules via importmap
  - Three.js v0.159.0 from CDN
  - OrbitControls addon
  - CSS2DRenderer addon

### 4. Routes Configuration

**Location:** `/config/routes.rb`

**Added Routes:**
```ruby
# View route
resources :knowledge_map, only: [] do
  member do
    get '', to: 'knowledge_visualization#show', as: ''
  end
end

# API routes
namespace :api do
  get 'knowledge_visualization/:id/graph_data', to: 'knowledge_visualization#graph_data'
  get 'knowledge_visualization/:id/nodes/:node_id', to: 'knowledge_visualization#node_detail'
  get 'knowledge_visualization/:id/statistics', to: 'knowledge_visualization#statistics'
  post 'knowledge_visualization/:id/filter', to: 'knowledge_visualization#filter_nodes'
end
```

**Example URLs:**
- View: `http://localhost:3000/knowledge_map/1`
- Graph Data: `http://localhost:3000/api/knowledge_visualization/1/graph_data`
- Node Detail: `http://localhost:3000/api/knowledge_visualization/1/nodes/5`
- Statistics: `http://localhost:3000/api/knowledge_visualization/1/statistics`
- Filter: `POST http://localhost:3000/api/knowledge_visualization/1/filter`

### 5. Test Coverage

#### Service Tests
**Location:** `/spec/services/three_d_graph_service_spec.rb`
**Tests:** 14 test cases

**Coverage:**
- Service initialization
- Graph generation with nodes and edges
- 3D position calculations
- Fibonacci sphere distribution
- Node color calculations by mastery level
- Node size calculations
- Edge strength calculations
- Edge color coding
- Hierarchical layout alternative

#### Controller Tests
**Location:** `/spec/controllers/api/knowledge_visualization_controller_spec.rb`
**Tests:** 16 test cases

**Coverage:**
- Graph data endpoint
- Node detail endpoint
- Statistics endpoint
- Filter endpoint
- Authentication requirements
- Authorization checks
- Error handling
- JSON response validation

## Technical Details

### Algorithm: Force-Directed Layout

The force-directed layout algorithm simulates a physical system where:

1. **Repulsion Forces:** All nodes repel each other (inverse square law)
   - Prevents node overlap
   - Creates natural spacing
   - Formula: `F = REPULSION_STRENGTH / distance²`

2. **Attraction Forces:** Connected nodes attract each other (Hooke's law)
   - Keeps related concepts close
   - Weighted by edge strength
   - Formula: `F = distance × ATTRACTION_STRENGTH × weight`

3. **Velocity and Damping:**
   - Nodes have velocity that accumulates forces
   - Damping prevents infinite oscillation
   - System cools down over iterations

4. **Iterations:**
   - Runs 100 iterations to reach equilibrium
   - Cooling schedule reduces movement over time
   - Results in stable, aesthetically pleasing layout

### Color System

The color system provides immediate visual feedback on learning progress:

| Color | Hex Code | Mastery Range | Status |
|-------|----------|---------------|---------|
| Green | #00ff00 | 80-100% | Mastered |
| Yellow | #ffff00 | 40-80% | Learning |
| Red | #ff0000 | 0-40% | Weak |
| Gray | #808080 | N/A | Untested |

### Edge Relationship Types

| Type | Color | Strength Multiplier | Description |
|------|-------|---------------------|-------------|
| prerequisite | #ff6b6b (Red) | 1.2 | Required prior knowledge |
| part_of | #4ecdc4 (Teal) | 1.0 | Hierarchical parent-child |
| related_to | #95e1d3 (Light Teal) | 0.8 | Related concepts |
| leads_to | #f7dc6f (Yellow) | 0.9 | Learning progression |
| example_of | #bb8fce (Purple) | 0.6 | Example instances |

## Integration Points

### Existing Models
- `KnowledgeNode`: Provides node data (name, level, difficulty, importance)
- `KnowledgeEdge`: Provides relationship data between nodes
- `UserMastery`: Tracks user's mastery level for each node
- `StudyMaterial`: Container for knowledge graphs

### Existing Services
- `KnowledgeGraphService`: Creates and manages the knowledge graph
- Can be used alongside 3D visualization

### UI Integration
- Links from Dashboard to 3D view
- Links from Study Materials pages
- Could be embedded in study session results

## Performance Considerations

### Optimization Strategies
1. **Client-Side Rendering:** Three.js runs in browser, reducing server load
2. **Cached Positions:** Could cache calculated positions to speed up subsequent loads
3. **Progressive Loading:** Large graphs could load in chunks
4. **LOD (Level of Detail):** Could reduce geometry complexity for distant nodes
5. **Edge Culling:** Could hide edges between distant nodes

### Scalability
- Current implementation handles ~100 nodes comfortably
- For larger graphs (500+ nodes):
  - Implement clustering
  - Add zoom-based filtering
  - Use instanced rendering
  - Consider WebGL optimizations

## Future Enhancements

### Potential Improvements
1. **Animation:** Animate layout changes when filtering
2. **Search:** Highlight nodes matching search query
3. **Path Visualization:** Show learning paths as colored trails
4. **VR Support:** Add WebXR for immersive exploration
5. **Collaborative Mode:** Show multiple users' progress
6. **Export:** Save graph as image or 3D model
7. **Custom Layouts:** User-definable positioning
8. **Time-lapse:** Animate progress over time
9. **AR Support:** Overlay on real-world study materials
10. **Social Sharing:** Share progress visualization

### Integration Opportunities
1. Link nodes to practice questions
2. Generate study recommendations based on graph structure
3. Identify knowledge gaps automatically
4. Compare progress with peers (anonymized)
5. Generate study schedules based on prerequisites

## Usage Guide

### For Users

1. **Navigate to Knowledge Map:**
   - Go to Dashboard
   - Select a Study Material
   - Click "3D Knowledge Map" button

2. **Explore the Graph:**
   - Drag to rotate the view
   - Scroll to zoom
   - Click nodes to see details
   - Use filters to focus on specific areas

3. **Interpret Colors:**
   - Green nodes: You've mastered these concepts
   - Yellow nodes: Currently learning
   - Red nodes: Need more practice
   - Gray nodes: Not yet studied

4. **Use Filters:**
   - Filter by difficulty to focus on challenging concepts
   - Filter by mastery status to find weak areas
   - Combine filters for targeted review

### For Developers

1. **Adding New Relationship Types:**
   - Update `KnowledgeEdge` model validation
   - Add color in `calculate_edge_color` method
   - Add strength multiplier in `calculate_edge_strength` method
   - Update legend in view

2. **Customizing Layout:**
   - Adjust constants in `ThreeDGraphService`
   - Modify force calculation methods
   - Implement alternative layout algorithms

3. **Extending API:**
   - Add endpoints in `Api::KnowledgeVisualizationController`
   - Add corresponding methods in `ThreeDGraphService`
   - Update tests

## File Checklist

- [x] `/app/controllers/knowledge_visualization_controller.rb`
- [x] `/app/controllers/api/knowledge_visualization_controller.rb`
- [x] `/app/services/three_d_graph_service.rb`
- [x] `/app/views/knowledge_visualization/show.html.erb`
- [x] `/spec/services/three_d_graph_service_spec.rb`
- [x] `/spec/controllers/api/knowledge_visualization_controller_spec.rb`
- [x] Updated `/config/routes.rb`

## Testing Instructions

### Manual Testing

1. **Setup:**
   ```bash
   cd rails-api
   rails db:seed  # Ensure test data exists
   rails server
   ```

2. **Test Flow:**
   - Login as test user
   - Navigate to Dashboard
   - Select a study material with knowledge graph data
   - Click to view 3D Knowledge Map
   - Verify graph loads with nodes and edges
   - Test camera controls (rotate, zoom, pan)
   - Click on nodes to view details
   - Test filters
   - Verify statistics update correctly

### Automated Testing

```bash
cd rails-api

# Run service tests
rspec spec/services/three_d_graph_service_spec.rb

# Run controller tests
rspec spec/controllers/api/knowledge_visualization_controller_spec.rb

# Run all related tests
rspec spec/services/three_d_graph_service_spec.rb spec/controllers/api/knowledge_visualization_controller_spec.rb
```

## Dependencies

### Frontend
- Three.js v0.159.0 (via CDN)
- OrbitControls addon
- CSS2DRenderer addon

### Backend
- Ruby 3.3.0+
- Rails 8.0+
- PostgreSQL
- Existing models: KnowledgeNode, KnowledgeEdge, UserMastery, StudyMaterial

## Summary

Epic 14 successfully implements a fully-featured 3D Knowledge Map visualization system with:
- **1,091 lines** of production code
- **322 lines** of sophisticated force-directed layout algorithm
- **579 lines** of interactive Three.js visualization
- **30+ test cases** covering core functionality
- **4 RESTful API endpoints** for data access
- Complete color-coding system for learning progress
- Interactive filtering and exploration features
- Comprehensive documentation

The implementation provides users with an intuitive, visually engaging way to understand their knowledge structure and identify areas for improvement in their certification exam preparation.
