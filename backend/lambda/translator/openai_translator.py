"""
OpenAI GPT Translation Service
Uses GPT-4o-mini for cost-effective, high-quality translations.
"""
import json
import logging
from typing import Any

from openai import OpenAI

logger = logging.getLogger()

# Language names for better GPT context
LANGUAGE_NAMES = {
    'ko': 'Korean',
    'en': 'English',
    'ja': 'Japanese',
    'zh': 'Chinese (Simplified)',
    'fr': 'French',
    'es': 'Spanish',
    'it': 'Italian',
    'de': 'German',
    'ru': 'Russian',
    'pt': 'Portuguese',
    'el': 'Greek',
    'ar': 'Arabic'
}


class OpenAITranslator:
    """Translates cooking content using OpenAI GPT."""

    def __init__(self, api_key: str, model: str = "gpt-4o-mini"):
        self.client = OpenAI(api_key=api_key)
        self.model = model

    def translate_content(
        self,
        content: dict[str, str],
        source_locale: str,
        target_locale: str,
        context: str = "cooking recipe"
    ) -> dict[str, str]:
        """
        Translate multiple fields at once for efficiency.

        Args:
            content: Dict of field_name -> text_to_translate
            source_locale: Source language code (e.g., 'ko', 'en')
            target_locale: Target language code
            context: Context hint for better translations

        Returns:
            Dict of field_name -> translated_text
        """
        source_lang = LANGUAGE_NAMES.get(source_locale, source_locale)
        target_lang = LANGUAGE_NAMES.get(target_locale, target_locale)

        # Filter out empty content
        non_empty_content = {k: v for k, v in content.items() if v and v.strip()}

        if not non_empty_content:
            return {k: '' for k in content.keys()}

        # Build the prompt
        fields_json = json.dumps(non_empty_content, ensure_ascii=False, indent=2)

        system_prompt = f"""You are a professional translator specializing in {context} content.
Translate the following JSON fields from {source_lang} to {target_lang}.

Rules:
1. Preserve the JSON structure exactly - return only valid JSON
2. Keep cooking terms natural in the target language
3. Maintain ingredient names that are commonly known (e.g., "kimchi" stays "kimchi" in most languages)
4. Keep measurements and numbers as-is
5. If a field is empty, return empty string
6. For Arabic, ensure proper RTL text
7. Be concise but accurate

Return ONLY the JSON object with translated values, no explanation."""

        user_prompt = f"""Translate this JSON to {target_lang}:

{fields_json}"""

        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.3,  # Lower temperature for more consistent translations
                max_tokens=2000
            )

            result_text = response.choices[0].message.content.strip()

            # Parse JSON response
            # Handle potential markdown code blocks
            if result_text.startswith('```'):
                result_text = result_text.split('```')[1]
                if result_text.startswith('json'):
                    result_text = result_text[4:]
                result_text = result_text.strip()

            translated = json.loads(result_text)

            # Ensure all original keys are present
            result = {}
            for key in content.keys():
                if key in translated:
                    result[key] = translated[key]
                elif key in non_empty_content:
                    # If translation failed for this field, use original
                    result[key] = content[key]
                else:
                    result[key] = ''

            logger.info(f"Successfully translated {len(non_empty_content)} fields to {target_lang}")
            return result

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse translation response: {e}")
            logger.error(f"Response was: {result_text[:500]}")
            raise ValueError(f"Invalid translation response format: {e}")

        except Exception as e:
            logger.error(f"Translation API error: {e}")
            raise

    def translate_single(
        self,
        text: str,
        source_locale: str,
        target_locale: str,
        context: str = "cooking recipe"
    ) -> str:
        """Convenience method to translate a single string."""
        if not text or not text.strip():
            return ''

        result = self.translate_content(
            content={'text': text},
            source_locale=source_locale,
            target_locale=target_locale,
            context=context
        )
        return result.get('text', text)
