#!/usr/bin/env python3
"""Create one recipe for each bot persona.

This script generates one AI-generated recipe for each of the 30 bot personas,
auto-creating bot users as needed.

Usage:
    cd bot_engine
    python scripts/create_recipes_all_bots.py
    python scripts/create_recipes_all_bots.py --step-images     # Include step images
    python scripts/create_recipes_all_bots.py --limit 5      # Only first 5 personas

Prerequisites:
    - Backend running at http://localhost:4000
    - OPENAI_API_KEY configured in .env
    - BOT_INTERNAL_SECRET configured in .env (matches backend)
"""

import argparse
import asyncio
import os
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
        description="Create one recipe for each bot persona"
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Limit to first N personas (for testing)",
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
    parser.add_argument(
        "--continue-on-error",
        action="store_true",
        default=True,
        help="Continue processing other personas if one fails (default: True)",
    )
    return parser.parse_args()


async def create_recipe_for_persona(
    persona: BotPersona,
    api_client: CookstemmaClient,
    text_gen: TextGenerator,
    image_gen: ImageGenerator,
    generate_step_images: bool,
    cover_image_count: int = 1,
) -> RecipeResult:
    """Create a recipe for a single persona (cover image always generated)."""
    try:
        # Authenticate with persona (auto-creates user if needed)
        auth = await api_client.login_by_persona(persona.name)
        print(f"  Authenticated as: {auth.username}")

        # Update persona with auth info
        persona.user_public_id = auth.user_public_id
        persona.persona_public_id = auth.persona_public_id

        # Get existing foods to exclude
        existing_foods = await api_client.get_created_foods()

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

        food_name = filtered[0]
        print(f"  Creating recipe for: {food_name}")

        # Create pipeline and generate recipe
        pipeline = RecipePipeline(api_client, text_gen, image_gen)
        recipe = await pipeline.generate_original_recipe(
            persona=persona,
            food_name=food_name,
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


async def main() -> None:
    """Create one recipe for each bot persona."""
    args = parse_args()

    # Load settings
    settings = get_settings()

    # Check for OpenAI API key
    if not settings.openai_api_key or settings.openai_api_key == "sk-test-placeholder":
        print("Error: OPENAI_API_KEY not configured in .env")
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

        # Apply limit if specified
        personas_to_process = all_personas
        if args.limit:
            personas_to_process = all_personas[:args.limit]

        total = len(personas_to_process)
        print(f"\nProcessing {total} personas...")
        print("=" * 60)

        generate_step_images = args.step_images
        cover_image_count = args.cover

        for i, persona in enumerate(personas_to_process, 1):
            print(f"\n[{i}/{total}] {persona.name} ({persona.display_name.get('en', '')})")

            result = await create_recipe_for_persona(
                persona=persona,
                api_client=api_client,
                text_gen=text_gen,
                image_gen=image_gen,
                generate_step_images=generate_step_images,
                cover_image_count=cover_image_count,
            )
            results.append(result)

            if result.success:
                print(f"  ✓ Created: {result.recipe_title}")
            else:
                print(f"  ✗ Failed: {result.error}")
                if not args.continue_on_error:
                    print("\nStopping due to error (use --continue-on-error to skip)")
                    break

        # Print summary
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

    except Exception as e:
        print(f"\nFatal error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

    finally:
        # Cleanup
        await api_client.close()
        await image_gen.close()

    # Exit with error code if any failures
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
