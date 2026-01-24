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
