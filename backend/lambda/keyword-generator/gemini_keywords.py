"""
Google Gemini Multilingual Keyword Generator
Generates search keywords for foods in 20 supported languages using Gemini 2.5 Flash Lite.
"""
import json
import logging
from typing import Any

import google.generativeai as genai

logger = logging.getLogger()

# 20 Supported locales with their language names
SUPPORTED_LOCALES = {
    'en': 'English',
    'ko': 'Korean',
    'ja': 'Japanese',
    'zh': 'Chinese (Simplified)',
    'de': 'German',
    'fr': 'French',
    'pt': 'Portuguese',
    'es': 'Spanish',
    'it': 'Italian',
    'ar': 'Arabic',
    'ru': 'Russian',
    'id': 'Indonesian',
    'vi': 'Vietnamese',
    'hi': 'Hindi',
    'th': 'Thai',
    'pl': 'Polish',
    'tr': 'Turkish',
    'nl': 'Dutch',
    'sv': 'Swedish',
    'fa': 'Persian'
}

# Template for multilingual keyword generation
KEYWORD_GENERATION_PROMPT = """You are a multilingual culinary search keyword generator for a recipe app.

Given a food item with its name and description in multiple languages, generate 5-8 relevant search keywords for EACH of the 20 supported languages.

**Food Names (by locale):**
{name_json}

**Descriptions (by locale):**
{description_json}

**Generate keywords for these 20 languages:**
en (English), ko (Korean), ja (Japanese), zh (Chinese), de (German),
fr (French), pt (Portuguese), es (Spanish), it (Italian), ar (Arabic),
ru (Russian), id (Indonesian), vi (Vietnamese), hi (Hindi), th (Thai),
pl (Polish), tr (Turkish), nl (Dutch), sv (Swedish), fa (Persian)

**Rules:**
1. Keywords should be in the TARGET language (native terms users would search)
2. Include: food name variations, cuisine type, meal type, cooking methods, key ingredients
3. Use culturally appropriate search terms that local users would actually use
4. Keep keywords concise (1-3 words each)
5. Separate keywords with commas
6. If a language has no name/description available, infer from other languages

**Output format - return ONLY valid JSON:**
{{
  "en": "keyword1, keyword2, keyword3, ...",
  "ko": "키워드1, 키워드2, 키워드3, ...",
  "ja": "キーワード1, キーワード2, ...",
  ...all 20 languages...
}}
"""


class GeminiKeywordGenerator:
    """Generates multilingual search keywords using Google Gemini."""

    def __init__(self, api_key: str, model: str = "gemini-2.0-flash-lite"):
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel(
            model_name=model,
            generation_config={
                "temperature": 0.4,
                "max_output_tokens": 4000,
                "response_mime_type": "application/json"
            }
        )

    def generate_keywords(
        self,
        name: dict[str, str],
        description: dict[str, str] | None = None
    ) -> dict[str, str]:
        """
        Generate search keywords for a food in all 20 supported languages.

        Args:
            name: Dict of locale -> food name (e.g., {"en": "Kimchi Stew", "ko": "김치찌개"})
            description: Dict of locale -> description (optional)

        Returns:
            Dict of locale -> comma-separated keywords for all 20 languages
        """
        name_json = json.dumps(name or {}, ensure_ascii=False, indent=2)
        desc_json = json.dumps(description or {}, ensure_ascii=False, indent=2)

        prompt = KEYWORD_GENERATION_PROMPT.format(
            name_json=name_json,
            description_json=desc_json
        )

        try:
            response = self.model.generate_content(prompt)
            result_text = response.text.strip()

            # Handle potential markdown code blocks
            if result_text.startswith('```'):
                result_text = result_text.split('```')[1]
                if result_text.startswith('json'):
                    result_text = result_text[4:]
                result_text = result_text.strip()

            keywords = json.loads(result_text)

            # Validate we have all 20 locales
            missing_locales = set(SUPPORTED_LOCALES.keys()) - set(keywords.keys())
            if missing_locales:
                logger.warning(f"Missing locales in response: {missing_locales}")
                # Fill missing locales with empty string
                for locale in missing_locales:
                    keywords[locale] = ""

            # Filter to only include supported locales
            keywords = {k: v for k, v in keywords.items() if k in SUPPORTED_LOCALES}

            logger.info(f"Generated keywords for {len(keywords)} languages")
            return keywords

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse keyword response: {e}")
            logger.error(f"Response was: {result_text[:500]}")
            raise ValueError(f"Invalid keyword response format: {e}")

        except Exception as e:
            logger.error(f"Keyword generation API error: {e}")
            raise
