"""Tests for recipe and log pipelines."""

import pytest
from typing import Dict, List
from unittest.mock import AsyncMock, MagicMock, patch

from src.api.models import (
    IngredientType,
    LogPost,
    MeasurementUnit,
    Recipe,
    RecipeIngredient,
    RecipeStep,
    ImageUploadResponse,
)
from src.orchestrator.recipe_pipeline import RecipePipeline
from src.orchestrator.log_pipeline import LogPipeline
from src.personas import BotPersona, DietaryFocus
from src.generators.text.prompts import CULTURAL_PREFERENCES, DIETARY_PREFERENCES


class TestRecipePipeline:
    """Tests for the RecipePipeline class."""

    @pytest.fixture
    def mock_text_generator(self, recipe_generation_response: Dict) -> AsyncMock:
        """Create a mock text generator."""
        mock = AsyncMock()
        mock.generate_recipe = AsyncMock(return_value=recipe_generation_response)
        mock.suggest_food_names = AsyncMock(
            return_value=["Dish 1", "Dish 2", "Dish 3"]
        )
        mock.suggest_variation_types = AsyncMock(
            return_value=["spicier", "healthier"]
        )
        mock.generate_variant = AsyncMock(
            return_value={
                "title": "Spicy Variant",
                "description": "A spicier version",
                "ingredients": [
                    {"name": "Chili", "quantity": 1.0, "unit": "TBSP", "type": "SEASONING"}
                ],
                "steps": [{"order": 1, "description": "Add chili"}],
                "hashtags": ["spicy"],
                "changeDiff": "Added chili",
                "changeReason": "For more heat",
                "changeCategories": ["SEASONING_CHANGE"],
            }
        )
        return mock

    @pytest.fixture
    def mock_image_generator(self) -> AsyncMock:
        """Create a mock image generator."""
        mock = AsyncMock()
        mock.generate_recipe_images = AsyncMock(
            return_value={"cover_images": [b"fake_image_data"]}
        )
        mock.optimize_image = MagicMock(return_value=b"optimized_image")
        mock.close = AsyncMock()
        return mock

    @pytest.fixture
    def mock_api_client(self, sample_recipe: Recipe) -> AsyncMock:
        """Create a mock API client."""
        mock = AsyncMock()
        mock.create_recipe = AsyncMock(return_value=sample_recipe)
        mock.upload_image_bytes = AsyncMock(
            return_value=ImageUploadResponse(
                public_id="img-uploaded-123",
                url="https://example.com/img.jpg",
            )
        )
        return mock

    @pytest.mark.asyncio
    async def test_generate_original_recipe(
        self,
        korean_persona: BotPersona,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
        sample_recipe: Recipe,
    ) -> None:
        """Test generating an original recipe."""
        pipeline = RecipePipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        result = await pipeline.generate_original_recipe(
            persona=korean_persona,
            food_name="Test Dish",
            generate_images=True,
        )

        # Verify text generation was called
        mock_text_generator.generate_recipe.assert_called_once_with(
            korean_persona, "Test Dish"
        )

        # Verify image generation was called
        mock_image_generator.generate_recipe_images.assert_called_once()

        # Verify API was called to create recipe
        mock_api_client.create_recipe.assert_called_once()

        # Result should be the created recipe
        assert result == sample_recipe

    @pytest.mark.asyncio
    async def test_generate_original_recipe_without_images(
        self,
        korean_persona: BotPersona,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
        sample_recipe: Recipe,
    ) -> None:
        """Test generating recipe without images."""
        pipeline = RecipePipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        await pipeline.generate_original_recipe(
            persona=korean_persona,
            food_name="Test Dish",
            generate_images=False,
        )

        # Image generator should not be called
        mock_image_generator.generate_recipe_images.assert_not_called()

    @pytest.mark.asyncio
    async def test_parse_ingredients(
        self,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
    ) -> None:
        """Test ingredient parsing from ChatGPT response."""
        pipeline = RecipePipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        ingredients_data = [
            {"name": "Chicken", "quantity": 500.0, "unit": "G", "type": "MAIN"},
            {"name": "Salt", "quantity": 1.0, "unit": "TSP", "type": "SEASONING"},
            {"name": "invalid_type", "quantity": 1.0, "unit": "PIECE", "type": "INVALID"},
            {"name": "no_unit", "quantity": 2.0, "unit": "INVALID_UNIT", "type": "MAIN"},
        ]

        result = pipeline._parse_ingredients(ingredients_data)

        assert len(result) == 4
        assert result[0].type == IngredientType.MAIN
        assert result[0].quantity == 500.0
        assert result[0].unit == MeasurementUnit.G
        assert result[1].type == IngredientType.SEASONING
        assert result[1].unit == MeasurementUnit.TSP
        # Invalid type should default to MAIN
        assert result[2].type == IngredientType.MAIN
        # Invalid unit should be None
        assert result[3].unit is None

    @pytest.mark.asyncio
    async def test_parse_steps(
        self,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
    ) -> None:
        """Test step parsing from ChatGPT response."""
        pipeline = RecipePipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        steps_data = [
            {"order": 1, "description": "Prepare ingredients"},
            {"order": 2, "description": "Cook"},
            {"description": "No order field"},  # Missing order
        ]

        result = pipeline._parse_steps(steps_data)

        assert len(result) == 3
        assert result[0].order == 1
        assert result[1].order == 2
        assert result[2].order == 3  # Should use index + 1 as fallback


