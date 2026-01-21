"""Image generator using Gemini Nano Banana (native image generation)."""

import io
import random
from typing import Optional

import structlog
from google import genai
from google.genai import types
from PIL import Image
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

from ...config import get_settings
from ...personas import BotPersona

logger = structlog.get_logger()


class ImageGenerator:
    """Generate professional food images using Gemini Nano Banana."""

    def __init__(
        self,
        gemini_api_key: Optional[str] = None,
    ) -> None:
        settings = get_settings()

        # Initialize Google GenAI Client
        self.client = genai.Client(
            api_key=gemini_api_key or settings.gemini_api_key
        )
        # Nano Banana: gemini-2.5-flash-image (fast) or gemini-3-pro-image-preview (pro)
        self.model = settings.gemini_image_model or "gemini-2.5-flash-image"

    async def close(self) -> None:
        """Close any resources (kept for interface compatibility)."""
        pass

    def _build_dish_prompt(
        self,
        dish_name: str,
        persona: BotPersona,
        style: str = "cover",
    ) -> str:
        """Build detailed prompts for food image generation."""
        base_prompt = f"Professional food photography of {dish_name}."

        if style == "cover":
            return f"""{base_prompt}
{persona.kitchen_style_prompt}
Composition: Beautifully plated, appetizing, shallow depth of field.
Lighting: Soft natural daylight, high-detail textures.
Technical: 4K resolution, cinematic food magazine style."""

        elif style == "step":
            return f"""{base_prompt}
{persona.kitchen_style_prompt}
Composition: Cooking in progress, hands visible moving ingredients.
Environment: Realistic home kitchen counter, natural lighting."""

        elif style == "log":
            return f"""{base_prompt}
{persona.kitchen_style_prompt}
Style: Casual smartphone photo, slightly imperfect, realistic presentation.
Lighting: Natural indoor lighting, high-quality amateur photography."""

        return base_prompt

    def _add_realism_imperfections(self, prompt: str) -> str:
        """Add subtle details to bypass 'AI-perfect' look."""
        imperfections = [
            "slight sauce drip on plate edge", "one herb leaf slightly wilted",
            "steam rising from hot food", "napkin slightly crumpled in background",
            "uneven browning on surface", "garnish placed slightly off-center"
        ]
        selected = random.sample(imperfections, k=min(2, len(imperfections)))
        return f"{prompt}\nInclude these realistic details: {', '.join(selected)}."

    @retry(
        retry=retry_if_exception_type(Exception),
        stop=stop_after_attempt(5),
        wait=wait_exponential(multiplier=2, min=10, max=120),
        before_sleep=lambda retry_state: logger.warning(
            "nano_banana_retry",
            attempt=retry_state.attempt_number,
            wait=retry_state.next_action.sleep,
        ),
    )
    async def _generate_image_internal(
        self,
        prompt: str,
    ) -> bytes:
        """Generate image using Gemini Nano Banana with retry."""
        response = await self.client.aio.models.generate_content(
            model=self.model,
            contents=[prompt],
            config=types.GenerateContentConfig(
                response_modalities=["IMAGE"],
                image_config=types.ImageConfig(
                    aspect_ratio="1:1",
                ),
            ),
        )

        # Extract image from response parts
        for part in response.parts:
            if part.inline_data is not None:
                logger.info(
                    "nano_banana_generated",
                    model=self.model,
                    prompt_preview=prompt[:50],
                )
                return part.inline_data.data

        raise ValueError("Nano Banana failed to return an image")

    async def generate_image(
        self,
        prompt: str,
        add_imperfections: bool = True,
    ) -> bytes:
        """Generate image using Gemini Nano Banana with automatic retries."""
        if add_imperfections:
            prompt = self._add_realism_imperfections(prompt)

        return await self._generate_image_internal(prompt)

    async def generate_recipe_images(
        self,
        dish_name: str,
        persona: BotPersona,
        cover_count: int = 2,
        step_count: int = 0,
    ) -> dict:
        """Generate full image set for a recipe."""
        result = {"cover_images": [], "step_images": []}

        # Generate main cover images
        for i in range(cover_count):
            prompt = self._build_dish_prompt(dish_name, persona, style="cover")
            try:
                image_bytes = await self.generate_image(prompt)
                result["cover_images"].append(image_bytes)
            except Exception as e:
                logger.error("cover_image_failed", error=str(e))

        # Generate process step images
        for i in range(step_count):
            prompt = self._build_dish_prompt(dish_name, persona, style="step")
            try:
                image_bytes = await self.generate_image(prompt)
                result["step_images"].append(image_bytes)
            except Exception as e:
                logger.error("step_image_failed", error=str(e))

        return result

    async def generate_log_image(
        self,
        dish_name: str,
        persona: BotPersona,
    ) -> Optional[bytes]:
        """Generate a casual log image."""
        prompt = self._build_dish_prompt(dish_name, persona, style="log")
        try:
            return await self.generate_image(prompt, add_imperfections=True)
        except Exception:
            return None

    def optimize_image(
        self,
        image_bytes: bytes,
        max_size: tuple = (1024, 1024),
        quality: int = 90,
    ) -> bytes:
        """Optimize and compress images for upload."""
        img = Image.open(io.BytesIO(image_bytes))
        if img.mode in ("RGBA", "P"):
            img = img.convert("RGB")
        img.thumbnail(max_size, Image.Resampling.LANCZOS)
        output = io.BytesIO()
        img.save(output, format="JPEG", quality=quality, optimize=True)
        return output.getvalue()