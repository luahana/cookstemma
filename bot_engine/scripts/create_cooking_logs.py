#!/usr/bin/env python3
"""Create cooking logs for existing recipes.

This script generates cooking logs using the LogPipeline with AI-generated content.

Usage:
    cd bot_engine

    # Generate log for a specific recipe
    python scripts/create_cooking_logs.py --recipe-id <uuid> --persona chef_park_soojin

    # Generate logs for random recipes
    python scripts/create_cooking_logs.py --count 5 --random-recipes

    # Generate multiple logs for a specific recipe
    python scripts/create_cooking_logs.py --recipe-id <uuid> --count 3

Prerequisites:
    - Backend running at http://localhost:4000
    - GEMINI_API_KEY in .env
    - BOT_INTERNAL_SECRET in .env
    - Existing recipes in the database
"""

import argparse
import asyncio
import os
import random
import sys
from dataclasses import dataclass
from typing import List, Optional

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv
load_dotenv()

from src.api import CookstemmaClient
from src.api.models import Recipe
from src.config import get_settings
from src.generators import ImageGenerator, TextGenerator
from src.orchestrator.log_pipeline import LogPipeline
from src.personas import BotPersona, get_persona_registry


@dataclass
class LogResult:
    """Result of log creation."""
    persona_name: str
    recipe_title: str
    success: bool
    log_id: Optional[str] = None
    rating: Optional[int] = None
    error: Optional[str] = None


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Create cooking logs using Gemini AI"
    )
    parser.add_argument(
        "--persona",
        type=str,
        default=None,
        help="Specific persona name (defaults to random)",
    )
    parser.add_argument(
        "--recipe-id",
        type=str,
        default=None,
        help="Recipe public ID (UUID)",
    )
    parser.add_argument(
        "--count",
        type=int,
        default=1,
        help="Number of logs to generate",
    )
    parser.add_argument(
        "--random-recipes",
        action="store_true",
        help="Generate logs for random existing recipes",
    )
    parser.add_argument(
        "--num-images",
        type=int,
        default=1,
        help="Number of images per log (1-3)",
    )
    parser.add_argument(
        "--rating",
        type=int,
        choices=[1, 2, 3, 4, 5],
        default=None,
        help="Fixed rating (1-5), or auto-select if not specified",
    )
    parser.add_argument(
        "--delay",
        type=int,
        default=3,
        help="Seconds between log generations",
    )
    return parser.parse_args()


async def create_log_for_recipe(
    persona: BotPersona,
    recipe: Recipe,
    api_client: CookstemmaClient,
    log_pipeline: LogPipeline,
    rating: Optional[int] = None,
    num_images: int = 1,
) -> LogResult:
    """Generate a cooking log for a specific recipe.

    Args:
        persona: Bot persona to use for log creation
        recipe: Recipe to create log for
        api_client: Authenticated API client
        log_pipeline: Log generation pipeline
        rating: Optional fixed rating (1-5)
        num_images: Number of images to generate

    Returns:
        LogResult with success status and details
    """
    try:
        # Authenticate as persona
        auth = await api_client.login_by_persona(persona.name)
        persona.user_public_id = auth.user_public_id
        persona.persona_public_id = auth.persona_public_id

        # Generate log using pipeline
        log = await log_pipeline.generate_log(
            persona=persona,
            recipe=recipe,
            rating=rating,
            num_images=num_images,
        )

        return LogResult(
            persona_name=persona.name,
            recipe_title=recipe.title,
            success=True,
            log_id=log.public_id,
            rating=log.rating,
        )

    except Exception as e:
        return LogResult(
            persona_name=persona.name,
            recipe_title=recipe.title,
            success=False,
            error=str(e),
        )


async def get_random_recipes(
    api_client: CookstemmaClient,
    count: int = 10,
) -> List[Recipe]:
    """Fetch random recipes from the backend.

    Args:
        api_client: API client
        count: Number of recipes to fetch

    Returns:
        List of Recipe objects
    """
    # Fetch first few pages and randomly select
    all_recipes = []
    for page in range(3):  # Fetch 3 pages
        recipes = await api_client.get_recipes(page=page, size=20)
        all_recipes.extend(recipes)
        if len(all_recipes) >= count:
            break

    if not all_recipes:
        raise ValueError("No recipes found in database")

    # Randomly select recipes
    return random.sample(all_recipes, min(count, len(all_recipes)))


async def main() -> None:
    """Main entry point."""
    args = parse_args()
    settings = get_settings()

    # Validate API keys
    if not settings.gemini_api_key or settings.gemini_api_key == "placeholder":
        print("Error: GEMINI_API_KEY not found in .env")
        sys.exit(1)

    # Initialize clients
    api_client = CookstemmaClient()
    text_gen = TextGenerator()
    image_gen = ImageGenerator()
    log_pipeline = LogPipeline(api_client, text_gen, image_gen)

    try:
        # Initialize persona registry
        registry = get_persona_registry()
        await registry.initialize(api_client)
        all_personas = registry.get_all()

        if not all_personas:
            print("Error: No personas found")
            sys.exit(1)

        # Determine which recipes to use
        recipes: List[Recipe] = []

        if args.recipe_id:
            # Use specific recipe
            recipe = await api_client.get_recipe(args.recipe_id)
            # Repeat the same recipe for multiple logs
            recipes = [recipe] * args.count
        elif args.random_recipes:
            # Fetch random recipes
            recipes = await get_random_recipes(api_client, args.count)
        else:
            print("Error: Must specify --recipe-id or --random-recipes")
            sys.exit(1)

        print(f"\n🚀 Generating {len(recipes)} cooking log(s)...")
        print(f"   Images per log: {args.num_images}")
        print(f"   Rating: {'auto-select' if not args.rating else args.rating}")
        print()

        # Generate logs
        results: List[LogResult] = []

        for i, recipe in enumerate(recipes, 1):
            # Select persona
            if args.persona:
                persona = registry.get(args.persona)
                if not persona:
                    print(f"Error: Persona '{args.persona}' not found")
                    sys.exit(1)
            else:
                persona = random.choice(all_personas)

            print(f"[{i}/{len(recipes)}] Generating log for '{recipe.title}'")
            print(f"           Using persona: {persona.name}")

            result = await create_log_for_recipe(
                persona=persona,
                recipe=recipe,
                api_client=api_client,
                log_pipeline=log_pipeline,
                rating=args.rating,
                num_images=args.num_images,
            )

            results.append(result)

            if result.success:
                print(f"           ✓ Success: Rating {result.rating}/5 (ID: {result.log_id})")
            else:
                print(f"           ✗ Failed: {result.error}")

            # Delay between logs (except for last one)
            if i < len(recipes):
                await asyncio.sleep(args.delay)

        # Print summary
        print()
        print("=" * 60)
        successful = [r for r in results if r.success]
        print(f"Summary: {len(successful)}/{len(results)} logs created successfully")

        if successful:
            avg_rating = sum(r.rating for r in successful) / len(successful)
            print(f"Average rating: {avg_rating:.1f}/5")

        print("=" * 60)

    finally:
        await api_client.close()
        await image_gen.close()


if __name__ == "__main__":
    asyncio.run(main())