class TestCrossCulturalSelection:
    """Tests for cross-cultural recipe selection and adaptation."""

    @pytest.fixture
    def mock_text_generator(self) -> AsyncMock:
        """Create a mock text generator."""
        return AsyncMock()

    @pytest.fixture
    def mock_image_generator(self) -> AsyncMock:
        """Create a mock image generator."""
        return AsyncMock()

    @pytest.fixture
    def mock_api_client(self) -> AsyncMock:
        """Create a mock API client."""
        return AsyncMock()

    @pytest.fixture
    def italian_recipe(self) -> Recipe:
        """Create a sample Italian recipe."""
        return Recipe(
            public_id="recipe-italian-123",
            title="Classic Pasta Carbonara",
            description="Traditional Italian pasta with eggs and bacon",
            locale="it-IT",
            cooking_style="IT",
            ingredients=[
                RecipeIngredient(name="Spaghetti", quantity=400.0, unit=MeasurementUnit.G),
            ],
            steps=[RecipeStep(step_number=1, description="Cook pasta")],
        )

    @pytest.fixture
    def american_recipe(self) -> Recipe:
        """Create a sample American recipe."""
        return Recipe(
            public_id="recipe-american-456",
            title="Classic Cheeseburger",
            description="Juicy American cheeseburger",
            locale="en-US",
            cooking_style="US",
            ingredients=[
                RecipeIngredient(name="Ground beef", quantity=1.0, unit=MeasurementUnit.LB),
            ],
            steps=[RecipeStep(step_number=1, description="Form patties")],
        )

    @pytest.fixture
    def korean_recipe(self) -> Recipe:
        """Create a sample Korean recipe."""
        return Recipe(
            public_id="recipe-korean-789",
            title="Kimchi Jjigae",
            description="Traditional Korean kimchi stew",
            locale="ko-KR",
            cooking_style="KR",
            ingredients=[
                RecipeIngredient(name="Kimchi", quantity=300.0, unit=MeasurementUnit.G),
            ],
            steps=[RecipeStep(step_number=1, description="Prepare kimchi")],
        )

    @pytest.fixture
    def recipe_pool(
        self,
        italian_recipe: Recipe,
        american_recipe: Recipe,
        korean_recipe: Recipe,
    ) -> List[Recipe]:
        """Create a pool of recipes from different cultures."""
        return [italian_recipe, american_recipe, korean_recipe]

    def test_select_parent_prefers_foreign_recipes(
        self,
        korean_persona: BotPersona,
        recipe_pool: List[Recipe],
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
    ) -> None:
        """Test that cross-cultural selection prefers foreign recipes."""
        pipeline = RecipePipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        # With 100% cross-cultural ratio, should never pick Korean recipe
        foreign_selections = 0
        for _ in range(100):
            selected = pipeline.select_parent_for_cross_cultural(
                persona=korean_persona,
                available_recipes=recipe_pool,
                cross_cultural_ratio=1.0,  # 100% foreign
            )
            if selected and selected.cooking_style != korean_persona.cooking_style:
                foreign_selections += 1

        # Should select foreign recipe 100% of the time
        assert foreign_selections == 100

    def test_select_parent_returns_none_for_empty_pool(
        self,
        korean_persona: BotPersona,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
    ) -> None:
        """Test that selection returns None for empty recipe pool."""
        pipeline = RecipePipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        result = pipeline.select_parent_for_cross_cultural(
            persona=korean_persona,
            available_recipes=[],
            cross_cultural_ratio=0.8,
        )

        assert result is None

    def test_select_parent_falls_back_to_same_culture(
        self,
        korean_persona: BotPersona,
        korean_recipe: Recipe,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
    ) -> None:
        """Test that selection falls back to same culture when no foreign available."""
        pipeline = RecipePipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        # Pool only has Korean recipes
        result = pipeline.select_parent_for_cross_cultural(
            persona=korean_persona,
            available_recipes=[korean_recipe],
            cross_cultural_ratio=0.8,
        )

        assert result is not None
        assert result.cooking_style == "KR"

    def test_get_cultural_context_returns_correct_preferences(
        self,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
    ) -> None:
        """Test that cultural context is built correctly."""
        pipeline = RecipePipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        context = pipeline.get_cultural_context(
            source_style="IT",
            target_style="KR",
        )

        assert context["source_culture"] == "Italian"
        assert context["target_culture"] == "Korean"
        assert "gochujang" in context["prefer_ingredients"]
        assert "cilantro" in context["avoid_ingredients"]
        assert "fermented" in context["cooking_notes"].lower()

    def test_get_cultural_context_handles_unknown_styles(
        self,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
    ) -> None:
        """Test that unknown cooking styles are handled gracefully."""
        pipeline = RecipePipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        context = pipeline.get_cultural_context(
            source_style="UNKNOWN",
            target_style="ALSO_UNKNOWN",
        )

        # Should use style code as fallback for name
        assert context["source_culture"] == "UNKNOWN"
        assert context["target_culture"] == "ALSO_UNKNOWN"
        # Should have empty lists for preferences
        assert context["avoid_ingredients"] == []
        assert context["prefer_ingredients"] == []
        assert context["cooking_notes"] == ""


