"""Text generator using OpenAI ChatGPT."""

import json
from typing import Any, Dict, List, Optional

import structlog
from openai import AsyncOpenAI
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

from ...config import get_settings
from ...personas import BotPersona
from .prompts import LogPrompts, RecipePrompts

logger = structlog.get_logger()


class TextGenerator:
    """Generate recipe and log content using ChatGPT."""

    def __init__(
        self,
        api_key: Optional[str] = None,
        model: Optional[str] = None,
        temperature: Optional[float] = None,
    ) -> None:
        settings = get_settings()
        self.client = AsyncOpenAI(api_key=api_key or settings.openai_api_key)
        self.model = model or settings.openai_model
        self.temperature = temperature or settings.openai_temperature

    @retry(
        retry=retry_if_exception_type(Exception),
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=30),
    )
    async def _chat_completion(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: Optional[float] = None,
    ) -> str:
        """Make a chat completion request."""
        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=temperature or self.temperature,
            response_format={"type": "json_object"},
        )
        content = response.choices[0].message.content
        if not content:
            raise ValueError("Empty response from ChatGPT")

        logger.debug(
            "chatgpt_response",
            model=self.model,
            tokens=response.usage.total_tokens if response.usage else None,
        )
        return content

    def _parse_json_response(self, response: str) -> Dict[str, Any]:
        """Parse JSON from ChatGPT response."""
        try:
            # Try to extract JSON from response
            response = response.strip()
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
            culinary_style=persona.culinary_locale,
            specialties=persona.specialties,
        )

        response = await self._chat_completion(system_prompt, user_prompt)
        recipe_data = self._parse_json_response(response)

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
    ) -> Dict[str, Any]:
        """Generate a recipe variant."""
        # Format parent recipe info
        parent_ingredients = "\n".join(
            f"- {i['name']}: {i['amount']}"
            for i in parent_recipe.get("ingredients", [])
        )
        parent_steps = "\n".join(
            f"{s['order']}. {s['description']}"
            for s in parent_recipe.get("steps", [])
        )

        system_prompt = persona.build_system_prompt()
        user_prompt = RecipePrompts.generate_variant_recipe(
            parent_title=parent_recipe["title"],
            parent_description=parent_recipe["description"],
            parent_ingredients=parent_ingredients,
            parent_steps=parent_steps,
            locale=persona.locale,
            variation_type=variation_type,
        )

        response = await self._chat_completion(system_prompt, user_prompt)
        variant_data = self._parse_json_response(response)

        logger.info(
            "variant_generated",
            persona=persona.name,
            parent=parent_recipe.get("title"),
            new_title=variant_data.get("title"),
            variation_type=variation_type,
        )
        return variant_data

    async def generate_log(
        self,
        persona: BotPersona,
        recipe_title: str,
        recipe_description: str,
        outcome: str,
    ) -> Dict[str, Any]:
        """Generate a cooking log."""
        system_prompt = persona.build_system_prompt()
        user_prompt = LogPrompts.generate_log(
            recipe_title=recipe_title,
            recipe_description=recipe_description,
            outcome=outcome,
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

        logger.info(
            "log_generated",
            persona=persona.name,
            recipe=recipe_title,
            outcome=outcome,
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
        lang = "Korean" if persona.is_korean() else "English"

        system_prompt = persona.build_system_prompt()
        user_prompt = f"""Suggest {count} dish names that you would love to cook and share recipes for.

Based on your specialties ({', '.join(persona.specialties)}), suggest dishes that:
- Match your cooking style and skill level
- Are popular and appealing
- Have variety (different meal types, techniques)
{"- Exclude these (already have recipes): " + exclude_str if exclude else ""}

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
        lang = "Korean" if persona.is_korean() else "English"

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

Return as JSON:
{{
    "variations": ["variation_type1", "variation_type2"]
}}

Choose types that make sense for this specific dish.
Return ONLY valid JSON."""

        response = await self._chat_completion(system_prompt, user_prompt)
        data = self._parse_json_response(response)
        return data.get("variations", ["healthier"])
