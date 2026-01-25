"""Image generator using Gemini Nano Banana (native image generation)."""
"""Image generator using Gemini Nano Banana (native image generation)."""

import io
import random
from typing import Dict, Optional

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


# Camera angle options for cover images
# Main angle (overhead) is used 50% of the time
# Other angles are used 50% of the time (randomly selected)
CAMERA_ANGLES: Dict[str, Dict[str, str]] = {
    # Main angle - overhead flat lay (current default, best for food photography)
    "overhead": {
        "angle_desc": "Shot directly from above",
        "composition": "Bird's eye view, dish perfectly centered, plate on table",
    },
    # Alternative angles
    "high_angle": {
        "angle_desc": "Shot from slightly above at 75-degree angle",
        "composition": "High angle view, dish centered with slight depth perspective",
    },
    "three_quarter": {
        "angle_desc": "Shot from 45-degree angle above",
        "composition": "Three-quarter overhead view, showing dish depth and layers",
    },
    "hero_angle": {
        "angle_desc": "Shot from 30-degree angle, classic food hero shot",
        "composition": "Hero angle view, emphasizing food height and textures",
    },
}

# Main angle name
MAIN_ANGLE = "overhead"

# Alternative angle names (excluding main)
ALTERNATIVE_ANGLES = [k for k in CAMERA_ANGLES.keys() if k != MAIN_ANGLE]


