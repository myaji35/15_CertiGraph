"""Pinecone repository for question vector storage.

Stores question embeddings in Pinecone for similarity search.
Uses user_id as namespace for data isolation.
"""

import logging
from typing import Any, Optional
from pinecone import Pinecone, ServerlessSpec

from app.core.config import get_settings

logger = logging.getLogger(__name__)


class PineconeQuestionRepository:
    """Repository for storing and querying question vectors in Pinecone."""

    DIMENSION = 1536  # text-embedding-3-small
    METRIC = "cosine"
    CLOUD = "aws"
    REGION = "us-east-1"
    BATCH_SIZE = 100

    def __init__(self):
        settings = get_settings()
        self.pc = Pinecone(api_key=settings.pinecone_api_key)
        self.index_name = settings.pinecone_index_name
        self._ensure_index()
        self.index = self.pc.Index(self.index_name)

    def _ensure_index(self):
        """Create index if it doesn't exist."""
        existing_indexes = [idx.name for idx in self.pc.list_indexes()]

        if self.index_name not in existing_indexes:
            logger.info(f"Creating Pinecone index: {self.index_name}")
            self.pc.create_index(
                name=self.index_name,
                dimension=self.DIMENSION,
                metric=self.METRIC,
                spec=ServerlessSpec(
                    cloud=self.CLOUD,
                    region=self.REGION,
                ),
            )
            logger.info(f"Created Pinecone index: {self.index_name}")

    async def upsert_questions(
        self,
        questions_with_embeddings: list[tuple[dict[str, Any], list[float]]],
        user_id: str,
    ) -> int:
        """
        Upsert question vectors to Pinecone.

        Args:
            questions_with_embeddings: List of (question, embedding) tuples
            user_id: User ID for namespace isolation

        Returns:
            Number of vectors upserted
        """
        vectors = []

        for question, embedding in questions_with_embeddings:
            vector = {
                "id": question["id"],
                "values": embedding,
                "metadata": {
                    "study_set_id": question.get("study_set_id", ""),
                    "user_id": user_id,
                    "question_number": question.get("question_number", 0),
                    "question_text": question.get("question_text", "")[:1000],  # Limit metadata size
                    "correct_answer": question.get("correct_answer", 0),
                    "subject": question.get("subject", ""),
                    "topic": question.get("topic", ""),
                },
            }
            vectors.append(vector)

        # Upsert in batches
        total_upserted = 0
        for i in range(0, len(vectors), self.BATCH_SIZE):
            batch = vectors[i:i + self.BATCH_SIZE]
            self.index.upsert(vectors=batch, namespace=user_id)
            total_upserted += len(batch)
            logger.info(f"Upserted batch {i // self.BATCH_SIZE + 1}/{(len(vectors) + self.BATCH_SIZE - 1) // self.BATCH_SIZE}")

        return total_upserted

    async def query_similar(
        self,
        embedding: list[float],
        user_id: str,
        top_k: int = 10,
        filter_dict: Optional[dict] = None,
    ) -> list[dict[str, Any]]:
        """
        Query similar questions by embedding.

        Args:
            embedding: Query embedding vector
            user_id: User namespace
            top_k: Number of results to return
            filter_dict: Optional metadata filter

        Returns:
            List of similar questions with scores
        """
        query_params = {
            "vector": embedding,
            "top_k": top_k,
            "namespace": user_id,
            "include_metadata": True,
        }

        if filter_dict:
            query_params["filter"] = filter_dict

        results = self.index.query(**query_params)

        return [
            {
                "id": match.id,
                "score": match.score,
                "metadata": match.metadata,
            }
            for match in results.matches
        ]

    async def query_by_study_set(
        self,
        embedding: list[float],
        user_id: str,
        study_set_id: str,
        top_k: int = 10,
    ) -> list[dict[str, Any]]:
        """
        Query similar questions within a specific study set.

        Args:
            embedding: Query embedding vector
            user_id: User namespace
            study_set_id: Study set to filter by
            top_k: Number of results to return

        Returns:
            List of similar questions with scores
        """
        return await self.query_similar(
            embedding=embedding,
            user_id=user_id,
            top_k=top_k,
            filter_dict={"study_set_id": study_set_id},
        )

    async def delete_by_study_set(
        self,
        user_id: str,
        study_set_id: str,
    ) -> None:
        """
        Delete all vectors for a study set.

        Args:
            user_id: User namespace
            study_set_id: Study set to delete
        """
        self.index.delete(
            filter={"study_set_id": study_set_id},
            namespace=user_id,
        )
        logger.info(f"Deleted vectors for study set {study_set_id}")

    async def delete_namespace(self, user_id: str) -> None:
        """
        Delete entire user namespace.

        Args:
            user_id: User namespace to delete
        """
        self.index.delete(delete_all=True, namespace=user_id)
        logger.info(f"Deleted namespace {user_id}")

    async def get_stats(self) -> dict[str, Any]:
        """Get index statistics."""
        return self.index.describe_index_stats()
