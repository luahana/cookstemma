"""Tests for bot persona functionality."""

import pytest

from bot_engine.src.personas import BotPersona, get_persona_registry


class TestBotPersona:
    """Tests for the BotPersona model."""

    def test_display_name_localized(self, korean_persona: BotPersona) -> None:
        """Test display name localization."""
        assert korean_persona.get_display_name("ko") == "테스트 셰프"
        assert korean_persona.get_display_name("en") == "Test Chef"
        # Fallback to English for unknown locales
        assert korean_persona.get_display_name("fr") == "Test Chef"

    def test_system_prompt_korean_locale(self, korean_persona: BotPersona) -> None:
        """Test that Korean persona generates Korean-only prompt."""
        prompt = korean_persona.build_system_prompt()

        assert "Korean" in prompt or "한국어" in prompt
        assert korean_persona.tone.lower() in prompt.lower()
        assert korean_persona.skill_level.lower() in prompt.lower()

    def test_system_prompt_english_locale(self, english_persona: BotPersona) -> None:
        """Test that English persona generates English prompt."""
        prompt = english_persona.build_system_prompt()

        assert "English" in prompt
        assert english_persona.tone.lower() in prompt.lower()

    def test_system_prompt_includes_kitchen_style(
        self, korean_persona: BotPersona
    ) -> None:
        """Test that system prompt includes kitchen style."""
        prompt = korean_persona.build_system_prompt()
        assert korean_persona.kitchen_style_prompt in prompt

    def test_system_prompt_enforces_language(
        self, korean_persona: BotPersona
    ) -> None:
        """Test that system prompt enforces language consistency."""
        prompt = korean_persona.build_system_prompt()
        # Should have instruction about writing in one language only
        assert "MUST" in prompt or "only" in prompt.lower()


class TestPersonaRegistry:
    """Tests for the persona registry."""

    def test_registry_has_ten_personas(self) -> None:
        """Test that registry contains all 10 personas."""
        registry = get_persona_registry()
        all_personas = registry.get_all()
        assert len(all_personas) == 10

    def test_registry_has_korean_personas(self) -> None:
        """Test that registry has 5 Korean personas."""
        registry = get_persona_registry()
        korean = registry.get_by_locale("ko")
        assert len(korean) == 5

    def test_registry_has_english_personas(self) -> None:
        """Test that registry has 5 English personas."""
        registry = get_persona_registry()
        english = registry.get_by_locale("en")
        assert len(english) == 5

    def test_registry_get_by_name(self) -> None:
        """Test getting persona by name."""
        registry = get_persona_registry()

        chef = registry.get("chef_park_soojin")
        assert chef is not None
        assert chef.locale == "ko"

        marcus = registry.get("chef_marcus_stone")
        assert marcus is not None
        assert marcus.locale == "en"

    def test_registry_get_nonexistent_returns_none(self) -> None:
        """Test that getting nonexistent persona returns None."""
        registry = get_persona_registry()
        persona = registry.get("nonexistent_persona")
        assert persona is None

    def test_korean_personas_have_korean_locale(self) -> None:
        """Test that all Korean personas have correct locale."""
        registry = get_persona_registry()
        korean_names = [
            "chef_park_soojin",
            "yoriking_minsu",
            "healthymom_hana",
            "bakingmom_jieun",
            "worldfoodie_junhyuk",
        ]

        for name in korean_names:
            persona = registry.get(name)
            assert persona is not None
            assert persona.locale == "ko"
            assert persona.culinary_locale == "ko"

    def test_english_personas_have_english_locale(self) -> None:
        """Test that all English personas have correct locale."""
        registry = get_persona_registry()
        english_names = [
            "chef_marcus_stone",
            "broke_college_cook",
            "fitfamilyfoods",
            "sweettoothemma",
            "globaleatsalex",
        ]

        for name in english_names:
            persona = registry.get(name)
            assert persona is not None
            assert persona.locale == "en"

    def test_each_persona_has_unique_specialties(self) -> None:
        """Test that personas have diverse specialties."""
        registry = get_persona_registry()
        all_personas = registry.get_all()

        # Each persona should have at least one specialty
        for persona in all_personas:
            assert len(persona.specialties) >= 1

    def test_persona_skill_levels_are_valid(self) -> None:
        """Test that all personas have valid skill levels."""
        registry = get_persona_registry()
        valid_levels = {"BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"}

        for persona in registry.get_all():
            assert persona.skill_level in valid_levels

    def test_persona_tones_are_valid(self) -> None:
        """Test that all personas have valid tones."""
        registry = get_persona_registry()
        valid_tones = {"CASUAL", "PROFESSIONAL", "ENTHUSIASTIC", "WARM", "PLAYFUL"}

        for persona in registry.get_all():
            assert persona.tone in valid_tones
