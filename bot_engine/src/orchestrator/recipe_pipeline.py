"""Recipe generation pipeline - coordinates text and image generation."""

import random
from typing import Any, Dict, List, Optional

import structlog

from ..api import CookstemmaClient
from ..api.models import (
    ChangeCategory,
    CreateRecipeRequest,
    IngredientType,
    MeasurementUnit,
    Recipe,
    RecipeIngredient,
    RecipeStep,
)
from ..generators import ImageGenerator, TextGenerator
from ..generators.text.prompts import CULTURAL_PREFERENCES, DIETARY_PREFERENCES
from ..personas import BotPersona

logger = structlog.get_logger()


class RecipePipeline:
    """Pipeline for generating and publishing recipes."""

    def __init__(
        self,
        api_client: CookstemmaClient,
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
        cover_image_count: int = 1,
        generate_step_images: bool = False,
        skip_dedup: bool = False,
    ) -> Recipe:
        """Generate and publish an original recipe.

        Args:
            persona: Bot persona to use
            food_name: Name of the dish to create
            generate_images: Whether to generate AI images
            cover_image_count: Number of cover images to generate
            generate_step_images: Whether to generate images for each step
            skip_dedup: Skip dedup check (used by batch caller that handles dedup separately)

        Returns:
            Created Recipe from API

        Raises:
            ValueError: If recipe for this food already exists (unless skip_dedup=True)
        """
        # Check if food already created (unless skipped by batch caller)
        if not skip_dedup:
            try:
                if await self.api.has_created_food(food_name):
                    raise ValueError(f"Recipe for '{food_name}' already exists for this bot")
            except ValueError:
                raise
            except Exception as e:
                logger.warning("dedup_check_failed", food=food_name, error=str(e))

        logger.info(
            "recipe_pipeline_start",
            persona=persona.name,
            food=food_name,
        )

        # 1. Generate recipe text
        recipe_data = await self.text_gen.generate_recipe(persona, food_name)

        # Validate response structure
        if isinstance(recipe_data, list):
            logger.error("recipe_data_is_list", data_preview=str(recipe_data)[:500])
            # If it's a list with one item that's a dict, unwrap it
            if len(recipe_data) == 1 and isinstance(recipe_data[0], dict):
                recipe_data = recipe_data[0]
            else:
                raise ValueError(f"Expected dict, got list: {str(recipe_data)[:200]}")

        if not isinstance(recipe_data, dict):
            raise ValueError(f"Expected dict, got {type(recipe_data).__name__}")

        logger.debug("recipe_data_received", title=recipe_data.get("title"), keys=list(recipe_data.keys()))

        # 2. Generate images if enabled
        image_public_ids: List[str] = []
        step_image_public_ids: List[str] = []

        if generate_images:
            step_count = len(recipe_data.get("steps", [])) if generate_step_images else 0

            if cover_image_count > 0 or step_count > 0:
                print(f"Generating {cover_image_count} cover image(s) and {step_count} step image(s)...")
                images = await self.image_gen.generate_recipe_images(
                    dish_name=food_name,
                    persona=persona,
                    cover_count=cover_image_count,
                    step_count=step_count,
                )
                print(f"Generated {len(images.get('cover_images', []))} cover images and {len(images.get('step_images', []))} step images")

                # Upload cover images
                for img_bytes in images.get("cover_images", []):
                    print(f"Uploading cover image ({len(img_bytes)} bytes)...")
                    optimized = self.image_gen.optimize_image(img_bytes)
                    upload = await self.api.upload_image_bytes(
                        optimized,
                        filename=f"{food_name.replace(' ', '_')}_cover.jpg",
                    )
                    print(f"Uploaded cover image: {upload.public_id}")
                    image_public_ids.append(upload.public_id)

                # Upload step images
                for i, img_bytes in enumerate(images.get("step_images", [])):
                    print(f"Uploading step image {i+1} ({len(img_bytes)} bytes)...")
                    optimized = self.image_gen.optimize_image(img_bytes)
                    upload = await self.api.upload_image_bytes(
                        optimized,
                        filename=f"{food_name.replace(' ', '_')}_step_{i+1}.jpg",
                    )
                    print(f"Uploaded step image: {upload.public_id}")
                    step_image_public_ids.append(upload.public_id)

        print(f"Total cover image_public_ids: {image_public_ids}")
        print(f"Total step image_public_ids: {step_image_public_ids}")

        # 3. Build recipe request
        ingredients = self._parse_ingredients(recipe_data.get("ingredients", []))
        steps = self._parse_steps(recipe_data.get("steps", []), step_image_public_ids)

        request = CreateRecipeRequest(
            title=recipe_data["title"][:100],
            description=recipe_data["description"][:500] if recipe_data.get("description") else None,
            locale=persona.locale,
            cooking_style=persona.cooking_style,
            original_language=persona.locale,
            new_food_name=food_name,
            ingredients=ingredients,
            steps=steps,
            image_public_ids=image_public_ids,
            hashtags=recipe_data.get("hashtags", [])[:5],
            servings=recipe_data.get("servings"),
            cooking_time_range=recipe_data.get("cookingTimeRange"),
        )

        # 4. Create recipe via API
        recipe = await self.api.create_recipe(request)

        # Record the food after successful creation (unless skipped)
        if not skip_dedup:
            try:
                await self.api.record_created_food(food_name, recipe.public_id)
            except Exception as e:
                logger.warning("failed_to_record_food", food=food_name, error=str(e))

        logger.info(
            "recipe_pipeline_complete",
            persona=persona.name,
            recipe_id=recipe.public_id,
            title=recipe.title,
            images=len(image_public_ids),
        )
        return recipe

    def select_parent_for_cross_cultural(
        self,
        persona: BotPersona,
        available_recipes: List[Recipe],
        cross_cultural_ratio: float = 0.8,
    ) -> Optional[Recipe]:
        """Select a parent recipe, preferring foreign cuisines for cross-cultural variants.

        Args:
            persona: Bot persona (determines target culture via cooking_style)
            available_recipes: Pool of recipes to select from
            cross_cultural_ratio: Probability of selecting foreign cuisine (default 80%)

        Returns:
            Selected Recipe or None if no suitable recipe found
        """
        if not available_recipes:
            return None

        persona_style = persona.cooking_style  # e.g., "KR", "JP", "US"

        # Separate recipes by cooking style
        foreign_recipes = [
            r for r in available_recipes
            if r.cooking_style and r.cooking_style != persona_style
        ]
        same_culture_recipes = [
            r for r in available_recipes
            if not r.cooking_style or r.cooking_style == persona_style
        ]

        # Decide whether to pick foreign or same-culture
        if foreign_recipes and random.random() < cross_cultural_ratio:
            selected = random.choice(foreign_recipes)
            logger.debug(
                "selected_foreign_parent",
                persona_style=persona_style,
                parent_style=selected.cooking_style,
                parent_title=selected.title,
            )
            return selected
        elif same_culture_recipes:
            return random.choice(same_culture_recipes)
        elif foreign_recipes:
            # Fall back to foreign if no same-culture available
            return random.choice(foreign_recipes)

        return None

    def get_cultural_context(
        self,
        source_style: str,
        target_style: str,
        dietary_focus: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Get cultural and dietary adaptation context for variant generation.

        Args:
            source_style: Cooking style of parent recipe (e.g., "IT")
            target_style: Cooking style of target persona (e.g., "KR")
            dietary_focus: Optional dietary focus of persona (e.g., "vegan")

        Returns:
            Dict with cultural and dietary adaptation guidance
        """
        target_prefs = CULTURAL_PREFERENCES.get(target_style, {})
        source_prefs = CULTURAL_PREFERENCES.get(source_style, {})
        dietary_prefs = DIETARY_PREFERENCES.get(dietary_focus, {}) if dietary_focus else {}

        # Merge avoid/prefer lists (combine cultural + dietary, remove duplicates)
        cultural_avoid = target_prefs.get("avoid_ingredients", [])
        dietary_avoid = dietary_prefs.get("avoid_ingredients", [])
        avoid = list(set(cultural_avoid + dietary_avoid))

        cultural_prefer = target_prefs.get("prefer_ingredients", [])
        dietary_prefer = dietary_prefs.get("prefer_ingredients", [])
        prefer = list(set(cultural_prefer + dietary_prefer))

        # Build combined cooking notes
        notes_parts = []
        if target_prefs.get("cooking_notes"):
            notes_parts.append(target_prefs["cooking_notes"])
        if dietary_prefs.get("cooking_notes"):
            notes_parts.append(dietary_prefs["cooking_notes"])

        return {
            "source_culture": source_prefs.get("name", source_style),
            "target_culture": target_prefs.get("name", target_style),
            "dietary_focus": dietary_prefs.get("name", ""),
            "avoid_ingredients": avoid,
            "prefer_ingredients": prefer,
            "cooking_notes": " ".join(notes_parts),
        }

    async def generate_variant_recipe(
        self,
        persona: BotPersona,
        parent_recipe: Recipe,
        variation_type: Optional[str] = None,
        generate_images: bool = True,
        cultural_context: Optional[Dict[str, Any]] = None,
    ) -> Recipe:
        """Generate and publish a recipe variant.

        Args:
            persona: Bot persona to use
            parent_recipe: Recipe to create variant from
            variation_type: Type of variation (or auto-suggest)
            generate_images: Whether to generate AI images
            cultural_context: Optional cultural adaptation context for cross-cultural variants

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

        is_cross_cultural = cultural_context is not None
        logger.info(
            "variant_pipeline_start",
            persona=persona.name,
            parent=parent_recipe.title,
            variation=variation_type,
            is_cross_cultural=is_cross_cultural,
            source_culture=cultural_context.get("source_culture") if cultural_context else None,
            target_culture=cultural_context.get("target_culture") if cultural_context else None,
        )

        # Convert parent to dict for text generation
        parent_dict = {
            "title": parent_recipe.title,
            "description": parent_recipe.description,
            "ingredients": [
                {
                    "name": i.name,
                    "quantity": i.quantity,
                    "unit": i.unit.value if i.unit else None,
                    "type": i.type,
                }
                for i in parent_recipe.ingredients
            ],
            "steps": [
                {"order": s.step_number, "description": s.description}
                for s in parent_recipe.steps
            ],
        }

        # 1. Generate variant text
        variant_data = await self.text_gen.generate_variant(
            persona=persona,
            parent_recipe=parent_dict,
            variation_type=variation_type,
            cultural_context=cultural_context,
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

        # Handle changeDiff - API expects a dict/object, not a string
        raw_change_diff = variant_data.get("changeDiff")
        if isinstance(raw_change_diff, dict):
            change_diff = raw_change_diff
        elif isinstance(raw_change_diff, str):
            # Wrap string in a dict with description key
            change_diff = {"description": raw_change_diff}
        else:
            change_diff = None

        # Use parent's description directly (empty if parent has none)
        description = parent_recipe.description[:500] if parent_recipe.description else ""

        request = CreateRecipeRequest(
            title=variant_data["title"][:100],
            description=description,
            locale=persona.locale,
            cooking_style=persona.cooking_style,
            original_language=persona.locale,
            ingredients=ingredients,
            steps=steps,
            image_public_ids=image_public_ids,
            hashtags=variant_data.get("hashtags", [])[:5],
            servings=variant_data.get("servings"),
            cooking_time_range=variant_data.get("cookingTimeRange"),
            parent_public_id=parent_recipe.public_id,
            change_diff=change_diff,
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

        # Fetch foods this bot has already created
        existing_foods: List[str] = []
        try:
            existing_foods = await self.api.get_created_foods()
            logger.info(
                "fetched_existing_foods",
                persona=persona.name,
                count=len(existing_foods),
            )
        except Exception as e:
            logger.warning("failed_to_fetch_existing_foods", error=str(e))

        # Generate originals, excluding existing foods
        food_suggestions = await self.text_gen.suggest_food_names(
            persona=persona,
            count=original_count + 5,  # Request extra in case some are filtered
            exclude=existing_foods,
        )

        # Filter suggestions (case-insensitive)
        existing_lower = {f.lower() for f in existing_foods}
        filtered_suggestions = [
            f for f in food_suggestions
            if f.lower() not in existing_lower
        ]

        for food_name in filtered_suggestions[:original_count]:
            try:
                recipe = await self.generate_original_recipe(
                    persona=persona,
                    food_name=food_name,
                    generate_images=generate_images,
                    skip_dedup=True,  # Batch handles dedup separately
                )
                recipes.append(recipe)

                # Record this food in bot memory
                try:
                    await self.api.record_created_food(food_name, recipe.public_id)
                except Exception as e:
                    logger.warning("failed_to_record_food", food=food_name, error=str(e))

                # Add to local list to prevent duplicates in same batch
                existing_lower.add(food_name.lower())

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
        """Parse ingredient data from AI response."""
        result = []
        for i, ing in enumerate(ingredients_data):
            # Handle case where ingredient might be a list (malformed response)
            if isinstance(ing, list):
                logger.warning("ingredient_is_list", index=i, data=ing)
                continue
            if not isinstance(ing, dict):
                logger.warning("ingredient_invalid_type", index=i, type=type(ing).__name__)
                continue

            ing_type = ing.get("type", "MAIN")
            if isinstance(ing_type, str):
                ing_type = ing_type.upper()
            else:
                ing_type = "MAIN"
            if ing_type not in ["MAIN", "SECONDARY", "SEASONING"]:
                ing_type = "MAIN"

            # Parse unit (validate against enum)
            unit_str = ing.get("unit")
            unit = None
            if unit_str and isinstance(unit_str, str):
                try:
                    unit = MeasurementUnit(unit_str.upper())
                except ValueError:
                    unit = None  # Invalid unit, will be ignored

            result.append(
                RecipeIngredient(
                    name=str(ing.get("name", "")),
                    quantity=ing.get("quantity"),
                    unit=unit,
                    type=IngredientType(ing_type),
                    order=i,
                )
            )
        return result

    def _parse_steps(
        self,
        steps_data: List[Dict[str, Any]],
        step_image_public_ids: Optional[List[str]] = None,
    ) -> List[RecipeStep]:
        """Parse step data from AI response.

        Args:
            steps_data: List of step dictionaries from AI
            step_image_public_ids: Optional list of image public IDs for each step
        """
        result = []
        for i, step in enumerate(steps_data):
            # Handle case where step might be a list (malformed response)
            if isinstance(step, list):
                logger.warning("step_is_list", index=i, data=step)
                continue
            if not isinstance(step, dict):
                logger.warning("step_invalid_type", index=i, type=type(step).__name__)
                continue

            image_id = None
            if step_image_public_ids and i < len(step_image_public_ids):
                image_id = step_image_public_ids[i]

            order = step.get("order", i + 1)
            if not isinstance(order, int):
                order = i + 1

            result.append(RecipeStep(
                step_number=order,
                description=str(step.get("description", "")),
                image_public_id=image_id,
            ))
        return result
