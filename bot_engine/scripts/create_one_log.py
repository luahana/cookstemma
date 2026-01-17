#!/usr/bin/env python3
"""Create a cooking log for an existing recipe with AI-generated content.

This script generates one AI-generated cooking log using a bot persona,
complete with a casual-style "user photo" generated via OpenAI DALL-E.

Usage:
    cd bot_engine
    python scripts/create_one_log.py
    python scripts/create_one_log.py --recipe-id abc123
    python scripts/create_one_log.py --outcome PARTIAL

Prerequisites:
    - Backend running at http://localhost:4001
    - OPENAI_API_KEY configured in .env
    - Bot API keys configured in .env
    - At least one recipe exists in the database
"""

import argparse
import asyncio
import os
import sys

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Load .env file
from dotenv import load_dotenv
load_dotenv()

from src.api import PairingPlanetClient
from src.api.models import LogOutcome
from src.config import get_settings
from src.generators import ImageGenerator, TextGenerator
from src.orchestrator.log_pipeline import LogPipeline
from src.personas import get_persona_registry


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Create a cooking log for an existing recipe with AI-generated content."
    )
    parser.add_argument(
        "--recipe-id",
        type=str,
        help="Public ID of the recipe to create a log for. If not provided, uses the most recent recipe.",
    )
    parser.add_argument(
        "--outcome",
        type=str,
        choices=["SUCCESS", "PARTIAL", "FAILED"],
        default="SUCCESS",
        help="Cooking outcome (default: SUCCESS)",
    )
    parser.add_argument(
        "--no-image",
        action="store_true",
        help="Skip image generation",
    )
    return parser.parse_args()


async def main() -> None:
    """Create a single AI-generated cooking log with image."""
    args = parse_args()

    # Load settings
    settings = get_settings()

    # Check for OpenAI API key
    if not settings.openai_api_key or settings.openai_api_key == "sk-test-placeholder":
        print("Error: OPENAI_API_KEY not configured in .env")
        print("Add your OpenAI API key to bot_engine/.env:")
        print("  OPENAI_API_KEY=sk-your-key-here")
        sys.exit(1)

    # 1. Get persona
    registry = get_persona_registry()
    persona = registry.get("chef_park_soojin")  # Korean professional chef

    if not persona:
        print("Error: Persona 'chef_park_soojin' not found")
        sys.exit(1)

    print(f"Using persona: {persona.display_name.get('en', persona.name)}")

    # 2. Setup clients
    api_client = PairingPlanetClient()
    text_gen = TextGenerator()
    image_gen = ImageGenerator()

    try:
        # 3. Authenticate with bot API key
        api_key = os.getenv(
            "BOT_API_KEY_CHEF_PARK_SOOJIN",
            os.getenv("BOT_API_KEY", ""),
        )

        if not api_key:
            print("Error: Bot API key not configured")
            print("Set BOT_API_KEY_CHEF_PARK_SOOJIN or BOT_API_KEY in .env")
            sys.exit(1)

        print("Authenticating with backend...")
        await api_client.login_bot(api_key=api_key)
        print("Authenticated successfully!")

        # 4. Fetch recipe
        if args.recipe_id:
            print(f"\nFetching recipe: {args.recipe_id}")
            recipe = await api_client.get_recipe(args.recipe_id)
        else:
            print("\nFetching most recent recipe...")
            recipes = await api_client.get_recipes(page=0, size=1)
            if not recipes:
                print("Error: No recipes found in database")
                print("Run create_one_recipe.py first to create a recipe.")
                sys.exit(1)
            recipe = recipes[0]

        print(f"Using recipe: {recipe.title} (ID: {recipe.public_id})")

        # 5. Create pipeline and generate log
        pipeline = LogPipeline(api_client, text_gen, image_gen)

        outcome = LogOutcome(args.outcome)
        generate_image = not args.no_image

        print(f"\nGenerating cooking log...")
        print(f"  Outcome: {outcome.value}")
        print(f"  Generate image: {generate_image}")
        if generate_image:
            print("This may take a minute (generating text + casual photo image)...")

        log = await pipeline.generate_log(
            persona=persona,
            recipe=recipe,
            outcome=outcome,
            generate_image=generate_image,
        )

        # 6. Print results
        print("\n" + "=" * 50)
        print("Cooking log created successfully!")
        print("=" * 50)
        print(f"Public ID: {log.public_id}")
        print(f"Title: {log.title}")
        print(f"Outcome: {log.outcome.value}")
        print(f"Recipe: {log.recipe_title}")
        print(f"\nContent:")
        content_preview = log.content[:200] + "..." if len(log.content) > 200 else log.content
        print(f"  {content_preview}")

        if log.hashtags:
            print(f"\nHashtags: {' '.join(f'#{h}' for h in log.hashtags)}")

        if log.image_urls:
            print("\nImage URLs:")
            for i, url in enumerate(log.image_urls, 1):
                print(f"  {i}. {url}")

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
