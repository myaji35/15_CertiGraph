# CertiGraph Phase 2 Roadmap

**Project:** CertiGraph (AI 자격증 마스터)
**Timeline:** 2025 Q2-Q3 (April - September)
**Prerequisites:** MVP launched and stable

---

## 📊 Phase 2 Overview

### Vision
Transform CertiGraph from a basic test platform into an AI-powered intelligent learning system with personalized insights and recommendations.

### Key Differentiators
- **Semantic Search:** Find similar questions across all materials
- **Knowledge Graph:** Understand concept relationships
- **GraphRAG Analysis:** AI-powered weakness identification
- **Learning Paths:** Personalized study recommendations

---

## 🏗️ Architecture Expansion

### Current State (MVP)
```
Frontend (Next.js)
    ↓
Backend (FastAPI)
    ↓
GCP Cloud SQL (PostgreSQL)
```

### Phase 2 Target
```
Frontend (Next.js)
    ↓
Backend (FastAPI)
    ↓
┌─────────────┬──────────────┬─────────────┐
│  Cloud SQL  │   Pinecone   │    Neo4j    │
│   (Data)    │  (Vectors)   │   (Graph)   │
└─────────────┴──────────────┴─────────────┘
```

---

## 📅 Implementation Timeline

### **Month 1: Vector Search** (April 2025)

#### Goals
- Enable semantic question search
- Find similar questions across materials
- Improve question quality

#### Technical Tasks

**Week 1-2: Pinecone Setup**
```python
# 1. Create Pinecone index
index = pinecone.create_index(
    name="certigraph-questions",
    dimension=1536,  # OpenAI embedding size
    metric="cosine"
)

# 2. Migrate existing questions
for question in questions:
    embedding = openai.embed(question.text)
    pinecone.upsert(
        id=question.id,
        values=embedding,
        metadata={
            "text": question.text,
            "material_id": question.material_id,
            "difficulty": question.difficulty
        }
    )
```

**Week 3-4: Search Implementation**
- Semantic search API endpoint
- Similar questions UI component
- Duplicate detection system

#### Deliverables
- `/v1/questions/search` API endpoint
- "Find similar" button on questions
- Automatic duplicate warnings

---

### **Month 2: Knowledge Graph** (May 2025)

#### Goals
- Map concept relationships
- Track prerequisite knowledge
- Identify knowledge gaps

#### Technical Tasks

**Week 1-2: Neo4j Setup**
```cypher
// Core schema
CREATE (c:Concept {
    id: "concept_001",
    name: "사회복지실천",
    level: "subject"
})

CREATE (q:Question {
    id: "q_001",
    text: "...",
    material_id: "mat_001"
})

CREATE (q)-[:TESTS]->(c)
CREATE (c1)-[:PREREQUISITE]->(c2)
```

**Week 3-4: Graph Construction**
```python
# LLM-powered concept extraction
async def extract_concepts(question_text):
    prompt = f"""
    Extract key concepts from this question:
    {question_text}

    Return: concept names and relationships
    """
    concepts = await llm.extract(prompt)
    neo4j.create_concepts(concepts)
```

#### Deliverables
- Concept relationship visualization
- Prerequisite tracking
- Knowledge gap identification

---

### **Month 3: GraphRAG Analysis** (June 2025)

#### Goals
- AI-powered weakness analysis
- Personalized learning paths
- Smart recommendations

#### Technical Tasks

**Week 1-2: GraphRAG Implementation**
```python
class GraphRAGAnalyzer:
    def analyze_weaknesses(self, user_id):
        # 1. Get wrong answers
        wrong_answers = get_user_wrong_answers(user_id)

        # 2. Traverse graph for root causes
        weak_concepts = neo4j.query("""
            MATCH (u:User {id: $user_id})-[:ANSWERED_WRONG]->(q:Question)
            -[:TESTS]->(c:Concept)<-[:PREREQUISITE*]-(root:Concept)
            RETURN root, count(q) as error_count
            ORDER BY error_count DESC
        """)

        # 3. Generate insights with LLM
        insights = llm.analyze(weak_concepts)
        return insights
```

**Week 3-4: Learning Path Generation**
```python
def generate_learning_path(weak_concepts):
    # Build prerequisite chain
    path = neo4j.query("""
        MATCH path = (basic:Concept)<-[:PREREQUISITE*]-(advanced:Concept)
        WHERE advanced IN $weak_concepts
        RETURN path
        ORDER BY length(path)
    """)

    return optimize_path(path)
```

#### Deliverables
- Weakness analysis dashboard
- Learning path recommendations
- Progress tracking with prerequisites

---

## 🔧 Technical Implementation

### Database Migrations

**Cloud SQL Changes**
```sql
-- Add vector reference
ALTER TABLE questions
ADD COLUMN pinecone_id VARCHAR(255),
ADD COLUMN neo4j_id VARCHAR(255);

-- Add concept tracking
CREATE TABLE user_concept_mastery (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    concept_id VARCHAR(255),
    mastery_level DECIMAL(3,2),
    last_updated TIMESTAMP
);
```