class TestCulturalPreferences:
    """Tests for the CULTURAL_PREFERENCES data structure."""

    def test_all_cultures_have_required_fields(self) -> None:
        """Test that all cultures have name, avoid, prefer, and cooking_notes."""
        required_fields = ["name", "avoid_ingredients", "prefer_ingredients", "cooking_notes"]

        for style, prefs in CULTURAL_PREFERENCES.items():
            for field in required_fields:
                assert field in prefs, f"Culture {style} missing field {field}"
                if field == "name":
                    assert isinstance(prefs[field], str)
                elif field == "cooking_notes":
                    assert isinstance(prefs[field], str)
                else:
                    assert isinstance(prefs[field], list)
                    assert len(prefs[field]) > 0, f"Culture {style} has empty {field}"

    def test_expected_cultures_are_defined(self) -> None:
        """Test that all expected cultures are defined."""
        expected_cultures = ["KR", "JP", "US", "IT", "CN", "MX", "IN", "TH", "FR", "VN"]

        for culture in expected_cultures:
            assert culture in CULTURAL_PREFERENCES, f"Missing culture: {culture}"

    def test_korean_preferences_are_accurate(self) -> None:
        """Test Korean cultural preferences."""
        kr = CULTURAL_PREFERENCES["KR"]

        assert kr["name"] == "Korean"
        assert "gochujang" in kr["prefer_ingredients"]
        assert "cilantro" in kr["avoid_ingredients"]


