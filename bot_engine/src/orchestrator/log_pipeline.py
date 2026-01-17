"""Cooking log generation pipeline."""

import random
from typing import List, Optional

import structlog

from ..api import PairingPlanetClient
from ..api.models import CreateLogRequest, LogOutcome, LogPost, Recipe
from ..config import get_settings
from ..generators import ImageGenerator, TextGenerator
from ..personas import BotPersona

logger = structlog.get_logger()


class LogPipeline:
    """Pipeline for generating and publishing cooking logs."""

    def __init__(
        self,
        api_client: PairingPlanetClient,
        text_generator: TextGenerator,
        image_generator: ImageGenerator,
    ) -> None:
        self.api = api_client
        self.text_gen = text_generator
        self.image_gen = image_generator
        self._settings = get_settings()

    def _select_outcome(self) -> LogOutcome:
        """Select a random outcome based on configured ratios."""
        rand = random.random()
        if rand < self._settings.log_success_ratio:
            return LogOutcome.SUCCESS
        elif rand < self._settings.log_success_ratio + self._settings.log_partial_ratio:
            return LogOutcome.PARTIAL
        else:
            return LogOutcome.FAILED

    async def generate_log(
        self,
        persona: BotPersona,
        recipe: Recipe,
        outcome: Optional[LogOutcome] = None,
        generate_image: bool = True,
    ) -> LogPost:
        """Generate and publish a cooking log.

        Args:
            persona: Bot persona to use
            recipe: Recipe that was "cooked"
            outcome: Cooking outcome (or auto-select based on ratios)
            generate_image: Whether to generate a log photo

        Returns:
            Created LogPost from API
        """
        # Auto-select outcome if not provided
        if outcome is None:
            outcome = self._select_outcome()

        logger.info(
            "log_pipeline_start",
            persona=persona.name,
            recipe=recipe.title,
            outcome=outcome.value,
        )

        # 1. Generate log text
        log_data = await self.text_gen.generate_log(
            persona=persona,
            recipe_title=recipe.title,
            recipe_description=recipe.description,
            outcome=outcome.value,
        )

        # 2. Generate image if enabled
        image_public_ids: List[str] = []
        if generate_image:
            img_bytes = await self.image_gen.generate_log_image(
                dish_name=recipe.title,
                persona=persona,
            )
            if img_bytes:
                optimized = self.image_gen.optimize_image(img_bytes)
                upload = await self.api.upload_image_bytes(
                    optimized,
                    filename=f"log_{recipe.title.replace(' ', '_')}.jpg",
                )
                image_public_ids.append(upload.public_id)

        # 3. Build log request (truncate content to 500 chars max)
        content = log_data.get("content", "")
        if len(content) > 500:
            content = content[:497] + "..."

        request = CreateLogRequest(
            recipe_public_id=recipe.public_id,
            title=log_data.get("title", f"Making {recipe.title}"),
            content=content,
            outcome=outcome,
            image_public_ids=image_public_ids,
            hashtags=log_data.get("hashtags", [])[:5],
        )

        # 4. Create log via API
        log = await self.api.create_log(request)

        logger.info(
            "log_pipeline_complete",
            persona=persona.name,
            log_id=log.public_id,
            recipe=recipe.title,
            outcome=outcome.value,
            has_image=len(image_public_ids) > 0,
        )
        return log

    async def generate_logs_for_recipe(
        self,
        personas: List[BotPersona],
        recipe: Recipe,
        count: int = 3,
        generate_images: bool = True,
    ) -> List[LogPost]:
        """Generate multiple logs for a single recipe from different personas.

        Args:
            personas: List of personas to use (will randomly select)
            recipe: Recipe to create logs for
            count: Number of logs to generate
            generate_images: Whether to generate images

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
                    generate_image=generate_images,
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
        generate_images: bool = True,
    ) -> List[LogPost]:
        """Generate logs for multiple recipes.

        Args:
            personas: List of personas to use
            recipes: Recipes to create logs for
            logs_per_recipe: Average logs per recipe
            generate_images: Whether to generate images

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
                generate_images=generate_images,
            )
            all_logs.extend(logs)

        logger.info(
            "batch_logs_complete",
            recipes=len(recipes),
            total_logs=len(all_logs),
        )
        return all_logs
