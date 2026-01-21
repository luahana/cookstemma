"""
Google Gemini Translation Service
Uses Gemini 2.5 Flash for cost-effective, high-quality translations.
"""
import json
import logging
from typing import Any

import google.generativeai as genai

logger = logging.getLogger()

# Language names for better context
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
    'ar': 'Arabic',
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


class ContentModerationResult:
    """Result of content moderation check."""

    def __init__(self, is_appropriate: bool, reason: str | None = None):
        self.is_appropriate = is_appropriate
        self.reason = reason

    def __bool__(self):
        return self.is_appropriate


class GeminiTranslator:
    """Translates cooking content using Google Gemini."""

    def __init__(self, api_key: str, model: str = "gemini-2.5-flash-lite"):
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel(
            model_name=model,
            generation_config={
                "temperature": 0.3,
                "max_output_tokens": 2000,
                "response_mime_type": "application/json"
            }
        )
        # Text moderation model (lower temperature for consistent results)
        self.moderation_model = genai.GenerativeModel(
            model_name=model,
            generation_config={
                "temperature": 0.1,
                "max_output_tokens": 500,
                "response_mime_type": "application/json"
            }
        )
        # Image moderation model - must be multimodal capable (not lite)
        # Using gemini-2.5-flash which supports vision/image input
        self.image_moderation_model = genai.GenerativeModel(
            model_name="gemini-2.5-flash",
            generation_config={
                "temperature": 0.1,
                "max_output_tokens": 500,
                "response_mime_type": "application/json"
            }
        )

    def moderate_recipe_content(
        self,
        title: str,
        description: str,
        steps: list[str],
        ingredients: list[str],
        food_name: str = ""
    ) -> ContentModerationResult:
        """
        Check if recipe text content is appropriate for a cooking recipe app.
        Returns ContentModerationResult with is_appropriate=True if content is OK.

        Checks for:
        - Inappropriate/offensive language
        - Content not related to cooking/food
        - Harmful or dangerous content
        - Spam or promotional content
        """
        all_text = f"""
Title: {title}
Description: {description}
Food Name: {food_name}
Steps: {json.dumps(steps, ensure_ascii=False)}
Ingredients: {json.dumps(ingredients, ensure_ascii=False)}
"""

        prompt = """You are a content moderator for a family-friendly cooking recipe app.
Analyze the following recipe content and determine if it is appropriate.

RECIPE CONTENT:
""" + all_text + """

CHECK FOR:
1. Inappropriate or offensive language (profanity, slurs, hate speech)
2. Content that is clearly NOT related to cooking or food
3. Dangerous or harmful instructions (not normal cooking hazards)
4. Spam, excessive self-promotion, or unrelated advertisements
5. Sexual or violent content
6. Content promoting illegal activities

IMPORTANT:
- Normal cooking content with knives, fire, heat, alcohol (for cooking) is APPROPRIATE
- Unusual but real foods/recipes should be allowed (exotic ingredients, cultural dishes)
- Recipe names that sound unusual but are legitimate dishes are APPROPRIATE

Return JSON: {"is_appropriate": true/false, "reason": "explanation if inappropriate, null if appropriate"}
"""

        try:
            response = self.moderation_model.generate_content(prompt)
            result_text = response.text.strip()

            # Handle potential markdown code blocks
            if result_text.startswith('```'):
                result_text = result_text.split('```')[1]
                if result_text.startswith('json'):
                    result_text = result_text[4:]
                result_text = result_text.strip()

            result = json.loads(result_text)
            is_appropriate = result.get('is_appropriate', True)
            reason = result.get('reason')

            if not is_appropriate:
                logger.warning(f"Recipe content flagged as inappropriate: {reason}")

            return ContentModerationResult(is_appropriate, reason)

        except Exception as e:
            logger.error(f"Content moderation error: {e}")
            # On error, default to allowing content (fail-open for moderation)
            # This prevents blocking legitimate content due to API issues
            return ContentModerationResult(True, None)

    def moderate_image(self, image_url: str) -> ContentModerationResult:
        """
        Check if an image is appropriate for a cooking recipe app.
        Uses Gemini's multimodal capabilities to analyze the image.

        Args:
            image_url: URL of the image to check

        Returns:
            ContentModerationResult with is_appropriate=True if image is OK
        """
        import urllib.request

        prompt = """You are a content moderator for a family-friendly cooking recipe app.
Analyze this image and determine if it is appropriate for a cooking/food recipe.

CHECK FOR:
1. Is this image related to food, cooking, ingredients, or kitchen?
2. Does it contain inappropriate content (nudity, violence, gore)?
3. Does it contain offensive symbols or text?
4. Is it spam or unrelated promotional content?

IMPORTANT:
- Raw meat, fish, seafood in cooking context is APPROPRIATE
- Unusual/exotic foods are APPROPRIATE
- Kitchen tools including knives are APPROPRIATE
- Flames/fire in cooking context is APPROPRIATE

Return JSON: {"is_appropriate": true/false, "reason": "explanation if inappropriate, null if appropriate"}
"""

        try:
            # Fetch image from URL
            req = urllib.request.Request(
                image_url,
                headers={'User-Agent': 'CookstemmaTranslator/1.0'}
            )
            with urllib.request.urlopen(req, timeout=10) as response:
                image_data = response.read()

            # Create image part for Gemini
            image_part = {
                "mime_type": "image/jpeg",  # Gemini handles format detection
                "data": image_data
            }

            response = self.image_moderation_model.generate_content([prompt, image_part])
            result_text = response.text.strip()

            # Handle potential markdown code blocks
            if result_text.startswith('```'):
                result_text = result_text.split('```')[1]
                if result_text.startswith('json'):
                    result_text = result_text[4:]
                result_text = result_text.strip()

            result = json.loads(result_text)
            is_appropriate = result.get('is_appropriate', True)
            reason = result.get('reason')

            if not is_appropriate:
                logger.warning(f"Image flagged as inappropriate ({image_url}): {reason}")

            return ContentModerationResult(is_appropriate, reason)

        except urllib.error.URLError as e:
            logger.error(f"Failed to fetch image for moderation ({image_url}): {e}")
            # On fetch error, allow content (image might be inaccessible but valid)
            return ContentModerationResult(True, None)

        except Exception as e:
            logger.error(f"Image moderation error ({image_url}): {e}")
            # On error, default to allowing (fail-open)
            return ContentModerationResult(True, None)

    def moderate_text_content(
        self,
        title: str | None,
        content: str | None,
        context: str = "cooking log post"
    ) -> ContentModerationResult:
        """
        Check if general text content is appropriate for a cooking app.
        Used for LOG_POST, comments, user bios, etc.

        Args:
            title: Optional title text
            content: Main content text
            context: Context description for moderation

        Returns:
            ContentModerationResult with is_appropriate=True if content is OK
        """
        all_text = f"""
Title: {title or '(none)'}
Content: {content or '(none)'}
"""

        prompt = f"""You are a content moderator for a family-friendly cooking recipe app.
Analyze the following {context} content and determine if it is appropriate.

CONTENT TO CHECK:
{all_text}

CHECK FOR:
1. Inappropriate or offensive language (profanity, slurs, hate speech)
2. Content that is clearly NOT related to cooking, food, or kitchen activities
3. Dangerous or harmful content
4. Spam, excessive self-promotion, or unrelated advertisements
5. Sexual or violent content
6. Content promoting illegal activities
7. Personal attacks or harassment

IMPORTANT:
- Cooking-related discussions are APPROPRIATE
- Food photography discussions are APPROPRIATE
- Kitchen tips and experiences are APPROPRIATE
- Personal stories about cooking/food are APPROPRIATE

Return JSON: {{"is_appropriate": true/false, "reason": "explanation if inappropriate, null if appropriate"}}
"""

        try:
            response = self.moderation_model.generate_content(prompt)
            result_text = response.text.strip()

            # Handle potential markdown code blocks
            if result_text.startswith('```'):
                result_text = result_text.split('```')[1]
                if result_text.startswith('json'):
                    result_text = result_text[4:]
                result_text = result_text.strip()

            result = json.loads(result_text)
            is_appropriate = result.get('is_appropriate', True)
            reason = result.get('reason')

            if not is_appropriate:
                logger.warning(f"{context} content flagged as inappropriate: {reason}")

            return ContentModerationResult(is_appropriate, reason)

        except Exception as e:
            logger.error(f"Text content moderation error: {e}")
            # On error, default to allowing content (fail-open)
            return ContentModerationResult(True, None)

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

        prompt = f"""You are a professional translator specializing in {context} content.
Translate the following JSON fields from {source_lang} to {target_lang}.

Rules:
1. Preserve the JSON structure exactly - return only valid JSON
2. Keep cooking terms natural in the target language
3. Maintain ingredient names that are commonly known (e.g., "kimchi" stays "kimchi" in most languages)
4. Keep measurements and numbers as-is
5. If a field is empty, return empty string
6. For Arabic, ensure proper RTL text
7. Be concise but accurate

Input JSON to translate to {target_lang}:

{fields_json}

Return ONLY the JSON object with translated values, no explanation."""

        try:
            response = self.model.generate_content(prompt)
            result_text = response.text.strip()

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

    def translate_recipe_batch(
        self,
        content: dict,
        source_locale: str,
        target_locale: str
    ) -> dict:
        """
        Translate entire recipe (title, description, food_name, steps, ingredients) at once.
        Provides context-aware translation for better quality and consistency.

        Args:
            content: Dict with 'title', 'description', 'food_name', 'steps' (list), 'ingredients' (list)
            source_locale: Source language code (e.g., 'ko', 'en')
            target_locale: Target language code

        Returns:
            Dict with translated 'title', 'description', 'food_name', 'steps' (list), 'ingredients' (list)
        """
        source_lang = LANGUAGE_NAMES.get(source_locale, source_locale)
        target_lang = LANGUAGE_NAMES.get(target_locale, target_locale)

        # Build structured content for translation
        steps_json = json.dumps(content.get('steps', []), ensure_ascii=False)
        ingredients_json = json.dumps(content.get('ingredients', []), ensure_ascii=False)
        food_name = content.get('food_name', '')

        prompt = f"""You are a professional culinary translator specializing in cooking recipes.
Translate this complete cooking recipe from {source_lang} to {target_lang}.

RECIPE TO TRANSLATE:
- Title: {content.get('title', '')}
- Description: {content.get('description', '')}
- Food Name: {food_name}
- Steps: {steps_json}
- Ingredients: {ingredients_json}

NOTES:
- "Title" is the creative recipe name (e.g., "Grandma's Special Bibimbap")
- "Food Name" is the standard dish name (e.g., "Bibimbap") - translate this appropriately for the target language

RULES:
1. Return valid JSON with exact structure: {{"title": "...", "description": "...", "food_name": "...", "steps": [...], "ingredients": [...]}}
2. Keep ingredient names that are internationally known (kimchi, tofu, parmesan, miso)
3. Use natural cooking terminology for the target language
4. CRITICAL: Maintain consistency - if you translate an ingredient name, use the same translation in all steps
5. Keep measurements, numbers, and units unchanged
6. The number of steps in output MUST exactly match the input ({len(content.get('steps', []))} steps)
7. The number of ingredients in output MUST exactly match the input ({len(content.get('ingredients', []))} ingredients)
8. Preserve the cooking intent and nuance of the original recipe

Return ONLY the JSON object, no explanation or markdown formatting."""

        try:
            response = self.model.generate_content(prompt)
            result_text = response.text.strip()

            # Handle potential markdown code blocks
            if result_text.startswith('```'):
                result_text = result_text.split('```')[1]
                if result_text.startswith('json'):
                    result_text = result_text[4:]
                result_text = result_text.strip()

            translated = json.loads(result_text)

            # Validate output structure
            expected_steps = len(content.get('steps', []))
            expected_ingredients = len(content.get('ingredients', []))
            actual_steps = len(translated.get('steps', []))
            actual_ingredients = len(translated.get('ingredients', []))

            if actual_steps != expected_steps:
                logger.warning(f"Step count mismatch: expected {expected_steps}, got {actual_steps}")
            if actual_ingredients != expected_ingredients:
                logger.warning(f"Ingredient count mismatch: expected {expected_ingredients}, got {actual_ingredients}")

            # Ensure all fields are present
            result = {
                'title': translated.get('title', content.get('title', '')),
                'description': translated.get('description', content.get('description', '')),
                'food_name': translated.get('food_name', content.get('food_name', '')),
                'steps': translated.get('steps', content.get('steps', [])),
                'ingredients': translated.get('ingredients', content.get('ingredients', []))
            }

            logger.info(f"Successfully translated full recipe to {target_lang}")
            return result

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse batch translation response: {e}")
            logger.error(f"Response was: {result_text[:500]}")
            raise ValueError(f"Invalid translation response format: {e}")

        except Exception as e:
            logger.error(f"Batch translation API error: {e}")
            raise
