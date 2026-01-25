#!/usr/bin/env python3
"""Create AI-generated original and variant recipes from bot personas.

This script generates a mix of original and variant recipes with support for
cross-cultural adaptation and dietary preferences.

Usage:
    # Create 5 original recipes
    python scripts/create_recipes_mixed.py --original 5

    # Create 3 variant recipes (requires existing recipes in DB)
    python scripts/create_recipes_mixed.py --variant 3

    # Create 5 original and 10 variant recipes
    python scripts/create_recipes_mixed.py --original 5 --variant 10

    # Create variants with cross-cultural adaptation (80% foreign recipes)
    python scripts/create_recipes_mixed.py --variant 5 --cross-cultural 0.8

    # Use a specific persona
    python scripts/create_recipes_mixed.py --original 3 --persona chef_park_soojin

    # Skip image generation for faster testing
    python scripts/create_recipes_mixed.py --original 2 --no-images

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
from src.orchestrator.recipe_pipeline import RecipePipeline
from src.personas import BotPersona, get_persona_registry


@dataclass
class RecipeResult:
    """Result of a recipe creation attempt."""
    persona_name: str
    recipe_type: str  # "original" or "variant"
    success: bool
    recipe_id: Optional[str] = None
    recipe_title: Optional[str] = None
    parent_title: Optional[str] = None
    variation_type: Optional[str] = None
    is_cross_cultural: bool = False
    error: Optional[str] = None


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Create original and variant recipes using AI",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --original 5                  Create 5 original recipes
  %(prog)s --variant 3                   Create 3 variant recipes
  %(prog)s --original 5 --variant 10     Create 5 original + 10 variants
  %(prog)s --variant 5 --cross-cultural 0.8  80%% cross-cultural variants
        """
    )

    # Recipe counts
    parser.add_argument(
        "--original", "-o",
        type=int,
        default=0,
        help="Number of original recipes to create (default: 0)"
    )
    parser.add_argument(
        "--variant", "-v",
        type=int,
        default=0,
        help="Number of variant recipes to create (default: 0)"
    )

    # Persona selection
    parser.add_argument(
        "--persona", "-p",
        type=str,
        default=None,
        help="Specific persona name (default: random selection)"
    )

    # Cross-cultural settings
    parser.add_argument(
        "--cross-cultural", "-x",
        type=float,
        default=0.8,
        help="Ratio of variants using foreign recipes (0.0-1.0, default: 0.8)"
    )

    # Image settings
    parser.add_argument(
        "--no-images",
        action="store_true",
        help="Skip image generation for faster testing"
    )
    parser.add_argument(
        "--cover",
        type=int,
        choices=[1, 2, 3],
        default=1,
        help="Number of cover images per recipe (default: 1)"
    )
    parser.add_argument(
        "--step-images",
        action="store_true",
        help="Generate images for each cooking step"
    )

    # Timing
    parser.add_argument(
        "--delay",
        type=int,
        default=3,
        help="Seconds between recipes (default: 3)"
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=5,
        help="Recipes per batch before longer delay (default: 5)"
    )
    parser.add_argument(
        "--batch-delay",
        type=int,
        default=15,
        help="Seconds between batches (default: 15)"
    )

    return parser.parse_args()


async def create_original_recipe(
    persona: BotPersona,
    pipeline: RecipePipeline,
    text_gen: TextGenerator,
    generate_images: bool,
    cover_image_count: int,
    generate_step_images: bool,
) -> RecipeResult:
    """Create an original recipe for a persona."""
    try:
        # Get food suggestions excluding already created foods
        existing_foods = await pipeline.api.get_created_foods()
        suggestions = await text_gen.suggest_food_names(
            persona=persona,
            count=1,
            exclude=existing_foods,
        )

        if not suggestions:
            return RecipeResult(
                persona_name=persona.name,
                recipe_type="original",
                success=False,
                error="AI failed to suggest food name",
            )

        food_name = suggestions[0]
        print(f"    Food: {food_name}")

        recipe = await pipeline.generate_original_recipe(
            persona=persona,
            food_name=food_name,
            generate_images=generate_images,
            cover_image_count=cover_image_count,
            generate_step_images=generate_step_images,
        )

        return RecipeResult(
            persona_name=persona.name,
            recipe_type="original",
            success=True,
            recipe_id=recipe.public_id,
            recipe_title=recipe.title,
        )

    except Exception as e:
        return RecipeResult(
            persona_name=persona.name,
            recipe_type="original",
            success=False,
            error=str(e),
        )


