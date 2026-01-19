"""Prompt templates for content generation."""

from typing import List, Optional


class RecipePrompts:
    """Prompts for recipe generation."""

    @staticmethod
    def generate_original_recipe(
        food_name: str,
        locale: str,
        culinary_style: str,
        specialties: List[str],
    ) -> str:
        """Generate prompt for creating an original recipe."""
        lang = "Korean" if locale.startswith("ko") else "English"
        specialties_str = ", ".join(specialties) if specialties else "various"

        # US uses cups/tablespoons/ounces; rest of world uses metric
        use_us_measurements = locale.endswith("-US") or locale == "en-US"

        if use_us_measurements:
            unit_codes = """Unit codes (USE US MEASUREMENTS):
- Volume: TSP (teaspoon), TBSP (tablespoon), CUP, FL_OZ (fluid ounce), PINT, QUART
- Weight: OZ (ounce), LB (pound)
- Count/Other: PIECE, PINCH, DASH, TO_TASTE, CLOVE, BUNCH, CAN, PACKAGE"""
            unit_instruction = "Use US measurement units (CUP, TBSP, TSP, OZ, LB) - NOT metric units like grams or milliliters"
        else:
            unit_codes = """Unit codes (USE METRIC MEASUREMENTS):
- Volume: ML (milliliter), L (liter)
- Weight: G (gram), KG (kilogram)
- Count/Other: PIECE, PINCH, DASH, TO_TASTE, CLOVE, BUNCH, CAN, PACKAGE"""
            unit_instruction = "Use metric units (G, KG, ML, L) - NOT cups or ounces"

        return f"""Create a complete recipe for "{food_name}" in the style of {culinary_style} cuisine.

Your specialties include: {specialties_str}

Generate a recipe with the following structure in JSON format:
{{
    "title": "Recipe title (include dish name + key cooking method/style, e.g., 'Crispy Pan-Fried Chicken with Garlic Butter Sauce')",
    "description": "2-3 sentences that include: the dish name, main ingredients, cooking method, and why it's delicious. Write naturally but include searchable terms.",
    "servings": number (1-8),
    "cookingTimeRange": "UNDER_15" | "UNDER_30" | "UNDER_60" | "OVER_60",
    "ingredients": [
        {{
            "name": "ingredient name",
            "quantity": number (e.g., 2.0, 100, 0.5),
            "unit": "UNIT_CODE",
            "type": "MAIN" | "SECONDARY" | "SEASONING"
        }}
    ],
    "steps": [
        {{
            "order": 1,
            "description": "Detailed step with specific cooking terms (e.g., 'sauté', 'simmer', 'fold'), temperatures, and timing"
        }}
    ],
    "hashtags": ["tag1", "tag2", "tag3", "tag4", "tag5"],
    "tipFromChef": "One helpful cooking tip"
}}

{unit_codes}

Requirements:
- Write EVERYTHING in {lang}
- Include 5-15 ingredients with realistic amounts
- {unit_instruction}
- IMPORTANT: Every ingredient MUST have both quantity (number) and unit filled
- Include 4-10 detailed cooking steps
- Make the description personal and engaging
- Include 5 relevant hashtags (without #)
- Cooking time should match the complexity
- SEO: Include dish name in title, mention key ingredients and cooking methods in description
- Steps should use specific culinary terms (sauté, blanch, fold, etc.) and include temperatures/times

Return ONLY valid JSON, no additional text."""

    @staticmethod
    def generate_variant_recipe(
        parent_title: str,
        parent_description: str,
        parent_ingredients: str,
        parent_steps: str,
        locale: str,
        variation_type: str,
    ) -> str:
        """Generate prompt for creating a recipe variant."""
        lang = "Korean" if locale.startswith("ko") else "English"

        # US uses cups/tablespoons/ounces; rest of world uses metric
        use_us_measurements = locale.endswith("-US") or locale == "en-US"

        if use_us_measurements:
            unit_codes = """Unit codes (USE US MEASUREMENTS):
- Volume: TSP (teaspoon), TBSP (tablespoon), CUP, FL_OZ (fluid ounce), PINT, QUART
- Weight: OZ (ounce), LB (pound)
- Count/Other: PIECE, PINCH, DASH, TO_TASTE, CLOVE, BUNCH, CAN, PACKAGE"""
            unit_instruction = "Use US measurement units (CUP, TBSP, TSP, OZ, LB) - NOT metric units like grams or milliliters"
        else:
            unit_codes = """Unit codes (USE METRIC MEASUREMENTS):
- Volume: ML (milliliter), L (liter)
- Weight: G (gram), KG (kilogram)
- Count/Other: PIECE, PINCH, DASH, TO_TASTE, CLOVE, BUNCH, CAN, PACKAGE"""
            unit_instruction = "Use metric units (G, KG, ML, L) - NOT cups or ounces"

        variation_instructions = {
            "healthier": "Make a healthier version - reduce oil, sugar, or use better alternatives",
            "budget": "Make a budget-friendly version - substitute expensive ingredients with cheaper ones",
            "quick": "Make a quicker version - simplify steps or use shortcuts",
            "vegetarian": "Make a vegetarian version - replace meat with plant-based alternatives",
            "spicier": "Make a spicier version - add more heat and bold flavors",
            "kid_friendly": "Make a kid-friendly version - milder flavors, fun presentation",
            "gourmet": "Make a gourmet version - elevate with premium ingredients and techniques",
        }

        instruction = variation_instructions.get(
            variation_type,
            "Create a creative variation with meaningful improvements",
        )

        return f"""You are creating a VARIANT of an existing recipe.

ORIGINAL RECIPE:
Title: {parent_title}
Description: {parent_description}
Ingredients: {parent_ingredients}
Steps: {parent_steps}

TASK: {instruction}

Generate a variant recipe in JSON format:
{{
    "title": "Title with variation type + dish name (e.g., 'Quick 15-Minute Garlic Butter Shrimp' or 'Healthy Low-Carb Chicken Stir-Fry')",
    "description": "2-3 sentences that include: what changed, the dish name, key ingredients, and cooking method. Write naturally but include searchable terms.",
    "servings": number,
    "cookingTimeRange": "UNDER_15" | "UNDER_30" | "UNDER_60" | "OVER_60",
    "ingredients": [
        {{
            "name": "ingredient name",
            "quantity": number (e.g., 2.0, 100, 0.5),
            "unit": "UNIT_CODE",
            "type": "MAIN" | "SECONDARY" | "SEASONING"
        }}
    ],
    "steps": [
        {{
            "order": 1,
            "description": "Detailed step with specific cooking terms (e.g., 'sauté', 'simmer', 'fold'), temperatures, and timing"
        }}
    ],
    "hashtags": ["tag1", "tag2", "tag3", "tag4", "tag5"],
    "changeDiff": "Clear description of what changed from the original",
    "changeReason": "Why you made these changes (1-2 sentences)",
    "changeCategories": ["INGREDIENT_SUBSTITUTION", "QUANTITY_ADJUSTMENT", "COOKING_METHOD", "SEASONING_CHANGE", "DIETARY_ADAPTATION", "TIME_OPTIMIZATION", "EQUIPMENT_CHANGE", "PRESENTATION"]
}}

{unit_codes}

Requirements:
- Write EVERYTHING in {lang}
- Make meaningful, noticeable changes (not just minor tweaks)
- Keep the dish recognizable as a variant of the original
- {unit_instruction}
- IMPORTANT: Every ingredient MUST have both quantity (number) and unit filled
- Clearly explain what changed and why
- Select 1-3 appropriate changeCategories
- SEO: Include variation type and dish name in title, mention key ingredients and cooking methods in description
- Steps should use specific culinary terms (sauté, blanch, fold, etc.) and include temperatures/times

Return ONLY valid JSON, no additional text."""


