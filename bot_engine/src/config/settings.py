"""Application settings using Pydantic Settings."""

from functools import lru_cache
from typing import Optional

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application configuration loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # API Configuration
    backend_base_url: str = Field(
        default="http://localhost:4001/api/v1",
        description="Pairing Planet backend API base URL",
    )

    # OpenAI Configuration
    openai_api_key: str = Field(
        default="sk-test-placeholder",
        description="OpenAI API key for ChatGPT",
    )
    openai_model: str = Field(
        default="gpt-4o",
        description="OpenAI model to use for text generation",
    )
    openai_temperature: float = Field(
        default=0.8,
        description="Temperature for text generation (0.0-2.0)",
    )

    # Image Generation Configuration
    nano_banana_api_key: Optional[str] = Field(
        default=None,
        description="Nano Banana Pro API key for image generation",
    )
    nano_banana_base_url: str = Field(
        default="https://api.nanobanana.pro/v1",
        description="Nano Banana Pro API base URL",
    )

    # Redis Configuration (for Celery)
    redis_url: str = Field(
        default="redis://localhost:6379/0",
        description="Redis URL for Celery broker and backend",
    )

    # Content Generation Settings
    recipes_per_day: int = Field(
        default=3,
        description="Number of recipes to generate per day during drip mode",
    )
    logs_per_day: int = Field(
        default=8,
        description="Number of cooking logs to generate per day during drip mode",
    )
    variant_ratio: float = Field(
        default=0.5,
        description="Ratio of variants to original recipes (0.5 = 50% variants)",
    )

    # Outcome Distribution for Logs
    log_success_ratio: float = Field(
        default=0.7,
        description="Ratio of SUCCESS outcome logs",
    )
    log_partial_ratio: float = Field(
        default=0.2,
        description="Ratio of PARTIAL outcome logs",
    )
    # FAILED ratio is 1 - success - partial

    # Rate Limiting
    api_requests_per_minute: int = Field(
        default=20,
        description="Max API requests per minute to backend",
    )
    openai_requests_per_minute: int = Field(
        default=60,
        description="Max requests per minute to OpenAI API",
    )

    # Logging
    log_level: str = Field(
        default="INFO",
        description="Logging level (DEBUG, INFO, WARNING, ERROR)",
    )


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
