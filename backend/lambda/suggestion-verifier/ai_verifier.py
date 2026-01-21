"""
AI Verifier Module
Uses OpenAI GPT to validate food/ingredient names and translate them.
"""
import json
import logging
from typing import Any

from openai import OpenAI

logger = logging.getLogger()

# Language names for better GPT context
LANGUAGE_NAMES = {
    'ko': 'Korean', 'ko-KR': 'Korean',
    'en': 'English', 'en-US': 'English',
    'ja': 'Japanese', 'ja-JP': 'Japanese',
    'zh': 'Chinese (Simplified)', 'zh-CN': 'Chinese (Simplified)',
    'fr': 'French', 'fr-FR': 'French',
    'es': 'Spanish', 'es-ES': 'Spanish',
    'it': 'Italian', 'it-IT': 'Italian',
    'de': 'German', 'de-DE': 'German',
    'ru': 'Russian', 'ru-RU': 'Russian',
    'pt': 'Portuguese', 'pt-BR': 'Portuguese',
    'ar': 'Arabic', 'ar-SA': 'Arabic',
    'id': 'Indonesian', 'id-ID': 'Indonesian',
    'vi': 'Vietnamese', 'vi-VN': 'Vietnamese',
    'hi': 'Hindi', 'hi-IN': 'Hindi',
    'th': 'Thai', 'th-TH': 'Thai',
    'pl': 'Polish', 'pl-PL': 'Polish',
    'tr': 'Turkish', 'tr-TR': 'Turkish',
    'nl': 'Dutch', 'nl-NL': 'Dutch',
    'sv': 'Swedish', 'sv-SE': 'Swedish',
    'fa': 'Persian', 'fa-IR': 'Persian'
}

# Target locales for translation (BCP47 format)
TARGET_LOCALES = [
    'en-US', 'zh-CN', 'es-ES', 'ja-JP', 'de-DE', 'fr-FR', 'pt-BR', 'ko-KR',
    'it-IT', 'ar-SA', 'ru-RU', 'id-ID', 'vi-VN', 'hi-IN', 'th-TH', 'pl-PL',
    'tr-TR', 'nl-NL', 'sv-SE', 'fa-IR'
]

VERIFICATION_PROMPT = """You are a food/ingredient name validator for a cooking recipe app.

Analyze the following suggested name and respond with a JSON object:

Suggested Name: "{name}"
Language: {language}
Type: {item_type}

IMPORTANT: Apply rules based on the Type:

=== FOR "Food name" (dish/meal names) ===
1. VALID: Dish names, meal names, prepared foods (e.g., "bibimbap", "pizza", "pasta carbonara", "kimchi-jjigae", "spaghetti bolognese")
2. REJECT if gibberish, random text, or not recognizable as food/dish in any cuisine
3. REJECT if contains quality adjectives (e.g., "delicious pizza" -> suggest "pizza")
4. ACCEPT regional/cultural dish names in any language (e.g., "불고기", "phở", "ramen", "김치찌개")

=== FOR "Main ingredient", "Secondary ingredient", or "Seasoning or sauce" ===
1. VALID: Simple ingredient names, sauces, seasonings (e.g., "chicken", "soy sauce", "oregano")
2. REJECT if plural form (e.g., "tomatoes" -> suggest "tomato")
3. REJECT if contains preparation adjectives (e.g., "fresh basil" -> suggest "basil")
4. REJECT if not a food/ingredient/sauce/seasoning (e.g., "kitchen", random text)
5. REJECT if it's a complete dish name (e.g., "pizza", "bibimbap")
6. ACCEPT compound ingredients (e.g., "soy sauce", "olive oil", "tomato paste")

=== COMMON RULES (all types) ===
- REJECT if contains excessive numbers or special characters
- REJECT if too long (more than 50 characters) unless it's a known name
- REJECT if contains profanity or inappropriate content

Respond ONLY with this JSON (no markdown, no explanation):
{{"is_valid": true/false, "rejection_reason": "English reason if rejected, null if valid", "suggested_correction": "Corrected name if applicable, null otherwise", "canonical_name": "The clean English name for this item (for translation)"}}"""

TRANSLATION_PROMPT = """Translate the following food/ingredient name to {target_count} languages.
The name should be a simple, commonly used term for this ingredient in each language.

Source (English): {name}

Provide translations for these locales: {locales}

Respond ONLY with a JSON object mapping locale codes to translated names (no markdown, no explanation):
{{"en-US": "...", "ko-KR": "...", "ja-JP": "...", ...}}"""