class LogPrompts:
    """Prompts for cooking log generation."""

    @staticmethod
    def generate_log(
        recipe_title: str,
        recipe_description: str,
        outcome: str,
        locale: str,
        persona_background: str,
    ) -> str:
        """Generate prompt for creating a cooking log."""
        lang = "Korean" if locale.startswith("ko") else "English"

        outcome_instructions = {
            "SUCCESS": "You successfully made this dish and it turned out great!",
            "PARTIAL": "The dish turned out okay but not perfect - something was a bit off.",
            "FAILED": "The cooking attempt didn't go well - describe what went wrong.",
        }

        return f"""You just cooked "{recipe_title}" - {recipe_description}

Result: {outcome_instructions.get(outcome, outcome_instructions["SUCCESS"])}

Your background: {persona_background}

Write a cooking log entry in JSON format:
{{
    "title": "Short, catchy title for this cooking experience",
    "content": "2-4 paragraphs describing your cooking experience. Include:
        - How the cooking process went
        - Any challenges or surprises
        - How it tasted/looked
        - Tips for others or what you'd do differently
        - Personal touch reflecting your personality",
    "hashtags": ["tag1", "tag2", "tag3", "tag4", "tag5"]
}}

Requirements:
- Write EVERYTHING in {lang}
- Be authentic and personal - this is YOUR cooking experience
- Match the outcome ({outcome}) in your tone and content
- Include specific details that make it feel real
- 5 relevant hashtags (without #)

Return ONLY valid JSON, no additional text."""

    @staticmethod
    def generate_failed_log_details(locale: str) -> str:
        """Generate realistic failure scenarios."""
        lang = "Korean" if locale.startswith("ko") else "English"

        return f"""Generate a realistic cooking failure scenario in {lang}.
Pick ONE of these failure types and describe it vividly:
- Burnt food (forgot to set timer, heat too high)
- Undercooked (didn't check temperature, impatient)
- Wrong ingredient measurement (too much salt, not enough sugar)
- Missing ingredient discovered mid-cooking
- Equipment malfunction (oven temperature off, blender broke)
- Timing issues (everything finished at different times)
- Texture problems (too dry, too soggy, too tough)

Return as JSON:
{{
    "failureType": "Brief failure type",
    "whatWentWrong": "Specific description of the failure",
    "emotionalReaction": "How you felt about it"
}}

Return ONLY valid JSON."""