def select_random_angle(main_angle_probability: float = 0.5) -> str:
    """Randomly select a camera angle for a recipe.

    Args:
        main_angle_probability: Probability of selecting the main overhead angle (default 50%)

    Returns:
        Selected angle name (e.g., "overhead", "high_angle", etc.)
    """
    if random.random() < main_angle_probability:
        return MAIN_ANGLE
    else:
        return random.choice(ALTERNATIVE_ANGLES)


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
        logger.info("image_generator_init", model=self.model)

    async def close(self) -> None:
        """Close any resources (kept for interface compatibility)."""
        pass

    def _build_dish_prompt(
        self,
        dish_name: str,
        persona: BotPersona,
        style: str = "cover",
        angle: Optional[str] = None,
    ) -> str:
        """Build detailed prompts for food image generation.

        Args:
            dish_name: Name of the dish to photograph
            persona: Bot persona for kitchen style
            style: Image style - "cover", "step", or "log"
            angle: Camera angle name for cover images (default: "overhead")

        Returns:
            Detailed prompt string for image generation
        """
        if style == "cover":
            # Get camera angle config (default to overhead if not specified or invalid)
            angle_name = angle if angle in CAMERA_ANGLES else MAIN_ANGLE
            angle_config = CAMERA_ANGLES[angle_name]

            base_prompt = f"Professional food photography of {dish_name}. {angle_config['angle_desc']}. Food centered in frame. No people, no hands, no human body parts. No text, no words, no letters, no writing, no watermarks, no labels, no captions."

            return f"""{base_prompt}
{persona.kitchen_style_prompt}
Composition: {angle_config['composition']}.
Lighting: Soft natural daylight, high-detail food textures.
Style: Food magazine, appetizing, professional."""

        # For step and log, always use overhead angle for consistency
        base_prompt = f"Overhead flat lay food photography of {dish_name}. Shot directly from above. Food centered in frame. No people, no hands, no human body parts. No text, no words, no letters, no writing, no watermarks, no labels, no captions."

        if style == "step":
            return f"""{base_prompt}
{persona.kitchen_style_prompt}
Composition: Top-down view, ingredients arranged on cutting board.
Lighting: Clean kitchen, natural lighting."""

        elif style == "log":
            return f"""{base_prompt}
{persona.kitchen_style_prompt}
Style: Casual overhead food photo, home-cooked feel.
Composition: Top-down, plate centered on table."""

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

    async def _generate_image_internal(
        self,
        prompt: str,
    ) -> bytes:
        """Generate image using Gemini Nano Banana."""
        try:
            logger.debug("nano_banana_request", model=self.model, prompt_len=len(prompt))
            response = await self.client.aio.models.generate_content(
                model=self.model,
                contents=[prompt],
                config=types.GenerateContentConfig(
                    response_modalities=["IMAGE"],
                    image_config=types.ImageConfig(
                        aspect_ratio="16:9",
                    ),
                ),
            )

            # Debug: log response structure
            logger.debug(
                "nano_banana_response",
                has_candidates=bool(response.candidates) if hasattr(response, 'candidates') else None,
                has_parts=bool(response.parts) if hasattr(response, 'parts') else None,
            )

            # Extract image from response parts
            if response.parts:
                for part in response.parts:
                    if part.inline_data is not None:
                        logger.info(
                            "nano_banana_generated",
                            model=self.model,
                            prompt_preview=prompt[:50],
                        )
                        return part.inline_data.data

            # Try candidates structure
            if hasattr(response, 'candidates') and response.candidates:
                for i, candidate in enumerate(response.candidates):
                    logger.debug(
                        "nano_banana_candidate",
                        index=i,
                        candidate_type=type(candidate).__name__,
                        has_content=hasattr(candidate, 'content'),
                        content_type=type(candidate.content).__name__ if hasattr(candidate, 'content') and candidate.content else None,
                    )
                    if hasattr(candidate, 'content') and candidate.content:
                        content = candidate.content
                        logger.debug(
                            "nano_banana_content",
                            has_parts=hasattr(content, 'parts'),
                            parts_len=len(content.parts) if hasattr(content, 'parts') and content.parts else 0,
                        )
                        if hasattr(content, 'parts') and content.parts:
                            for j, part in enumerate(content.parts):
                                logger.debug(
                                    "nano_banana_part",
                                    index=j,
                                    part_type=type(part).__name__,
                                    has_inline_data=hasattr(part, 'inline_data'),
                                    has_data=hasattr(part, 'data'),
                                    part_attrs=dir(part)[:20],
                                )
                                if hasattr(part, 'inline_data') and part.inline_data:
                                    logger.info(
                                        "nano_banana_generated",
                                        model=self.model,
                                        prompt_preview=prompt[:50],
                                    )
                                    return part.inline_data.data
                                # Try direct data attribute
                                if hasattr(part, 'data') and part.data:
                                    logger.info(
                                        "nano_banana_generated_data",
                                        model=self.model,
                                        prompt_preview=prompt[:50],
                                    )
                                    return part.data

            # Log what we got for debugging
            logger.error(
                "nano_banana_no_image",
                response_type=type(response).__name__,
            )
            raise ValueError("Nano Banana failed to return an image")
        except Exception as e:
            logger.error("nano_banana_error", error=str(e), error_type=type(e).__name__)
            raise

    @retry(
        retry=retry_if_exception_type(Exception),
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=2, min=5, max=30),
        before_sleep=lambda retry_state: logger.warning(
            "nano_banana_retry",
            attempt=retry_state.attempt_number,
            wait=retry_state.next_action.sleep,
            error=str(retry_state.outcome.exception()) if retry_state.outcome else None,
        ),
    )
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
        """Generate full image set for a recipe.

        Camera angle is randomly selected once per recipe:
        - 50% chance of main overhead angle
        - 50% chance of alternative angle (high_angle, three_quarter, hero_angle)

        All cover images for the same recipe use the same angle.

        Args:
            dish_name: Name of the dish
            persona: Bot persona for kitchen style
            cover_count: Number of cover images to generate
            step_count: Number of step images to generate

        Returns:
            Dict with "cover_images" and "step_images" lists of bytes
        """
        result = {"cover_images": [], "step_images": []}

        # Select a random camera angle for this recipe (50% overhead, 50% alternative)
        selected_angle = select_random_angle(main_angle_probability=0.5)
        logger.info(
            "selected_camera_angle",
            dish=dish_name,
            angle=selected_angle,
        )

        # Generate cover images (all use the same angle)
        for i in range(cover_count):
            prompt = self._build_dish_prompt(
                dish_name, persona, style="cover", angle=selected_angle
            )
            try:
                image_bytes = await self.generate_image(prompt)
                result["cover_images"].append(image_bytes)
            except Exception as e:
                logger.error("cover_image_failed", index=i, angle=selected_angle, error=str(e))

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