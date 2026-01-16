"""Recipe generation pipeline - coordinates text and image generation."""

import random
from typing import Any, Dict, List, Optional

import structlog

from ..api import PairingPlanetClient
from ..api.models import (
    ChangeCategory,
    CreateRecipeRequest,
    IngredientType,
    Recipe,
    RecipeIngredient,
    RecipeStep,
)
from ..generators import ImageGenerator, TextGenerator
from ..personas import BotPersona

logger = structlog.get_logger()


class RecipePipeline:
    """Pipeline for generating and publishing recipes."""

    def __init__(
        self,
        api_client: PairingPlanetClient,
        text_generator: TextGenerator,
        image_generator: ImageGenerator,
    ) -> None:
        self.api = api_client
        self.text_gen = text_generator
        self.image_gen = image_generator

    async def generate_original_recipe(
        self,
        persona: BotPersona,
        food_name: str,
        generate_images: bool = True,
        cover_image_count: int = 2,
    ) -> Recipe:
        """Generate and publish an original recipe.

        Args:
            persona: Bot persona to use
            food_name: Name of the dish to create
            generate_images: Whether to generate AI images
            cover_image_count: Number of cover images to generate

        Returns:
            Created Recipe from API
        """
        logger.info(
            "recipe_pipeline_start",
            persona=persona.name,
            food=food_name,
        )

        # 1. Generate recipe text
        recipe_data = await self.text_gen.generate_recipe(persona, food_name)

        # 2. Generate images if enabled
        image_public_ids: List[str] = []
        if generate_images:
            images = await self.image_gen.generate_recipe_images(
                dish_name=food_name,
                persona=persona,
                cover_count=cover_image_count,
            )

            # Upload cover images
            for img_bytes in images.get("cover_images", []):
                optimized = self.image_gen.optimize_image(img_bytes)
                upload = await self.api.upload_image_bytes(
                    optimized,
                    filename=f"{food_name.replace(' ', '_')}_cover.jpg",
                )
                image_public_ids.append(upload.public_id)

        # 3. Build recipe request
        ingredients = self._parse_ingredients(recipe_data.get("ingredients", []))
        steps = self._parse_steps(recipe_data.get("steps", []))

        request = CreateRecipeRequest(
            title=recipe_data["title"],
            description=recipe_data["description"],
            locale=persona.locale,
            culinary_locale=persona.culinary_locale,
            ingredients=ingredients,
            steps=steps,
            image_public_ids=image_public_ids,
            hashtags=recipe_data.get("hashtags", [])[:5],
            servings=recipe_data.get("servings"),
            cooking_time_range=recipe_data.get("cookingTimeRange"),
        )

        # 4. Create recipe via API
        recipe = await self.api.create_recipe(request)

        logger.info(
            "recipe_pipeline_complete",
            persona=persona.name,
            recipe_id=recipe.public_id,
            title=recipe.title,
            images=len(image_public_ids),
        )
        return recipe

    async def generate_variant_recipe(
        self,
        persona: BotPersona,
        parent_recipe: Recipe,
        variation_type: Optional[str] = None,
        generate_images: bool = True,
    ) -> Recipe:
        """Generate and publish a recipe variant.

        Args:
            persona: Bot persona to use
            parent_recipe: Recipe to create variant from
            variation_type: Type of variation (or auto-suggest)
            generate_images: Whether to generate AI images

        Returns:
            Created variant Recipe from API
        """
        # Auto-suggest variation type if not provided
        if not variation_type:
            suggestions = await self.text_gen.suggest_variation_types(
                persona=persona,
                recipe_title=parent_recipe.title,
                recipe_description=parent_recipe.description,
            )
            variation_type = suggestions[0] if suggestions else "creative"

        logger.info(
            "variant_pipeline_start",
            persona=persona.name,
            parent=parent_recipe.title,
            variation=variation_type,
        )

        # Convert parent to dict for text generation
        parent_dict = {
            "title": parent_recipe.title,
            "description": parent_recipe.description,
            "ingredients": [
                {"name": i.name, "amount": i.amount, "type": i.type}
                for i in parent_recipe.ingredients
            ],
            "steps": [
                {"order": s.order, "description": s.description}
                for s in parent_recipe.steps
            ],
        }

        # 1. Generate variant text
        variant_data = await self.text_gen.generate_variant(
            persona=persona,
            parent_recipe=parent_dict,
            variation_type=variation_type,
        )

        # 2. Generate images if enabled
        image_public_ids: List[str] = []
        if generate_images:
            images = await self.image_gen.generate_recipe_images(
                dish_name=variant_data["title"],
                persona=persona,
                cover_count=1,  # Fewer images for variants
            )

            for img_bytes in images.get("cover_images", []):
                optimized = self.image_gen.optimize_image(img_bytes)
                upload = await self.api.upload_image_bytes(
                    optimized,
                    filename=f"variant_cover.jpg",
                )
                image_public_ids.append(upload.public_id)

        # 3. Parse change categories
        change_categories = [
            ChangeCategory(cat)
            for cat in variant_data.get("changeCategories", [])
            if cat in [c.value for c in ChangeCategory]
        ]

        # 4. Build variant request
        ingredients = self._parse_ingredients(variant_data.get("ingredients", []))
        steps = self._parse_steps(variant_data.get("steps", []))

        request = CreateRecipeRequest(
            title=variant_data["title"],
            description=variant_data["description"],
            locale=persona.locale,
            culinary_locale=persona.culinary_locale,
            ingredients=ingredients,
            steps=steps,
            image_public_ids=image_public_ids,
            hashtags=variant_data.get("hashtags", [])[:5],
            servings=variant_data.get("servings"),
            cooking_time_range=variant_data.get("cookingTimeRange"),
            parent_public_id=parent_recipe.public_id,
            change_diff=variant_data.get("changeDiff", ""),
            change_reason=variant_data.get("changeReason", ""),
            change_categories=change_categories,
        )

        # 5. Create variant via API
        recipe = await self.api.create_recipe(request)

        logger.info(
            "variant_pipeline_complete",
            persona=persona.name,
            recipe_id=recipe.public_id,
            parent_id=parent_recipe.public_id,
            variation=variation_type,
        )
        return recipe

    async def generate_batch_recipes(
        self,
        persona: BotPersona,
        count: int = 5,
        variant_ratio: float = 0.5,
        generate_images: bool = True,
    ) -> List[Recipe]:
        """Generate a batch of recipes (mix of originals and variants).

        Args:
            persona: Bot persona to use
            count: Total number of recipes to generate
            variant_ratio: Ratio of variants (0.5 = 50% variants)
            generate_images: Whether to generate images

        Returns:
            List of created Recipe objects
        """
        recipes: List[Recipe] = []
        variant_count = int(count * variant_ratio)
        original_count = count - variant_count

        # Generate originals first
        food_suggestions = await self.text_gen.suggest_food_names(
            persona=persona,
            count=original_count,
        )

        for food_name in food_suggestions[:original_count]:
            try:
                recipe = await self.generate_original_recipe(
                    persona=persona,
                    food_name=food_name,
                    generate_images=generate_images,
                )
                recipes.append(recipe)
            except Exception as e:
                logger.error(
                    "batch_recipe_failed",
                    food=food_name,
                    error=str(e),
                )

        # Generate variants from created recipes
        if recipes and variant_count > 0:
            for _ in range(variant_count):
                parent = random.choice(recipes)
                try:
                    variant = await self.generate_variant_recipe(
                        persona=persona,
                        parent_recipe=parent,
                        generate_images=generate_images,
                    )
                    recipes.append(variant)
                except Exception as e:
                    logger.error(
                        "batch_variant_failed",
                        parent=parent.title,
                        error=str(e),
                    )

        logger.info(
            "batch_complete",
            persona=persona.name,
            total=len(recipes),
            originals=original_count,
            variants=len(recipes) - original_count,
        )
        return recipes

    def _parse_ingredients(
        self,
        ingredients_data: List[Dict[str, Any]],
    ) -> List[RecipeIngredient]:
        """Parse ingredient data from ChatGPT response."""
        result = []
        for i, ing in enumerate(ingredients_data):
            ing_type = ing.get("type", "MAIN").upper()
            if ing_type not in ["MAIN", "SECONDARY", "SEASONING"]:
                ing_type = "MAIN"

            result.append(
                RecipeIngredient(
                    name=ing.get("name", ""),
                    amount=ing.get("amount", ""),
                    type=IngredientType(ing_type),
                    order=i,
                )
            )
        return result

    def _parse_steps(
        self,
        steps_data: List[Dict[str, Any]],
    ) -> List[RecipeStep]:
        """Parse step data from ChatGPT response."""
        return [
            RecipeStep(
                order=step.get("order", i + 1),
                description=step.get("description", ""),
                image_public_ids=[],
            )
            for i, step in enumerate(steps_data)
        ]
