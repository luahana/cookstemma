#!/usr/bin/env python3
"""Create cooking logs for existing recipes with AI-generated content.

This script generates AI-generated cooking logs using a bot persona,
complete with casual-style "user photo" images generated via OpenAI DALL-E.

Usage:
    cd bot_engine
    python scripts/create_cooking_logs.py
    python scripts/create_cooking_logs.py --count 5
    python scripts/create_cooking_logs.py --recipe-id abc123 --rating 5
    python scripts/create_cooking_logs.py --count 3 --min-rating 4 --max-rating 5
    python scripts/create_cooking_logs.py --count 1 --images 3
    python scripts/create_cooking_logs.py --private --images 0

Prerequisites:
    - Backend running at http://localhost:4000
    - OPENAI_API_KEY configured in .env
    - Bot API keys configured in .env
    - At least one recipe exists in the database
"""

import argparse
import asyncio
import os
import random
import sys

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Load .env file
from dotenv import load_dotenv
load_dotenv()

from src.api import CookstemmaClient
from src.config import get_settings
from src.generators import ImageGenerator, TextGenerator
from src.orchestrator.log_pipeline import LogPipeline
from src.personas import get_persona_registry


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Create cooking logs for existing recipes with AI-generated content."
    )
    parser.add_argument(
        "--count",
        type=int,
        default=1,
        help="Number of logs to create (default: 1)",
    )
    parser.add_argument(
        "--recipe-id",
        type=str,
        help="Public ID of specific recipe (optional, random if not provided)",
    )
    parser.add_argument(
        "--rating",
        type=int,
        choices=[1, 2, 3, 4, 5],
        help="Fixed rating 1-5 (optional, random if not provided)",
    )
    parser.add_argument(
        "--min-rating",
        type=int,
        default=3,
        choices=[1, 2, 3, 4, 5],
        help="Minimum for random rating (default: 3)",
    )
    parser.add_argument(
        "--max-rating",
        type=int,
        default=5,
        choices=[1, 2, 3, 4, 5],
        help="Maximum for random rating (default: 5)",
    )
    parser.add_argument(
        "--images",
        type=int,
        default=1,
        help="Number of images to generate per log (default: 1, use 0 for no images)",
    )
    parser.add_argument(
        "--private",
        action="store_true",
        help="Create as private log",
    )
    parser.add_argument(
        "--persona",
        type=str,
        default=None,
        help="Bot persona to use. If not specified, picks random.",
    )
    return parser.parse_args()


async def main() -> None:
    """Create AI-generated cooking logs."""
    args = parse_args()

    # Validate rating range
    if args.min_rating > args.max_rating:
        print("Error: --min-rating cannot be greater than --max-rating")
        sys.exit(1)

    # Load settings
    settings = get_settings()

    # Check for OpenAI API key
    if not settings.openai_api_key or settings.openai_api_key == "sk-test-placeholder":
        print("Error: OPENAI_API_KEY not configured in .env")
        print("Add your OpenAI API key to bot_engine/.env:")
        print("  OPENAI_API_KEY=sk-your-key-here")
        sys.exit(1)

    # 1. Setup clients
    api_client = CookstemmaClient()
    text_gen = TextGenerator()
    image_gen = ImageGenerator()

    try:
        # 2. Initialize persona registry from API
        print("Fetching personas from backend...")
        registry = get_persona_registry()
        await registry.initialize(api_client)

        all_personas = registry.get_all()
        if not all_personas:
            print("Error: No personas found in backend")
            sys.exit(1)

        # 3. Get persona (specific or random)
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

        print(f"Using persona: {persona.name} ({persona.display_name.get('en', persona.name)})")

        # 4. Authenticate with persona (auto-creates user if needed)
        print("Authenticating (will create user if needed)...")
        auth = await api_client.login_by_persona(persona.name)
        print(f"Authenticated as: {auth.username}")

        # 5. Create pipeline
        pipeline = LogPipeline(api_client, text_gen, image_gen)

        # 6. Get recipes (specific or for random selection)
        if args.recipe_id:
            print(f"\nFetching recipe: {args.recipe_id}")
            recipe = await api_client.get_recipe(args.recipe_id)
            recipes = [recipe]
        else:
            print("\nFetching recipes for random selection...")
            recipes = await api_client.get_recipes(page=0, size=50)
            if not recipes:
                print("Error: No recipes found in database")
                print("Run create_one_recipe.py first to create a recipe.")
                sys.exit(1)
            print(f"Found {len(recipes)} recipes for selection")

        # 7. Generate logs
        print(f"\nGenerating {args.count} cooking log(s)...")
        print(f"  Rating: {args.rating if args.rating else f'random ({args.min_rating}-{args.max_rating})'}")
        print(f"  Images per log: {args.images}")
        print(f"  Private: {args.private}")
        if args.images > 0:
            print("Note: Image generation may take a minute per image...")

        created_logs = []
        for i in range(args.count):
            # Select recipe (specific or random)
            recipe = recipes[0] if args.recipe_id else random.choice(recipes)

            # Determine rating
            if args.rating:
                rating = args.rating
            else:
                rating = random.randint(args.min_rating, args.max_rating)

            print(f"\n[{i + 1}/{args.count}] Creating log for: {recipe.title}")
            print(f"  Rating: {rating}/5")

            log = await pipeline.generate_log(
                persona=persona,
                recipe=recipe,
                rating=rating,
                num_images=args.images,
                is_private=args.private,
            )
            created_logs.append((log, rating))

            print(f"  Created: {log.public_id}")

        # 8. Print summary
        print("\n" + "=" * 50)
        print(f"Successfully created {len(created_logs)} cooking log(s)!")
        print("=" * 50)

        for log, rating in created_logs:
            print(f"\nLog ID: {log.public_id}")
            print(f"  Rating: {'*' * rating} ({rating}/5)")
            print(f"  Recipe: {log.linked_recipe.title if log.linked_recipe else 'N/A'}")
            content_preview = log.content[:100] + "..." if len(log.content) > 100 else log.content
            print(f"  Content: {content_preview}")
            if log.images:
                print(f"  Images: {len(log.images)}")

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
