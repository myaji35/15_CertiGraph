"""Neo4j repository for Knowledge Graph storage.

Stores concepts, questions, and their relationships in Neo4j.
Supports GraphRAG-based weakness analysis.
"""

import logging
from typing import Any, Optional
from neo4j import AsyncGraphDatabase

from app.core.config import get_settings

logger = logging.getLogger(__name__)


class Neo4jConceptRepository:
    """Repository for managing concepts and relationships in Neo4j."""

    def __init__(self):
        settings = get_settings()
        self.driver = AsyncGraphDatabase.driver(
            settings.neo4j_uri,
            auth=(settings.neo4j_user, settings.neo4j_password),
        )

    async def close(self):
        """Close the driver connection."""
        await self.driver.close()

    async def create_concept(
        self,
        name: str,
        subject: str,
        chapter: str,
        description: Optional[str] = None,
    ) -> dict[str, Any]:
        """
        Create or merge a concept node.

        Args:
            name: Concept name
            subject: Subject area (사회복지기초, 사회복지실천, 사회복지정책과제도)
            chapter: Chapter/section name
            description: Optional description

        Returns:
            Created/merged concept node
        """
        async with self.driver.session() as session:
            result = await session.run(
                """
                MERGE (c:Concept {name: $name})
                ON CREATE SET
                    c.subject = $subject,
                    c.chapter = $chapter,
                    c.description = $description,
                    c.created_at = datetime()
                ON MATCH SET
                    c.updated_at = datetime()
                RETURN c
                """,
                name=name,
                subject=subject,
                chapter=chapter,
                description=description or "",
            )
            record = await result.single()
            return dict(record["c"]) if record else None

    async def create_question_node(
        self,
        question_id: str,
        study_set_id: str,
        question_text: str,
        question_number: int,
    ) -> dict[str, Any]:
        """
        Create a question node.

        Args:
            question_id: Unique question ID
            study_set_id: Associated study set ID
            question_text: Question text
            question_number: Question number in study set

        Returns:
            Created question node
        """
        async with self.driver.session() as session:
            result = await session.run(
                """
                MERGE (q:Question {id: $question_id})
                ON CREATE SET
                    q.study_set_id = $study_set_id,
                    q.text = $question_text,
                    q.question_number = $question_number,
                    q.created_at = datetime()
                RETURN q
                """,
                question_id=question_id,
                study_set_id=study_set_id,
                question_text=question_text[:500],  # Limit text length
                question_number=question_number,
            )
            record = await result.single()
            return dict(record["q"]) if record else None

    async def link_question_to_concept(
        self,
        question_id: str,
        concept_name: str,
        is_primary: bool = True,
    ) -> None:
        """
        Create TESTS relationship between question and concept.

        Args:
            question_id: Question ID
            concept_name: Concept name
            is_primary: Whether this is the primary concept tested
        """
        async with self.driver.session() as session:
            await session.run(
                """
                MATCH (q:Question {id: $question_id})
                MATCH (c:Concept {name: $concept_name})
                MERGE (q)-[r:TESTS]->(c)
                SET r.is_primary = $is_primary
                """,
                question_id=question_id,
                concept_name=concept_name,
                is_primary=is_primary,
            )

    async def create_prerequisite_relationship(
        self,
        concept_name: str,
        prerequisite_name: str,
    ) -> None:
        """
        Create PREREQUISITE relationship between concepts.

        Args:
            concept_name: Concept that requires prerequisite
            prerequisite_name: Prerequisite concept
        """
        async with self.driver.session() as session:
            await session.run(
                """
                MATCH (c:Concept {name: $concept_name})
                MATCH (p:Concept {name: $prerequisite_name})
                MERGE (c)-[:PREREQUISITE]->(p)
                """,
                concept_name=concept_name,
                prerequisite_name=prerequisite_name,
            )

    async def update_user_mastery(
        self,
        user_id: str,
        concept_name: str,
        is_correct: bool,
    ) -> None:
        """
        Update user's mastery level for a concept.

        Args:
            user_id: User ID
            concept_name: Concept name
            is_correct: Whether the user answered correctly
        """
        async with self.driver.session() as session:
            if is_correct:
                await session.run(
                    """
                    MERGE (u:User {id: $user_id})
                    MERGE (c:Concept {name: $concept_name})
                    MERGE (u)-[r:MASTERED]->(c)
                    ON CREATE SET r.count = 1
                    ON MATCH SET r.count = r.count + 1
                    SET r.updated_at = datetime()
                    """,
                    user_id=user_id,
                    concept_name=concept_name,
                )
            else:
                await session.run(
                    """
                    MERGE (u:User {id: $user_id})
                    MERGE (c:Concept {name: $concept_name})
                    MERGE (u)-[r:WEAK_AT]->(c)
                    ON CREATE SET r.count = 1
                    ON MATCH SET r.count = r.count + 1
                    SET r.updated_at = datetime()
                    """,
                    user_id=user_id,
                    concept_name=concept_name,
                )

    async def get_weak_concepts(
        self,
        user_id: str,
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        """
        Get user's weakest concepts based on test history.

        Args:
            user_id: User ID
            limit: Maximum number of concepts to return

        Returns:
            List of weak concepts with weakness scores
        """
        async with self.driver.session() as session:
            result = await session.run(
                """
                MATCH (u:User {id: $user_id})-[w:WEAK_AT]->(c:Concept)
                OPTIONAL MATCH (u)-[m:MASTERED]->(c)
                WITH c,
                     COALESCE(w.count, 0) as weak_count,
                     COALESCE(m.count, 0) as mastered_count
                WHERE weak_count > 0
                WITH c, weak_count, mastered_count,
                     weak_count * 1.0 / (weak_count + mastered_count) as weakness_score
                ORDER BY weakness_score DESC, weak_count DESC
                LIMIT $limit
                RETURN c.name as concept,
                       c.subject as subject,
                       c.chapter as chapter,
                       weak_count,
                       mastered_count,
                       weakness_score
                """,
                user_id=user_id,
                limit=limit,
            )

            records = await result.data()
            return records

    async def get_prerequisite_chain(
        self,
        concept_name: str,
        max_depth: int = 3,
    ) -> list[dict[str, Any]]:
        """
        Get prerequisite chain for a concept (for GraphRAG).

        Args:
            concept_name: Concept to analyze
            max_depth: Maximum depth to traverse

        Returns:
            List of prerequisite concepts in order
        """
        async with self.driver.session() as session:
            result = await session.run(
                """
                MATCH path = (c:Concept {name: $concept_name})-[:PREREQUISITE*1..$max_depth]->(p:Concept)
                RETURN p.name as prerequisite,
                       p.subject as subject,
                       p.chapter as chapter,
                       length(path) as depth
                ORDER BY depth ASC
                """,
                concept_name=concept_name,
                max_depth=max_depth,
            )

            records = await result.data()
            return records

    async def get_related_concepts(
        self,
        concept_name: str,
    ) -> list[dict[str, Any]]:
        """
        Get concepts related through shared questions.

        Args:
            concept_name: Concept to find related concepts for

        Returns:
            List of related concepts with connection strength
        """
        async with self.driver.session() as session:
            result = await session.run(
                """
                MATCH (c1:Concept {name: $concept_name})<-[:TESTS]-(q:Question)-[:TESTS]->(c2:Concept)
                WHERE c1 <> c2
                WITH c2, count(q) as shared_questions
                RETURN c2.name as concept,
                       c2.subject as subject,
                       shared_questions
                ORDER BY shared_questions DESC
                LIMIT 10
                """,
                concept_name=concept_name,
            )

            records = await result.data()
            return records

    async def get_user_progress(
        self,
        user_id: str,
    ) -> dict[str, Any]:
        """
        Get overall user progress statistics.

        Args:
            user_id: User ID

        Returns:
            Progress statistics
        """
        async with self.driver.session() as session:
            result = await session.run(
                """
                MATCH (c:Concept)
                WITH count(c) as total_concepts

                OPTIONAL MATCH (u:User {id: $user_id})-[m:MASTERED]->(mastered:Concept)
                WITH total_concepts, count(DISTINCT mastered) as mastered_count

                OPTIONAL MATCH (u:User {id: $user_id})-[w:WEAK_AT]->(weak:Concept)
                WITH total_concepts, mastered_count, count(DISTINCT weak) as weak_count

                RETURN total_concepts,
                       mastered_count,
                       weak_count,
                       total_concepts - mastered_count - weak_count as untested_count
                """,
                user_id=user_id,
            )

            record = await result.single()
            return dict(record) if record else {
                "total_concepts": 0,
                "mastered_count": 0,
                "weak_count": 0,
                "untested_count": 0,
            }

    async def delete_study_set_data(
        self,
        study_set_id: str,
    ) -> None:
        """
        Delete all questions for a study set (concepts are preserved).

        Args:
            study_set_id: Study set to delete data for
        """
        async with self.driver.session() as session:
            await session.run(
                """
                MATCH (q:Question {study_set_id: $study_set_id})
                DETACH DELETE q
                """,
                study_set_id=study_set_id,
            )
            logger.info(f"Deleted Neo4j data for study set {study_set_id}")
