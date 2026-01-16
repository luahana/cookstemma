"""Tests for recipe and log pipelines."""

import pytest
from typing import Dict
from unittest.mock import AsyncMock, MagicMock, patch

from bot_engine.src.api.models import (
    IngredientType,
    LogOutcome,
    LogPost,
    Recipe,
    RecipeIngredient,
    RecipeStep,
    ImageUploadResponse,
)
from bot_engine.src.orchestrator.recipe_pipeline import RecipePipeline
from bot_engine.src.orchestrator.log_pipeline import LogPipeline
from bot_engine.src.personas import BotPersona


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
                    {"name": "Chili", "amount": "1 tbsp", "type": "SEASONING"}
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
            {"name": "Chicken", "amount": "500g", "type": "MAIN"},
            {"name": "Salt", "amount": "1 tsp", "type": "SEASONING"},
            {"name": "invalid_type", "amount": "1", "type": "INVALID"},
        ]

        result = pipeline._parse_ingredients(ingredients_data)

        assert len(result) == 3
        assert result[0].type == IngredientType.MAIN
        assert result[1].type == IngredientType.SEASONING
        # Invalid type should default to MAIN
        assert result[2].type == IngredientType.MAIN

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
            outcome=LogOutcome.SUCCESS,
            generate_image=True,
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
            generate_image=False,
        )

        # Image generator should not be called
        mock_image_generator.generate_log_image.assert_not_called()

    @pytest.mark.asyncio
    async def test_select_outcome_distribution(
        self,
        mock_api_client: AsyncMock,
        mock_text_generator: AsyncMock,
        mock_image_generator: AsyncMock,
    ) -> None:
        """Test that outcome selection follows configured ratios."""
        pipeline = LogPipeline(
            api_client=mock_api_client,
            text_generator=mock_text_generator,
            image_generator=mock_image_generator,
        )

        # Generate many outcomes to verify distribution
        outcomes = [pipeline._select_outcome() for _ in range(1000)]

        success_count = sum(1 for o in outcomes if o == LogOutcome.SUCCESS)
        partial_count = sum(1 for o in outcomes if o == LogOutcome.PARTIAL)
        failed_count = sum(1 for o in outcomes if o == LogOutcome.FAILED)

        # Should roughly follow 70/20/10 distribution (with some tolerance)
        assert 600 < success_count < 800  # ~70%
        assert 100 < partial_count < 300  # ~20%
        assert 50 < failed_count < 200    # ~10%

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
            generate_images=False,
        )

        # Should generate requested number of logs
        assert len(logs) == 5

        # Text generator should be called 5 times
        assert mock_text_generator.generate_log.call_count == 5
