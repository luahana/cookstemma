"""Image generator using DALL-E."""

import io
from typing import Optional

import httpx
import structlog
from openai import AsyncOpenAI
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
    """Generate food images using DALL-E."""

    def __init__(
        self,
        openai_api_key: Optional[str] = None,
    ) -> None:
        settings = get_settings()
        self.openai_client = AsyncOpenAI(
            api_key=openai_api_key or settings.openai_api_key
        )
        self._http_client: Optional[httpx.AsyncClient] = None

    async def _ensure_http_client(self) -> httpx.AsyncClient:
        """Ensure HTTP client is initialized."""
        if self._http_client is None:
            self._http_client = httpx.AsyncClient(timeout=120.0)
        return self._http_client

    async def close(self) -> None:
        """Close HTTP client."""
        if self._http_client:
            await self._http_client.aclose()
            self._http_client = None

    def _build_dish_prompt(
        self,
        dish_name: str,
        persona: BotPersona,
        style: str = "cover",
    ) -> str:
        """Build prompt for dish image generation."""
        base_prompt = f"Professional food photography of {dish_name}."

        if style == "cover":
            # Finished dish, beautifully plated
            return f"""{base_prompt}
{persona.kitchen_style_prompt}
Beautifully plated, appetizing, natural lighting, shallow depth of field.
High-quality food photography style, 4K, detailed textures."""

        elif style == "step":
            # In-progress cooking shot
            return f"""{base_prompt}
{persona.kitchen_style_prompt}
Cooking in progress, hands visible, ingredients on counter.
Realistic home cooking scene, natural lighting."""

        elif style == "log":
            # More casual, "user photo" style
            return f"""{base_prompt}
{persona.kitchen_style_prompt}
Casual food photo style, slightly imperfect, like a real user photo.
Shot with phone camera, natural indoor lighting, realistic presentation."""

        return base_prompt

    def _add_realism_imperfections(self, prompt: str) -> str:
        """Add subtle imperfections to make images more realistic."""
        import random

        imperfections = [
            "slight sauce drip on plate edge",
            "one herb leaf slightly wilted",
            "steam rising from hot food",
            "napkin slightly crumpled in background",
            "fingerprint smudge on plate rim",
            "uneven browning on surface",
            "small bubble in sauce",
            "garnish placed slightly off-center",
        ]

        selected = random.sample(imperfections, k=min(2, len(imperfections)))
        return f"{prompt}\nSubtle realistic details: {', '.join(selected)}."

    @retry(
        retry=retry_if_exception_type(Exception),
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=2, min=5, max=60),
    )
    async def generate_with_dalle(
        self,
        prompt: str,
        size: str = "1024x1024",
    ) -> bytes:
        """Generate image using DALL-E 3."""
        response = await self.openai_client.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size=size,  # type: ignore
            quality="standard",
            n=1,
        )

        image_url = response.data[0].url
        if not image_url:
            raise ValueError("No image URL in DALL-E response")

        # Download the image
        client = await self._ensure_http_client()
        img_response = await client.get(image_url)
        img_response.raise_for_status()

        logger.info("dalle_image_generated", prompt_preview=prompt[:100])
        return img_response.content

    async def generate_image(
        self,
        prompt: str,
        size: str = "1024x1024",
        add_imperfections: bool = True,
    ) -> bytes:
        """Generate image using DALL-E."""
        if add_imperfections:
            prompt = self._add_realism_imperfections(prompt)

        return await self.generate_with_dalle(prompt, size)

    async def generate_recipe_images(
        self,
        dish_name: str,
        persona: BotPersona,
        cover_count: int = 2,
        step_count: int = 0,
    ) -> dict:
        """Generate images for a recipe.

        Returns:
            dict with "cover_images" and "step_images" lists of bytes
        """
        result = {"cover_images": [], "step_images": []}

        # Generate cover images
        for i in range(cover_count):
            prompt = self._build_dish_prompt(dish_name, persona, style="cover")
            try:
                image_bytes = await self.generate_image(prompt)
                result["cover_images"].append(image_bytes)
                logger.info(
                    "cover_image_generated",
                    dish=dish_name,
                    index=i + 1,
                    total=cover_count,
                )
            except Exception as e:
                logger.error("cover_image_failed", dish=dish_name, error=str(e))

        # Generate step images if requested
        for i in range(step_count):
            prompt = self._build_dish_prompt(dish_name, persona, style="step")
            try:
                image_bytes = await self.generate_image(prompt)
                result["step_images"].append(image_bytes)
                logger.info(
                    "step_image_generated",
                    dish=dish_name,
                    index=i + 1,
                    total=step_count,
                )
            except Exception as e:
                logger.error("step_image_failed", dish=dish_name, error=str(e))

        return result

    async def generate_log_image(
        self,
        dish_name: str,
        persona: BotPersona,
    ) -> Optional[bytes]:
        """Generate a single log image (casual style)."""
        prompt = self._build_dish_prompt(dish_name, persona, style="log")
        try:
            return await self.generate_image(prompt, add_imperfections=True)
        except Exception as e:
            logger.error("log_image_failed", dish=dish_name, error=str(e))
            return None

    def optimize_image(
        self,
        image_bytes: bytes,
        max_size: tuple = (1200, 1200),
        quality: int = 85,
    ) -> bytes:
        """Optimize image for upload (resize and compress)."""
        img = Image.open(io.BytesIO(image_bytes))

        # Convert to RGB if necessary (handles PNG with transparency)
        if img.mode in ("RGBA", "P"):
            img = img.convert("RGB")

        # Resize if larger than max_size
        img.thumbnail(max_size, Image.Resampling.LANCZOS)

        # Save with optimization
        output = io.BytesIO()
        img.save(output, format="JPEG", quality=quality, optimize=True)
        return output.getvalue()