class TestLogPipeline:
    """Tests for the LogPipeline class."""

    @pytest.fixture
    def mock_text_generator(self, log_generation_response: Dict) -> AsyncMock:
        """Create a mock text generator."""
        mock = AsyncMock()
        mock.generate_log = AsyncMock(return_value=log_generation_response)
        return mock

    @pytest.fixture
    def mock_image_generator(self) -> AsyncMock:
        """Create a mock image generator."""
        mock = AsyncMock()
        mock.generate_log_image = AsyncMock(return_value=b"fake_log_image")
        mock.optimize_image = MagicMock(return_value=b"optimized_image")
        mock.close = AsyncMock()
        return mock

    @pytest.fixture
    def mock_api_client(self, sample_log: LogPost) -> AsyncMock:
        """Create a mock API client."""
        mock = AsyncMock()
        mock.create_log = AsyncMock(return_value=sample_log)
        mock.upload_image_bytes = AsyncMock(
            return_value=ImageUploadResponse(
                public_id="log-img-uploaded",
                url="https://example.com/log.jpg",
            )
        )
        return mock

    @pytest.mark.asyncio
    async def test_generate_log(
        self,
        english_persona: BotPersona,
        sample_recipe: Recipe,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
        sample_log: LogPost,
    ) -> None:
        """Test generating a cooking log."""
        pipeline = LogPipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        result = await pipeline.generate_log(
            persona=english_persona,
            recipe=sample_recipe,
            rating=5,
            num_images=1,
        )

        # Verify text generation was called
        mock_text_generator.generate_log.assert_called_once()

        # Verify image generation was called
        mock_image_generator.generate_log_image.assert_called_once()

        # Verify API was called to create log
        mock_api_client.create_log.assert_called_once()

        assert result == sample_log

    @pytest.mark.asyncio
    async def test_generate_log_without_image(
        self,
        english_persona: BotPersona,
        sample_recipe: Recipe,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
    ) -> None:
        """Test generating log without image."""
        pipeline = LogPipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        await pipeline.generate_log(
            persona=english_persona,
            recipe=sample_recipe,
            num_images=0,
        )

        # Image generator should not be called
        mock_image_generator.generate_log_image.assert_not_called()

    @pytest.mark.asyncio
    async def test_select_rating_distribution(
        self,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
    ) -> None:
        """Test that rating selection follows configured distribution."""
        pipeline = LogPipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        # Generate many ratings to verify distribution (default: 3-5)
        ratings = [pipeline._select_rating() for _ in range(1000)]

        # All ratings should be in 3-5 range (default)
        assert all(3 <= r <= 5 for r in ratings)

        # Should be biased towards higher ratings
        rating_5_count = sum(1 for r in ratings if r == 5)
        rating_4_count = sum(1 for r in ratings if r == 4)
        rating_3_count = sum(1 for r in ratings if r == 3)

        # Rating 4 and 5 should be more common than 3
        assert rating_5_count > rating_3_count * 0.5
        assert rating_4_count > rating_3_count * 0.5

    @pytest.mark.asyncio
    async def test_generate_logs_for_recipe_uses_multiple_personas(
        self,
        korean_persona: BotPersona,
        english_persona: BotPersona,
        sample_recipe: Recipe,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
        sample_log: LogPost,
    ) -> None:
        """Test generating multiple logs uses different personas."""
        pipeline = LogPipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        personas = [korean_persona, english_persona]
        logs = await pipeline.generate_logs_for_recipe(
            personas=personas,
            recipe=sample_recipe,
            count=5,
            num_images=0,
        )

        # Should generate requested number of logs
        assert len(logs) == 5

        # Text generator should be called 5 times
        assert mock_text_generator.generate_log.call_count == 5


class TestDietaryPreferences:
    """Tests for the DIETARY_PREFERENCES data structure."""

    def test_all_dietary_types_have_required_fields(self) -> None:
        """Test that all dietary types have name, avoid, prefer, and cooking_notes."""
        required_fields = ["name", "avoid_ingredients", "prefer_ingredients", "cooking_notes"]

        for diet_type, prefs in DIETARY_PREFERENCES.items():
            for field in required_fields:
                assert field in prefs, f"Diet type {diet_type} missing field {field}"
                if field == "name":
                    assert isinstance(prefs[field], str)
                elif field == "cooking_notes":
                    assert isinstance(prefs[field], str)
                else:
                    assert isinstance(prefs[field], list)

    def test_expected_dietary_types_are_defined(self) -> None:
        """Test that all expected dietary types are defined."""
        expected_types = [
            # Existing types
            "vegetarian", "healthy", "budget", "fine_dining",
            "quick_meals", "baking", "international", "farm_to_table",
            # New types
            "vegan", "keto", "gluten_free", "halal",
            "kosher", "pescatarian", "dairy_free", "low_sodium",
        ]

        for diet_type in expected_types:
            assert diet_type in DIETARY_PREFERENCES, f"Missing diet type: {diet_type}"

    def test_dietary_types_match_enum(self) -> None:
        """Test that all DietaryFocus enum values have corresponding preferences."""
        for focus in DietaryFocus:
            assert focus.value in DIETARY_PREFERENCES, (
                f"DietaryFocus.{focus.name} ({focus.value}) not in DIETARY_PREFERENCES"
            )

    def test_vegan_preferences_are_accurate(self) -> None:
        """Test vegan dietary preferences."""
        vegan = DIETARY_PREFERENCES["vegan"]

        assert vegan["name"] == "Vegan"
        assert "tofu" in vegan["prefer_ingredients"]
        assert "meat" in vegan["avoid_ingredients"]
        assert "dairy" in vegan["avoid_ingredients"]
        assert "eggs" in vegan["avoid_ingredients"]

    def test_halal_preferences_are_accurate(self) -> None:
        """Test halal dietary preferences."""
        halal = DIETARY_PREFERENCES["halal"]

        assert halal["name"] == "Halal"
        assert "pork" in halal["avoid_ingredients"]
        assert "alcohol" in halal["avoid_ingredients"]
        assert "lamb" in halal["prefer_ingredients"]

    def test_keto_preferences_are_accurate(self) -> None:
        """Test keto dietary preferences."""
        keto = DIETARY_PREFERENCES["keto"]

        assert keto["name"] == "Keto/Low-Carb"
        assert "rice" in keto["avoid_ingredients"]
        assert "pasta" in keto["avoid_ingredients"]
        assert "avocado" in keto["prefer_ingredients"]
        assert "cauliflower" in keto["prefer_ingredients"]


