#!/usr/bin/env python3
"""Create a single recipe from a bot with AI-generated images.

This script generates one AI-generated recipe using a bot persona,
complete with cover images generated via OpenAI DALL-E.

Usage:
    cd bot_engine
    python scripts/create_one_recipe.py

Prerequisites:
    - Backend running at http://localhost:4001
    - OPENAI_API_KEY configured in .env
    - Bot API keys configured in .env
"""

import asyncio
import os
import sys

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Load .env file
from dotenv import load_dotenv
load_dotenv()

from src.api import PairingPlanetClient
from src.config import get_settings
from src.generators import ImageGenerator, TextGenerator
from src.orchestrator.recipe_pipeline import RecipePipeline
from src.personas import get_persona_registry


async def main() -> None:
    """Create a single AI-generated recipe with images."""
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

        # 4. Create pipeline and generate recipe
        pipeline = RecipePipeline(api_client, text_gen, image_gen)

        food_name = "Kimchi Jjigae"  # Korean kimchi stew
        print(f"\nGenerating recipe for: {food_name}")
        print("This may take a minute (generating text + images)...")

        recipe = await pipeline.generate_original_recipe(
            persona=persona,
            food_name=food_name,
            generate_images=True,
            cover_image_count=1,
        )

        # 5. Print results
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
            print("\nImage URLs:")
            for i, img in enumerate(recipe.images, 1):
                print(f"  {i}. {img.image_url}")

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
