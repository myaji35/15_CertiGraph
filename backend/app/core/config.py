from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Clerk (for JWT verification)
    clerk_jwks_url: str

    # Supabase (Database only)
    supabase_url: str
    supabase_service_key: str

    # OpenAI
    openai_api_key: str

    # Upstage
    upstage_api_key: str

    # Pinecone
    pinecone_api_key: str
    pinecone_index_name: str = "certigraph-questions"

    # Neo4j
    neo4j_uri: str
    neo4j_user: str = "neo4j"
    neo4j_password: str

    # Server
    cors_origins: str = "http://localhost:3000"

    @property
    def cors_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",")]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache
def get_settings() -> Settings:
    return Settings()