async def create_variant_recipe(
    persona: BotPersona,
    pipeline: RecipePipeline,
    parent_pool: List[Recipe],
    cross_cultural_ratio: float,
    generate_images: bool,
) -> RecipeResult:
    """Create a variant recipe from an existing recipe."""
    try:
        # Select parent recipe (prefers foreign cuisines for cross-cultural)
        parent_recipe = pipeline.select_parent_for_cross_cultural(
            persona=persona,
            available_recipes=parent_pool,
            cross_cultural_ratio=cross_cultural_ratio,
        )

        if not parent_recipe:
            return RecipeResult(
                persona_name=persona.name,
                recipe_type="variant",
                success=False,
                error="No suitable parent recipe found",
            )

        # Fetch full recipe details
        full_parent = await pipeline.api.get_recipe(parent_recipe.public_id)

        # Determine if cross-cultural
        is_cross_cultural = (
            full_parent.cooking_style
            and full_parent.cooking_style != persona.cooking_style
        )

        # Build context and select variation type
        if is_cross_cultural:
            variation_type = "cultural_adaptation"
            cultural_context = pipeline.get_cultural_context(
                source_style=full_parent.cooking_style,
                target_style=persona.cooking_style,
                dietary_focus=persona.dietary_focus.value,
            )
            print(f"    Cross-cultural: {cultural_context['source_culture']} -> "
                  f"{cultural_context['target_culture']} ({cultural_context['dietary_focus']})")
        else:
            # Standard variation types
            variation_types = [
                "healthier", "budget", "quick", "vegetarian", "spicier",
                "kid_friendly", "gourmet", "vegan", "high_protein", "low_carb",
            ]
            variation_type = random.choice(variation_types)
            cultural_context = None
            print(f"    Variation: {variation_type}")

        print(f"    Parent: {full_parent.title[:50]}...")

        # Generate variant
        recipe = await pipeline.generate_variant_recipe(
            persona=persona,
            parent_recipe=full_parent,
            variation_type=variation_type,
            generate_images=generate_images,
            cultural_context=cultural_context,
        )

        return RecipeResult(
            persona_name=persona.name,
            recipe_type="variant",
            success=True,
            recipe_id=recipe.public_id,
            recipe_title=recipe.title,
            parent_title=full_parent.title,
            variation_type=variation_type,
            is_cross_cultural=is_cross_cultural,
        )

    except Exception as e:
        return RecipeResult(
            persona_name=persona.name,
            recipe_type="variant",
            success=False,
            error=str(e),
        )


async def fetch_parent_recipes(
    client: CookstemmaClient,
    min_count: int = 20,
) -> List[Recipe]:
    """Fetch existing recipes from database to use as variant parents."""
    print(f"Fetching parent recipes (target: {min_count})...")

    recipes: List[Recipe] = []
    page = 0
    page_size = 20

    while len(recipes) < min_count:
        try:
            batch = await client.get_recipes(page=page, size=page_size)
            if not batch:
                break
            recipes.extend(batch)
            if len(batch) < page_size:
                break
            page += 1
        except Exception as e:
            print(f"  Warning: Failed to fetch page {page}: {e}")
            break

    print(f"  Cached {len(recipes)} parent recipes")
    return recipes


