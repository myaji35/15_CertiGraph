"""OpenAI embedding service for generating text vectors.

Uses text-embedding-3-small model for 1536-dimensional embeddings.
"""

import asyncio
import logging
from typing import Any
import openai

from app.core.config import get_settings

logger = logging.getLogger(__name__)


class OpenAIEmbeddingService:
    """Service for generating text embeddings using OpenAI."""

    MODEL = "text-embedding-3-small"
    DIMENSION = 1536
    BATCH_SIZE = 100  # OpenAI limit

    def __init__(self):
        settings = get_settings()
        self.client = openai.AsyncOpenAI(api_key=settings.openai_api_key)

    async def embed_text(self, text: str) -> list[float]:
        """
        Generate embedding for a single text.

        Args:
            text: Text to embed

        Returns:
            1536-dimensional embedding vector
        """
        try:
            response = await self.client.embeddings.create(
                model=self.MODEL,
                input=text,
            )
            return response.data[0].embedding
        except Exception as e:
            logger.error(f"Failed to embed text: {e}")
            raise

    async def embed_texts(self, texts: list[str]) -> list[list[float]]:
        """
        Generate embeddings for multiple texts.

        Args:
            texts: List of texts to embed

        Returns:
            List of 1536-dimensional embedding vectors
        """
        embeddings = []

        # Process in batches
        for i in range(0, len(texts), self.BATCH_SIZE):
            batch = texts[i:i + self.BATCH_SIZE]
            try:
                response = await self.client.embeddings.create(
                    model=self.MODEL,
                    input=batch,
                )
                batch_embeddings = [item.embedding for item in response.data]
                embeddings.extend(batch_embeddings)

                logger.info(f"Embedded batch {i // self.BATCH_SIZE + 1}/{(len(texts) + self.BATCH_SIZE - 1) // self.BATCH_SIZE}")

            except Exception as e:
                logger.error(f"Failed to embed batch: {e}")
                raise

        return embeddings

    def prepare_question_text(self, question: dict[str, Any]) -> str:
        """
        Prepare question text for embedding.

        Combines question text and options for better semantic representation.

        Args:
            question: Question dict with question_text and options

        Returns:
            Combined text for embedding
        """
        question_text = question.get("question_text", "")
        options = question.get("options", [])

        # Format options
        options_text = ""
        for opt in options:
            if isinstance(opt, dict):
                options_text += f"\n{opt.get('number', '')}. {opt.get('text', '')}"
            else:
                options_text += f"\n{opt}"

        return f"{question_text}{options_text}"

    async def embed_questions(
        self,
        questions: list[dict[str, Any]],
    ) -> list[tuple[dict[str, Any], list[float]]]:
        """
        Generate embeddings for a list of questions.

        Args:
            questions: List of question dicts

        Returns:
            List of (question, embedding) tuples
        """
        # Prepare texts
        texts = [self.prepare_question_text(q) for q in questions]

        # Generate embeddings
        embeddings = await self.embed_texts(texts)

        return list(zip(questions, embeddings))
