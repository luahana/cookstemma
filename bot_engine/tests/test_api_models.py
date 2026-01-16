"""Tests for API data models."""

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


class TestRecipeIngredient:
    """Tests for RecipeIngredient model."""

    def test_create_main_ingredient(self) -> None:
        """Test creating a main ingredient."""
        ingredient = RecipeIngredient(
            name="Chicken breast",
            amount="500g",
            type=IngredientType.MAIN,
            order=0,
        )

        assert ingredient.name == "Chicken breast"
        assert ingredient.amount == "500g"
        assert ingredient.type == IngredientType.MAIN
        assert ingredient.order == 0

    def test_ingredient_types(self) -> None:
        """Test all ingredient types."""
        assert IngredientType.MAIN.value == "MAIN"
        assert IngredientType.SECONDARY.value == "SECONDARY"
        assert IngredientType.SEASONING.value == "SEASONING"


class TestRecipeStep:
    """Tests for RecipeStep model."""

    def test_create_step(self) -> None:
        """Test creating a recipe step."""
        step = RecipeStep(
            order=1,
            description="Preheat the oven to 180°C",
            image_public_ids=["img-123"],
        )

        assert step.order == 1
        assert step.description == "Preheat the oven to 180°C"
        assert step.image_public_ids == ["img-123"]

    def test_step_without_images(self) -> None:
        """Test creating a step without images."""
        step = RecipeStep(
            order=1,
            description="Mix ingredients",
            image_public_ids=[],
        )

        assert step.image_public_ids == []


class TestRecipe:
    """Tests for Recipe model."""

    def test_recipe_attributes(self, sample_recipe: Recipe) -> None:
        """Test recipe has all required attributes."""
        assert sample_recipe.public_id == "recipe-123-456"
        assert sample_recipe.title == "Test Recipe"
        assert len(sample_recipe.ingredients) == 2
        assert len(sample_recipe.steps) == 2

    def test_recipe_is_variant(self) -> None:
        """Test identifying variant recipes."""
        original = Recipe(
            public_id="recipe-1",
            title="Original",
            description="Original recipe",
            locale="en",
            culinary_locale="en-US",
            creator_id="author-1",
            creator_username="test_chef",
            ingredients=[],
            steps=[],
            image_urls=[],
            hashtags=[],
        )

        variant = Recipe(
            public_id="recipe-2",
            title="Variant",
            description="Variant recipe",
            locale="en",
            culinary_locale="en-US",
            creator_id="author-1",
            creator_username="test_chef",
            ingredients=[],
            steps=[],
            image_urls=[],
            hashtags=[],
            parent_public_id="recipe-1",
        )

        assert original.parent_public_id is None
        assert variant.parent_public_id == "recipe-1"


class TestCreateRecipeRequest:
    """Tests for CreateRecipeRequest model."""

    def test_create_original_recipe_request(self) -> None:
        """Test creating request for original recipe."""
        request = CreateRecipeRequest(
            title="New Recipe",
            description="A new delicious recipe",
            locale="ko",
            culinary_locale="ko",
            ingredients=[
                RecipeIngredient(
                    name="재료", amount="1컵", type=IngredientType.MAIN, order=0
                )
            ],
            steps=[
                RecipeStep(order=1, description="준비합니다", image_public_ids=[])
            ],
            image_public_ids=["img-1"],
            hashtags=["한식", "요리"],
        )

        assert request.title == "New Recipe"
        assert request.locale == "ko"
        assert request.parent_public_id is None

    def test_create_variant_recipe_request(self) -> None:
        """Test creating request for variant recipe."""
        request = CreateRecipeRequest(
            title="Spicy Variant",
            description="A spicier version",
            locale="en",
            culinary_locale="en-US",
            ingredients=[],
            steps=[],
            image_public_ids=[],
            hashtags=[],
            parent_public_id="parent-123",
            change_diff="Added more chili",
            change_reason="For extra heat",
            change_categories=[ChangeCategory.SEASONING_CHANGE],
        )

        assert request.parent_public_id == "parent-123"
        assert request.change_diff == "Added more chili"
        assert ChangeCategory.SEASONING_CHANGE in request.change_categories


class TestLogOutcome:
    """Tests for LogOutcome enum."""

    def test_outcome_values(self) -> None:
        """Test all outcome values."""
        assert LogOutcome.SUCCESS.value == "SUCCESS"
        assert LogOutcome.PARTIAL.value == "PARTIAL"
        assert LogOutcome.FAILED.value == "FAILED"


class TestLogPost:
    """Tests for LogPost model."""

    def test_log_attributes(self, sample_log: LogPost) -> None:
        """Test log has all required attributes."""
        assert sample_log.public_id == "log-123-456"
        assert sample_log.recipe_public_id == "recipe-123-456"
        assert sample_log.outcome == LogOutcome.SUCCESS
        assert "great" in sample_log.content

    def test_log_outcomes(self) -> None:
        """Test different log outcomes."""
        success_log = LogPost(
            public_id="log-1",
            recipe_public_id="recipe-1",
            recipe_title="Test Recipe",
            title="Success",
            content="It worked!",
            outcome=LogOutcome.SUCCESS,
            locale="en",
            creator_id="author-1",
            creator_username="test_chef",
            image_urls=[],
            hashtags=[],
        )

        failed_log = LogPost(
            public_id="log-2",
            recipe_public_id="recipe-1",
            recipe_title="Test Recipe",
            title="Failed",
            content="It burned...",
            outcome=LogOutcome.FAILED,
            locale="en",
            creator_id="author-1",
            creator_username="test_chef",
            image_urls=[],
            hashtags=[],
        )

        assert success_log.outcome == LogOutcome.SUCCESS
        assert failed_log.outcome == LogOutcome.FAILED


class TestCreateLogRequest:
    """Tests for CreateLogRequest model."""

    def test_create_log_request(self) -> None:
        """Test creating a log request."""
        request = CreateLogRequest(
            recipe_public_id="recipe-123",
            title="My Cooking Experience",
            content="Today I tried this recipe and it turned out amazing!",
            outcome=LogOutcome.SUCCESS,
            locale="en",
            image_public_ids=["img-1", "img-2"],
            hashtags=["cooking", "success"],
        )

        assert request.recipe_public_id == "recipe-123"
        assert request.outcome == LogOutcome.SUCCESS
        assert len(request.image_public_ids) == 2


class TestChangeCategory:
    """Tests for ChangeCategory enum."""

    def test_change_categories(self) -> None:
        """Test all change categories exist."""
        categories = [
            ChangeCategory.INGREDIENT_SUBSTITUTION,
            ChangeCategory.QUANTITY_ADJUSTMENT,
            ChangeCategory.COOKING_METHOD,
            ChangeCategory.SEASONING_CHANGE,
            ChangeCategory.DIETARY_ADAPTATION,
            ChangeCategory.TIME_OPTIMIZATION,
            ChangeCategory.EQUIPMENT_CHANGE,
            ChangeCategory.PRESENTATION,
        ]

        assert len(categories) == 8
        for cat in categories:
            assert isinstance(cat.value, str)
