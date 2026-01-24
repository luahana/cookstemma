"""Tests for text and image generators."""

import json
from typing import Dict
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.generators.text.generator import TextGenerator
from src.personas import BotPersona


class TestTextGenerator:
    """Tests for the TextGenerator class."""

    @pytest.fixture
    def text_generator(self) -> TextGenerator:
        """Create a text generator with mocked OpenAI client."""
        with patch("src.generators.text.generator.AsyncOpenAI") as mock_openai:
            generator = TextGenerator()
            return generator

    @pytest.mark.asyncio
    async def test_generate_recipe_returns_expected_structure(
        self,
        korean_persona: BotPersona,
        recipe_generation_response: Dict,
    ) -> None:
        """Test that generate_recipe returns properly structured data."""
        with patch("src.generators.text.generator.AsyncOpenAI") as mock_openai:
            # Setup mock
            mock_client = MagicMock()
            mock_openai.return_value = mock_client

            mock_response = MagicMock()
            mock_response.choices = [
                MagicMock(
                    message=MagicMock(
                        content=json.dumps(recipe_generation_response)
                    )
                )
            ]
            mock_response.usage = MagicMock(total_tokens=100)
            mock_client.chat.completions.create = AsyncMock(
                return_value=mock_response
            )

            generator = TextGenerator()
            result = await generator.generate_recipe(
                persona=korean_persona,
                food_name="Korean Fried Chicken",
            )

            assert "title" in result
            assert "description" in result
            assert "ingredients" in result
            assert "steps" in result
            assert isinstance(result["ingredients"], list)
            assert isinstance(result["steps"], list)

    @pytest.mark.asyncio
    async def test_generate_recipe_calls_openai_with_persona(
        self,
        korean_persona: BotPersona,
        recipe_generation_response: Dict,
    ) -> None:
        """Test that generate_recipe uses persona's system prompt."""
        with patch("src.generators.text.generator.AsyncOpenAI") as mock_openai:
            mock_client = MagicMock()
            mock_openai.return_value = mock_client

            mock_response = MagicMock()
            mock_response.choices = [
                MagicMock(
                    message=MagicMock(
                        content=json.dumps(recipe_generation_response)
                    )
                )
            ]
            mock_response.usage = MagicMock(total_tokens=100)
            mock_client.chat.completions.create = AsyncMock(
                return_value=mock_response
            )

            generator = TextGenerator()
            await generator.generate_recipe(
                persona=korean_persona,
                food_name="Test Dish",
            )

            # Verify OpenAI was called
            mock_client.chat.completions.create.assert_called_once()

            # Check that system message contains persona prompt
            call_kwargs = mock_client.chat.completions.create.call_args[1]
            messages = call_kwargs["messages"]
            system_message = messages[0]
            assert system_message["role"] == "system"
            # System prompt includes persona's specialties
            for specialty in korean_persona.specialties:
                assert specialty in system_message["content"]

    @pytest.mark.asyncio
    async def test_generate_log_returns_expected_structure(
        self,
        english_persona: BotPersona,
        log_generation_response: Dict,
    ) -> None:
        """Test that generate_log returns properly structured data."""
        with patch("src.generators.text.generator.AsyncOpenAI") as mock_openai:
            mock_client = MagicMock()
            mock_openai.return_value = mock_client

            mock_response = MagicMock()
            mock_response.choices = [
                MagicMock(
                    message=MagicMock(
                        content=json.dumps(log_generation_response)
                    )
                )
            ]
            mock_response.usage = MagicMock(total_tokens=100)
            mock_client.chat.completions.create = AsyncMock(
                return_value=mock_response
            )

            generator = TextGenerator()
            result = await generator.generate_log(
                persona=english_persona,
                recipe_title="Test Recipe",
                recipe_description="A test description",
                rating=5,
            )

            assert "content" in result
            assert isinstance(result["content"], str)

    @pytest.mark.asyncio
    async def test_suggest_food_names_returns_list(
        self,
        korean_persona: BotPersona,
    ) -> None:
        """Test that suggest_food_names returns a list of names."""
        with patch("src.generators.text.generator.AsyncOpenAI") as mock_openai:
            mock_client = MagicMock()
            mock_openai.return_value = mock_client

            food_names = ["Kimchi Jjigae", "Bibimbap", "Japchae"]
            mock_response = MagicMock()
            mock_response.choices = [
                MagicMock(
                    message=MagicMock(
                        content=json.dumps({"dishes": food_names})
                    )
                )
            ]
            mock_response.usage = MagicMock(total_tokens=100)
            mock_client.chat.completions.create = AsyncMock(
                return_value=mock_response
            )

            generator = TextGenerator()
            result = await generator.suggest_food_names(
                persona=korean_persona,
                count=3,
            )

            assert isinstance(result, list)
            assert len(result) == 3

    @pytest.mark.asyncio
    async def test_generate_variant_includes_parent_info(
        self,
        english_persona: BotPersona,
    ) -> None:
        """Test that variant generation includes parent recipe info."""
        with patch("src.generators.text.generator.AsyncOpenAI") as mock_openai:
            mock_client = MagicMock()
            mock_openai.return_value = mock_client

            variant_response = {
                "title": "Spicy Variant",
                "description": "A spicier version",
                "ingredients": [],
                "steps": [],
                "hashtags": [],
                "changeDiff": "Added chili",
                "changeReason": "More heat",
                "changeCategories": ["SPICE_LEVEL"],
            }

            mock_response = MagicMock()
            mock_response.choices = [
                MagicMock(
                    message=MagicMock(
                        content=json.dumps(variant_response)
                    )
                )
            ]
            mock_response.usage = MagicMock(total_tokens=100)
            mock_client.chat.completions.create = AsyncMock(
                return_value=mock_response
            )

            generator = TextGenerator()
            parent_recipe = {
                "title": "Original Recipe",
                "description": "The original",
                "ingredients": [{"name": "Test", "amount": "1"}],
                "steps": [{"order": 1, "description": "Do something"}],
            }

            result = await generator.generate_variant(
                persona=english_persona,
                parent_recipe=parent_recipe,
                variation_type="spicier",
            )

            assert "changeDiff" in result
            assert "changeReason" in result


