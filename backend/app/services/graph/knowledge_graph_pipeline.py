"""Knowledge Graph Pipeline.

Orchestrates the complete flow from extracted questions to Knowledge Graph:
1. Generate embeddings for questions (OpenAI)
2. Store vectors in Pinecone
3. Extract concepts using LLM (Gemini)
4. Build graph in Neo4j
"""

import logging
from typing import Any, Optional

from app.core.config import get_settings
from app.services.embedding.openai_embeddings import OpenAIEmbeddingService
from app.repositories.pinecone_questions import PineconeQuestionRepository
from app.services.graph.concept_extractor import ConceptExtractor
from app.repositories.neo4j_concepts import Neo4jConceptRepository

logger = logging.getLogger(__name__)


class KnowledgeGraphPipeline:
    """Pipeline for building Knowledge Graph from questions."""

    def __init__(self):
        self.settings = get_settings()

        # Initialize services only if API keys are available
        self.embedding_service = None
        self.pinecone_repo = None
        self.concept_extractor = None
        self.neo4j_repo = None

        if self.settings.openai_api_key:
            self.embedding_service = OpenAIEmbeddingService()
        if self.settings.pinecone_api_key:
            self.pinecone_repo = PineconeQuestionRepository()
        if self.settings.google_api_key:
            self.concept_extractor = ConceptExtractor()
        if self.settings.neo4j_uri:
            self.neo4j_repo = Neo4jConceptRepository()

    async def process_study_set(
        self,
        study_set_id: str,
        user_id: str,
        questions: list[dict[str, Any]],
        on_progress: Optional[callable] = None,
    ) -> dict[str, Any]:
        """
        Process a study set through the Knowledge Graph pipeline.

        Args:
            study_set_id: Study set ID
            user_id: User ID for namespace
            questions: List of extracted questions
            on_progress: Optional callback for progress updates

        Returns:
            Processing results
        """
        results = {
            "vectors_stored": 0,
            "concepts_extracted": 0,
            "graph_nodes_created": 0,
            "errors": [],
        }

        # Step 1: Generate and store embeddings
        if self.embedding_service and self.pinecone_repo:
            try:
                if on_progress:
                    await on_progress(60, "벡터 임베딩 생성 중...")

                questions_with_embeddings = await self.embedding_service.embed_questions(questions)
                results["vectors_stored"] = await self.pinecone_repo.upsert_questions(
                    questions_with_embeddings,
                    user_id,
                )
                logger.info(f"Stored {results['vectors_stored']} vectors in Pinecone")

            except Exception as e:
                logger.error(f"Embedding/Pinecone error: {e}")
                results["errors"].append(f"Vector storage: {str(e)}")
        else:
            logger.info("Skipping vector storage (OpenAI or Pinecone not configured)")

        # Step 2: Extract concepts
        extracted_concepts = []
        if self.concept_extractor:
            try:
                if on_progress:
                    await on_progress(75, "개념 추출 중...")

                concept_results = await self.concept_extractor.extract_concepts_batch(
                    questions,
                    on_progress=None,  # Use our own progress
                )

                for question, concepts in concept_results:
                    if concepts:
                        extracted_concepts.append((question, concepts))
                        results["concepts_extracted"] += 1

                logger.info(f"Extracted concepts from {results['concepts_extracted']} questions")

            except Exception as e:
                logger.error(f"Concept extraction error: {e}")
                results["errors"].append(f"Concept extraction: {str(e)}")
        else:
            logger.info("Skipping concept extraction (Google API not configured)")

        # Step 3: Build Neo4j graph
        if self.neo4j_repo and extracted_concepts:
            try:
                if on_progress:
                    await on_progress(90, "Knowledge Graph 구축 중...")

                for question, concepts in extracted_concepts:
                    # Create question node
                    await self.neo4j_repo.create_question_node(
                        question_id=question["id"],
                        study_set_id=study_set_id,
                        question_text=question.get("question_text", ""),
                        question_number=question.get("question_number", 0),
                    )
                    results["graph_nodes_created"] += 1

                    # Create primary concept node and link
                    if concepts.primary_concept:
                        await self.neo4j_repo.create_concept(
                            name=concepts.primary_concept,
                            subject=concepts.subject,
                            chapter=concepts.chapter,
                        )
                        await self.neo4j_repo.link_question_to_concept(
                            question["id"],
                            concepts.primary_concept,
                            is_primary=True,
                        )
                        results["graph_nodes_created"] += 1

                    # Create secondary concept nodes and links
                    for secondary in concepts.secondary_concepts:
                        await self.neo4j_repo.create_concept(
                            name=secondary,
                            subject=concepts.subject,
                            chapter=concepts.chapter,
                        )
                        await self.neo4j_repo.link_question_to_concept(
                            question["id"],
                            secondary,
                            is_primary=False,
                        )
                        results["graph_nodes_created"] += 1

                    # Create prerequisite relationships
                    for prereq in concepts.prerequisite_concepts:
                        await self.neo4j_repo.create_concept(
                            name=prereq,
                            subject=concepts.subject,
                            chapter="",  # Will be updated when encountered as primary
                        )
                        await self.neo4j_repo.create_prerequisite_relationship(
                            concepts.primary_concept,
                            prereq,
                        )

                logger.info(f"Created {results['graph_nodes_created']} graph nodes")

            except Exception as e:
                logger.error(f"Neo4j error: {e}")
                results["errors"].append(f"Graph construction: {str(e)}")
        else:
            logger.info("Skipping Neo4j graph (not configured or no concepts)")

        return results

    async def cleanup_study_set(
        self,
        study_set_id: str,
        user_id: str,
    ) -> None:
        """
        Clean up all data for a study set.

        Args:
            study_set_id: Study set to clean up
            user_id: User ID for namespace
        """
        if self.pinecone_repo:
            try:
                await self.pinecone_repo.delete_by_study_set(user_id, study_set_id)
            except Exception as e:
                logger.error(f"Pinecone cleanup error: {e}")

        if self.neo4j_repo:
            try:
                await self.neo4j_repo.delete_study_set_data(study_set_id)
            except Exception as e:
                logger.error(f"Neo4j cleanup error: {e}")

    async def close(self):
        """Close all connections."""
        if self.neo4j_repo:
            await self.neo4j_repo.close()
