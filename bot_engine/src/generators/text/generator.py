"""Text generator using Gemini with retry logic."""

import json
from typing import Any, Dict, List, Optional

import structlog
from google import genai
from google.genai import types
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

from ...config import get_settings
from ...holidays import HolidayService
from ...personas import BotPersona
from .prompts import CULTURAL_PREFERENCES, VARIATION_TYPE_HASHTAGS, LogPrompts, RecipePrompts

logger = structlog.get_logger()


class TextGenerator:
    """Generate recipe and log content using Gemini."""

    def __init__(
        self,
        gemini_api_key: Optional[str] = None,
        temperature: Optional[float] = None,
    ) -> None:
        settings = get_settings()

        # Initialize native Google GenAI Client
        self.client = genai.Client(
            api_key=gemini_api_key or settings.gemini_api_key
        )

        self.model = settings.gemini_text_model or "gemini-2.5-flash-lite"
        self.temperature = temperature or settings.temperature

    @retry(
        retry=retry_if_exception_type(Exception),
        stop=stop_after_attempt(5),
        wait=wait_exponential(multiplier=2, min=5, max=60),
        before_sleep=lambda retry_state: logger.warning(
            "gemini_text_retry",
            attempt=retry_state.attempt_number,
            wait=retry_state.next_action.sleep,
        ),
    )
    async def _chat_completion(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: Optional[float] = None,
    ) -> str:
        """Make a chat completion request with retry logic."""

        # Ensure the prompt contains 'json' for JSON mode
        if "json" not in system_prompt.lower() and "json" not in user_prompt.lower():
            system_prompt += "\nRespond ONLY with a valid JSON object."

        # Combine system and user prompts for Gemini
        combined_prompt = f"{system_prompt}\n\n{user_prompt}"

        logger.debug("attempting_gemini_completion", model=self.model)
        response = await self.client.aio.models.generate_content(
            model=self.model,
            contents=[combined_prompt],
            config=types.GenerateContentConfig(
                temperature=temperature or self.temperature,
                response_mime_type="application/json",
            ),
        )

        # Extract text from response
        content = response.text
        if not content:
            raise ValueError("Empty response from Gemini")

        logger.debug(
            "gemini_response",
            model=self.model,
            response_len=len(content),
        )
        return content

    def _parse_json_response(self, response: str) -> Dict[str, Any]:
        """Parse JSON from AI response."""
        try:
            response = response.strip()
            # Clean markdown formatting if present
            if response.startswith("```json"):
                response = response[7:]
            if response.startswith("```"):
                response = response[3:]
            if response.endswith("```"):
                response = response[:-3]
            return json.loads(response.strip())
        except json.JSONDecodeError as e:
            logger.error("json_parse_error", response=response[:200], error=str(e))
            raise ValueError(f"Invalid JSON response: {e}")

    async def generate_recipe(
        self,
        persona: BotPersona,
        food_name: str,
    ) -> Dict[str, Any]:
        """Generate an original recipe."""
        system_prompt = persona.build_system_prompt()
        user_prompt = RecipePrompts.generate_original_recipe(
            food_name=food_name,
            locale=persona.locale,
            culinary_style=persona.cooking_style,
            specialties=persona.specialties,
        )

        response = await self._chat_completion(system_prompt, user_prompt)

        try:
            recipe_data = self._parse_json_response(response)
        except ValueError as e:
            logger.error("recipe_parse_failed", error=str(e), response_preview=response[:500])
            raise

        # Handle Gemini returning [{...}] instead of {...}
        if isinstance(recipe_data, list):
            if len(recipe_data) == 1 and isinstance(recipe_data[0], dict):
                logger.debug("unwrapping_list_response")
                recipe_data = recipe_data[0]
            else:
                logger.error("recipe_is_list", data=str(recipe_data)[:300])
                raise ValueError(f"Expected dict, got list with {len(recipe_data)} items")

        if not isinstance(recipe_data, dict):
            logger.error("recipe_not_dict", type=type(recipe_data).__name__, data=str(recipe_data)[:300])
            raise ValueError(f"Expected dict, got {type(recipe_data).__name__}")

        logger.info(
            "recipe_generated",
            persona=persona.name,
            title=recipe_data.get("title"),
            food=food_name,
        )
        return recipe_data

    async def generate_variant(
        self,
        persona: BotPersona,
        parent_recipe: Dict[str, Any],
        variation_type: str = "creative",
        cultural_context: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Generate a recipe variant.

        Args:
            persona: Bot persona to use for generation
            parent_recipe: Parent recipe data dict
            variation_type: Type of variation to create
            cultural_context: Optional cultural adaptation context for cross-cultural variants

        Returns:
            Generated variant recipe data dict
        """

        # Format parent recipe info with quantity and unit
        def format_ingredient(i: Dict[str, Any]) -> str:
            name = i.get("name", "")
            quantity = i.get("quantity")
            unit = i.get("unit")
            if quantity and unit:
                return f"- {name}: {quantity} {unit}"
            elif quantity:
                return f"- {name}: {quantity}"
            else:
                return f"- {name}"

        parent_ingredients = "\n".join(
            format_ingredient(i) for i in parent_recipe.get("ingredients", [])
        )
        parent_steps = "\n".join(
            f"{s['order']}. {s['description']}" for s in parent_recipe.get("steps", [])
        )

        # Get the canonical hashtag for this variation type
        variation_hashtag = VARIATION_TYPE_HASHTAGS.get(variation_type, variation_type)

        system_prompt = persona.build_system_prompt()
        user_prompt = RecipePrompts.generate_variant_recipe(
            parent_title=parent_recipe["title"],
            parent_description=parent_recipe["description"],
            parent_ingredients=parent_ingredients,
            parent_steps=parent_steps,
            locale=persona.locale,
            variation_type=variation_type,
            cultural_context=cultural_context,
            variation_hashtag=variation_hashtag,
        )

        response = await self._chat_completion(system_prompt, user_prompt)
        variant_data = self._parse_json_response(response)

        # Handle Gemini returning [{...}] instead of {...}
        if isinstance(variant_data, list) and len(variant_data) == 1:
            variant_data = variant_data[0]

        log_extra = {}
        if cultural_context:
            log_extra["source_culture"] = cultural_context.get("source_culture")
            log_extra["target_culture"] = cultural_context.get("target_culture")

        logger.info(
            "variant_generated",
            persona=persona.name,
            parent=parent_recipe.get("title"),
            new_title=variant_data.get("title"),
            variation_type=variation_type,
            **log_extra,
        )
        return variant_data

    async def generate_log(
        self,
        persona: BotPersona,
        recipe_title: str,
        recipe_description: str,
        rating: int,
    ) -> Dict[str, Any]:
        """Generate a cooking log.

        Args:
            persona: Bot persona to use
            recipe_title: Title of the recipe
            recipe_description: Description of the recipe
            rating: Star rating 1-5

        Returns:
            Dict with 'content' and 'hashtags' keys
        """
        system_prompt = persona.build_system_prompt()
        user_prompt = LogPrompts.generate_log(
            recipe_title=recipe_title,
            recipe_description=recipe_description,
            rating=rating,
            locale=persona.locale,
            persona_background=persona.background_story,
        )

        # Use slightly lower temperature for logs (more consistent)
        response = await self._chat_completion(
            system_prompt,
            user_prompt,
            temperature=self.temperature - 0.1,
        )
        log_data = self._parse_json_response(response)

        # Handle Gemini returning [{...}] instead of {...}
        if isinstance(log_data, list) and len(log_data) == 1:
            log_data = log_data[0]

        logger.info(
            "log_generated",
            persona=persona.name,
            recipe=recipe_title,
            rating=rating,
        )
        return log_data

    async def suggest_food_names(
        self,
        persona: BotPersona,
        count: int = 10,
        exclude: Optional[List[str]] = None,
    ) -> List[str]:
        """Generate food name suggestions based on persona specialties."""
        exclude_str = ", ".join(exclude or [])
        lang = persona.get_language_name()

        # Get holiday context for temporal awareness
        holiday_service = HolidayService(persona.locale)
        holiday_context = holiday_service.build_prompt_context()

        system_prompt = persona.build_system_prompt()
        user_prompt = f"""Suggest {count} dish names that you would love to cook and share recipes for.
{holiday_context}

Based on your specialties ({', '.join(persona.specialties)}), suggest dishes that:
- Match your cooking style and skill level
- Are popular and appealing
- Have variety (different meal types, techniques)
{"- Exclude these (already have recipes): " + exclude_str if exclude else ""}

IMPORTANT - Food name rules (STRICT - follow exactly):
- Use ONLY the simple, canonical food name
- Do NOT use adjectives (descriptive words like: crispy, delicious, homemade, spicy, fresh)
- Do NOT use adverbs (words like: perfectly, freshly, slowly, very)
- Do NOT add descriptions or combine multiple dishes
- Do NOT use conjunctions to combine foods (and, with, 와/과, と, 和, и, etc.)

BAD examples by language (NEVER use these formats):
- English: "Crispy Fried Chicken" → "Fried Chicken", "Delicious Pasta" → "Pasta"
- Korean (ko): "매콤한 김치찌개" → "김치찌개", "바삭한 치킨" → "치킨"
- Japanese (ja): "美味しいラーメン" → "ラーメン", "サクサク天ぷら" → "天ぷら"
- Chinese (zh): "香辣火锅" → "火锅", "美味炒饭" → "炒饭"
- Spanish (es): "Deliciosa Paella" → "Paella", "Crujientes Churros" → "Churros"
- French (fr): "Délicieux Croissant" → "Croissant", "Croustillant Poulet" → "Poulet Rôti"
- German (de): "Leckere Bratwurst" → "Bratwurst", "Knusprige Schnitzel" → "Schnitzel"
- Italian (it): "Deliziosa Pizza" → "Pizza", "Cremosa Carbonara" → "Carbonara"
- Portuguese (pt): "Deliciosa Feijoada" → "Feijoada", "Crocante Pastel" → "Pastel"
- Russian (ru): "Вкусный борщ" → "Борщ", "Хрустящие блины" → "Блины"
- Arabic (ar): "كباب لذيذ" → "كباب", "فلافل مقرمشة" → "فلافل"
- Hindi (hi): "स्वादिष्ट बिरयानी" → "बिरयानी", "कुरकुरा समोसा" → "समोसा"
- Thai (th): "ผัดไทยอร่อย" → "ผัดไทย", "ต้มยำกุ้งรสเด็ด" → "ต้มยำกุ้ง"
- Vietnamese (vi): "Phở ngon tuyệt" → "Phở", "Bánh mì giòn" → "Bánh mì"
- Indonesian (id): "Nasi Goreng Lezat" → "Nasi Goreng", "Sate Ayam Empuk" → "Sate Ayam"
- Turkish (tr): "Lezzetli Kebap" → "Kebap", "Çıtır Börek" → "Börek"
- Dutch (nl): "Heerlijke Stroopwafel" → "Stroopwafel", "Krokante Bitterballen" → "Bitterballen"
- Polish (pl): "Pyszne Pierogi" → "Pierogi", "Chrupiący Schabowy" → "Schabowy"
- Swedish (sv): "Läckra Köttbullar" → "Köttbullar", "Krispig Smörgås" → "Smörgås"
- Persian (fa): "کباب خوشمزه" → "کباب", "قورمه‌سبزی لذیذ" → "قورمه‌سبزی"

GOOD examples (simple, canonical names only):
- Use the standard dictionary name for the dish
- No flavor descriptors, no texture words, no quality adjectives

Return as JSON:
{{
    "dishes": ["dish1", "dish2", ...]
}}

Write dish names in {lang}.
Return ONLY valid JSON."""

        response = await self._chat_completion(system_prompt, user_prompt)
        data = self._parse_json_response(response)
        return data.get("dishes", [])

    async def suggest_variation_types(
        self,
        persona: BotPersona,
        recipe_title: str,
        recipe_description: str,
    ) -> List[str]:
        """Suggest appropriate variation types for a recipe."""
        lang = persona.get_language_name()

        system_prompt = persona.build_system_prompt()
        user_prompt = f"""For the recipe "{recipe_title}" ({recipe_description}),
suggest 2-3 meaningful variations you could create.

Choose from these variation types:
- healthier: Make it healthier
- budget: Make it more affordable
- quick: Make it faster to prepare
- vegetarian: Make it plant-based
- spicier: Add more heat
- kid_friendly: Make it appealing to children
- gourmet: Elevate it with premium touches
- vegan: Make it fully vegan
- high_protein: Increase protein content
- low_carb: Reduce carbohydrates

Return as JSON:
{{
    "variations": ["variation_type1", "variation_type2"]
}}

Choose types that make sense for this specific dish.
Return ONLY valid JSON."""

        response = await self._chat_completion(system_prompt, user_prompt)
        data = self._parse_json_response(response)
        return data.get("variations", ["healthier"])
