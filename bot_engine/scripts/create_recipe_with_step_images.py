#!/usr/bin/env python3
"""Create a recipe with multiple cover photos and step images.

This script generates an AI-generated recipe with:
- 3 cover images
- Step images for each cooking step

Usage:
    cd bot_engine
    python scripts/create_recipe_with_step_images.py

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
from src.api.models import (
    CreateRecipeRequest,
    IngredientType,
    RecipeIngredient,
    RecipeStep,
)
from src.config import get_settings
from src.generators import ImageGenerator, TextGenerator
from src.personas import get_persona_registry


async def main() -> None:
    """Create a recipe with 3 cover images and step images."""
    # Load settings
    settings = get_settings()

    # Check for OpenAI API key
    if not settings.openai_api_key or settings.openai_api_key == "sk-test-placeholder":
        print("Error: OPENAI_API_KEY not configured in .env")
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
            sys.exit(1)

        print("Authenticating with backend...")
        await api_client.login_bot(api_key=api_key)
        print("Authenticated successfully!")

        # 4. Generate recipe text
        food_name = "Bibimbap"  # Korean mixed rice bowl
        print(f"\nGenerating recipe text for: {food_name}")
        recipe_data = await text_gen.generate_recipe(persona, food_name)
        print(f"Recipe: {recipe_data['title']}")
        print(f"Steps: {len(recipe_data.get('steps', []))} steps")

        # 5. Generate and upload COVER images (3)
        print("\n--- Generating 3 Cover Images ---")
        cover_image_ids = []
        cover_images = await image_gen.generate_recipe_images(
            dish_name=food_name,
            persona=persona,
            cover_count=3,
        )

        for i, img_bytes in enumerate(cover_images.get("cover_images", []), 1):
            print(f"Uploading cover image {i}/3 ({len(img_bytes)} bytes)...")
            optimized = image_gen.optimize_image(img_bytes)
            upload = await api_client.upload_image_bytes(
                optimized,
                filename=f"{food_name.replace(' ', '_')}_cover_{i}.jpg",
            )
            cover_image_ids.append(upload.public_id)
            print(f"  -> Uploaded: {upload.public_id}")

        print(f"Cover images uploaded: {len(cover_image_ids)}")

        # 6. Generate and upload STEP images
        print("\n--- Generating Step Images ---")
        steps_data = recipe_data.get("steps", [])
        step_image_ids = {}  # step_number -> image_public_id

        for step in steps_data:
            step_num = step.get("order", 0)
            step_desc = step.get("description", "")

            print(f"\nStep {step_num}: {step_desc[:50]}...")

            # Generate step image with description as context
            step_prompt = f"""Professional food photography of cooking step for {food_name}.
Step: {step_desc}
{persona.kitchen_style_prompt}
Show the cooking process in action with chef's hands visible.
Clean, well-lit kitchen background.
Sharp focus on the main action."""

            print(f"  Generating step image...")
            try:
                img_bytes = await image_gen.generate_image(step_prompt)
                if img_bytes:
                    optimized = image_gen.optimize_image(img_bytes)
                    upload = await api_client.upload_image_bytes(
                        optimized,
                        filename=f"{food_name.replace(' ', '_')}_step_{step_num}.jpg",
                        image_type="STEP",
                    )
                    step_image_ids[step_num] = upload.public_id
                    print(f"  -> Uploaded: {upload.public_id}")
                else:
                    print(f"  -> Failed to generate image")
            except Exception as e:
                print(f"  -> Error generating step image: {e}")

        print(f"\nStep images uploaded: {len(step_image_ids)}")

        # 7. Build ingredients
        ingredients = []
        for i, ing in enumerate(recipe_data.get("ingredients", [])):
            ing_type = ing.get("type", "MAIN").upper()
            if ing_type not in ["MAIN", "SECONDARY", "SEASONING"]:
                ing_type = "MAIN"
            ingredients.append(
                RecipeIngredient(
                    name=ing.get("name", ""),
                    amount=ing.get("amount", ""),
                    type=IngredientType(ing_type),
                    order=i,
                )
            )

        # 8. Build steps with images
        steps = []
        for i, step in enumerate(steps_data):
            step_num = step.get("order", i + 1)
            steps.append(
                RecipeStep(
                    step_number=step_num,
                    description=step.get("description", ""),
                    image_public_id=step_image_ids.get(step_num),
                )
            )

        # 9. Create recipe
        print("\n--- Creating Recipe ---")
        request = CreateRecipeRequest(
            title=recipe_data["title"],
            description=recipe_data["description"],
            locale=persona.locale,
            culinary_locale=persona.culinary_locale,
            new_food_name=food_name,
            ingredients=ingredients,
            steps=steps,
            image_public_ids=cover_image_ids,
            hashtags=recipe_data.get("hashtags", [])[:5],
            servings=recipe_data.get("servings"),
            cooking_time_range=recipe_data.get("cookingTimeRange"),
        )

        recipe = await api_client.create_recipe(request)

        # 10. Print results
        print("\n" + "=" * 50)
        print("Recipe created successfully!")
        print("=" * 50)
        print(f"Public ID: {recipe.public_id}")
        print(f"Title: {recipe.title}")
        print(f"Description: {recipe.description[:100]}...")
        print(f"Ingredients: {len(recipe.ingredients)} items")
        print(f"Steps: {len(recipe.steps)} steps")
        print(f"Cover Images: {len(recipe.images)}")

        print("\nCover Image URLs:")
        for i, img in enumerate(recipe.images, 1):
            print(f"  {i}. {img.image_url}")

        print("\nStep Images:")
        for step in recipe.steps:
            has_img = "with image" if step.image_public_id else "no image"
            print(f"  Step {step.step_number}: {has_img}")

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