class TestTextGeneratorLanguageEnforcement:
    """Tests for language enforcement in text generation."""

    @pytest.mark.asyncio
    async def test_korean_persona_enforces_korean(
        self,
        korean_persona: BotPersona,
    ) -> None:
        """Test that Korean persona's prompt enforces Korean language."""
        prompt = korean_persona.build_system_prompt()

        # Should mention writing in Korean
        assert "한국어" in prompt or "Korean" in prompt
        # Should have strong language enforcement
        assert "MUST" in prompt or "only" in prompt.lower()

    @pytest.mark.asyncio
    async def test_english_persona_enforces_english(
        self,
        english_persona: BotPersona,
    ) -> None:
        """Test that English persona's prompt enforces English language."""
        prompt = english_persona.build_system_prompt()

        # Should mention writing in English
        assert "English" in prompt
        # Should have language enforcement
        assert "MUST" in prompt or "only" in prompt.lower()


class TestImageGeneratorCameraAngles:
    """Tests for ImageGenerator camera angle variations."""

    def test_cover_camera_angles_structure(self) -> None:
        """Test that COVER_CAMERA_ANGLES has expected structure."""
        from src.generators.image.generator import COVER_CAMERA_ANGLES

        assert len(COVER_CAMERA_ANGLES) >= 2, "Should have at least 2 angles"

        for i, angle in enumerate(COVER_CAMERA_ANGLES):
            assert "name" in angle, f"Angle {i} missing 'name'"
            assert "angle_desc" in angle, f"Angle {i} missing 'angle_desc'"
            assert "composition" in angle, f"Angle {i} missing 'composition'"

    def test_first_angle_is_overhead(self) -> None:
        """Test that the first (main) angle is overhead."""
        from src.generators.image.generator import COVER_CAMERA_ANGLES

        main_angle = COVER_CAMERA_ANGLES[0]
        assert main_angle["name"] == "overhead"
        assert "above" in main_angle["angle_desc"].lower()
        assert "bird's eye" in main_angle["composition"].lower()

    def test_angles_have_unique_names(self) -> None:
        """Test that all angle names are unique."""
        from src.generators.image.generator import COVER_CAMERA_ANGLES

        names = [angle["name"] for angle in COVER_CAMERA_ANGLES]
        assert len(names) == len(set(names)), "Angle names should be unique"

    def test_build_dish_prompt_uses_angle_index(
        self,
        korean_persona: BotPersona,
    ) -> None:
        """Test that _build_dish_prompt uses different angles based on index."""
        from src.generators.image.generator import COVER_CAMERA_ANGLES, ImageGenerator

        with patch("src.generators.image.generator.genai"):
            generator = ImageGenerator()

            # First angle (overhead)
            prompt_0 = generator._build_dish_prompt(
                dish_name="Test Dish",
                persona=korean_persona,
                style="cover",
                angle_index=0,
            )
            assert "above" in prompt_0.lower()
            assert "Bird's eye" in prompt_0

            # Second angle (high_angle)
            prompt_1 = generator._build_dish_prompt(
                dish_name="Test Dish",
                persona=korean_persona,
                style="cover",
                angle_index=1,
            )
            assert "75-degree" in prompt_1 or "high angle" in prompt_1.lower()

    def test_build_dish_prompt_wraps_angle_index(
        self,
        korean_persona: BotPersona,
    ) -> None:
        """Test that angle index wraps around if out of range."""
        from src.generators.image.generator import COVER_CAMERA_ANGLES, ImageGenerator

        with patch("src.generators.image.generator.genai"):
            generator = ImageGenerator()

            # Index equal to length should wrap to 0
            prompt_wrapped = generator._build_dish_prompt(
                dish_name="Test Dish",
                persona=korean_persona,
                style="cover",
                angle_index=len(COVER_CAMERA_ANGLES),
            )
            prompt_first = generator._build_dish_prompt(
                dish_name="Test Dish",
                persona=korean_persona,
                style="cover",
                angle_index=0,
            )
            assert prompt_wrapped == prompt_first

    def test_step_and_log_styles_ignore_angle_index(
        self,
        korean_persona: BotPersona,
    ) -> None:
        """Test that step and log styles always use overhead angle."""
        from src.generators.image.generator import ImageGenerator

        with patch("src.generators.image.generator.genai"):
            generator = ImageGenerator()

            # Step style should be same regardless of angle_index
            step_prompt_0 = generator._build_dish_prompt(
                dish_name="Test Dish",
                persona=korean_persona,
                style="step",
                angle_index=0,
            )
            step_prompt_1 = generator._build_dish_prompt(
                dish_name="Test Dish",
                persona=korean_persona,
                style="step",
                angle_index=1,
            )
            assert step_prompt_0 == step_prompt_1
            assert "above" in step_prompt_0.lower()

            # Log style should also be overhead
            log_prompt = generator._build_dish_prompt(
                dish_name="Test Dish",
                persona=korean_persona,
                style="log",
                angle_index=2,
            )
            assert "above" in log_prompt.lower()

    @pytest.mark.asyncio
    async def test_generate_recipe_images_uses_different_angles(
        self,
        korean_persona: BotPersona,
    ) -> None:
        """Test that generate_recipe_images uses different angles for cover images."""
        from src.generators.image.generator import ImageGenerator

        with patch("src.generators.image.generator.genai") as mock_genai:
            # Setup mock client
            mock_client = MagicMock()
            mock_genai.Client.return_value = mock_client

            # Mock response with image data
            mock_response = MagicMock()
            mock_part = MagicMock()
            mock_part.inline_data = MagicMock()
            mock_part.inline_data.data = b"fake_image_bytes"
            mock_response.parts = [mock_part]

            mock_client.aio.models.generate_content = AsyncMock(return_value=mock_response)

            generator = ImageGenerator()

            # Generate 3 cover images
            result = await generator.generate_recipe_images(
                dish_name="Test Dish",
                persona=korean_persona,
                cover_count=3,
                step_count=0,
            )

            assert len(result["cover_images"]) == 3

            # Verify generate_content was called 3 times with different prompts
            calls = mock_client.aio.models.generate_content.call_args_list
            assert len(calls) == 3

            # Extract prompts from calls
            prompts = [call[1]["contents"][0] for call in calls]

            # First prompt should be overhead
            assert "above" in prompts[0].lower()

            # Prompts should be different (different angles)
            assert prompts[0] != prompts[1]
            assert prompts[1] != prompts[2]
