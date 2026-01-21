"""Pytest configuration and fixtures for bot engine tests."""

from typing import Dict
from unittest.mock import AsyncMock, MagicMock

import pytest

from src.api.models import (
    ChangeCategory,
    CreateLogRequest,
    CreateRecipeRequest,
    IngredientType,
    LogPost,
    LinkedRecipeSummary,
    MeasurementUnit,
    Recipe,
    RecipeIngredient,
    RecipeStep,
)
from src.personas import BotPersona, Tone, SkillLevel, DietaryFocus, VocabularyStyle


@pytest.fixture
def korean_persona() -> BotPersona:
    """Create a test Korean persona."""
    return BotPersona(
        name="test_korean_chef",
        display_name={"ko": "테스트 셰프", "en": "Test Chef"},
        tone=Tone.PROFESSIONAL,
        skill_level=SkillLevel.PROFESSIONAL,
        vocabulary_style=VocabularyStyle.TECHNICAL,
        locale="ko-KR",
        cooking_style="KR",
        dietary_focus=DietaryFocus.FINE_DINING,
        kitchen_style_prompt="Modern Korean kitchen with professional equipment",
        specialties=["Korean cuisine", "Fusion"],
    )


@pytest.fixture
def english_persona() -> BotPersona:
    """Create a test English persona."""
    return BotPersona(
        name="test_english_chef",
        display_name={"ko": "테스트 셰프", "en": "Test Chef"},
        tone=Tone.CASUAL,
        skill_level=SkillLevel.INTERMEDIATE,
        vocabulary_style=VocabularyStyle.STANDARD,
        locale="en-US",
        cooking_style="US",
        dietary_focus=DietaryFocus.HEALTHY,
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
        cooking_style="en-US",
        creator_id="author-123",
        creator_username="test_chef",
        ingredients=[
            RecipeIngredient(
                name="Test Ingredient",
                quantity=1.0,
                unit=MeasurementUnit.CUP,
                type=IngredientType.MAIN,
                order=0,
            ),
            RecipeIngredient(
                name="Salt",
                quantity=1.0,
                unit=MeasurementUnit.TSP,
                type=IngredientType.SEASONING,
                order=1,
            ),
        ],
        steps=[
            RecipeStep(
                step_number=1,
                description="Prepare the ingredients",
            ),
            RecipeStep(
                step_number=2,
                description="Cook everything together",
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
        linked_recipe=LinkedRecipeSummary(
            public_id="recipe-123-456",
            title="Test Recipe",
        ),
        title="Making Test Recipe",
        content="Today I made the test recipe and it turned out great!",
        rating=5,
        creator_public_id="author-123",
        user_name="test_chef",
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
            {"name": "Chicken thighs", "quantity": 1.0, "unit": "LB", "type": "MAIN"},
            {"name": "Gochujang", "quantity": 3.0, "unit": "TBSP", "type": "SEASONING"},
            {"name": "Honey", "quantity": 2.0, "unit": "TBSP", "type": "SEASONING"},
            {"name": "Cornstarch", "quantity": 0.5, "unit": "CUP", "type": "SECONDARY"},
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
