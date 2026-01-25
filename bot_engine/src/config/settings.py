"""Application settings using Pydantic Settings."""

from functools import lru_cache

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
        default="http://localhost:4000/api/v1",
        description="Cookstemma backend API base URL",
    )
    bot_internal_secret: str = Field(
        default="dev-secret-change-me",
        description="Internal secret for bot auto-creation (must match backend)",
    )

    # Gemini Configuration
    gemini_api_key: str = Field(
        default="placeholder",
        description="Google Gemini API key from AI Studio",
    )
    gemini_image_model: str = Field(
        default="gemini-2.5-flash-image",
        description="Gemini model for image generation (Nano Banana)",
    )
    gemini_text_model: str = Field(
        default="gemini-2.5-flash-lite",
        description="Gemini model for text generation (lightweight)",
    )
    temperature: float = Field(
        default=0.8,
        description="Temperature for text generation (0.0-2.0)",
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

    # Rate Limiting
    api_requests_per_minute: int = Field(
        default=20,
        description="Max API requests per minute to backend",
    )
    gemini_requests_per_minute: int = Field(
        default=60,
        description="Max requests per minute to Gemini API",
    )

    # Logging
    log_level: str = Field(
        default="INFO",
        description="Logging level (DEBUG, INFO, WARNING, ERROR)",
    )

    # ==================== Engagement Simulation Settings ====================

    # Simulation Duration and Volume
    simulation_duration_hours: int = Field(
        default=24,
        description="Duration of engagement simulation in hours",
    )
    recipes_per_24h: int = Field(
        default=30,
        description="Total recipes to create in 24-hour simulation",
    )
    logs_per_24h: int = Field(
        default=100,
        description="Total cooking logs to create in 24-hour simulation",
    )
    social_actions_per_24h: int = Field(
        default=270,
        description="Total social interactions in 24-hour simulation",
    )

    # Social Interaction Mix (ratios must sum to 1.0)
    follow_ratio: float = Field(
        default=0.30,
        description="Ratio of follow actions in social mix",
    )
    recipe_save_ratio: float = Field(
        default=0.25,
        description="Ratio of recipe save actions in social mix",
    )
    log_save_ratio: float = Field(
        default=0.20,
        description="Ratio of log save actions in social mix",
    )
    comment_ratio: float = Field(
        default=0.15,
        description="Ratio of comment actions in social mix",
    )
    reply_ratio: float = Field(
        default=0.05,
        description="Ratio of reply actions in social mix",
    )
    comment_like_ratio: float = Field(
        default=0.05,
        description="Ratio of comment like actions in social mix",
    )

    # Rate Limiting for Simulation
    actions_per_minute: int = Field(
        default=10,
        description="Max actions per minute during simulation",
    )
    retry_attempts: int = Field(
        default=3,
        description="Number of retry attempts for failed actions",
    )
    retry_delay_seconds: int = Field(
        default=5,
        description="Delay in seconds between retry attempts",
    )


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()