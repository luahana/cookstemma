"""Cooking log generation pipeline."""

import random
from typing import List, Optional

import structlog

from ..api import CookstemmaClient
from ..api.models import CreateLogRequest, LogPost, Recipe
from ..config import get_settings
from ..generators import ImageGenerator, TextGenerator
from ..personas import BotPersona

logger = structlog.get_logger()


class LogPipeline:
    """Pipeline for generating and publishing cooking logs."""

    def __init__(
        self,
        api_client: CookstemmaClient,
        text_generator: TextGenerator,
        image_generator: ImageGenerator,
    ) -> None:
        self.api = api_client
        self.text_gen = text_generator
        self.image_gen = image_generator
        self._settings = get_settings()

    def _select_rating(self, min_rating: int = 3, max_rating: int = 5) -> int:
        """Select a random rating biased towards positive (3-5).

        Args:
            min_rating: Minimum rating (1-5, default 3)
            max_rating: Maximum rating (1-5, default 5)

        Returns:
            Random rating between min_rating and max_rating
        """
        # Weights for ratings 1-5 (biased towards positive)
        all_weights = [0.05, 0.10, 0.20, 0.35, 0.30]  # 1-5 stars
        ratings = list(range(min_rating, max_rating + 1))
        weights = all_weights[min_rating - 1 : max_rating]
        # Normalize weights
        total = sum(weights)
        weights = [w / total for w in weights]
        return random.choices(ratings, weights=weights)[0]

    async def generate_log(
        self,
        persona: BotPersona,
        recipe: Recipe,
        rating: Optional[int] = None,
        num_images: int = 1,
        is_private: bool = False,
    ) -> LogPost:
        """Generate and publish a cooking log.

        Args:
            persona: Bot persona to use
            recipe: Recipe that was "cooked"
            rating: Star rating 1-5 (or auto-select if None)
            num_images: Number of images to generate (default: 1)
            is_private: Whether the log is private (default: False)

        Returns:
            Created LogPost from API
        """
        # Auto-select rating if not provided
        if rating is None:
            rating = self._select_rating()

        logger.info(
            "log_pipeline_start",
            persona=persona.name,
            recipe=recipe.title,
            rating=rating,
        )

        # 1. Generate log text
        log_data = await self.text_gen.generate_log(
            persona=persona,
            recipe_title=recipe.title,
            recipe_description=recipe.description,
            rating=rating,
        )

        # 2. Generate images (loop for num_images)
        image_public_ids: List[str] = []
        for i in range(num_images):
            img_bytes = await self.image_gen.generate_log_image(
                dish_name=recipe.title,
                persona=persona,
            )
            if img_bytes:
                optimized = self.image_gen.optimize_image(img_bytes)
                suffix = f"_{i + 1}" if num_images > 1 else ""
                upload = await self.api.upload_image_bytes(
                    optimized,
                    filename=f"log_{recipe.title.replace(' ', '_')}{suffix}.jpg",
                )
                image_public_ids.append(upload.public_id)

        # 3. Build log request (truncate content to 1000 chars max)
        content = log_data.get("content", "")
        if len(content) > 1000:
            content = content[:997] + "..."

        request = CreateLogRequest(
            recipe_public_id=recipe.public_id,
            content=content,
            rating=rating,
            image_public_ids=image_public_ids,
            hashtags=log_data.get("hashtags", [])[:5],
            is_private=is_private,
            original_language=persona.locale,
        )

        # 4. Create log via API
        log = await self.api.create_log(request)

        logger.info(
            "log_pipeline_complete",
            persona=persona.name,
            log_id=log.public_id,
            recipe=recipe.title,
            rating=rating,
            num_images=len(image_public_ids),
        )
        return log

    async def generate_logs_for_recipe(
        self,
        personas: List[BotPersona],
        recipe: Recipe,
        count: int = 3,
        num_images: int = 1,
    ) -> List[LogPost]:
        """Generate multiple logs for a single recipe from different personas.

        Args:
            personas: List of personas to use (will randomly select)
            recipe: Recipe to create logs for
            count: Number of logs to generate
            num_images: Number of images per log (default: 1)

        Returns:
            List of created LogPost objects
        """
        logs: List[LogPost] = []

        for i in range(count):
            persona = random.choice(personas)

            try:
                log = await self.generate_log(
                    persona=persona,
                    recipe=recipe,
                    num_images=num_images,
                )
                logs.append(log)
            except Exception as e:
                logger.error(
                    "log_generation_failed",
                    persona=persona.name,
                    recipe=recipe.title,
                    error=str(e),
                )

        logger.info(
            "logs_for_recipe_complete",
            recipe=recipe.title,
            count=len(logs),
        )
        return logs

    async def generate_batch_logs(
        self,
        personas: List[BotPersona],
        recipes: List[Recipe],
        logs_per_recipe: int = 2,
        num_images: int = 1,
    ) -> List[LogPost]:
        """Generate logs for multiple recipes.

        Args:
            personas: List of personas to use
            recipes: Recipes to create logs for
            logs_per_recipe: Average logs per recipe
            num_images: Number of images per log (default: 1)

        Returns:
            List of all created LogPost objects
        """
        all_logs: List[LogPost] = []

        for recipe in recipes:
            # Vary the number of logs per recipe
            count = max(1, logs_per_recipe + random.randint(-1, 1))

            logs = await self.generate_logs_for_recipe(
                personas=personas,
                recipe=recipe,
                count=count,
                num_images=num_images,
            )
            all_logs.extend(logs)

        logger.info(
            "batch_logs_complete",
            recipes=len(recipes),
            total_logs=len(all_logs),
        )
        return all_logs