class AIVerifier:
    """Verifies and translates food/ingredient names using OpenAI GPT."""

    def __init__(self, api_key: str, model: str = "gpt-4o-mini"):
        self.client = OpenAI(api_key=api_key)
        self.model = model

    def verify_name(
        self,
        name: str,
        locale: str,
        item_type: str
    ) -> dict[str, Any]:
        """
        Verify if a suggested name is a valid food/ingredient.

        Args:
            name: The suggested name to verify
            locale: Source language code (e.g., 'ko', 'en-US')
            item_type: Type of item (FOOD, MAIN, SECONDARY, SEASONING)

        Returns:
            Dict with is_valid, rejection_reason, suggested_correction, canonical_name
        """
        language = LANGUAGE_NAMES.get(locale, locale)

        # Map item types to human-readable format
        type_display = {
            'FOOD': 'Food name',
            'MAIN': 'Main ingredient',
            'SECONDARY': 'Secondary ingredient',
            'SEASONING': 'Seasoning or sauce'
        }.get(item_type, item_type)

        prompt = VERIFICATION_PROMPT.format(
            name=name,
            language=language,
            item_type=type_display
        )

        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "user", "content": prompt}
                ],
                temperature=0.1,
                max_tokens=500
            )

            result_text = response.choices[0].message.content.strip()

            # Parse JSON response, handle markdown code blocks
            if result_text.startswith('```'):
                result_text = result_text.split('```')[1]
                if result_text.startswith('json'):
                    result_text = result_text[4:]
                result_text = result_text.strip()

            result = json.loads(result_text)

            # Ensure required fields
            return {
                'is_valid': result.get('is_valid', False),
                'rejection_reason': result.get('rejection_reason'),
                'suggested_correction': result.get('suggested_correction'),
                'canonical_name': result.get('canonical_name', name)
            }

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse verification response: {e}")
            logger.error(f"Response was: {result_text[:500]}")
            # On parse error, reject to be safe
            return {
                'is_valid': False,
                'rejection_reason': 'Verification failed - unable to process',
                'suggested_correction': None,
                'canonical_name': name
            }

        except Exception as e:
            logger.error(f"Verification API error: {e}")
            raise

    def translate_to_all_locales(
        self,
        name: str,
        source_locale: str
    ) -> dict[str, str]:
        """
        Translate a food/ingredient name to all supported locales.

        Args:
            name: The canonical English name to translate
            source_locale: Source locale for reference

        Returns:
            Dict mapping locale codes to translated names
        """
        # Ensure we have the English name first
        if source_locale not in ['en', 'en-US']:
            # First get English translation
            english_name = self._translate_to_english(name, source_locale)
        else:
            english_name = name

        # Now translate from English to all locales
        locales_str = ', '.join(TARGET_LOCALES)

        prompt = TRANSLATION_PROMPT.format(
            name=english_name,
            target_count=len(TARGET_LOCALES),
            locales=locales_str
        )

        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3,
                max_tokens=2000
            )

            result_text = response.choices[0].message.content.strip()

            # Parse JSON response
            if result_text.startswith('```'):
                result_text = result_text.split('```')[1]
                if result_text.startswith('json'):
                    result_text = result_text[4:]
                result_text = result_text.strip()

            translations = json.loads(result_text)

            # Ensure all target locales are present
            for locale in TARGET_LOCALES:
                if locale not in translations:
                    translations[locale] = english_name

            logger.info(f"Translated '{english_name}' to {len(translations)} locales")
            return translations

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse translation response: {e}")
            logger.error(f"Response was: {result_text[:500]}")
            # Return English name for all locales as fallback
            return {locale: english_name for locale in TARGET_LOCALES}

        except Exception as e:
            logger.error(f"Translation API error: {e}")
            raise

    def _translate_to_english(self, name: str, source_locale: str) -> str:
        """Translate a name to English."""
        language = LANGUAGE_NAMES.get(source_locale, source_locale)

        prompt = f"""Translate the following food/ingredient name from {language} to English.
Provide just the simple, commonly used English name.

{language}: {name}

English (respond with just the translated name, no explanation):"""

        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "user", "content": prompt}
                ],
                temperature=0.1,
                max_tokens=100
            )

            return response.choices[0].message.content.strip()

        except Exception as e:
            logger.error(f"English translation error: {e}")
            return name  # Return original as fallback