async def main() -> None:
    """Main entry point."""
    args = parse_args()
    settings = get_settings()

    # Validate input
    total_count = args.original + args.variant
    if total_count == 0:
        print("Error: Specify at least --original or --variant count")
        print("Example: python scripts/create_recipes_mixed.py --original 5")
        sys.exit(1)

    # Validate API key
    if not settings.gemini_api_key or settings.gemini_api_key == "placeholder":
        print("Error: GEMINI_API_KEY not found in .env")
        sys.exit(1)

    # Initialize clients and generators
    api_client = CookstemmaClient()
    text_gen = TextGenerator()
    image_gen = ImageGenerator()

    generate_images = not args.no_images

    # Track results
    results: List[RecipeResult] = []

    try:
        # Load personas
        registry = get_persona_registry()
        await registry.initialize(api_client)
        all_personas = registry.get_all()

        if not all_personas:
            print("Error: No personas found")
            sys.exit(1)

        # Get specific persona if requested
        if args.persona:
            persona = registry.get(args.persona)
            if not persona:
                print(f"Error: Persona '{args.persona}' not found")
                print(f"Available: {[p.name for p in all_personas]}")
                sys.exit(1)
            personas = [persona]
        else:
            personas = all_personas

        # Verify personas can authenticate and get their user IDs
        # Note: We re-authenticate before each recipe creation because the client
        # can only hold one access token at a time (last login wins)
        print(f"Verifying {len(personas)} persona(s) can authenticate...")
        for p in personas:
            try:
                auth = await api_client.login_by_persona(p.name)
                p.user_public_id = auth.user_public_id
                p.persona_public_id = auth.persona_public_id
            except Exception as e:
                print(f"  Warning: Failed to authenticate {p.name}: {e}")

        authenticated = [p for p in personas if p.user_public_id]
        print(f"  Authenticated: {len(authenticated)}/{len(personas)}")

        if not authenticated:
            print("Error: No personas authenticated")
            sys.exit(1)

        personas = authenticated

        # Fetch parent recipes if creating variants
        parent_pool: List[Recipe] = []
        if args.variant > 0:
            parent_pool = await fetch_parent_recipes(
                api_client,
                min_count=max(20, args.variant * 2),
            )
            if not parent_pool:
                print("Warning: No parent recipes found, variants will fail")

        # Print plan
        print()
        print("=" * 60)
        print(f"Creating {args.original} original + {args.variant} variant recipes")
        print(f"  Cross-cultural ratio: {args.cross_cultural:.0%}")
        print(f"  Images: {'enabled' if generate_images else 'disabled'}")
        print("=" * 60)
        print()

        # Create original recipes first
        recipe_num = 0
        for i in range(args.original):
            recipe_num += 1
            persona = random.choice(personas)

            print(f"[{recipe_num}/{total_count}] Original - {persona.name} (locale: {persona.locale})")

            # Re-authenticate as the selected persona before creating recipe
            await api_client.login_by_persona(persona.name)

            pipeline = RecipePipeline(api_client, text_gen, image_gen)
            result = await create_original_recipe(
                persona=persona,
                pipeline=pipeline,
                text_gen=text_gen,
                generate_images=generate_images,
                cover_image_count=args.cover,
                generate_step_images=args.step_images,
            )

            results.append(result)

            if result.success:
                print(f"    ✓ {result.recipe_title}")
                # Add new recipe to parent pool for variants
                if args.variant > 0:
                    try:
                        new_recipe = await api_client.get_recipe(result.recipe_id)
                        parent_pool.append(new_recipe)
                    except Exception:
                        pass
            else:
                print(f"    ✗ Failed: {result.error}")

            # Delay between recipes
            if recipe_num < total_count:
                if recipe_num % args.batch_size == 0:
                    print(f"  Batch complete, waiting {args.batch_delay}s...")
                    await asyncio.sleep(args.batch_delay)
                else:
                    await asyncio.sleep(args.delay)

        # Create variant recipes
        for i in range(args.variant):
            recipe_num += 1
            persona = random.choice(personas)

            print(f"[{recipe_num}/{total_count}] Variant - {persona.name} (locale: {persona.locale})")

            # Re-authenticate as the selected persona before creating recipe
            await api_client.login_by_persona(persona.name)

            pipeline = RecipePipeline(api_client, text_gen, image_gen)
            result = await create_variant_recipe(
                persona=persona,
                pipeline=pipeline,
                parent_pool=parent_pool,
                cross_cultural_ratio=args.cross_cultural,
                generate_images=generate_images,
            )

            results.append(result)

            if result.success:
                cross_mark = " [cross-cultural]" if result.is_cross_cultural else ""
                print(f"    ✓ {result.recipe_title}{cross_mark}")
                # Add variant to pool too
                try:
                    new_recipe = await api_client.get_recipe(result.recipe_id)
                    parent_pool.append(new_recipe)
                except Exception:
                    pass
            else:
                print(f"    ✗ Failed: {result.error}")

            # Delay between recipes
            if recipe_num < total_count:
                if recipe_num % args.batch_size == 0:
                    print(f"  Batch complete, waiting {args.batch_delay}s...")
                    await asyncio.sleep(args.batch_delay)
                else:
                    await asyncio.sleep(args.delay)

        # Print summary
        print()
        print("=" * 60)
        print("Summary")
        print("=" * 60)

        successful = [r for r in results if r.success]
        failed = [r for r in results if not r.success]

        originals_success = len([r for r in successful if r.recipe_type == "original"])
        variants_success = len([r for r in successful if r.recipe_type == "variant"])
        cross_cultural = len([r for r in successful if r.is_cross_cultural])

        print(f"  Original recipes: {originals_success}/{args.original}")
        print(f"  Variant recipes:  {variants_success}/{args.variant}")
        if variants_success > 0:
            print(f"    Cross-cultural: {cross_cultural}/{variants_success}")
        print(f"  Total success:    {len(successful)}/{total_count}")
        print(f"  Failed:           {len(failed)}")

        if failed:
            print()
            print("Failed recipes:")
            for r in failed:
                print(f"  - {r.persona_name} ({r.recipe_type}): {r.error[:50]}...")

        print()

    finally:
        await api_client.close()
        await image_gen.close()


if __name__ == "__main__":
    asyncio.run(main())
