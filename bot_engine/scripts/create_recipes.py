#!/usr/bin/env python3
"""Create AI-generated recipes from bot personas.

This script generates recipes using Gemini 3 Pro Image with retry logic.

Prerequisites:
    - Backend running at http://localhost:4000
    - GEMINI_API_KEY in .env
    - BOT_INTERNAL_SECRET in .env
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
from src.config import get_settings
from src.generators import ImageGenerator, TextGenerator
from src.orchestrator.recipe_pipeline import RecipePipeline
from src.personas import BotPersona, get_persona_registry

@dataclass
class RecipeResult:
    persona_name: str
    success: bool
    recipe_id: Optional[str] = None
    recipe_title: Optional[str] = None
    error: Optional[str] = None

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create recipes using Gemini 3 Pro Image")
    parser.add_argument("--persona", type=str, default=None, help="Persona name")
    parser.add_argument("--food", type=str, default=None, help="Specific food name")
    parser.add_argument("--count", type=int, default=1, help="Number of recipes")
    parser.add_argument("--step-images", action="store_true", help="Generate step images")
    parser.add_argument("--cover", type=int, choices=[1, 2, 3], default=1, help="Cover image count")
    parser.add_argument("--batch-size", type=int, default=5, help="Batch size")
    parser.add_argument("--delay", type=int, default=3, help="Seconds between recipes")
    parser.add_argument("--batch-delay", type=int, default=15, help="Seconds between batches")
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
    try:
        auth = await api_client.login_by_persona(persona.name)
        persona.user_public_id = auth.user_public_id
        persona.persona_public_id = auth.persona_public_id

        existing_foods = await api_client.get_created_foods()

        if food_name:
            chosen_food = food_name
        else:
            suggestions = await text_gen.suggest_food_names(persona=persona, count=1, exclude=existing_foods)
            if not suggestions:
                return RecipeResult(persona_name=persona.name, success=False, error="AI suggest failed")
            chosen_food = suggestions[0]

        print(f"  Target Food: {chosen_food}")
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
        return RecipeResult(persona_name=persona.name, success=False, error=str(e))

async def main() -> None:
    args = parse_args()
    settings = get_settings()

    # Validate Keys
    if not settings.gemini_api_key or settings.gemini_api_key == "placeholder":
        print("Error: GEMINI_API_KEY not found in .env")
        sys.exit(1)

    api_client = CookstemmaClient()
    text_gen = TextGenerator()  # Uses Gemini for text
    image_gen = ImageGenerator()  # Uses Gemini 3 Pro with retry

    try:
        registry = get_persona_registry()
        await registry.initialize(api_client)
        all_personas = registry.get_all()

        if args.count > 1:
            print(f"\n🚀 Batch Mode: Generating {args.count} recipes...")
            for i in range(args.count):
                persona = random.choice(all_personas)
                print(f"[{i+1}/{args.count}] Using {persona.name}")
                
                result = await create_recipe_for_persona(
                    persona, api_client, text_gen, image_gen, args.step_images, args.cover
                )
                
                if (i + 1) % args.batch_size == 0 and i < args.count - 1:
                    print(f"Waiting {args.batch_delay}s for next batch...")
                    await asyncio.sleep(args.batch_delay)
                elif i < args.count - 1:
                    await asyncio.sleep(args.delay)
        else:
            # Single mode
            persona = registry.get(args.persona) if args.persona else random.choice(all_personas)
            print(f"Generating single recipe for {persona.name}...")
            result = await create_recipe_for_persona(
                persona, api_client, text_gen, image_gen, args.step_images, args.cover, args.food
            )
            if result.success:
                print(f"✓ Success: {result.recipe_title} ({result.recipe_id})")
            else:
                print(f"✗ Failed: {result.error}")

    finally:
        await api_client.close()
        await image_gen.close()

if __name__ == "__main__":
    asyncio.run(main())