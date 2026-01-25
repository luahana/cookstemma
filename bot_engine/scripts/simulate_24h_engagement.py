#!/usr/bin/env python3
"""24-Hour User Engagement Simulation Script.

This script orchestrates a continuous 24-hour simulation of user engagement
with constant activity patterns including:
- Recipe creation
- Cooking log generation
- Social interactions (follows, saves, comments, likes)

Activity is distributed evenly across all hours since this is a global service
with users distributed across timezones.

Usage:
    cd bot_engine

    # Run with default settings (24h, medium volume)
    python scripts/simulate_24h_engagement.py

    # Custom volume
    python scripts/simulate_24h_engagement.py --recipes 100 --logs 300 --social 500

    # Shorter duration for testing
    python scripts/simulate_24h_engagement.py --duration-hours 1 --recipes 2 --logs 5 --social 10

    # Dry run (show schedule without executing)
    python scripts/simulate_24h_engagement.py --dry-run

Prerequisites:
    - Backend running at http://localhost:4000
    - GEMINI_API_KEY in .env
    - BOT_INTERNAL_SECRET in .env
    - Active bot personas in database
"""

import argparse
import asyncio
import os
import random
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv
load_dotenv()

from src.api import CookstemmaClient
from src.api.models import Comment, LogPost, Recipe
from src.config import get_settings
from src.generators import TextGenerator, ImageGenerator
from src.orchestrator.recipe_pipeline import RecipePipeline
from src.personas import BotPersona, get_persona_registry


# ==================== Data Classes ====================


@dataclass
class HourlyActivity:
    """Activity to perform in a given hour."""
    hour: int  # 0-23
    recipes: int
    recipes_original: int = 0
    recipes_variant: int = 0
    logs: int = 0
    follows: int = 0
    recipe_saves: int = 0
    log_saves: int = 0
    comments: int = 0
    replies: int = 0
    comment_likes: int = 0

    @property
    def total_social(self) -> int:
        """Total social interactions for this hour."""
        return (
            self.follows + self.recipe_saves + self.log_saves +
            self.comments + self.replies + self.comment_likes
        )


@dataclass
class SimulationStats:
    """Statistics tracking for the simulation."""
    recipes_created: int = 0
    recipes_original: int = 0
    recipes_variant: int = 0
    logs_created: int = 0
    follows_done: int = 0
    recipe_saves_done: int = 0
    log_saves_done: int = 0
    comments_created: int = 0
    replies_created: int = 0
    comment_likes_done: int = 0
    failed_actions: int = 0
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None

    @property
    def total_social(self) -> int:
        """Total social interactions completed."""
        return (
            self.follows_done + self.recipe_saves_done + self.log_saves_done +
            self.comments_created + self.replies_created + self.comment_likes_done
        )

    @property
    def success_rate(self) -> float:
        """Calculate success rate as percentage."""
        total_attempted = (
            self.recipes_created + self.logs_created + self.total_social + self.failed_actions
        )
        if total_attempted == 0:
            return 0.0
        return ((total_attempted - self.failed_actions) / total_attempted) * 100


# ==================== Activity Scheduler ====================


