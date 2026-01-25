"""Persona registry - Fetches bot personas from backend API."""

from typing import TYPE_CHECKING, Dict, List, Optional

import structlog

from ..api.models import BotPersonaResponse
from .models import (
    BotPersona,
    DietaryFocus,
    SkillLevel,
    Tone,
    VocabularyStyle,
)

if TYPE_CHECKING:
    from ..api.client import CookstemmaClient

logger = structlog.get_logger()


class PersonaRegistry:
    """Registry of bot personas fetched from backend API."""

    def __init__(self) -> None:
        self._personas: Dict[str, BotPersona] = {}
        self._initialized = False

    @property
    def is_initialized(self) -> bool:
        """Check if registry has been initialized with API data."""
        return self._initialized

    async def initialize(self, api_client: "CookstemmaClient") -> None:
        """Initialize registry by fetching personas from backend API.

        Args:
            api_client: CookstemmaClient instance to fetch personas.

        Raises:
            RuntimeError: If initialization fails.
        """
        if self._initialized:
            logger.debug("persona_registry_already_initialized")
            return

        try:
            responses = await api_client.get_all_active_personas()
            for response in responses:
                persona = self._convert_response(response)
                self._personas[persona.name] = persona

            self._initialized = True
            logger.info(
                "persona_registry_initialized",
                persona_count=len(self._personas),
                personas=list(self._personas.keys()),
            )
        except Exception as e:
            logger.error("persona_registry_init_failed", error=str(e))
            raise RuntimeError(f"Failed to initialize persona registry: {e}") from e

    def _convert_response(self, response: BotPersonaResponse) -> BotPersona:
        """Convert API response to BotPersona model.

        Args:
            response: BotPersonaResponse from backend API.

        Returns:
            BotPersona instance.
        """
        return BotPersona(
            name=response.name,
            display_name=response.display_name,
            tone=Tone(response.tone.lower()),
            skill_level=SkillLevel(response.skill_level.lower()),
            dietary_focus=DietaryFocus(response.dietary_focus.lower()),
            vocabulary_style=VocabularyStyle(response.vocabulary_style.lower()),
            locale=response.locale,
            cooking_style=response.cooking_style,
            kitchen_style_prompt=response.kitchen_style_prompt,
            specialties=[],
            catchphrases=[],
            background_story="",
        )

    def _ensure_initialized(self) -> None:
        """Ensure registry is initialized before access."""
        if not self._initialized:
            raise RuntimeError(
                "PersonaRegistry not initialized. Call initialize() first."
            )

    def get(self, name: str) -> Optional[BotPersona]:
        """Get a persona by name.

        Args:
            name: Persona name (e.g., 'chef_park_soojin').

        Returns:
            BotPersona if found, None otherwise.
        """
        self._ensure_initialized()
        return self._personas.get(name)

    def get_all(self) -> List[BotPersona]:
        """Get all personas.

        Returns:
            List of all BotPersona instances.
        """
        self._ensure_initialized()
        return list(self._personas.values())

    def get_by_locale(self, locale: str) -> List[BotPersona]:
        """Get personas by locale (e.g., 'ko-KR' or 'en-US').

        Args:
            locale: Locale string.

        Returns:
            List of personas matching the locale.
        """
        self._ensure_initialized()
        return [p for p in self._personas.values() if p.locale == locale]

    def get_korean_personas(self) -> List[BotPersona]:
        """Get all Korean-speaking personas.

        Returns:
            List of Korean personas.
        """
        self._ensure_initialized()
        return [p for p in self._personas.values() if p.is_korean()]

    def get_english_personas(self) -> List[BotPersona]:
        """Get all English-speaking personas.

        Returns:
            List of English personas.
        """
        self._ensure_initialized()
        return [p for p in self._personas.values() if p.is_english()]

    def get_by_skill_level(self, skill_level: SkillLevel) -> List[BotPersona]:
        """Get personas by skill level.

        Args:
            skill_level: SkillLevel enum value.

        Returns:
            List of personas matching the skill level.
        """
        self._ensure_initialized()
        return [p for p in self._personas.values() if p.skill_level == skill_level]

    def get_by_dietary_focus(self, focus: DietaryFocus) -> List[BotPersona]:
        """Get personas by dietary focus.

        Args:
            focus: DietaryFocus enum value.

        Returns:
            List of personas matching the dietary focus.
        """
        self._ensure_initialized()
        return [p for p in self._personas.values() if p.dietary_focus == focus]


# Global registry instance
_registry: Optional[PersonaRegistry] = None


def get_persona_registry() -> PersonaRegistry:
    """Get the global persona registry instance.

    Note: Must call initialize() before using getter methods.

    Returns:
        PersonaRegistry instance.
    """
    global _registry
    if _registry is None:
        _registry = PersonaRegistry()
    return _registry
