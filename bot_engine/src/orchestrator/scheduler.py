"""Content generation scheduler for ongoing content drip."""

import asyncio
import random
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Set

import structlog
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.triggers.interval import IntervalTrigger

from ..api import PairingPlanetClient
from ..api.models import Recipe
from ..config import get_settings
from ..generators import ImageGenerator, TextGenerator
from ..personas import BotPersona, get_persona_registry
from .log_pipeline import LogPipeline
from .recipe_pipeline import RecipePipeline

logger = structlog.get_logger()


class ContentScheduler:
    """Scheduler for automated content generation."""

    def __init__(
        self,
        persona_api_keys: Dict[str, str],
        generate_images: bool = True,
    ) -> None:
        """Initialize scheduler.

        Args:
            persona_api_keys: Dict mapping persona name to API key
            generate_images: Whether to generate AI images
        """
        self._settings = get_settings()
        self._persona_api_keys = persona_api_keys
        self._generate_images = generate_images
        self._scheduler: Optional[AsyncIOScheduler] = None
        self._registry = get_persona_registry()
        self._created_recipes: List[Recipe] = []
        self._used_food_names: Set[str] = set()

    def _get_configured_personas(self) -> List[BotPersona]:
        """Get personas that have API keys configured."""
        personas = []
        for name, api_key in self._persona_api_keys.items():
            persona = self._registry.get(name)
            if persona:
                persona.api_key = api_key
                personas.append(persona)
        return personas

    async def _create_clients(
        self,
        persona: BotPersona,
    ) -> tuple:
        """Create authenticated clients for a persona."""
        api_client = PairingPlanetClient()
        await api_client.login_persona(persona)

        text_gen = TextGenerator()
        image_gen = ImageGenerator()

        return api_client, text_gen, image_gen

    async def generate_daily_content(self) -> None:
        """Generate daily content quota (recipes and logs)."""
        personas = self._get_configured_personas()
        if not personas:
            logger.warning("no_configured_personas")
            return

        logger.info(
            "daily_content_start",
            recipes_target=self._settings.recipes_per_day,
            logs_target=self._settings.logs_per_day,
            personas=len(personas),
        )

        # Split work across personas
        recipes_per_persona = max(
            1,
            self._settings.recipes_per_day // len(personas),
        )

        all_new_recipes: List[Recipe] = []

        for persona in personas:
            try:
                api_client, text_gen, image_gen = await self._create_clients(persona)

                async with api_client:
                    recipe_pipeline = RecipePipeline(api_client, text_gen, image_gen)

                    # Generate recipes
                    recipes = await recipe_pipeline.generate_batch_recipes(
                        persona=persona,
                        count=recipes_per_persona,
                        variant_ratio=self._settings.variant_ratio,
                        generate_images=self._generate_images,
                    )
                    all_new_recipes.extend(recipes)
                    self._created_recipes.extend(recipes)

                await image_gen.close()

            except Exception as e:
                logger.error(
                    "persona_content_failed",
                    persona=persona.name,
                    error=str(e),
                )

        # Generate logs distributed across all new and existing recipes
        if all_new_recipes or self._created_recipes:
            await self._generate_daily_logs(personas, all_new_recipes)

        logger.info(
            "daily_content_complete",
            new_recipes=len(all_new_recipes),
            total_tracked=len(self._created_recipes),
        )

    async def _generate_daily_logs(
        self,
        personas: List[BotPersona],
        new_recipes: List[Recipe],
    ) -> None:
        """Generate daily log quota."""
        logs_remaining = self._settings.logs_per_day

        # 70% of logs for new recipes, 30% for existing
        new_recipe_logs = int(logs_remaining * 0.7)
        existing_recipe_logs = logs_remaining - new_recipe_logs

        for persona in personas:
            try:
                api_client, text_gen, image_gen = await self._create_clients(persona)

                async with api_client:
                    log_pipeline = LogPipeline(api_client, text_gen, image_gen)

                    # Logs for new recipes
                    if new_recipes:
                        recipes_to_log = random.sample(
                            new_recipes,
                            min(new_recipe_logs, len(new_recipes)),
                        )
                        for recipe in recipes_to_log:
                            await log_pipeline.generate_log(
                                persona=persona,
                                recipe=recipe,
                                generate_image=self._generate_images,
                            )

                    # Logs for older recipes
                    if self._created_recipes and existing_recipe_logs > 0:
                        older_recipes = random.sample(
                            self._created_recipes,
                            min(existing_recipe_logs, len(self._created_recipes)),
                        )
                        for recipe in older_recipes:
                            await log_pipeline.generate_log(
                                persona=persona,
                                recipe=recipe,
                                generate_image=self._generate_images,
                            )

                await image_gen.close()
                break  # One persona handles logs for this run

            except Exception as e:
                logger.error(
                    "log_generation_failed",
                    persona=persona.name,
                    error=str(e),
                )

    async def run_initial_seed(
        self,
        total_recipes: int = 500,
        total_logs: int = 2000,
    ) -> None:
        """Run initial content seeding.

        Args:
            total_recipes: Target number of recipes (50% originals, 50% variants)
            total_logs: Target number of cooking logs
        """
        personas = self._get_configured_personas()
        if not personas:
            raise RuntimeError("No personas configured with API keys")

        logger.info(
            "initial_seed_start",
            target_recipes=total_recipes,
            target_logs=total_logs,
            personas=len(personas),
        )

        recipes_per_persona = total_recipes // len(personas)
        logs_per_recipe = total_logs // total_recipes

        all_recipes: List[Recipe] = []

        for persona in personas:
            logger.info("seeding_persona", name=persona.name)

            try:
                api_client, text_gen, image_gen = await self._create_clients(persona)

                async with api_client:
                    recipe_pipeline = RecipePipeline(api_client, text_gen, image_gen)
                    log_pipeline = LogPipeline(api_client, text_gen, image_gen)

                    # Generate recipes
                    recipes = await recipe_pipeline.generate_batch_recipes(
                        persona=persona,
                        count=recipes_per_persona,
                        variant_ratio=0.5,
                        generate_images=self._generate_images,
                    )
                    all_recipes.extend(recipes)

                    # Generate logs for this persona's recipes
                    await log_pipeline.generate_batch_logs(
                        personas=personas,
                        recipes=recipes,
                        logs_per_recipe=logs_per_recipe,
                        generate_images=self._generate_images,
                    )

                await image_gen.close()

            except Exception as e:
                logger.error(
                    "seed_persona_failed",
                    persona=persona.name,
                    error=str(e),
                )

        self._created_recipes = all_recipes

        logger.info(
            "initial_seed_complete",
            total_recipes=len(all_recipes),
        )

    def start_scheduler(
        self,
        daily_time: str = "09:00",
        timezone: str = "Asia/Seoul",
    ) -> None:
        """Start the content generation scheduler.

        Args:
            daily_time: Time to run daily generation (HH:MM)
            timezone: Timezone for scheduling
        """
        self._scheduler = AsyncIOScheduler(timezone=timezone)

        hour, minute = map(int, daily_time.split(":"))

        # Daily content generation
        self._scheduler.add_job(
            self.generate_daily_content,
            CronTrigger(hour=hour, minute=minute),
            id="daily_content",
            name="Daily content generation",
        )

        self._scheduler.start()
        logger.info(
            "scheduler_started",
            daily_time=daily_time,
            timezone=timezone,
        )

    def stop_scheduler(self) -> None:
        """Stop the scheduler."""
        if self._scheduler:
            self._scheduler.shutdown()
            self._scheduler = None
            logger.info("scheduler_stopped")