class ActivityScheduler:
    """Calculates activity distribution across 24 hours with constant global activity."""

    def __init__(
        self,
        total_recipes: int,
        total_logs: int,
        total_social: int,
        duration_hours: int = 24,
        variant_ratio: float = 0.5,
    ) -> None:
        self.total_recipes = total_recipes
        self.total_logs = total_logs
        self.total_social = total_social
        self.duration_hours = duration_hours
        self.variant_ratio = variant_ratio
        self.settings = get_settings()

    def get_hourly_schedule(self) -> List[HourlyActivity]:
        """Generate complete hourly schedule with even distribution.

        Returns constant activity throughout the day since this is a global service
        with users distributed across timezones.

        Returns:
            List of HourlyActivity for each hour
        """
        schedule = []

        # Calculate base amounts per hour (evenly distributed)
        recipes_per_hour = self.total_recipes // self.duration_hours
        logs_per_hour = self.total_logs // self.duration_hours
        social_per_hour = self.total_social // self.duration_hours

        for hour in range(self.duration_hours):
            # Split recipes into original and variant
            variants_this_hour = round(recipes_per_hour * self.variant_ratio)
            originals_this_hour = recipes_per_hour - variants_this_hour

            # Distribute social actions according to ratios
            follows = int(social_per_hour * self.settings.follow_ratio)
            recipe_saves = int(social_per_hour * self.settings.recipe_save_ratio)
            log_saves = int(social_per_hour * self.settings.log_save_ratio)
            comments = int(social_per_hour * self.settings.comment_ratio)
            replies = int(social_per_hour * self.settings.reply_ratio)
            comment_likes = int(social_per_hour * self.settings.comment_like_ratio)

            schedule.append(
                HourlyActivity(
                    hour=hour,
                    recipes=recipes_per_hour,
                    recipes_original=originals_this_hour,
                    recipes_variant=variants_this_hour,
                    logs=logs_per_hour,
                    follows=follows,
                    recipe_saves=recipe_saves,
                    log_saves=log_saves,
                    comments=comments,
                    replies=replies,
                    comment_likes=comment_likes,
                )
            )

        # Adjust for rounding errors - distribute remainder evenly
        self._adjust_for_rounding(schedule)

        return schedule

    def _adjust_for_rounding(self, schedule: List[HourlyActivity]) -> None:
        """Adjust schedule to match exact totals after rounding."""
        # Distribute any remainder evenly across all hours
        all_indices = list(range(len(schedule)))

        # Adjust recipes (maintain original/variant ratio)
        current_recipes = sum(act.recipes for act in schedule)
        remaining_recipes = self.total_recipes - current_recipes
        if remaining_recipes > 0:
            for i in range(remaining_recipes):
                idx = all_indices[i % len(all_indices)]
                schedule[idx].recipes += 1
                # Maintain the ratio when adding remainder
                if self.variant_ratio >= 0.5:
                    schedule[idx].recipes_variant += 1
                else:
                    schedule[idx].recipes_original += 1

        # Adjust logs
        current_logs = sum(act.logs for act in schedule)
        remaining_logs = self.total_logs - current_logs
        if remaining_logs > 0:
            for i in range(remaining_logs):
                idx = all_indices[i % len(all_indices)]
                schedule[idx].logs += 1

        # Adjust social (add to follows)
        current_social = sum(act.total_social for act in schedule)
        remaining_social = self.total_social - current_social
        if remaining_social > 0:
            for i in range(remaining_social):
                idx = all_indices[i % len(all_indices)]
                schedule[idx].follows += 1


# ==================== Content Orchestrator ====================


