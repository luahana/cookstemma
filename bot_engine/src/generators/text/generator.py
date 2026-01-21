"""Text generator using Gemini with OpenAI ChatGPT fallback."""

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
    """Generate recipe and log content using Gemini with GPT fallback."""

    def __init__(
        self,
        gemini_api_key: Optional[str] = None,
        openai_api_key: Optional[str] = None,
        model: Optional[str] = None,
        temperature: Optional[float] = None,
    ) -> None:
        settings = get_settings()
        
        # 1. Initialize Gemini Client (Primary)
        # Uses the OpenAI-compatible base URL for Gemini
        self.gemini_client = AsyncOpenAI(
            api_key=gemini_api_key or settings.gemini_api_key,
            base_url="https://generativelanguage.googleapis.com/v1beta/openai/"
        )
        
        # 2. Initialize OpenAI Client (Fallback)
        self.openai_client = AsyncOpenAI(
            api_key=openai_api_key or settings.openai_api_key
        )
        
        # Default models from settings
        self.gemini_model = settings.gemini_model or "gemini-3-pro-preview"
        self.openai_model = settings.openai_model or "gpt-4o"
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
        """Make a chat completion request with fallback logic."""
        
        # Ensure the prompt contains 'json' for JSON mode
        if "json" not in system_prompt.lower() and "json" not in user_prompt.lower():
            system_prompt += "\nRespond ONLY with a valid JSON object."

        try:
            # Step 1: Attempt with Gemini (Primary)
            logger.debug("attempting_gemini_completion", model=self.gemini_model)
            response = await self.gemini_client.chat.completions.create(
                model=self.gemini_model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=temperature or self.temperature,
                response_format={"type": "json_object"}, # Supported in compatibility mode
            )
            return response.choices[0].message.content

        except Exception as e:
            # Step 2: Fallback to OpenAI if Gemini fails
            logger.warning("gemini_failed_falling_back_to_gpt", error=str(e))
            response = await self.openai_client.chat.completions.create(
                model=self.openai_model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=temperature or self.temperature,
                response_format={"type": "json_object"},
            )
            return response.choices[0].message.content

    def _parse_json_response(self, response: str) -> Dict[str, Any]:
        """Parse JSON from AI response."""
        try:
            response = response.strip()
            # Clean markdown formatting if present
            if response.startswith("```json"): response = response[7:]
            if response.startswith("```"): response = response[3:]
            if response.endswith("```"): response = response[:-3]
            return json.loads(response.strip())
        except json.JSONDecodeError as e:
            logger.error("json_parse_error", response=response[:200], error=str(e))
            raise ValueError(f"Invalid JSON response: {e}")

    # ... Rest of the methods (generate_recipe, generate_variant, etc.) remain the same
    # because they all call the internal _chat_completion method.