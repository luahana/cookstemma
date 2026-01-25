"""Tests for API data models."""

import pytest

from src.api.models import (
    ChangeCategory,
    CreateLogRequest,
    CreateRecipeRequest,
    IngredientType,
    LogPost,
    MeasurementUnit,
    Recipe,
    RecipeIngredient,
    RecipeStep,
)


class TestRecipeIngredient:
    """Tests for RecipeIngredient model."""

    def test_create_main_ingredient(self) -> None:
        """Test creating a main ingredient with quantity and unit."""
        ingredient = RecipeIngredient(
            name="Chicken breast",
            quantity=500.0,
            unit=MeasurementUnit.G,
            type=IngredientType.MAIN,
            order=0,
        )

        assert ingredient.name == "Chicken breast"
        assert ingredient.quantity == 500.0
        assert ingredient.unit == MeasurementUnit.G
        assert ingredient.type == IngredientType.MAIN
        assert ingredient.order == 0

    def test_ingredient_without_unit(self) -> None:
        """Test creating an ingredient without unit (e.g., 'to taste')."""
        ingredient = RecipeIngredient(
            name="Salt",
            quantity=None,
            unit=MeasurementUnit.TO_TASTE,
            type=IngredientType.SEASONING,
            order=0,
        )

        assert ingredient.name == "Salt"
        assert ingredient.quantity is None
        assert ingredient.unit == MeasurementUnit.TO_TASTE

    def test_ingredient_types(self) -> None:
        """Test all ingredient types."""
        assert IngredientType.MAIN.value == "MAIN"
        assert IngredientType.SECONDARY.value == "SECONDARY"
        assert IngredientType.SEASONING.value == "SEASONING"


class TestMeasurementUnit:
    """Tests for MeasurementUnit enum."""

    def test_volume_units(self) -> None:
        """Test volume measurement units."""
        assert MeasurementUnit.ML.value == "ML"
        assert MeasurementUnit.L.value == "L"
        assert MeasurementUnit.TSP.value == "TSP"
        assert MeasurementUnit.TBSP.value == "TBSP"
        assert MeasurementUnit.CUP.value == "CUP"

    def test_weight_units(self) -> None:
        """Test weight measurement units."""
        assert MeasurementUnit.G.value == "G"
        assert MeasurementUnit.KG.value == "KG"
        assert MeasurementUnit.OZ.value == "OZ"
        assert MeasurementUnit.LB.value == "LB"

    def test_count_units(self) -> None:
        """Test count/other measurement units."""
        assert MeasurementUnit.PIECE.value == "PIECE"
        assert MeasurementUnit.PINCH.value == "PINCH"
        assert MeasurementUnit.TO_TASTE.value == "TO_TASTE"
        assert MeasurementUnit.CLOVE.value == "CLOVE"


class TestRecipeStep:
    """Tests for RecipeStep model."""

    def test_create_step(self) -> None:
        """Test creating a recipe step."""
        step = RecipeStep(
            step_number=1,
            description="Preheat the oven to 180°C",
            image_public_id="img-123",
        )

        assert step.step_number == 1
        assert step.description == "Preheat the oven to 180°C"
        assert step.image_public_id == "img-123"

    def test_step_without_images(self) -> None:
        """Test creating a step without images."""
        step = RecipeStep(
            step_number=1,
            description="Mix ingredients",
        )

        assert step.image_public_id is None


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
            cooking_style="en-US",
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
            cooking_style="en-US",
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
            cooking_style="ko",
            ingredients=[
                RecipeIngredient(
                    name="재료",
                    quantity=1.0,
                    unit=MeasurementUnit.CUP,
                    type=IngredientType.MAIN,
                    order=0,
                )
            ],
            steps=[
                RecipeStep(step_number=1, description="준비합니다")
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
            cooking_style="en-US",
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


class TestLogPost:
    """Tests for LogPost model."""

    def test_log_attributes(self, sample_log: LogPost) -> None:
        """Test log has all required attributes."""
        assert sample_log.public_id == "log-123-456"
        assert sample_log.recipe_public_id == "recipe-123-456"
        assert sample_log.rating == 5
        assert "great" in sample_log.content

    def test_log_ratings(self) -> None:
        """Test different log ratings."""
        high_rating_log = LogPost(
            public_id="log-1",
            content="It worked great!",
            rating=5,
            hashtags=[],
        )

        low_rating_log = LogPost(
            public_id="log-2",
            content="It burned...",
            rating=1,
            hashtags=[],
        )

        assert high_rating_log.rating == 5
        assert low_rating_log.rating == 1


class TestCreateLogRequest:
    """Tests for CreateLogRequest model."""

    def test_create_log_request(self) -> None:
        """Test creating a log request."""
        request = CreateLogRequest(
            recipe_public_id="recipe-123",
            title="My amazing cooking experience",
            content="Today I tried this recipe and it turned out amazing!",
            rating=5,
            image_public_ids=["img-1", "img-2"],
            hashtags=["cooking", "success"],
        )

        assert request.recipe_public_id == "recipe-123"
        assert request.title == "My amazing cooking experience"
        assert request.rating == 5
        assert len(request.image_public_ids) == 2

    def test_create_log_request_with_private(self) -> None:
        """Test creating a private log request."""
        request = CreateLogRequest(
            recipe_public_id="recipe-123",
            title="My private log",
            content="Private log content",
            rating=4,
            is_private=True,
        )

        assert request.is_private is True
        assert request.title == "My private log"
        assert request.rating == 4


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