class ContentOrchestrator:
    """Manages content creation (recipes and logs) via subprocess calls."""

    def __init__(self, scripts_dir: Path) -> None:
        self.scripts_dir = scripts_dir
        self.settings = get_settings()
        self._parent_recipe_pool: List[Recipe] = []

    async def fetch_parent_recipes(
        self, client: CookstemmaClient, min_count: int = 20
    ) -> int:
        """Fetch existing recipes from database to use as parents for variants.

        Args:
            client: API client for fetching recipes
            min_count: Minimum number of recipes to fetch

        Returns:
            Number of recipes cached in the pool
        """
        print(f"    Fetching parent recipes (target: {min_count})...")

        page = 0
        page_size = 20

        while len(self._parent_recipe_pool) < min_count:
            try:
                # Fetch a page of recipes
                recipes = await client.get_recipes(page=page, size=page_size)

                if not recipes:
                    break

                # Add all recipes to pool - list API doesn't include ingredients/steps
                # The variant pipeline will fetch full details when creating variants
                self._parent_recipe_pool.extend(recipes)

                # If we got fewer recipes than requested, we've reached the end
                if len(recipes) < page_size:
                    break

                page += 1

            except Exception as e:
                print(f"      Warning: Failed to fetch recipes page {page}: {e}")
                break

        count = len(self._parent_recipe_pool)
        print(f"    ✓ Cached {count} parent recipes")
        return count

    async def create_recipes(
        self,
        count: int,  # Original recipes
        persona_names: List[str],
        variant_count: int = 0,  # NEW: Variant recipes
        personas: Optional[List[BotPersona]] = None,  # NEW: For variants
        client: Optional[CookstemmaClient] = None,  # NEW: For variants
    ) -> Tuple[int, int]:  # Returns (originals, variants)
        """Create original and variant recipes.

        Args:
            count: Number of original recipes to create
            persona_names: List of persona names to use for originals
            variant_count: Number of variant recipes to create
            personas: List of personas for variants (required if variant_count > 0)
            client: API client for variants (required if variant_count > 0)

        Returns:
            Tuple of (successful_originals, successful_variants)
        """
        success_originals = 0
        success_variants = 0

        # Create original recipes via subprocess
        if count > 0:
            print(f"      Creating {count} original recipes...")

            for _ in range(count):
                try:
                    # Call create_recipes.py script
                    result = subprocess.run(
                        [
                            sys.executable,
                            str(self.scripts_dir / "create_recipes.py"),
                            "--count", "1",
                            "--cover", "1",
                        ],
                        cwd=self.scripts_dir.parent,
                        capture_output=True,
                        text=True,
                        encoding='utf-8',
                        errors='replace',  # Replace problematic characters instead of failing
                        timeout=120,
                    )

                    if result.returncode == 0:
                        success_originals += 1
                    else:
                        print(f"        Recipe creation failed: {result.stderr[:200]}")

                    # Small delay between creations
                    await asyncio.sleep(2)

                except subprocess.TimeoutExpired:
                    print("        Recipe creation timed out")
                except Exception as e:
                    print(f"        Recipe creation error: {e}")

        # Create variant recipes
        if variant_count > 0 and personas and client:
            # Refresh parent pool to include newly created original recipes
            if success_originals > 0 and not self._parent_recipe_pool:
                print("      Refreshing parent recipe pool with new recipes...")
                await self.fetch_parent_recipes(client, min_count=1)

            success_variants = await self.create_variant_recipes(
                count=variant_count,
                personas=personas,
                client=client,
            )

        return (success_originals, success_variants)

    async def create_variant_recipes(
        self,
        count: int,
        personas: List[BotPersona],
        client: CookstemmaClient,
        cross_cultural_ratio: float = 0.8,
    ) -> int:
        """Create variant recipes using RecipePipeline with cross-cultural adaptation.

        Args:
            count: Number of variants to create
            personas: List of personas to randomly assign
            client: API client for recipe operations
            cross_cultural_ratio: Probability of selecting foreign cuisine for adaptation

        Returns:
            Number of successfully created variants
        """
        if count == 0:
            return 0

        if not self._parent_recipe_pool:
            print("      Warning: No parent recipes available, skipping variants")
            return 0

        print(f"      Creating {count} variant recipes (cross-cultural ratio: {cross_cultural_ratio:.0%})...")

        # Standard variation types (used when NOT doing cross-cultural adaptation)
        standard_variation_types = [
            "healthier", "budget", "quick", "vegetarian", "spicier",
            "kid_friendly", "gourmet", "vegan", "high_protein", "low_carb"
        ]

        successes = 0
        cross_cultural_count = 0

        # Initialize generators for the pipeline
        text_gen = TextGenerator()
        image_gen = ImageGenerator()

        for _ in range(count):
            try:
                # Pick random persona
                persona = random.choice(personas)

                # Initialize pipeline with generators
                pipeline = RecipePipeline(
                    api_client=client,
                    text_generator=text_gen,
                    image_generator=image_gen,
                )

                # Use intelligent parent selection (prefers foreign cuisines)
                parent_recipe = pipeline.select_parent_for_cross_cultural(
                    persona=persona,
                    available_recipes=self._parent_recipe_pool,
                    cross_cultural_ratio=cross_cultural_ratio,
                )

                if not parent_recipe:
                    print("        No suitable parent recipe found")
                    continue

                # Fetch full parent recipe details (list API doesn't include ingredients/steps)
                full_parent_recipe = await client.get_recipe(parent_recipe.public_id)

                # Determine if this is a cross-cultural adaptation
                is_cross_cultural = (
                    full_parent_recipe.cooking_style
                    and full_parent_recipe.cooking_style != persona.cooking_style
                )

                # Select variation type and cultural context
                if is_cross_cultural:
                    variation_type = "cultural_adaptation"
                    cultural_context = pipeline.get_cultural_context(
                        source_style=full_parent_recipe.cooking_style,
                        target_style=persona.cooking_style,
                        dietary_focus=persona.dietary_focus.value,
                    )
                    cross_cultural_count += 1
                else:
                    variation_type = random.choice(standard_variation_types)
                    cultural_context = None

                # Generate variant with cultural context
                variant_recipe = await pipeline.generate_variant_recipe(
                    persona=persona,
                    parent_recipe=full_parent_recipe,
                    variation_type=variation_type,
                    generate_images=True,
                    cultural_context=cultural_context,
                )

                if variant_recipe:
                    successes += 1
                    # Add the new variant to the pool so it can be a parent too
                    self._parent_recipe_pool.append(variant_recipe)
                else:
                    print("        Variant creation returned None")

                # Small delay between creations
                await asyncio.sleep(2)

            except Exception as e:
                print(f"        Variant creation error: {e}")

        print(f"      ✓ Created {successes} variants ({cross_cultural_count} cross-cultural)")
        return successes

    async def create_logs(
        self,
        count: int,
        persona_names: List[str],
    ) -> int:
        """Create cooking logs by calling create_cooking_logs.py script.

        Args:
            count: Number of logs to create
            persona_names: List of persona names to use

        Returns:
            Number of successfully created logs
        """
        if count == 0:
            return 0

        print(f"      Creating {count} logs...")

        successes = 0

        for _ in range(count):
            try:
                # Call create_cooking_logs.py script with random recipes
                result = subprocess.run(
                    [
                        sys.executable,
                        str(self.scripts_dir / "create_cooking_logs.py"),
                        "--random-recipes",
                        "--count", "1",
                    ],
                    cwd=self.scripts_dir.parent,
                    capture_output=True,
                    text=True,
                    encoding='utf-8',
                    errors='replace',  # Replace problematic characters instead of failing
                    timeout=120,
                )

                if result.returncode == 0:
                    successes += 1
                else:
                    print(f"        Log creation failed: {result.stderr[:200]}")

                # Small delay between creations
                await asyncio.sleep(2)

            except subprocess.TimeoutExpired:
                print("        Log creation timed out")
            except Exception as e:
                print(f"        Log creation error: {e}")

        return successes


