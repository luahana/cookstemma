"""Tests for bot persona functionality."""

import pytest

from src.personas import BotPersona, get_persona_registry, Tone, SkillLevel


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

    def test_system_prompt_includes_specialties(
        self, korean_persona: BotPersona
    ) -> None:
        """Test that system prompt includes cooking specialties."""
        prompt = korean_persona.build_system_prompt()
        # System prompt should include specialties
        for specialty in korean_persona.specialties:
            assert specialty in prompt

    def test_system_prompt_enforces_language(
        self, korean_persona: BotPersona
    ) -> None:
        """Test that system prompt enforces language consistency."""
        prompt = korean_persona.build_system_prompt()
        # Should have instruction about writing in one language only
        assert "MUST" in prompt or "only" in prompt.lower()


class TestPersonaRegistry:
    """Tests for the persona registry.
    
    Note: These tests use a pre-initialized mock registry since the actual
    registry fetches personas from the backend API dynamically.
    """

    @pytest.fixture
    def initialized_registry(self, korean_persona: BotPersona, english_persona: BotPersona):
        """Create a registry with mock personas for testing."""
        from src.personas.registry import PersonaRegistry
        
        registry = PersonaRegistry()
        # Manually inject test personas
        registry._personas = {
            korean_persona.name: korean_persona,
            english_persona.name: english_persona,
        }
        registry._initialized = True
        return registry

    def test_registry_requires_initialization(self) -> None:
        """Test that registry raises error when not initialized."""
        from src.personas.registry import PersonaRegistry
        
        registry = PersonaRegistry()
        with pytest.raises(RuntimeError, match="not initialized"):
            registry.get_all()

    def test_registry_get_by_name(self, initialized_registry, korean_persona: BotPersona) -> None:
        """Test getting persona by name."""
        persona = initialized_registry.get(korean_persona.name)
        assert persona is not None
        assert persona.name == korean_persona.name

    def test_registry_get_nonexistent_returns_none(self, initialized_registry) -> None:
        """Test that getting nonexistent persona returns None."""
        persona = initialized_registry.get("nonexistent_persona")
        assert persona is None

    def test_registry_get_all_returns_all_personas(self, initialized_registry) -> None:
        """Test that get_all returns all registered personas."""
        all_personas = initialized_registry.get_all()
        assert len(all_personas) == 2  # korean + english test personas

    def test_registry_get_korean_personas(self, initialized_registry, korean_persona: BotPersona) -> None:
        """Test filtering Korean personas."""
        korean = initialized_registry.get_korean_personas()
        assert len(korean) == 1
        assert korean[0].is_korean()

    def test_registry_get_english_personas(self, initialized_registry, english_persona: BotPersona) -> None:
        """Test filtering English personas."""
        english = initialized_registry.get_english_personas()
        assert len(english) == 1
        assert english[0].is_english()

    def test_registry_get_by_locale(self, initialized_registry, korean_persona: BotPersona) -> None:
        """Test filtering by locale."""
        ko_personas = initialized_registry.get_by_locale("ko-KR")
        assert len(ko_personas) == 1
        assert ko_personas[0].locale == "ko-KR"

    def test_persona_skill_levels_are_valid(self, initialized_registry) -> None:
        """Test that all personas have valid skill levels."""
        valid_levels = {SkillLevel.PROFESSIONAL, SkillLevel.INTERMEDIATE, SkillLevel.BEGINNER, SkillLevel.HOME_COOK}

        for persona in initialized_registry.get_all():
            assert persona.skill_level in valid_levels

    def test_persona_tones_are_valid(self, initialized_registry) -> None:
        """Test that all personas have valid tones."""
        valid_tones = {Tone.CASUAL, Tone.PROFESSIONAL, Tone.ENTHUSIASTIC, Tone.WARM, Tone.EDUCATIONAL, Tone.MOTIVATIONAL}

        for persona in initialized_registry.get_all():
            assert persona.tone in valid_tones
