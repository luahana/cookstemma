"""
Google Gemini Translation Service
Uses Gemini 2.5 Flash for cost-effective, high-quality translations.
"""
import json
import logging
from typing import Any

from google import genai
from google.genai import types

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
        self.client = genai.Client(api_key=api_key)
        self.model = model
        self.image_model = "gemini-2.5-flash"  # For multimodal tasks

    def moderate_recipe_content(
        self,
        title: str,
        description: str,
        steps: list[str],
        ingredients: list[str],
        food_name: str = "",
        is_variant: bool = False,
        change_reason: str = ""
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
        if is_variant:
            all_text = f"""
Title: {title}
Description (from parent recipe): {description}
Change Reason (why this variant differs): {change_reason}
Food Name: {food_name}
Steps: {json.dumps(steps, ensure_ascii=False)}
Ingredients: {json.dumps(ingredients, ensure_ascii=False)}
"""
        else:
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
""" + ("""
VARIANT RECIPE NOTE:
- This is a VARIANT recipe - the description comes from the PARENT recipe
- The variant's ingredients/steps may intentionally differ from the description (e.g., vegetarian version of a meat dish)
- Focus on checking the variant's own content (title, change_reason, steps, ingredients) for appropriateness
- Do NOT flag as inappropriate just because ingredients don't match the parent's description
""" if is_variant else "") + """
Return JSON: {"is_appropriate": true/false, "reason": "explanation if inappropriate, null if appropriate"}
"""

        try:
            response = self.client.models.generate_content(
                model=self.model,
                contents=[prompt],
                config=types.GenerateContentConfig(
                    temperature=0.1,
                    max_output_tokens=500,
                    response_mime_type="application/json"
                )
            )
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
        import base64

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

            # Create image part for Gemini (base64 encoded)
            image_base64 = base64.b64encode(image_data).decode('utf-8')

            response = self.client.models.generate_content(
                model=self.image_model,
                contents=[
                    prompt,
                    types.Part.from_bytes(
                        data=image_data,
                        mime_type="image/jpeg"
                    )
                ],
                config=types.GenerateContentConfig(
                    temperature=0.1,
                    max_output_tokens=500,
                    response_mime_type="application/json"
                )
            )
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
            response = self.client.models.generate_content(
                model=self.model,
                contents=[prompt],
                config=types.GenerateContentConfig(
                    temperature=0.1,
                    max_output_tokens=500,
                    response_mime_type="application/json"
                )
            )
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

        # Add ingredient-specific rules if context is about ingredients
        ingredient_rules = ""
        if "ingredient" in context.lower():
            ingredient_rules = """
8. IMPORTANT - Strip all adjectives and adverbs, keep only the core ingredient noun:
   - Remove size adjectives: large, small, medium, big, little
   - Remove freshness adjectives: fresh, ripe, dried, frozen, raw
   - Remove preparation words: chopped, diced, minced, sliced, grated, crushed, ground, peeled
   - Remove quality adjectives: organic, premium, homemade, store-bought
   - Examples: "freshly chopped garlic" → "garlic", "large ripe tomatoes" → "tomato"
"""

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
{ingredient_rules}
Input JSON to translate to {target_lang}:

{fields_json}

Return ONLY the JSON object with translated values, no explanation."""

        try:
            response = self.client.models.generate_content(
                model=self.model,
                contents=[prompt],
                config=types.GenerateContentConfig(
                    temperature=0.3,
                    max_output_tokens=8000,
                    response_mime_type="application/json"
                )
            )
            result_text = response.text.strip()

            # Parse JSON response
            # Handle potential markdown code blocks
            if result_text.startswith('```'):
                result_text = result_text.split('```')[1]
                if result_text.startswith('json'):
                    result_text = result_text[4:]
                result_text = result_text.strip()

            # Handle extra data after JSON (decode only the first valid JSON object)
            try:
                translated = json.loads(result_text)
            except json.JSONDecodeError as e:
                if "Extra data" in str(e):
                    # Extract just the first JSON object
                    decoder = json.JSONDecoder()
                    translated, _ = decoder.raw_decode(result_text)
                    logger.warning(f"Removed extra data after JSON object: {result_text[decoder.raw_decode(result_text)[1]:][:100]}")
                else:
                    raise

            # Strict validation - all non-empty fields must be translated
            result = {}
            unchanged_fields = []

            for key in content.keys():
                if key in non_empty_content:
                    # Field had content to translate
                    if key not in translated:
                        raise ValueError(f"Translation missing required field: {key}")
                    if not translated[key]:
                        raise ValueError(f"Translation returned empty for field: {key}")

                    # Check if translation is unchanged from source
                    if translated[key] == content[key]:
                        # Allow unchanged for very short content (emojis, punctuation, proper nouns, numbers)
                        # or when content is likely universal (< 10 chars often contains names, brands, etc.)
                        if len(content[key].strip()) >= 10:
                            unchanged_fields.append(key)
                            logger.warning(f"Translation unchanged from source for field '{key}': {content[key][:50]}")

                    result[key] = translated[key]
                else:
                    # Field was empty, keep empty
                    result[key] = ''

            # Only fail if ALL non-empty fields are unchanged AND there are multiple fields
            # For single-field entities (comments, log posts), allow unchanged content
            # (could be proper nouns, universal terms, already in target language, etc.)
            if unchanged_fields and len(unchanged_fields) == len(non_empty_content) and len(non_empty_content) > 1:
                raise ValueError(f"All fields unchanged from source: {', '.join(unchanged_fields)}")

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

        # Strict validation - no fallback to original
        if 'text' not in result:
            raise ValueError("Translation missing 'text' field")
        if not result['text']:
            raise ValueError("Translation returned empty text")

        return result['text']

    def translate_recipe_batch(
        self,
        content: dict,
        source_locale: str,
        target_locale: str
    ) -> dict:
        """
        Translate entire recipe (title, description, food_name, steps, ingredients, change_reason) at once.
        Provides context-aware translation for better quality and consistency.

        Args:
            content: Dict with 'title', 'description', 'food_name', 'steps' (list), 'ingredients' (list),
                     and optionally 'change_reason' (for variant recipes)
            source_locale: Source language code (e.g., 'ko', 'en')
            target_locale: Target language code

        Returns:
            Dict with translated 'title', 'description', 'food_name', 'steps' (list), 'ingredients' (list),
            and 'change_reason' (if provided in input)
        """
        source_lang = LANGUAGE_NAMES.get(source_locale, source_locale)
        target_lang = LANGUAGE_NAMES.get(target_locale, target_locale)

        # Build structured content for translation
        steps_json = json.dumps(content.get('steps', []), ensure_ascii=False)
        ingredients_json = json.dumps(content.get('ingredients', []), ensure_ascii=False)
        food_name = content.get('food_name', '')
        change_reason = content.get('change_reason', '')

        # Build change_reason section for prompt if present (variant recipes only)
        change_reason_section = ""
        change_reason_note = ""
        change_reason_json_field = ""
        if change_reason:
            change_reason_section = f"\n- Change Reason: {change_reason}"
            change_reason_note = '\n- "Change Reason" explains why this variant differs from the original recipe - translate naturally while preserving the meaning'
            change_reason_json_field = ', "change_reason": "..."'

        prompt = f"""You are a professional culinary translator specializing in cooking recipes.
Translate this complete cooking recipe from {source_lang} to {target_lang}.

RECIPE TO TRANSLATE:
- Title: {content.get('title', '')}
- Description: {content.get('description', '')}
- Food Name: {food_name}
- Steps: {steps_json}
- Ingredients: {ingredients_json}{change_reason_section}

NOTES:
- "Title" is the creative recipe name (e.g., "Grandma's Special Bibimbap")
- "Food Name" is the standard dish name (e.g., "Bibimbap") - translate this appropriately for the target language{change_reason_note}

RULES:
1. Return valid JSON with exact structure: {{"title": "...", "description": "...", "food_name": "...", "steps": [...], "ingredients": [...]{change_reason_json_field}}}
2. Keep ingredient names that are internationally known (kimchi, tofu, parmesan, miso)
3. Use natural cooking terminology for the target language
4. CRITICAL: Maintain consistency - if you translate an ingredient name, use the same translation in all steps
5. Keep measurements, numbers, and units unchanged
6. The number of steps in output MUST exactly match the input ({len(content.get('steps', []))} steps)
7. The number of ingredients in output MUST exactly match the input ({len(content.get('ingredients', []))} ingredients)
8. Preserve the cooking intent and nuance of the original recipe
9. INGREDIENTS ONLY - Strip all adjectives and adverbs, keep only the core ingredient noun:
   - Remove size adjectives: large, small, medium, big, little
   - Remove freshness adjectives: fresh, ripe, dried, frozen, raw
   - Remove preparation words: chopped, diced, minced, sliced, grated, crushed, ground, peeled
   - Remove quality adjectives: organic, premium, homemade, store-bought
   - Examples: "freshly chopped garlic" → "garlic", "large ripe tomatoes" → "tomato", "finely diced onion" → "onion"

Return ONLY the JSON object, no explanation or markdown formatting."""

        try:
            response = self.client.models.generate_content(
                model=self.model,
                contents=[prompt],
                config=types.GenerateContentConfig(
                    temperature=0.3,
                    max_output_tokens=8000,
                    response_mime_type="application/json"
                )
            )
            result_text = response.text.strip()

            # Log response length for debugging token limit issues
            logger.info(f"Received translation response: {len(result_text)} characters, ~{len(result_text)//4} tokens")

            # Handle potential markdown code blocks
            if result_text.startswith('```'):
                result_text = result_text.split('```')[1]
                if result_text.startswith('json'):
                    result_text = result_text[4:]
                result_text = result_text.strip()

            # Check if response looks truncated (ends abruptly without closing brace)
            if not result_text.endswith('}') and not result_text.endswith(']'):
                logger.warning(f"Response appears truncated - does not end with '}}' or ']'. Last 100 chars: {result_text[-100:]}")

            # Handle extra data after JSON (decode only the first valid JSON object)
            try:
                translated = json.loads(result_text)
            except json.JSONDecodeError as e:
                if "Extra data" in str(e):
                    # Extract just the first JSON object
                    decoder = json.JSONDecoder()
                    translated, end_pos = decoder.raw_decode(result_text)
                    extra_data = result_text[end_pos:][:100]
                    logger.warning(f"Removed extra data after JSON object: {extra_data}")
                else:
                    raise

            # Validate output structure - STRICT validation, no fallbacks
            expected_steps = len(content.get('steps', []))
            expected_ingredients = len(content.get('ingredients', []))
            actual_steps = len(translated.get('steps', []))
            actual_ingredients = len(translated.get('ingredients', []))

            # Verify all required fields are present
            if not translated.get('title'):
                raise ValueError(f"Translation missing 'title' field")
            if not translated.get('steps'):
                raise ValueError(f"Translation missing 'steps' field")
            if not translated.get('ingredients'):
                raise ValueError(f"Translation missing 'ingredients' field")

            # Verify counts match exactly
            if actual_steps != expected_steps:
                raise ValueError(f"Step count mismatch: expected {expected_steps}, got {actual_steps}")
            if actual_ingredients != expected_ingredients:
                raise ValueError(f"Ingredient count mismatch: expected {expected_ingredients}, got {actual_ingredients}")

            # Verify translation is not just the original content (detect translation failure)
            # Allow unchanged titles for very short content (brand names, proper nouns)
            if translated.get('title') == content.get('title'):
                if len(content.get('title', '').strip()) >= 10:
                    # Title is long enough that it should have been translated
                    # Check if other fields also unchanged (indicates complete failure)
                    steps_unchanged = all(
                        translated['steps'][i] == content['steps'][i]
                        for i in range(len(content.get('steps', [])))
                    ) if content.get('steps') else False

                    if steps_unchanged:
                        raise ValueError(f"Translation appears completely unchanged from source")
                    else:
                        # Title unchanged but steps translated - allow it (might be a proper noun)
                        logger.warning(f"Recipe title unchanged from source but steps translated: {content.get('title', '')[:50]}")

            # Return only translated content, NO fallbacks to original
            result = {
                'title': translated['title'],
                'description': translated.get('description', ''),  # Description can be empty
                'food_name': translated.get('food_name', ''),  # Food name can be empty
                'steps': translated['steps'],
                'ingredients': translated['ingredients']
            }

            # Include change_reason translation if it was in the input
            if change_reason:
                result['change_reason'] = translated.get('change_reason', '')

            logger.info(f"Successfully translated full recipe to {target_lang}")
            return result

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse batch translation response: {e}")
            logger.error(f"Response length: {len(result_text)} chars")
            logger.error(f"Response first 500 chars: {result_text[:500]}")
            logger.error(f"Response last 200 chars: {result_text[-200:]}")
            raise ValueError(f"Invalid translation response format (likely truncated due to token limit): {e}")

        except Exception as e:
            logger.error(f"Batch translation API error: {e}")
            raise