# ==================== Social Interaction Engine ====================


class SocialInteractionEngine:
    """Performs social interactions using CookstemmaClient."""

    def __init__(self) -> None:
        self.settings = get_settings()
        self._recent_recipes: List[Recipe] = []
        self._recent_logs: List[LogPost] = []
        self._recent_comments: List[Comment] = []

    async def random_follows(
        self,
        count: int,
        personas: List[BotPersona],
        client: CookstemmaClient,
    ) -> int:
        """Perform random follow actions between personas.

        Args:
            count: Number of follows to perform
            personas: List of personas to use
            client: Authenticated API client

        Returns:
            Number of successful follows
        """
        if count == 0 or len(personas) < 2:
            return 0

        # Filter to personas with valid user_public_id
        valid_personas = [p for p in personas if p.user_public_id]
        if len(valid_personas) < 2:
            return 0

        successes = 0

        for _ in range(count):
            try:
                # Pick two random personas
                follower, target = random.sample(valid_personas, 2)

                # Authenticate as follower
                await client.login_by_persona(follower.name)

                # Follow target
                success = await client.follow_user(target.user_public_id)
                if success:
                    successes += 1

                await asyncio.sleep(0.5)

            except Exception as e:
                print(f"        Follow error: {e}")

        return successes

    async def save_recent_recipes(
        self,
        count: int,
        personas: List[BotPersona],
        client: CookstemmaClient,
    ) -> int:
        """Save recent recipes from random personas.

        Args:
            count: Number of saves to perform
            personas: List of personas
            client: API client

        Returns:
            Number of successful saves
        """
        if count == 0:
            return 0

        # Refresh recent recipes if needed
        if not self._recent_recipes:
            self._recent_recipes = await client.get_recipes(page=0, size=20)

        if not self._recent_recipes:
            return 0

        successes = 0

        for _ in range(count):
            try:
                persona = random.choice(personas)
                recipe = random.choice(self._recent_recipes)

                await client.login_by_persona(persona.name)
                success = await client.save_recipe(recipe.public_id)

                if success:
                    successes += 1

                await asyncio.sleep(0.5)

            except Exception as e:
                print(f"        Recipe save error: {e}")

        return successes

    async def save_recent_logs(
        self,
        count: int,
        personas: List[BotPersona],
        client: CookstemmaClient,
    ) -> int:
        """Save recent log posts from random personas.

        Args:
            count: Number of saves to perform
            personas: List of personas
            client: API client

        Returns:
            Number of successful saves
        """
        if count == 0:
            return 0

        # Refresh recent logs if needed
        if not self._recent_logs:
            self._recent_logs = await client.get_logs(page=0, size=20)

        if not self._recent_logs:
            return 0

        successes = 0

        for _ in range(count):
            try:
                persona = random.choice(personas)
                log = random.choice(self._recent_logs)

                await client.login_by_persona(persona.name)
                success = await client.save_log(log.public_id)

                if success:
                    successes += 1

                await asyncio.sleep(0.5)

            except Exception as e:
                print(f"        Log save error: {e}")

        return successes

    async def comment_on_logs(
        self,
        count: int,
        personas: List[BotPersona],
        client: CookstemmaClient,
    ) -> int:
        """Create comments on recent log posts.

        Args:
            count: Number of comments to create
            personas: List of personas
            client: API client

        Returns:
            Number of successful comments
        """
        if count == 0:
            return 0

        # Refresh recent logs if needed
        if not self._recent_logs:
            self._recent_logs = await client.get_logs(page=0, size=20)

        if not self._recent_logs:
            return 0

        # Sample comment templates
        comment_templates = [
            "Looks delicious! 😋",
            "Great job on this!",
            "I need to try this recipe!",
            "This turned out so well!",
            "Yum! Adding this to my list.",
            "Beautiful presentation!",
            "Thanks for sharing this!",
            "Can't wait to make this myself!",
        ]

        successes = 0

        for _ in range(count):
            try:
                persona = random.choice(personas)
                log = random.choice(self._recent_logs)
                comment_text = random.choice(comment_templates)

                await client.login_by_persona(persona.name)
                comment = await client.create_comment(log.public_id, comment_text)

                if comment:
                    successes += 1
                    self._recent_comments.append(comment)

                await asyncio.sleep(0.5)

            except Exception as e:
                print(f"        Comment error: {e}")

        return successes

    async def reply_to_comments(
        self,
        count: int,
        personas: List[BotPersona],
        client: CookstemmaClient,
    ) -> int:
        """Create replies to existing comments.

        Args:
            count: Number of replies to create
            personas: List of personas
            client: API client

        Returns:
            Number of successful replies
        """
        if count == 0 or not self._recent_comments:
            return 0

        reply_templates = [
            "Thanks!",
            "Appreciate it!",
            "Glad you like it!",
            "Let me know how it turns out!",
            "You're welcome!",
            "Hope you enjoy!",
        ]

        successes = 0

        for _ in range(count):
            try:
                persona = random.choice(personas)
                comment = random.choice(self._recent_comments)
                reply_text = random.choice(reply_templates)

                await client.login_by_persona(persona.name)
                reply = await client.create_reply(comment.public_id, reply_text)

                if reply:
                    successes += 1

                await asyncio.sleep(0.5)

            except Exception as e:
                print(f"        Reply error: {e}")

        return successes

    async def like_comments(
        self,
        count: int,
        personas: List[BotPersona],
        client: CookstemmaClient,
    ) -> int:
        """Like existing comments.

        Args:
            count: Number of likes to perform
            personas: List of personas
            client: API client

        Returns:
            Number of successful likes
        """
        if count == 0 or not self._recent_comments:
            return 0

        successes = 0

        for _ in range(count):
            try:
                persona = random.choice(personas)
                comment = random.choice(self._recent_comments)

                await client.login_by_persona(persona.name)
                success = await client.like_comment(comment.public_id)

                if success:
                    successes += 1

                await asyncio.sleep(0.5)

            except Exception as e:
                print(f"        Like error: {e}")

        return successes


