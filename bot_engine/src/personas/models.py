"""Persona data models."""

from enum import Enum
from typing import Dict, List, Optional

from pydantic import BaseModel, Field


class Tone(str, Enum):
    """Communication tone of a bot persona."""

    PROFESSIONAL = "professional"
    CASUAL = "casual"
    WARM = "warm"
    ENTHUSIASTIC = "enthusiastic"
    EDUCATIONAL = "educational"
    MOTIVATIONAL = "motivational"


class SkillLevel(str, Enum):
    """Cooking skill level of a bot persona."""

    PROFESSIONAL = "professional"
    INTERMEDIATE = "intermediate"
    BEGINNER = "beginner"
    HOME_COOK = "home_cook"


class DietaryFocus(str, Enum):
    """Dietary specialty of a bot persona."""

    # Existing types
    FINE_DINING = "fine_dining"
    BUDGET = "budget"
    HEALTHY = "healthy"
    BAKING = "baking"
    INTERNATIONAL = "international"
    FARM_TO_TABLE = "farm_to_table"
    VEGETARIAN = "vegetarian"
    QUICK_MEALS = "quick_meals"
    # New dietary types
    VEGAN = "vegan"
    KETO = "keto"
    GLUTEN_FREE = "gluten_free"
    HALAL = "halal"
    KOSHER = "kosher"
    PESCATARIAN = "pescatarian"
    DAIRY_FREE = "dairy_free"
    LOW_SODIUM = "low_sodium"


class VocabularyStyle(str, Enum):
    """Vocabulary style of a bot persona."""

    TECHNICAL = "technical"
    SIMPLE = "simple"
    STANDARD = "standard"


# Locale to language name mapping for all supported locales
LOCALE_TO_LANGUAGE = {
    "en": "English",
    "ko": "Korean",
    "ja": "Japanese",
    "zh": "Chinese",
    "fr": "French",
    "de": "German",
    "es": "Spanish",
    "it": "Italian",
    "pt": "Portuguese",
    "ru": "Russian",
    "fa": "Persian",
    "th": "Thai",
    "vi": "Vietnamese",
    "hi": "Hindi",
    "ar": "Arabic",
    "tr": "Turkish",
    "nl": "Dutch",
    "pl": "Polish",
    "id": "Indonesian",
    "sv": "Swedish",
}


class BotPersona(BaseModel):
    """Bot persona definition with all personality traits."""

    name: str = Field(description="Unique identifier name (e.g., 'chef_park_soojin')")
    display_name: Dict[str, str] = Field(
        description="Localized display names {'en': 'Chef Park', 'ko': '박수진 셰프'}"
    )
    tone: Tone = Field(description="Communication tone")
    skill_level: SkillLevel = Field(description="Cooking skill level")
    dietary_focus: DietaryFocus = Field(description="Dietary specialty")
    vocabulary_style: VocabularyStyle = Field(description="Language style")
    locale: str = Field(description="Primary locale (e.g., 'ko-KR', 'en-US')")
    cooking_style: str = Field(description="Culinary style country code (e.g., 'KR', 'US')")
    kitchen_style_prompt: str = Field(description="Prompt for image generation")
    specialties: List[str] = Field(
        default_factory=list,
        description="List of cooking specialties",
    )
    catchphrases: List[str] = Field(
        default_factory=list,
        description="Characteristic phrases the persona uses",
    )
    background_story: str = Field(
        default="",
        description="Brief background story for the persona",
    )

    # Runtime fields (populated after authentication)
    api_key: Optional[str] = Field(default=None, exclude=True)
    user_public_id: Optional[str] = Field(default=None)
    persona_public_id: Optional[str] = Field(default=None)
    access_token: Optional[str] = Field(default=None, exclude=True)
    refresh_token: Optional[str] = Field(default=None, exclude=True)

    def get_display_name(self, locale: str = "en") -> str:
        """Get display name for locale, falling back to English."""
        if locale in self.display_name:
            return self.display_name[locale]
        lang_code = locale.split("-")[0]
        if lang_code in self.display_name:
            return self.display_name[lang_code]
        return self.display_name.get("en", self.name)

    def get_language_code(self) -> str:
        """Get the language code (e.g., 'ko' from 'ko-KR')."""
        return self.locale.split("-")[0]

    def is_korean(self) -> bool:
        """Check if persona uses Korean language."""
        return self.locale.startswith("ko")

    def is_english(self) -> bool:
        """Check if persona uses English language."""
        return self.locale.startswith("en")

    def get_language_name(self) -> str:
        """Get the full language name for this persona's locale."""
        lang_code = self.get_language_code()
        return LOCALE_TO_LANGUAGE.get(lang_code, "English")

    def build_system_prompt(self) -> str:
        """Build the system prompt for ChatGPT based on persona traits."""
        lang = self.get_language_name()

        skill_desc = {
            SkillLevel.PROFESSIONAL: "a professional chef with restaurant experience",
            SkillLevel.INTERMEDIATE: "an experienced home cook",
            SkillLevel.BEGINNER: "someone just learning to cook",
            SkillLevel.HOME_COOK: "a comfortable home cook",
        }

        tone_desc = {
            Tone.PROFESSIONAL: "Use professional, precise language.",
            Tone.CASUAL: "Use casual, relaxed language like talking to a friend.",
            Tone.WARM: "Use warm, nurturing language like a caring parent.",
            Tone.ENTHUSIASTIC: "Use excited, energetic language with enthusiasm!",
            Tone.EDUCATIONAL: "Use informative, teaching-focused language.",
            Tone.MOTIVATIONAL: "Use encouraging, supportive language.",
        }

        vocab_desc = {
            VocabularyStyle.TECHNICAL: "Use proper culinary terminology.",
            VocabularyStyle.SIMPLE: "Use simple, easy-to-understand words.",
            VocabularyStyle.STANDARD: "Use natural, everyday language.",
        }

        prompt = f"""You are {self.get_display_name(self.locale)}, {skill_desc[self.skill_level]}.

You specialize in {self.dietary_focus.value.replace('_', ' ')} cooking.
{tone_desc[self.tone]}
{vocab_desc[self.vocabulary_style]}

IMPORTANT: You MUST write EVERYTHING in {lang} only. Never mix languages.
"""

        if self.background_story:
            prompt += f"\nYour background: {self.background_story}\n"

        if self.catchphrases:
            prompt += f"\nYou often say things like: {', '.join(self.catchphrases)}\n"

        if self.specialties:
            prompt += f"\nYour cooking specialties: {', '.join(self.specialties)}\n"

        return prompt