**Pinecone Schema**
```python
{
    "id": "q_12345",
    "values": [0.1, 0.2, ...],  # 1536-dim embedding
    "metadata": {
        "question_id": 12345,
        "material_id": 67,
        "concepts": ["개념1", "개념2"],
        "difficulty": 3,
        "created_at": "2025-04-01"
    }
}
```

**Neo4j Schema**
```cypher
// Nodes
(:User {id, clerk_id, name})
(:Concept {id, name, level, description})
(:Question {id, text, material_id})
(:StudySet {id, name, user_id})

// Relationships
(:User)-[:WEAK_AT {score}]->(:Concept)
(:Question)-[:TESTS]->(:Concept)
(:Concept)-[:PREREQUISITE]->(:Concept)
(:User)-[:ANSWERED {correct, timestamp}]->(:Question)
```

---

## 💰 Cost Estimation

### Monthly Costs (Estimated)

| Service | Tier | Monthly Cost | Notes |
|---------|------|-------------|-------|
| Pinecone | Starter | $70 | 1M vectors, 100K queries |
| Neo4j AuraDB | Free → Professional | $65 | 1GB storage, 1M nodes |
| OpenAI Embeddings | Pay-per-use | ~$50 | ~100K embeddings/month |
| GPT-4 Analysis | Pay-per-use | ~$100 | GraphRAG queries |
| **Total** | | **~$285/month** | |

### Cost Optimization
1. Cache embeddings aggressively
2. Batch embedding requests
3. Use GPT-4o-mini for non-critical analysis
4. Implement usage quotas per user

---

## 📈 Success Metrics

### Technical Metrics
- Embedding generation < 100ms
- Semantic search < 500ms
- Graph traversal < 200ms
- Learning path generation < 2s

### Business Metrics
- 30% improvement in test scores
- 50% reduction in study time
- 80% user satisfaction with recommendations
- 40% increase in paid conversions

---

## 🚦 Go/No-Go Criteria

### Prerequisites for Phase 2
- [ ] MVP stable for 2+ months
- [ ] 500+ active users
- [ ] 10,000+ questions in database
- [ ] Positive user feedback on core features
- [ ] Revenue covering infrastructure costs

### Decision Points

**April 1, 2025:** Vector Search
- If user base > 500 → Proceed
- If user base < 500 → Delay 1 month

**May 1, 2025:** Knowledge Graph
- If vector search adoption > 30% → Proceed
- Otherwise → Focus on vector search optimization

**June 1, 2025:** GraphRAG
- If graph quality > 80% → Proceed
- Otherwise → Improve graph construction

---

## 🛠️ Development Plan

### Team Requirements
- 1 Full-stack developer (existing)
- 1 ML Engineer (hire or contract)
- 1 Data Scientist (part-time)

### Sprint Structure
- 2-week sprints
- Weekly demos to stakeholders
- Monthly user testing sessions

### Testing Strategy
1. A/B test each feature
2. 10% rollout initially
3. Monitor performance impact
4. Full rollout after validation

---

## 🔄 Migration Strategy

### Data Migration
1. **Existing Questions → Embeddings**
   - Batch process during off-hours
   - 1000 questions/hour rate limit
   - Total time: ~10 hours for 10K questions

2. **User History → Graph**
   - Build retroactively from test_sessions
   - Create user mastery scores
   - Identify historical weak points

### Rollback Plan
- Feature flags for all Phase 2 features
- Dual-write to both old and new systems
- 1-click disable if issues arise
- Data sync every 6 hours

---

## 📚 Technical Dependencies

### New Libraries/Services
```python
# requirements-phase2.txt
pinecone-client==2.2.0
neo4j==5.14.0
langchain==0.1.0
langchain-openai==0.0.5
networkx==3.1  # Graph algorithms
scikit-learn==1.3.0  # Clustering
```

### API Keys Needed
- Pinecone API Key
- Neo4j Aura credentials
- OpenAI API Key (increased quota)

### Infrastructure Changes
- Increase Cloud Run memory to 2GB
- Add Cloud Scheduler for batch jobs
- Setup Cloud Tasks for async processing

---

## 🎯 Phase 2 Definition of Success

### Must Have
- ✅ Semantic search working
- ✅ Basic knowledge graph
- ✅ Simple weakness identification

### Nice to Have
- ⭕ Advanced learning paths
- ⭕ Collaborative filtering
- ⭕ Spaced repetition

### Future (Phase 3)
- 🔮 Mobile app
- 🔮 AI tutor chat
- 🔮 Multi-language support

---

## 📊 Risk Assessment

### Technical Risks
1. **Graph complexity** - Start simple, iterate
2. **Embedding costs** - Cache aggressively
3. **Query performance** - Optimize indexes

### Business Risks
1. **User adoption** - A/B test everything
2. **ROI unclear** - Track metrics closely
3. **Complexity** - Phase features gradually

---

**Document Version:** 1.0
**Created:** 2026-01-08
**Review Schedule:** Monthly after MVP launch
**Owner:** CertiGraph Development Team

## Next Steps
1. Launch and stabilize MVP (Jan-Mar 2025)
2. Gather user feedback on pain points
3. Validate Phase 2 assumptions
4. Secure budget approval
5. Begin Phase 2 development (April 2025)