# ==================== Main Simulator ====================


class EngagementSimulator:
    """Main orchestrator for 24-hour engagement simulation."""

    def __init__(
        self,
        total_recipes: int,
        total_logs: int,
        total_social: int,
        duration_hours: int = 24,
        dry_run: bool = False,
        variant_ratio: float = 0.5,
    ) -> None:
        self.total_recipes = total_recipes
        self.total_logs = total_logs
        self.total_social = total_social
        self.duration_hours = duration_hours
        self.dry_run = dry_run
        self.variant_ratio = variant_ratio

        self.settings = get_settings()
        self.scripts_dir = Path(__file__).parent
        self.stats = SimulationStats()

        # Initialize components
        self.scheduler = ActivityScheduler(
            total_recipes, total_logs, total_social, duration_hours,
            variant_ratio=variant_ratio
        )
        self.content_orchestrator = ContentOrchestrator(self.scripts_dir)
        self.social_engine = SocialInteractionEngine()

    def print_banner(self) -> None:
        """Print startup banner with configuration."""
        print()
        print("=" * 70)
        print("🚀 Starting 24-Hour Engagement Simulation")
        print("=" * 70)
        print()
        print("Configuration:")
        print(f"  Duration: {self.duration_hours} hours")
        print(f"  Total Recipes: {self.total_recipes}")
        print(f"  Variant Ratio: {self.variant_ratio:.0%}")
        print(f"  Total Logs: {self.total_logs}")
        print(f"  Total Social Actions: {self.total_social}")
        print()
        print("Activity Pattern:")
        print(f"  Constant activity throughout the day (global service)")
        print(f"  ~{self.total_recipes // self.duration_hours} recipes/hour")
        print(f"  ~{self.total_logs // self.duration_hours} logs/hour")
        print(f"  ~{self.total_social // self.duration_hours} social actions/hour")
        print()
        print("=" * 70)
        print()

    def print_schedule(self, schedule: List[HourlyActivity]) -> None:
        """Print the complete hourly schedule."""
        print("Hourly Schedule:")
        print()
        for activity in schedule:
            recipe_detail = f"{activity.recipes} recipes"
            if activity.recipes > 0 and (activity.recipes_original > 0 or activity.recipes_variant > 0):
                recipe_detail += f" ({activity.recipes_original}o/{activity.recipes_variant}v)"
            print(
                f"  Hour {activity.hour:2d}: "
                f"{recipe_detail}, {activity.logs} logs, "
                f"{activity.total_social} social"
            )
        print()
        print("=" * 70)
        print()

    async def execute_hourly_activity(
        self,
        activity: HourlyActivity,
        personas: List[BotPersona],
        client: CookstemmaClient,
    ) -> None:
        """Execute all activities for a given hour.

        Args:
            activity: Hourly activity plan
            personas: List of available personas
            client: API client
        """
        print(f"[Hour {activity.hour + 1}/{self.duration_hours}] {activity.hour:02d}:00 - {activity.hour+1:02d}:00 🌍")

        # Content creation (subprocess calls)
        if activity.recipes > 0:
            print(f"    ⏳ Creating {activity.recipes} recipes "
                  f"({activity.recipes_original} original, {activity.recipes_variant} variant)...")
            if not self.dry_run:
                success_orig, success_var = await self.content_orchestrator.create_recipes(
                    count=activity.recipes_original,
                    persona_names=[p.name for p in personas],
                    variant_count=activity.recipes_variant,
                    personas=personas,
                    client=client,
                )
                self.stats.recipes_created += success_orig + success_var
                self.stats.recipes_original += success_orig
                self.stats.recipes_variant += success_var
                self.stats.failed_actions += (activity.recipes_original - success_orig) + \
                                              (activity.recipes_variant - success_var)

        if activity.logs > 0:
            print(f"    ⏳ Creating {activity.logs} logs...")
            if not self.dry_run:
                success_count = await self.content_orchestrator.create_logs(
                    activity.logs,
                    [p.name for p in personas],
                )
                self.stats.logs_created += success_count
                self.stats.failed_actions += activity.logs - success_count

        # Social interactions
        if activity.total_social > 0:
            print(f"    ⏳ Performing {activity.total_social} social actions...")

            if not self.dry_run:
                # Follows
                if activity.follows > 0:
                    count = await self.social_engine.random_follows(
                        activity.follows, personas, client
                    )
                    self.stats.follows_done += count
                    self.stats.failed_actions += activity.follows - count

                # Recipe saves
                if activity.recipe_saves > 0:
                    count = await self.social_engine.save_recent_recipes(
                        activity.recipe_saves, personas, client
                    )
                    self.stats.recipe_saves_done += count
                    self.stats.failed_actions += activity.recipe_saves - count

                # Log saves
                if activity.log_saves > 0:
                    count = await self.social_engine.save_recent_logs(
                        activity.log_saves, personas, client
                    )
                    self.stats.log_saves_done += count
                    self.stats.failed_actions += activity.log_saves - count

                # Comments
                if activity.comments > 0:
                    count = await self.social_engine.comment_on_logs(
                        activity.comments, personas, client
                    )
                    self.stats.comments_created += count
                    self.stats.failed_actions += activity.comments - count

                # Replies
                if activity.replies > 0:
                    count = await self.social_engine.reply_to_comments(
                        activity.replies, personas, client
                    )
                    self.stats.replies_created += count
                    self.stats.failed_actions += activity.replies - count

                # Comment likes
                if activity.comment_likes > 0:
                    count = await self.social_engine.like_comments(
                        activity.comment_likes, personas, client
                    )
                    self.stats.comment_likes_done += count
                    self.stats.failed_actions += activity.comment_likes - count

        # Print completion
        print(
            f"    ✅ Completed: {activity.recipes} recipes, {activity.logs} logs, "
            f"{activity.total_social} social"
        )
        print()

    def print_final_report(self) -> None:
        """Print final summary report."""
        duration = self.stats.end_time - self.stats.start_time if self.stats.end_time and self.stats.start_time else timedelta(0)
        hours, remainder = divmod(duration.total_seconds(), 3600)
        minutes, seconds = divmod(remainder, 60)

        print()
        print("=" * 70)
        print("🎉 24-Hour Simulation Complete!")
        print("=" * 70)
        print()
        print("Final Report:")
        print(f"  Duration: {int(hours)}h {int(minutes)}m {int(seconds)}s")
        print(f"  Recipes Created: {self.stats.recipes_created}/{self.total_recipes} "
              f"({self.stats.recipes_created/self.total_recipes*100:.0f}%) "
              f"[{self.stats.recipes_original} original, {self.stats.recipes_variant} variant]")
        print(f"  Logs Created: {self.stats.logs_created}/{self.total_logs} "
              f"({self.stats.logs_created/self.total_logs*100:.0f}%)")
        print(f"  Social Actions: {self.stats.total_social}/{self.total_social} "
              f"({self.stats.total_social/self.total_social*100:.0f}%)")
        print()
        print("Breakdown:")
        print(f"  Follows: {self.stats.follows_done}")
        print(f"  Recipe Saves: {self.stats.recipe_saves_done}")
        print(f"  Log Saves: {self.stats.log_saves_done}")
        print(f"  Comments: {self.stats.comments_created}")
        print(f"  Replies: {self.stats.replies_created}")
        print(f"  Comment Likes: {self.stats.comment_likes_done}")
        print()
        print(f"Success Rate: {self.stats.success_rate:.1f}%")
        print(f"Failed Actions: {self.stats.failed_actions}")
        print("=" * 70)
        print()

    async def run_24h_simulation(self) -> None:
        """Execute the complete 24-hour simulation."""
        self.stats.start_time = datetime.now()

        # Print banner and schedule
        self.print_banner()

        # Generate schedule
        schedule = self.scheduler.get_hourly_schedule()
        self.print_schedule(schedule)

        if self.dry_run:
            print("DRY RUN - No actions will be executed")
            return

        # Initialize API client and personas
        client = CookstemmaClient()

        try:
            # Load personas
            registry = get_persona_registry()
            await registry.initialize(client)
            personas = registry.get_all()

            if not personas:
                print("Error: No personas found")
                return

            print(f"Loaded {len(personas)} personas")

            # Authenticate all personas to populate user_public_id
            print("Authenticating personas...")
            for persona in personas:
                try:
                    auth = await client.login_by_persona(persona.name)
                    persona.user_public_id = auth.user_public_id
                except Exception as e:
                    print(f"  Warning: Failed to authenticate {persona.name}: {e}")

            authenticated = [p for p in personas if p.user_public_id]
            print(f"Authenticated {len(authenticated)}/{len(personas)} personas")
            print()

            if len(authenticated) < 2:
                print("Error: Need at least 2 authenticated personas for social interactions")
                return

            # Use authenticated personas for the simulation
            personas = authenticated

            # Fetch parent recipes if we need to create variants
            if self.total_recipes > 0:
                total_variants = int(self.total_recipes * self.variant_ratio)
                if total_variants > 0:
                    min_parents = max(20, total_variants * 2)
                    print(f"Fetching parent recipes for {total_variants} variants...")
                    await self.content_orchestrator.fetch_parent_recipes(
                        client=client, min_count=min_parents
                    )
                    print()

            # Execute each hour
            for activity in schedule:
                await self.execute_hourly_activity(activity, personas, client)

                # Sleep until next hour (in real simulation)
                # For testing, you might want to reduce this
                # await asyncio.sleep(3600)  # 1 hour
                # For now, just continue immediately

        finally:
            await client.close()
            self.stats.end_time = datetime.now()

        # Print final report
        self.print_final_report()


