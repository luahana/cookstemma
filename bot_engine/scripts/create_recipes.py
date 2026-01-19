#!/usr/bin/env python3
"""Create AI-generated recipes from bot personas.

This script generates AI-generated recipes using bot personas,
complete with cover images generated via OpenAI DALL-E.

Usage:
    cd bot_engine

    # Single recipe (existing behavior)
    python scripts/create_recipes.py                      # Random persona
    python scripts/create_recipes.py --persona chef_park_soojin  # Specific persona

    # Multiple recipes with random personas
    python scripts/create_recipes.py --count 5
    python scripts/create_recipes.py --count 10 --step-images

Prerequisites:
    - Backend running at http://localhost:4000
    - OPENAI_API_KEY configured in .env
    - BOT_INTERNAL_SECRET configured in .env (matches backend)
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

# Load .env file for local development
from dotenv import load_dotenv
load_dotenv()

from src.api import CookstemmaClient
from src.config import get_settings
from src.generators import ImageGenerator, TextGenerator
from src.orchestrator.recipe_pipeline import RecipePipeline
from src.personas import BotPersona, get_persona_registry


@dataclass
class RecipeResult:
    """Result of recipe creation for a persona."""
    persona_name: str
    success: bool
    recipe_id: Optional[str] = None
    recipe_title: Optional[str] = None
    error: Optional[str] = None


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Create AI-generated recipes from bot personas"
    )
    parser.add_argument(
        "--persona",
        type=str,
        default=None,
        help="Persona name to use (e.g., chef_park_soojin). If not specified, picks random. Ignored when --count > 1.",
    )
    parser.add_argument(
        "--food",
        type=str,
        default=None,
        help="Food name to create recipe for. If not specified, AI suggests one.",
    )
    parser.add_argument(
        "--count",
        type=int,
        default=1,
        help="Number of recipes to generate (uses random personas, ignores --persona)",
    )
    parser.add_argument(
        "--step-images",
        action="store_true",
        help="Generate images for each recipe step (default: cover image only)",
    )
    parser.add_argument(
        "--cover",
        type=int,
        choices=[1, 2, 3],
        default=1,
        help="Number of cover images to generate (1, 2, or 3)",
    )
    return parser.parse_args()


async def create_recipe_for_persona(
    persona: BotPersona,
    api_client: CookstemmaClient,
    text_gen: TextGenerator,
    image_gen: ImageGenerator,
    generate_step_images: bool,
    cover_image_count: int = 1,
    food_name: Optional[str] = None,
) -> RecipeResult:
    """Create a recipe for a single persona.

    Args:
        persona: The bot persona to use
        api_client: API client for backend communication
        text_gen: Text generator for AI content
        image_gen: Image generator for DALL-E images
        generate_step_images: Whether to generate step images
        cover_image_count: Number of cover images to generate (1-3)
        food_name: Optional specific food name. If None, AI suggests one.

    Returns:
        RecipeResult with success/failure info
    """
    try:
        # Authenticate with persona (auto-creates user if needed)
        auth = await api_client.login_by_persona(persona.name)
        print(f"  Authenticated as: {auth.username}")

        # Update persona with auth info
        persona.user_public_id = auth.user_public_id
        persona.persona_public_id = auth.persona_public_id

        # Get existing foods to exclude
        existing_foods = await api_client.get_created_foods()

        # Determine food name
        if food_name:
            chosen_food = food_name
            print(f"  Using specified food: {chosen_food}")
        else:
            # Ask AI to suggest a food name
            suggestions = await text_gen.suggest_food_names(
                persona=persona,
                count=1,
                exclude=existing_foods,
            )

            if not suggestions:
                return RecipeResult(
                    persona_name=persona.name,
                    success=False,
                    error="AI couldn't suggest any new foods",
                )

            # Filter out duplicates
            existing_lower = {f.lower() for f in existing_foods}
            filtered = [f for f in suggestions if f.lower() not in existing_lower]

            if not filtered:
                return RecipeResult(
                    persona_name=persona.name,
                    success=False,
                    error="All suggested foods already exist",
                )

            chosen_food = filtered[0]
            print(f"  AI chose: {chosen_food}")

        # Create pipeline and generate recipe
        pipeline = RecipePipeline(api_client, text_gen, image_gen)
        recipe = await pipeline.generate_original_recipe(
            persona=persona,
            food_name=chosen_food,
            generate_images=True,
            cover_image_count=cover_image_count,
            generate_step_images=generate_step_images,
        )

        return RecipeResult(
            persona_name=persona.name,
            success=True,
            recipe_id=recipe.public_id,
            recipe_title=recipe.title,
        )

    except Exception as e:
        return RecipeResult(
            persona_name=persona.name,
            success=False,
            error=str(e),
        )


def print_recipe_details(recipe_result: RecipeResult, recipe: any) -> None:
    """Print detailed recipe information for single recipe mode."""
    print("\n" + "=" * 50)
    print("Recipe created successfully!")
    print("=" * 50)
    print(f"Public ID: {recipe.public_id}")
    print(f"Title: {recipe.title}")
    print(f"Description: {recipe.description[:100]}...")
    print(f"Ingredients: {len(recipe.ingredients)} items")
    print(f"Steps: {len(recipe.steps)} steps")
    print(f"Images: {len(recipe.images)} cover images")

    if recipe.images:
        print("\nCover Image URLs:")
        for i, img in enumerate(recipe.images, 1):
            print(f"  {i}. {img.image_url}")

    # Show step images
    steps_with_images = [s for s in recipe.steps if s.image_public_id]
    if steps_with_images:
        print(f"\nSteps with images: {len(steps_with_images)}")
        for step in steps_with_images:
            print(f"  Step {step.step_number}: image_id={step.image_public_id}")

    print("\nView in app or backend logs for full details.")


def print_summary(results: List[RecipeResult]) -> None:
    """Print summary of multiple recipe creations."""
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)

    successful = [r for r in results if r.success]
    failed = [r for r in results if not r.success]

    print(f"\nTotal: {len(results)}")
    print(f"Successful: {len(successful)}")
    print(f"Failed: {len(failed)}")

    if successful:
        print("\nSuccessful recipes:")
        for r in successful:
            print(f"  - {r.persona_name}: {r.recipe_title} ({r.recipe_id})")

    if failed:
        print("\nFailed personas:")
        for r in failed:
            print(f"  - {r.persona_name}: {r.error}")


async def main() -> None:
    """Create AI-generated recipes."""
    args = parse_args()

    # Load settings
    settings = get_settings()

    # Check for OpenAI API key
    if not settings.openai_api_key or settings.openai_api_key == "sk-test-placeholder":
        print("Error: OPENAI_API_KEY not configured in .env")
        print("Add your OpenAI API key to bot_engine/.env:")
        print("  OPENAI_API_KEY=sk-your-key-here")
        sys.exit(1)

    # Check for internal secret
    if not settings.bot_internal_secret or settings.bot_internal_secret == "":
        print("Error: BOT_INTERNAL_SECRET not configured in .env")
        sys.exit(1)

    # Setup clients
    api_client = CookstemmaClient()
    text_gen = TextGenerator()
    image_gen = ImageGenerator()

    results: List[RecipeResult] = []

    try:
        # Initialize persona registry from API
        print("Fetching personas from backend...")
        registry = get_persona_registry()
        await registry.initialize(api_client)

        all_personas = registry.get_all()
        if not all_personas:
            print("Error: No personas found in backend")
            sys.exit(1)

        print(f"Found {len(all_personas)} personas")

        generate_step_images = args.step_images
        cover_image_count = args.cover
        count = args.count

        if count > 1:
            # Multi-recipe mode: random personas, ignore --persona arg
            if args.persona:
                print(f"\nNote: --persona ignored when --count > 1 (using random personas)")

            print(f"\nGenerating {count} recipes with random personas...")
            print("=" * 60)

            for i in range(count):
                persona = random.choice(all_personas)
                print(f"\n[{i + 1}/{count}] {persona.name} ({persona.display_name.get('en', persona.name)})")

                if generate_step_images:
                    print("  Generating recipe with step images...")
                else:
                    print("  Generating recipe (cover only)...")

                result = await create_recipe_for_persona(
                    persona=persona,
                    api_client=api_client,
                    text_gen=text_gen,
                    image_gen=image_gen,
                    generate_step_images=generate_step_images,
                    cover_image_count=cover_image_count,
                    food_name=None,  # AI suggests for each
                )
                results.append(result)

                if result.success:
                    print(f"  ✓ Created: {result.recipe_title}")
                else:
                    print(f"  ✗ Failed: {result.error}")

            # Print summary
            print_summary(results)

            # Exit with error code if any failures
            failed = [r for r in results if not r.success]
            if failed:
                sys.exit(1)

        else:
            # Single recipe mode: use specified persona or random
            if args.persona:
                persona = registry.get(args.persona)
                if not persona:
                    print(f"Error: Persona '{args.persona}' not found")
                    print("Available personas:")
                    for p in all_personas:
                        print(f"  - {p.name}")
                    sys.exit(1)
            else:
                persona = random.choice(all_personas)

            print(f"\nUsing persona: {persona.name} ({persona.display_name.get('en', persona.name)})")

            if generate_step_images:
                print("\nThis may take a while (generating text + cover + step images)...")
            else:
                print("\nGenerating recipe (text + cover image)...")

            # For single recipe, we want detailed output, so do inline creation
            # Authenticate with persona (auto-creates user if needed)
            print("Authenticating (will create user if needed)...")
            auth = await api_client.login_by_persona(persona.name)
            print(f"Authenticated as: {auth.username}")

            # Update persona with auth info
            persona.user_public_id = auth.user_public_id
            persona.persona_public_id = auth.persona_public_id

            # Create pipeline
            pipeline = RecipePipeline(api_client, text_gen, image_gen)

            # Get existing foods to exclude from suggestions
            print("\nFetching existing foods...")
            existing_foods = await api_client.get_created_foods()
            print(f"Bot has created {len(existing_foods)} foods already")

            # Determine food name
            if args.food:
                food_name = args.food
                print(f"Using specified food: {food_name}")
            else:
                # Ask AI to suggest a food name
                print("Asking AI for food suggestion...")
                suggestions = await text_gen.suggest_food_names(
                    persona=persona,
                    count=1,
                    exclude=existing_foods,
                )

                if not suggestions:
                    print("Error: AI couldn't suggest any new foods")
                    sys.exit(1)

                # Filter out any that somehow still match existing (case-insensitive)
                existing_lower = {f.lower() for f in existing_foods}
                filtered = [f for f in suggestions if f.lower() not in existing_lower]

                if not filtered:
                    print("Error: All suggested foods already exist")
                    sys.exit(1)

                food_name = filtered[0]
                print(f"AI chose: {food_name}")

            # Generate recipe
            recipe = await pipeline.generate_original_recipe(
                persona=persona,
                food_name=food_name,
                generate_images=True,
                cover_image_count=cover_image_count,
                generate_step_images=generate_step_images,
            )

            # Print detailed results for single recipe
            print("\n" + "=" * 50)
            print("Recipe created successfully!")
            print("=" * 50)
            print(f"Public ID: {recipe.public_id}")
            print(f"Title: {recipe.title}")
            print(f"Description: {recipe.description[:100]}...")
            print(f"Ingredients: {len(recipe.ingredients)} items")
            print(f"Steps: {len(recipe.steps)} steps")
            print(f"Images: {len(recipe.images)} cover images")

            if recipe.images:
                print("\nCover Image URLs:")
                for i, img in enumerate(recipe.images, 1):
                    print(f"  {i}. {img.image_url}")

            # Show step images
            steps_with_images = [s for s in recipe.steps if s.image_public_id]
            if steps_with_images:
                print(f"\nSteps with images: {len(steps_with_images)}")
                for step in steps_with_images:
                    print(f"  Step {step.step_number}: image_id={step.image_public_id}")

            print("\nView in app or backend logs for full details.")

    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

    finally:
        # Cleanup
        await api_client.close()
        await image_gen.close()


if __name__ == "__main__":
    asyncio.run(main())