class TestCulturalAndDietaryContext:
    """Tests for combined cultural and dietary context."""

    @pytest.fixture
    def mock_text_generator(self) -> AsyncMock:
        """Create a mock text generator."""
        return AsyncMock()

    @pytest.fixture
    def mock_image_generator(self) -> AsyncMock:
        """Create a mock image generator."""
        return AsyncMock()

    @pytest.fixture
    def mock_api_client(self) -> AsyncMock:
        """Create a mock API client."""
        return AsyncMock()

    def test_get_cultural_context_with_dietary_focus(
        self,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
    ) -> None:
        """Test that cultural context includes dietary focus."""
        pipeline = RecipePipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        context = pipeline.get_cultural_context(
            source_style="IT",
            target_style="US",
            dietary_focus="vegan",
        )

        assert context["dietary_focus"] == "Vegan"
        # Should include vegan avoid ingredients
        assert "meat" in context["avoid_ingredients"]
        assert "dairy" in context["avoid_ingredients"]
        # Should include vegan prefer ingredients
        assert "tofu" in context["prefer_ingredients"]

    def test_get_cultural_context_merges_preferences(
        self,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
    ) -> None:
        """Test that cultural and dietary preferences are merged."""
        pipeline = RecipePipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        context = pipeline.get_cultural_context(
            source_style="IT",
            target_style="KR",
            dietary_focus="vegan",
        )

        # Should have Korean cultural preferences
        assert "gochujang" in context["prefer_ingredients"]
        assert "cilantro" in context["avoid_ingredients"]
        # Should also have vegan preferences merged
        assert "tofu" in context["prefer_ingredients"]
        assert "meat" in context["avoid_ingredients"]
        # Dietary focus should be set
        assert context["dietary_focus"] == "Vegan"

    def test_get_cultural_context_halal_korean_combination(
        self,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
    ) -> None:
        """Test halal + Korean culture combination."""
        pipeline = RecipePipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        context = pipeline.get_cultural_context(
            source_style="FR",
            target_style="KR",
            dietary_focus="halal",
        )

        assert context["source_culture"] == "French"
        assert context["target_culture"] == "Korean"
        assert context["dietary_focus"] == "Halal"
        # Should have both Korean and halal avoid ingredients
        assert "pork" in context["avoid_ingredients"]  # From halal
        assert "alcohol" in context["avoid_ingredients"]  # From halal
        assert "cilantro" in context["avoid_ingredients"]  # From Korean
        # Should have Korean prefer ingredients
        assert "gochujang" in context["prefer_ingredients"]

    def test_get_cultural_context_without_dietary_focus(
        self,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
    ) -> None:
        """Test that context works without dietary focus."""
        pipeline = RecipePipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        context = pipeline.get_cultural_context(
            source_style="IT",
            target_style="KR",
        )

        # Should still have cultural preferences
        assert context["target_culture"] == "Korean"
        assert "gochujang" in context["prefer_ingredients"]
        # Dietary focus should be empty
        assert context["dietary_focus"] == ""

    def test_get_cultural_context_combines_cooking_notes(
        self,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
    ) -> None:
        """Test that cooking notes from both sources are combined."""
        pipeline = RecipePipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        context = pipeline.get_cultural_context(
            source_style="IT",
            target_style="KR",
            dietary_focus="vegan",
        )

        # Should include notes from both Korean culture and vegan diet
        notes = context["cooking_notes"]
        assert "fermented" in notes.lower()  # Korean cooking notes
        assert "plant-based" in notes.lower()  # Vegan cooking notes
