"""Tests for text and image generators."""

import json
from typing import Dict
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.generators.text.generator import TextGenerator
from src.personas import BotPersona


def create_mock_gemini_response(content: str) -> MagicMock:
    """Create a mock Gemini response with the given content."""
    mock_response = MagicMock()
    mock_response.text = content
    return mock_response


class TestTextGenerator:
    """Tests for the TextGenerator class."""

    @pytest.fixture
    def text_generator(self) -> TextGenerator:
        """Create a text generator with mocked Gemini client."""
        with patch("src.generators.text.generator.genai") as mock_genai:
            generator = TextGenerator()
            return generator

    @pytest.mark.asyncio
    async def test_generate_recipe_returns_expected_structure(
        self,
        korean_persona: BotPersona,
        recipe_generation_response: Dict,
    ) -> None:
        """Test that generate_recipe returns properly structured data."""
        with patch("src.generators.text.generator.genai") as mock_genai:
            # Setup mock
            mock_client = MagicMock()
            mock_genai.Client.return_value = mock_client

            mock_response = create_mock_gemini_response(
                json.dumps(recipe_generation_response)
            )
            mock_client.aio.models.generate_content = AsyncMock(
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
    async def test_generate_recipe_calls_gemini_with_persona(
        self,
        korean_persona: BotPersona,
        recipe_generation_response: Dict,
    ) -> None:
        """Test that generate_recipe uses persona's system prompt."""
        with patch("src.generators.text.generator.genai") as mock_genai:
            mock_client = MagicMock()
            mock_genai.Client.return_value = mock_client

            mock_response = create_mock_gemini_response(
                json.dumps(recipe_generation_response)
            )
            mock_client.aio.models.generate_content = AsyncMock(
                return_value=mock_response
            )

            generator = TextGenerator()
            await generator.generate_recipe(
                persona=korean_persona,
                food_name="Test Dish",
            )

            # Verify Gemini was called
            mock_client.aio.models.generate_content.assert_called_once()

            # Check that the prompt contains persona's specialties
            call_args = mock_client.aio.models.generate_content.call_args
            contents = call_args[1]["contents"]
            prompt = contents[0] if isinstance(contents, list) else contents
            for specialty in korean_persona.specialties:
                assert specialty in prompt

    @pytest.mark.asyncio
    async def test_generate_log_returns_expected_structure(
        self,
        english_persona: BotPersona,
        log_generation_response: Dict,
    ) -> None:
        """Test that generate_log returns properly structured data."""
        with patch("src.generators.text.generator.genai") as mock_genai:
            mock_client = MagicMock()
            mock_genai.Client.return_value = mock_client

            mock_response = create_mock_gemini_response(
                json.dumps(log_generation_response)
            )
            mock_client.aio.models.generate_content = AsyncMock(
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
        with patch("src.generators.text.generator.genai") as mock_genai:
            mock_client = MagicMock()
            mock_genai.Client.return_value = mock_client

            food_names = ["Kimchi Jjigae", "Bibimbap", "Japchae"]
            mock_response = create_mock_gemini_response(
                json.dumps({"dishes": food_names})
            )
            mock_client.aio.models.generate_content = AsyncMock(
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
        with patch("src.generators.text.generator.genai") as mock_genai:
            mock_client = MagicMock()
            mock_genai.Client.return_value = mock_client

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

            mock_response = create_mock_gemini_response(
                json.dumps(variant_response)
            )
            mock_client.aio.models.generate_content = AsyncMock(
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
    """Tests for ImageGenerator camera angle selection."""

    def test_camera_angles_structure(self) -> None:
        """Test that CAMERA_ANGLES has expected structure."""
        from src.generators.image.generator import CAMERA_ANGLES, MAIN_ANGLE

        assert len(CAMERA_ANGLES) >= 2, "Should have at least 2 angles"
        assert MAIN_ANGLE in CAMERA_ANGLES, "Main angle should be in CAMERA_ANGLES"

        for name, config in CAMERA_ANGLES.items():
            assert "angle_desc" in config, f"Angle {name} missing 'angle_desc'"
            assert "composition" in config, f"Angle {name} missing 'composition'"

    def test_main_angle_is_overhead(self) -> None:
        """Test that the main angle is overhead."""
        from src.generators.image.generator import CAMERA_ANGLES, MAIN_ANGLE

        assert MAIN_ANGLE == "overhead"
        assert "above" in CAMERA_ANGLES[MAIN_ANGLE]["angle_desc"].lower()

    def test_alternative_angles_excludes_main(self) -> None:
        """Test that ALTERNATIVE_ANGLES doesn't include main angle."""
        from src.generators.image.generator import ALTERNATIVE_ANGLES, MAIN_ANGLE

        assert MAIN_ANGLE not in ALTERNATIVE_ANGLES
        assert len(ALTERNATIVE_ANGLES) >= 1

    def test_select_random_angle_distribution(self) -> None:
        """Test that select_random_angle follows 50/50 distribution."""
        from src.generators.image.generator import MAIN_ANGLE, select_random_angle

        # Run many selections to verify distribution
        selections = [select_random_angle(0.5) for _ in range(1000)]

        main_count = sum(1 for s in selections if s == MAIN_ANGLE)
        alt_count = len(selections) - main_count

        # Should be roughly 50/50 (allow 10% variance)
        assert 400 <= main_count <= 600, f"Main angle count {main_count} not in expected range"
        assert 400 <= alt_count <= 600, f"Alternative count {alt_count} not in expected range"

    def test_select_random_angle_respects_probability(self) -> None:
        """Test that select_random_angle respects custom probability."""
        from src.generators.image.generator import MAIN_ANGLE, select_random_angle

        # 100% main angle
        selections_all_main = [select_random_angle(1.0) for _ in range(100)]
        assert all(s == MAIN_ANGLE for s in selections_all_main)

        # 0% main angle
        selections_no_main = [select_random_angle(0.0) for _ in range(100)]
        assert all(s != MAIN_ANGLE for s in selections_no_main)

    def test_build_dish_prompt_uses_angle(
        self,
        korean_persona: BotPersona,
    ) -> None:
        """Test that _build_dish_prompt uses the specified angle."""
        from src.generators.image.generator import ImageGenerator

        with patch("src.generators.image.generator.genai"):
            generator = ImageGenerator()

            # Overhead angle
            prompt_overhead = generator._build_dish_prompt(
                dish_name="Test Dish",
                persona=korean_persona,
                style="cover",
                angle="overhead",
            )
            assert "above" in prompt_overhead.lower()
            assert "Bird's eye" in prompt_overhead

            # Hero angle
            prompt_hero = generator._build_dish_prompt(
                dish_name="Test Dish",
                persona=korean_persona,
                style="cover",
                angle="hero_angle",
            )
            assert "30-degree" in prompt_hero
            assert "Hero angle" in prompt_hero

    def test_build_dish_prompt_defaults_to_main_angle(
        self,
        korean_persona: BotPersona,
    ) -> None:
        """Test that invalid or missing angle defaults to main angle."""
        from src.generators.image.generator import ImageGenerator

        with patch("src.generators.image.generator.genai"):
            generator = ImageGenerator()

            # No angle specified
            prompt_default = generator._build_dish_prompt(
                dish_name="Test Dish",
                persona=korean_persona,
                style="cover",
            )
            assert "Bird's eye" in prompt_default

            # Invalid angle
            prompt_invalid = generator._build_dish_prompt(
                dish_name="Test Dish",
                persona=korean_persona,
                style="cover",
                angle="invalid_angle",
            )
            assert "Bird's eye" in prompt_invalid

    @pytest.mark.asyncio
    async def test_generate_recipe_images_selects_random_angle(
        self,
        korean_persona: BotPersona,
    ) -> None:
        """Test that generate_recipe_images selects a random angle for the recipe."""
        from src.generators.image.generator import CAMERA_ANGLES, ImageGenerator

        with patch("src.generators.image.generator.genai") as mock_genai:
            mock_client = MagicMock()
            mock_genai.Client.return_value = mock_client

            mock_response = MagicMock()
            mock_part = MagicMock()
            mock_part.inline_data = MagicMock()
            mock_part.inline_data.data = b"fake_image_bytes"
            mock_response.parts = [mock_part]

            mock_client.aio.models.generate_content = AsyncMock(return_value=mock_response)

            generator = ImageGenerator()

            # Generate 2 cover images
            result = await generator.generate_recipe_images(
                dish_name="Test Dish",
                persona=korean_persona,
                cover_count=2,
                step_count=0,
            )

            assert len(result["cover_images"]) == 2

            # Both cover images should use the same angle
            calls = mock_client.aio.models.generate_content.call_args_list
            prompts = [call[1]["contents"][0] for call in calls]

            # Find which angle was used by checking the angle description in prompts
            def get_angle_from_prompt(prompt: str) -> str:
                for angle_name, config in CAMERA_ANGLES.items():
                    if config["angle_desc"] in prompt:
                        return angle_name
                return "unknown"

            angle_1 = get_angle_from_prompt(prompts[0])
            angle_2 = get_angle_from_prompt(prompts[1])

            assert angle_1 == angle_2, "All cover images should use the same angle"
            assert angle_1 in CAMERA_ANGLES, f"Angle should be valid: {angle_1}"
