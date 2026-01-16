"""Pytest configuration and fixtures for bot engine tests."""

from typing import Dict
from unittest.mock import AsyncMock, MagicMock

import pytest

from bot_engine.src.api.models import (
    ChangeCategory,
    CreateLogRequest,
    CreateRecipeRequest,
    IngredientType,
    LogOutcome,
    LogPost,
    Recipe,
    RecipeIngredient,
    RecipeStep,
)
from bot_engine.src.personas import BotPersona


@pytest.fixture
def korean_persona() -> BotPersona:
    """Create a test Korean persona."""
    return BotPersona(
        name="test_korean_chef",
        display_name={"ko": "테스트 셰프", "en": "Test Chef"},
        tone="PROFESSIONAL",
        skill_level="EXPERT",
        vocabulary_style="TECHNICAL",
        locale="ko",
        culinary_locale="ko",
        dietary_focus="NONE",
        kitchen_style_prompt="Modern Korean kitchen with professional equipment",
        specialties=["Korean cuisine", "Fusion"],
    )


@pytest.fixture
def english_persona() -> BotPersona:
    """Create a test English persona."""
    return BotPersona(
        name="test_english_chef",
        display_name={"ko": "테스트 셰프", "en": "Test Chef"},
        tone="CASUAL",
        skill_level="INTERMEDIATE",
        vocabulary_style="COLLOQUIAL",
        locale="en",
        culinary_locale="en-US",
        dietary_focus="HEALTHY",
        kitchen_style_prompt="Cozy home kitchen with natural lighting",
        specialties=["American comfort food"],
    )


@pytest.fixture
def sample_recipe() -> Recipe:
    """Create a sample recipe for testing."""
    return Recipe(
        public_id="recipe-123-456",
        title="Test Recipe",
        description="A delicious test recipe",
        locale="en",
        culinary_locale="en-US",
        creator_id="author-123",
        creator_username="test_chef",
        ingredients=[
            RecipeIngredient(
                name="Test Ingredient",
                amount="1 cup",
                type=IngredientType.MAIN,
                order=0,
            ),
            RecipeIngredient(
                name="Salt",
                amount="1 tsp",
                type=IngredientType.SEASONING,
                order=1,
            ),
        ],
        steps=[
            RecipeStep(
                order=1,
                description="Prepare the ingredients",
                image_public_ids=[],
            ),
            RecipeStep(
                order=2,
                description="Cook everything together",
                image_public_ids=[],
            ),
        ],
        image_urls=["https://example.com/img-123.jpg"],
        hashtags=["test", "recipe"],
    )


@pytest.fixture
def sample_log() -> LogPost:
    """Create a sample log post for testing."""
    return LogPost(
        public_id="log-123-456",
        recipe_public_id="recipe-123-456",
        recipe_title="Test Recipe",
        title="Making Test Recipe",
        content="Today I made the test recipe and it turned out great!",
        outcome=LogOutcome.SUCCESS,
        locale="en",
        creator_id="author-123",
        creator_username="test_chef",
        image_urls=["https://example.com/log-img-123.jpg"],
        hashtags=["cooking", "success"],
    )


@pytest.fixture
def mock_openai_client() -> MagicMock:
    """Create a mock OpenAI client."""
    mock = MagicMock()
    mock.chat = MagicMock()
    mock.chat.completions = MagicMock()
    mock.chat.completions.create = AsyncMock()
    return mock


@pytest.fixture
def mock_api_client() -> AsyncMock:
    """Create a mock API client."""
    mock = AsyncMock()
    mock.login_persona = AsyncMock()
    mock.create_recipe = AsyncMock()
    mock.create_log = AsyncMock()
    mock.upload_image_bytes = AsyncMock()
    mock.__aenter__ = AsyncMock(return_value=mock)
    mock.__aexit__ = AsyncMock(return_value=None)
    return mock


@pytest.fixture
def recipe_generation_response() -> Dict:
    """Sample ChatGPT recipe generation response."""
    return {
        "title": "Spicy Korean Fried Chicken",
        "description": "Crispy fried chicken with a sweet and spicy gochujang glaze",
        "ingredients": [
            {"name": "Chicken thighs", "amount": "1 lb", "type": "MAIN"},
            {"name": "Gochujang", "amount": "3 tbsp", "type": "SEASONING"},
            {"name": "Honey", "amount": "2 tbsp", "type": "SEASONING"},
            {"name": "Cornstarch", "amount": "1/2 cup", "type": "SECONDARY"},
        ],
        "steps": [
            {"order": 1, "description": "Cut chicken into bite-sized pieces"},
            {"order": 2, "description": "Coat chicken in cornstarch"},
            {"order": 3, "description": "Deep fry until golden and crispy"},
            {"order": 4, "description": "Toss with gochujang-honey glaze"},
        ],
        "hashtags": ["koreanfood", "friedchicken", "spicy", "homecooking"],
        "servings": 4,
        "cookingTimeRange": "30_TO_60_MIN",
    }


@pytest.fixture
def log_generation_response() -> Dict:
    """Sample ChatGPT log generation response."""
    return {
        "title": "First Attempt at Korean Fried Chicken!",
        "content": (
            "Just made this amazing fried chicken! The gochujang glaze was "
            "perfectly balanced between sweet and spicy. My family loved it. "
            "Next time I'll try making it even crispier by double frying."
        ),
        "hashtags": ["homecooking", "friedchicken", "success", "familydinner"],
    }