# ==================== CLI ====================


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="24-Hour User Engagement Simulation"
    )
    parser.add_argument(
        "--duration-hours",
        type=int,
        default=None,
        help="Simulation duration in hours (default: from settings)",
    )
    parser.add_argument(
        "--recipes",
        type=int,
        default=None,
        help="Total recipes to create (default: from settings)",
    )
    parser.add_argument(
        "--logs",
        type=int,
        default=None,
        help="Total logs to create (default: from settings)",
    )
    parser.add_argument(
        "--social",
        type=int,
        default=None,
        help="Total social actions (default: from settings)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show schedule without executing actions",
    )
    parser.add_argument(
        "--variant-ratio",
        type=float,
        default=None,
        help="Ratio of variant recipes (0.0-1.0, default: from settings or 0.5)",
    )
    return parser.parse_args()


async def main() -> None:
    """Main entry point."""
    args = parse_args()
    settings = get_settings()

    # Use CLI args or fall back to settings
    duration_hours = args.duration_hours or settings.simulation_duration_hours
    total_recipes = args.recipes or settings.recipes_per_24h
    total_logs = args.logs or settings.logs_per_24h
    total_social = args.social or settings.social_actions_per_24h
    variant_ratio = args.variant_ratio if args.variant_ratio is not None else \
                    getattr(settings, 'variant_ratio', 0.5)

    # Create and run simulator
    simulator = EngagementSimulator(
        total_recipes=total_recipes,
        total_logs=total_logs,
        total_social=total_social,
        duration_hours=duration_hours,
        dry_run=args.dry_run,
        variant_ratio=variant_ratio,
    )

    await simulator.run_24h_simulation()


if __name__ == "__main__":
    asyncio.run(main())
