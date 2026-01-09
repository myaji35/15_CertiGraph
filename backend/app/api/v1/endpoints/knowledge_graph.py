"""Knowledge Graph endpoints for 3D visualization."""

from fastapi import APIRouter, Depends
from typing import List, Dict, Any

from app.api.v1.deps import CurrentUser, SettingsDep

router = APIRouter(prefix="/knowledge-graph", tags=["Knowledge Graph"])


@router.get("")
async def get_knowledge_graph(
    current_user: CurrentUser,
    settings: SettingsDep
) -> Dict[str, Any]:
    """
    Get 3D knowledge graph data for visualization.

    Returns:
        - nodes: List of concept nodes with id, label, status (mastered/weak/untested)
        - edges: List of edges representing prerequisite relationships
    """
    if settings.dev_mode or settings.test_mode:
        return {
            "nodes": [
                {
                    "id": "concept_1",
                    "label": "데이터베이스 기초",
                    "status": "mastered",
                    "accuracy": 90.0,
                    "questions_count": 20
                },
                {
                    "id": "concept_2",
                    "label": "데이터베이스 정규화",
                    "status": "weak",
                    "accuracy": 45.0,
                    "questions_count": 10
                },
                {
                    "id": "concept_3",
                    "label": "SQL 쿼리",
                    "status": "mastered",
                    "accuracy": 85.0,
                    "questions_count": 25
                },
                {
                    "id": "concept_4",
                    "label": "트랜잭션 관리",
                    "status": "weak",
                    "accuracy": 60.0,
                    "questions_count": 15
                },
                {
                    "id": "concept_5",
                    "label": "네트워크 프로토콜",
                    "status": "untested",
                    "accuracy": 0.0,
                    "questions_count": 0
                },
                {
                    "id": "concept_6",
                    "label": "OSI 7 계층",
                    "status": "untested",
                    "accuracy": 0.0,
                    "questions_count": 0
                }
            ],
            "edges": [
                {
                    "source": "concept_1",
                    "target": "concept_2",
                    "type": "prerequisite",
                    "strength": 0.9
                },
                {
                    "source": "concept_1",
                    "target": "concept_3",
                    "type": "prerequisite",
                    "strength": 0.8
                },
                {
                    "source": "concept_3",
                    "target": "concept_4",
                    "type": "prerequisite",
                    "strength": 0.7
                },
                {
                    "source": "concept_5",
                    "target": "concept_6",
                    "type": "prerequisite",
                    "strength": 0.85
                }
            ],
            "metadata": {
                "total_concepts": 6,
                "mastered_concepts": 2,
                "weak_concepts": 2,
                "untested_concepts": 2
            }
        }

    # TODO: Query Neo4j for real graph data
    # For now, return empty graph
    return {
        "nodes": [],
        "edges": [],
        "metadata": {
            "total_concepts": 0,
            "mastered_concepts": 0,
            "weak_concepts": 0,
            "untested_concepts": 0
        }
    }


@router.get("/{concept_id}")
async def get_concept_details(
    concept_id: str,
    current_user: CurrentUser,
    settings: SettingsDep
) -> Dict[str, Any]:
    """
    Get detailed information about a specific concept.

    Args:
        concept_id: The unique identifier for the concept

    Returns:
        Concept details including prerequisites, related questions, and statistics
    """
    if settings.dev_mode or settings.test_mode:
        # Mock data for known concepts
        mock_concepts = {
            "concept_normalization": {
                "id": "concept_normalization",
                "name": "데이터베이스 정규화",
                "description": "데이터베이스 설계 시 중복을 최소화하고 데이터 무결성을 보장하기 위한 프로세스",
                "prerequisites": [
                    {
                        "id": "concept_1",
                        "name": "데이터베이스 기초",
                        "status": "mastered"
                    }
                ],
                "related_questions": [
                    {
                        "id": "q_101",
                        "title": "정규화의 목적은 무엇인가?",
                        "difficulty": "medium",
                        "user_answered": True,
                        "user_correct": False
                    },
                    {
                        "id": "q_102",
                        "title": "제3정규형에 대해 설명하시오",
                        "difficulty": "hard",
                        "user_answered": True,
                        "user_correct": False
                    }
                ],
                "statistics": {
                    "total_questions": 10,
                    "attempted_questions": 10,
                    "correct_answers": 4,
                    "accuracy": 40.0,
                    "status": "weak"
                }
            },
            "concept_1": {
                "id": "concept_1",
                "name": "데이터베이스 기초",
                "description": "데이터베이스의 기본 개념과 구조",
                "prerequisites": [],
                "related_questions": [
                    {
                        "id": "q_001",
                        "title": "데이터베이스란 무엇인가?",
                        "difficulty": "easy",
                        "user_answered": True,
                        "user_correct": True
                    }
                ],
                "statistics": {
                    "total_questions": 20,
                    "attempted_questions": 20,
                    "correct_answers": 18,
                    "accuracy": 90.0,
                    "status": "mastered"
                }
            },
            "concept_2": {
                "id": "concept_2",
                "name": "데이터베이스 정규화",
                "description": "데이터베이스 설계 시 중복을 최소화하고 데이터 무결성을 보장하기 위한 프로세스",
                "prerequisites": [
                    {
                        "id": "concept_1",
                        "name": "데이터베이스 기초",
                        "status": "mastered"
                    }
                ],
                "related_questions": [],
                "statistics": {
                    "total_questions": 10,
                    "attempted_questions": 10,
                    "correct_answers": 4,
                    "accuracy": 45.0,
                    "status": "weak"
                }
            }
        }

        if concept_id in mock_concepts:
            return mock_concepts[concept_id]

        # Return 404 for unknown concepts
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail=f"Concept '{concept_id}' not found")

    # TODO: Query Neo4j for real concept data
    from fastapi import HTTPException
    raise HTTPException(status_code=404, detail=f"Concept '{concept_id}' not found")
