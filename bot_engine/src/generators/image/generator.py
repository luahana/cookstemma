"""Image generator using Gemini 3 Pro Image with DALL-E 3 fallback."""

import io
import random
from typing import Optional, List

import httpx
import structlog
from google import genai
from google.genai import types
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
    """Generate professional food images using Gemini 3 Pro (Nano Banana Pro)."""

    def __init__(
        self,
        openai_api_key: Optional[str] = None,
        gemini_api_key: Optional[str] = None,
    ) -> None:
        settings = get_settings()
        
        # Initialize Gemini 3 Pro Client
        self.gemini_client = genai.Client(
            api_key=gemini_api_key or settings.gemini_api_key
        )
        
        # Initialize OpenAI Client for DALL-E 3 fallback
        self.openai_client = AsyncOpenAI(
            api_key=openai_api_key or settings.openai_api_key
        )
        
        self._http_client: Optional[httpx.AsyncClient] = None

    async def _ensure_http_client(self) -> httpx.AsyncClient:
        """Ensure HTTP client is initialized for downloading DALL-E images."""
        if self._http_client is None:
            self._http_client = httpx.AsyncClient(timeout=120.0)
        return self._http_client

    async def close(self) -> None:
        """Close HTTP and API clients."""
        if self._http_client:
            await self._http_client.aclose()
            self._http_client = None

    def _build_dish_prompt(
        self,
        dish_name: str,
        persona: BotPersona,
        style: str = "cover",
    ) -> str:
        """Build detailed prompts optimized for Gemini 3 visual reasoning."""
        # Gemini 3 Pro benefits from clear, descriptive reasoning
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

    async def generate_with_gemini(
        self,
        prompt: str,
        res: str = "4K"
    ) -> bytes:
        """Generate high-fidelity 4K images using Gemini 3 Pro Image."""
        # Gemini 3 Pro Image supports up to 4K resolution
        response = await self.gemini_client.aio.models.generate_content(
            model="gemini-3-pro-image-preview",
            contents=[prompt],
            config=types.GenerateContentConfig(
                response_modalities=["IMAGE"],
                image_config=types.ImageConfig(
                    aspect_ratio="1:1",
                    image_size=res # Native 4K support
                )
            )
        )

        for part in response.parts:
            if part.inline_data:
                logger.info("gemini_3_pro_generated", res=res, prompt_preview=prompt[:50])
                return part.inline_data.data
        
        raise ValueError("Gemini 3 Pro failed to return an image part")

    async def generate_with_dalle(
        self,
        prompt: str,
        size: str = "1024x1024",
    ) -> bytes:
        """Generate image using DALL-E 3 as a high-reliability fallback."""
        response = await self.openai_client.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size=size, # type: ignore
            quality="standard",
            n=1,
        )

        image_url = response.data[0].url
        if not image_url:
            raise ValueError("No image URL in DALL-E response")

        client = await self._ensure_http_client()
        img_response = await client.get(image_url)
        img_response.raise_for_status()

        logger.info("dalle_fallback_triggered", prompt_preview=prompt[:50])
        return img_response.content

    @retry(
        retry=retry_if_exception_type(Exception),
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=2, min=5, max=60),
    )
    async def generate_image(
        self,
        prompt: str,
        size: str = "1024x1024",
        add_imperfections: bool = True,
    ) -> bytes:
        """Orchestrates generation: Gemini 3 Pro first, then DALL-E 3."""
        if add_imperfections:
            prompt = self._add_realism_imperfections(prompt)

        try:
            # Try 4K generation with Gemini 3 Pro first
            return await self.generate_with_gemini(prompt, res="4K")
        except Exception as e:
            logger.warning("gemini_3_pro_failed", error=str(e))
            # Fallback to DALL-E 3 if Gemini is blocked or unavailable
            return await self.generate_with_dalle(prompt, size)

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
        max_size: tuple = (2048, 2048), # Increased for Gemini 3 4K outputs
        quality: int = 90,
    ) -> bytes:
        """Optimize and compress high-res images."""
        img = Image.open(io.BytesIO(image_bytes))
        if img.mode in ("RGBA", "P"):
            img = img.convert("RGB")
        img.thumbnail(max_size, Image.Resampling.LANCZOS)
        output = io.BytesIO()
        img.save(output, format="JPEG", quality=quality, optimize=True)
        return output.getvalue()