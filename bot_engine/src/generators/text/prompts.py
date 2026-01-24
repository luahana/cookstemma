"""Prompt templates for content generation."""

from typing import Any, Dict, List, Optional

from ...personas.models import LOCALE_TO_LANGUAGE


# Cultural preferences mapping for cross-cultural recipe adaptation
CULTURAL_PREFERENCES: Dict[str, Dict[str, Any]] = {
    "KR": {
        "name": "Korean",
        "avoid_ingredients": [
            "cilantro", "cumin", "blue cheese", "lamb",
            "strong curry", "fennel", "licorice",
        ],
        "prefer_ingredients": [
            "gochugaru", "gochujang", "doenjang", "sesame oil", "kimchi",
            "perilla leaves", "soy sauce", "garlic", "green onions", "tofu",
        ],
        "cooking_notes": (
            "Koreans often prefer bold fermented flavors, less raw vegetables, "
            "more banchan-style sides. Dishes often include rice as a staple."
        ),
    },
    "JP": {
        "name": "Japanese",
        "avoid_ingredients": [
            "cilantro", "strong spices", "excessive oil", "raw garlic",
            "heavy cream", "blue cheese",
        ],
        "prefer_ingredients": [
            "dashi", "miso", "soy sauce", "mirin", "sake", "nori",
            "wasabi", "ginger", "rice vinegar", "sesame seeds",
        ],
        "cooking_notes": (
            "Japanese cuisine values subtle umami, clean presentation, "
            "seasonal ingredients. Less oil, more steaming and grilling."
        ),
    },
    "US": {
        "name": "American",
        "avoid_ingredients": [
            "fish sauce", "fermented bean paste", "offal", "insects",
            "durian", "natto", "stinky tofu",
        ],
        "prefer_ingredients": [
            "butter", "cheese", "bacon", "ranch", "bbq sauce",
            "ketchup", "mayonnaise", "cheddar", "cream cheese",
        ],
        "cooking_notes": (
            "American palate prefers familiar comfort flavors, larger portions. "
            "Grilling, frying, and baking are popular cooking methods."
        ),
    },
    "IT": {
        "name": "Italian",
        "avoid_ingredients": [
            "soy sauce", "gochujang", "fish sauce", "heavy cream in pasta",
            "ketchup on pasta", "pineapple on pizza",
        ],
        "prefer_ingredients": [
            "olive oil", "parmesan", "basil", "tomato", "garlic",
            "oregano", "mozzarella", "prosciutto", "balsamic vinegar",
        ],
        "cooking_notes": (
            "Italian cuisine values simplicity, quality ingredients, "
            "regional traditions. Al dente pasta, fresh herbs."
        ),
    },
    "CN": {
        "name": "Chinese",
        "avoid_ingredients": [
            "cheese", "raw salads", "cold dishes in winter",
            "rare meat", "blue cheese",
        ],
        "prefer_ingredients": [
            "soy sauce", "oyster sauce", "shaoxing wine", "ginger",
            "scallions", "five spice", "chili oil", "Sichuan peppercorn",
        ],
        "cooking_notes": (
            "Chinese cooking emphasizes wok hei, balanced textures, "
            "medicinal food concepts. Hot dishes preferred."
        ),
    },
    "MX": {
        "name": "Mexican",
        "avoid_ingredients": [
            "soy sauce", "fish sauce", "raw fish",
            "miso", "seaweed",
        ],
        "prefer_ingredients": [
            "chili peppers", "lime", "cilantro", "cumin", "corn tortillas",
            "avocado", "tomato", "onion", "jalapeño", "queso fresco",
        ],
        "cooking_notes": (
            "Mexican cuisine uses bold spices, fresh salsas, corn-based staples. "
            "Layered flavors with heat and acidity."
        ),
    },
    "IN": {
        "name": "Indian",
        "avoid_ingredients": [
            "beef", "pork", "raw fish",
            "rare meat",
        ],
        "prefer_ingredients": [
            "cumin", "turmeric", "garam masala", "ghee", "yogurt",
            "lentils", "coriander", "cardamom", "chili", "ginger",
        ],
        "cooking_notes": (
            "Indian cooking uses layered spices, often vegetarian-friendly. "
            "Regional variations significant. Bread and rice as staples."
        ),
    },
    "TH": {
        "name": "Thai",
        "avoid_ingredients": [
            "cheese", "butter", "heavy cream",
            "raw beef",
        ],
        "prefer_ingredients": [
            "fish sauce", "lemongrass", "galangal", "Thai basil",
            "coconut milk", "chilies", "lime", "palm sugar", "shrimp paste",
        ],
        "cooking_notes": (
            "Thai cuisine balances sweet, sour, salty, spicy in each dish. "
            "Fresh herbs essential. Rice as staple."
        ),
    },
    "FR": {
        "name": "French",
        "avoid_ingredients": [
            "fish sauce", "gochujang", "extreme spice",
            "ketchup", "processed cheese",
        ],
        "prefer_ingredients": [
            "butter", "cream", "wine", "shallots", "herbs de provence",
            "dijon mustard", "tarragon", "thyme", "gruyere",
        ],
        "cooking_notes": (
            "French cooking emphasizes technique, sauces, regional terroir. "
            "Quality ingredients and proper methodology."
        ),
    },
    "VN": {
        "name": "Vietnamese",
        "avoid_ingredients": [
            "cheese", "heavy cream", "excessive oil",
            "butter",
        ],
        "prefer_ingredients": [
            "fish sauce", "rice noodles", "fresh herbs", "lime",
            "bean sprouts", "cilantro", "mint", "lemongrass", "shrimp paste",
        ],
        "cooking_notes": (
            "Vietnamese cuisine values fresh herbs, light broths, "
            "balanced flavors. Less oil, more steaming."
        ),
    },
}


# Dietary preferences mapping for dietary-focused recipe adaptation
DIETARY_PREFERENCES: Dict[str, Dict[str, Any]] = {
    # === Existing types (mapped from DietaryFocus enum values) ===
    "vegetarian": {
        "name": "Vegetarian",
        "avoid_ingredients": [
            "beef", "pork", "chicken", "fish", "seafood",
            "gelatin", "lard", "animal rennet",
        ],
        "prefer_ingredients": [
            "tofu", "tempeh", "legumes", "mushrooms",
            "cheese", "eggs", "paneer",
        ],
        "cooking_notes": (
            "Replace meat with plant-based proteins. Eggs and dairy are allowed."
        ),
    },
    "healthy": {
        "name": "Healthy",
        "avoid_ingredients": [
            "excessive oil", "deep frying", "heavy cream",
            "processed foods", "refined sugar", "trans fats",
        ],
        "prefer_ingredients": [
            "olive oil", "lean protein", "whole grains", "vegetables",
            "fresh herbs", "nuts", "seeds",
        ],
        "cooking_notes": (
            "Focus on nutrient-dense ingredients, lighter cooking methods, "
            "balanced portions."
        ),
    },
    "budget": {
        "name": "Budget-Friendly",
        "avoid_ingredients": [
            "wagyu", "truffle", "saffron", "lobster", "caviar", "premium cuts",
        ],
        "prefer_ingredients": [
            "chicken thighs", "legumes", "seasonal vegetables",
            "rice", "eggs", "canned goods",
        ],
        "cooking_notes": (
            "Use affordable staples, maximize flavor from simple ingredients."
        ),
    },
    "fine_dining": {
        "name": "Fine Dining",
        "avoid_ingredients": [
            "instant foods", "canned vegetables", "processed cheese",
        ],
        "prefer_ingredients": [
            "fresh herbs", "quality proteins", "compound butter",
            "reductions", "garnishes",
        ],
        "cooking_notes": (
            "Emphasize technique, presentation, and premium ingredients."
        ),
    },
    "quick_meals": {
        "name": "Quick Meals",
        "avoid_ingredients": [
            "slow-cook meats", "dried beans", "long-marinated items",
        ],
        "prefer_ingredients": [
            "pre-cut vegetables", "quick-cooking proteins",
            "canned beans", "frozen vegetables",
        ],
        "cooking_notes": (
            "Streamline steps, use time-saving ingredients, prioritize "
            "30-minute meals."
        ),
    },
    "baking": {
        "name": "Baking-Focused",
        "avoid_ingredients": [],
        "prefer_ingredients": [
            "flour", "butter", "sugar", "eggs", "yeast", "baking powder",
        ],
        "cooking_notes": (
            "When adapting savory dishes, consider adding baked elements "
            "or pastry components."
        ),
    },
    "international": {
        "name": "International Fusion",
        "avoid_ingredients": [],
        "prefer_ingredients": [
            "global spices", "fusion combinations", "cross-cultural ingredients",
        ],
        "cooking_notes": (
            "Embrace ingredient combinations from multiple cuisines."
        ),
    },
    "farm_to_table": {
        "name": "Farm-to-Table",
        "avoid_ingredients": [
            "processed foods", "out-of-season produce", "preservatives",
        ],
        "prefer_ingredients": [
            "seasonal vegetables", "local proteins", "fresh herbs",
            "farmers market finds",
        ],
        "cooking_notes": (
            "Prioritize seasonal, local, and sustainable ingredients."
        ),
    },
    # === NEW dietary types ===
    "vegan": {
        "name": "Vegan",
        "avoid_ingredients": [
            "meat", "poultry", "fish", "seafood", "eggs", "dairy",
            "cheese", "butter", "cream", "honey", "gelatin", "lard",
        ],
        "prefer_ingredients": [
            "tofu", "tempeh", "seitan", "nutritional yeast", "plant milk",
            "cashew cream", "coconut cream", "legumes", "nuts",
        ],
        "cooking_notes": (
            "Replace ALL animal products with plant-based alternatives. "
            "No eggs, dairy, or honey."
        ),
    },
    "keto": {
        "name": "Keto/Low-Carb",
        "avoid_ingredients": [
            "rice", "pasta", "bread", "potatoes", "sugar", "flour",
            "corn", "beans", "high-sugar fruits",
        ],
        "prefer_ingredients": [
            "avocado", "olive oil", "butter", "cheese", "eggs", "fatty fish",
            "nuts", "leafy greens", "cauliflower",
        ],
        "cooking_notes": (
            "Very low carb, high fat. Use cauliflower rice, zucchini noodles, "
            "almond flour as substitutes."
        ),
    },
    "gluten_free": {
        "name": "Gluten-Free",
        "avoid_ingredients": [
            "wheat", "barley", "rye", "regular pasta", "bread",
            "flour", "soy sauce", "beer",
        ],
        "prefer_ingredients": [
            "rice", "quinoa", "rice noodles", "tamari", "corn tortillas",
            "gluten-free oats", "almond flour",
        ],
        "cooking_notes": (
            "Replace wheat-based ingredients with gluten-free alternatives. "
            "Use tamari instead of soy sauce."
        ),
    },
    "halal": {
        "name": "Halal",
        "avoid_ingredients": [
            "pork", "bacon", "ham", "lard", "alcohol", "wine",
            "beer", "gelatin from pork", "non-halal meat",
        ],
        "prefer_ingredients": [
            "halal-certified meat", "lamb", "chicken", "fish",
            "legumes", "vegetables",
        ],
        "cooking_notes": (
            "No pork products or alcohol. Use halal-certified meats only. "
            "Replace wine with broth or vinegar."
        ),
    },
    "kosher": {
        "name": "Kosher",
        "avoid_ingredients": [
            "pork", "shellfish", "mixing meat and dairy", "non-kosher meat",
        ],
        "prefer_ingredients": [
            "kosher-certified meat", "fish with scales",
            "separate dairy", "pareve ingredients",
        ],
        "cooking_notes": (
            "No pork or shellfish. Never mix meat and dairy in same dish. "
            "Fish must have fins and scales."
        ),
    },
    "pescatarian": {
        "name": "Pescatarian",
        "avoid_ingredients": [
            "beef", "pork", "chicken", "lamb", "poultry", "meat-based broths",
        ],
        "prefer_ingredients": [
            "fish", "shrimp", "salmon", "tuna", "shellfish",
            "eggs", "dairy", "tofu",
        ],
        "cooking_notes": (
            "No meat or poultry, but fish and seafood are allowed. "
            "Eggs and dairy permitted."
        ),
    },
    "dairy_free": {
        "name": "Dairy-Free",
        "avoid_ingredients": [
            "milk", "cheese", "butter", "cream", "yogurt",
            "ghee", "whey", "casein",
        ],
        "prefer_ingredients": [
            "coconut milk", "almond milk", "oat milk", "coconut cream",
            "olive oil", "vegan butter",
        ],
        "cooking_notes": (
            "Replace all dairy with plant-based alternatives. "
            "Check for hidden dairy in processed foods."
        ),
    },
    "low_sodium": {
        "name": "Low-Sodium",
        "avoid_ingredients": [
            "table salt", "soy sauce", "fish sauce", "cured meats",
            "processed foods", "canned soups", "pickled items",
        ],
        "prefer_ingredients": [
            "fresh herbs", "citrus", "vinegar", "garlic", "onion",
            "low-sodium soy sauce", "fresh vegetables",
        ],
        "cooking_notes": (
            "Minimize salt, maximize flavor with herbs, spices, "
            "citrus, and aromatics."
        ),
    },
}


def _get_language_from_locale(locale: str) -> str:
    """Get the full language name from a locale string."""
    lang_code = locale.split("-")[0]
    return LOCALE_TO_LANGUAGE.get(lang_code, "English")


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
        lang = _get_language_from_locale(locale)
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
    "title": "Recipe title - max 100 characters (include dish name + key cooking method/style, e.g., 'Crispy Pan-Fried Chicken with Garlic Butter Sauce')",
    "description": "2-3 sentences, max 1000 characters, that include: the dish name, main ingredients, cooking method, and why it's delicious. Write naturally but include searchable terms.",
    "servings": number (1-8),
    "cookingTimeRange": "UNDER_15_MIN" | "MIN_15_TO_30" | "MIN_30_TO_60" | "HOUR_1_TO_2" | "OVER_2_HOURS",
    "ingredients": [
        {{
            "name": "ingredient name (plain noun only - no adjectives like 'fresh', 'diced', 'boneless', etc.)",
            "quantity": number (e.g., 2.0, 100, 0.5),
            "unit": "UNIT_CODE",
            "type": "MAIN" | "SECONDARY" | "SEASONING"
        }}
    ],
    "steps": [
        {{
            "order": 1,
            "description": "Detailed step - max 1000 characters - with specific cooking terms (e.g., 'sauté', 'simmer', 'fold'), temperatures, and timing"
        }}
    ],
    "hashtags": ["tag1", "tag2", "tag3", "tag4", "tag5"],
    "tipFromChef": "One helpful cooking tip"
}}

{unit_codes}

Requirements:
- Write EVERYTHING in {lang}
- IMPORTANT: Keep title under 100 characters, description under 1000 characters, each step under 1000 characters
- Include 5-15 ingredients with realistic amounts
- IMPORTANT: Ingredient names must be plain nouns only (e.g., "chicken breast", "onion", "garlic"). Do NOT include adjectives or preparation methods (NO "fresh", "diced", "minced", "boneless", "organic", etc.)
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
        cultural_context: Optional[Dict[str, Any]] = None,
    ) -> str:
        """Generate prompt for creating a recipe variant.

        Args:
            parent_title: Title of the parent recipe
            parent_description: Description of the parent recipe
            parent_ingredients: Formatted ingredients string
            parent_steps: Formatted steps string
            locale: Target locale for the variant
            variation_type: Type of variation to create
            cultural_context: Optional cultural adaptation context with keys:
                - source_culture: Name of the source culture (e.g., "Italian")
                - target_culture: Name of the target culture (e.g., "Korean")
                - avoid_ingredients: List of ingredients to avoid
                - prefer_ingredients: List of preferred ingredients
                - cooking_notes: Notes about the target culture's cooking style
        """
        lang = _get_language_from_locale(locale)

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
            "vegan": "Make a vegan version - replace all animal products (meat, dairy, eggs, honey) with plant-based alternatives",
            "high_protein": "Make a high-protein version - increase protein with chicken, fish, eggs, Greek yogurt, legumes, or protein powder",
            "low_carb": "Make a low-carb version - substitute high-carb ingredients (pasta, rice, bread, potatoes, sugar) with low-carb alternatives",
            "cultural_adaptation": "Adapt this recipe for the target culture's cuisine and preferences",
        }

        instruction = variation_instructions.get(
            variation_type,
            "Create a creative variation with meaningful improvements",
        )

        # Build cultural adaptation instructions if provided
        cultural_instructions = ""
        if cultural_context:
            source = cultural_context.get("source_culture", "foreign")
            target = cultural_context.get("target_culture", "local")
            dietary = cultural_context.get("dietary_focus", "")
            avoid = cultural_context.get("avoid_ingredients", [])
            prefer = cultural_context.get("prefer_ingredients", [])
            notes = cultural_context.get("cooking_notes", "")

            # Build dietary focus description
            dietary_info = ""
            if dietary:
                dietary_info = f" with a {dietary} focus"

            # Build dietary requirements line
            dietary_requirements = ""
            if dietary:
                dietary_requirements = f"\nIMPORTANT: Ensure the recipe meets {dietary} dietary requirements."

            cultural_instructions = f"""

CULTURAL ADAPTATION CONTEXT:
This is a {source} recipe being adapted for {target} cuisine{dietary_info}.

Ingredients to AVOID: {', '.join(avoid) if avoid else 'none specified'}
Ingredients to PREFER: {', '.join(prefer) if prefer else 'none specified'}
Cooking style notes: {notes}

IMPORTANT: Replace any avoided ingredients with appropriate alternatives from the preferred list.
Keep the dish's core essence while making it appealing to {target} palates.{dietary_requirements}
The title should reflect the adaptation (e.g., "Korean-Style Vegan Pasta" or "Japanese Low-Carb Taco Bowl").
"""

        return f"""You are creating a VARIANT of an existing recipe.

ORIGINAL RECIPE:
Title: {parent_title}
Description: {parent_description}
Ingredients: {parent_ingredients}
Steps: {parent_steps}

TASK: {instruction}
{cultural_instructions}

Generate a variant recipe in JSON format:
{{
    "title": "Title - max 100 characters - with variation type + dish name (e.g., 'Quick 15-Minute Garlic Butter Shrimp' or 'Healthy Low-Carb Chicken Stir-Fry')",
    "description": "2-3 sentences, max 1000 characters, that include: what changed, the dish name, key ingredients, and cooking method. Write naturally but include searchable terms.",
    "servings": number,
    "cookingTimeRange": "UNDER_15_MIN" | "MIN_15_TO_30" | "MIN_30_TO_60" | "HOUR_1_TO_2" | "OVER_2_HOURS",
    "ingredients": [
        {{
            "name": "ingredient name (plain noun only - no adjectives like 'fresh', 'diced', 'boneless', etc.)",
            "quantity": number (e.g., 2.0, 100, 0.5),
            "unit": "UNIT_CODE",
            "type": "MAIN" | "SECONDARY" | "SEASONING"
        }}
    ],
    "steps": [
        {{
            "order": 1,
            "description": "Detailed step - max 1000 characters - with specific cooking terms (e.g., 'sauté', 'simmer', 'fold'), temperatures, and timing"
        }}
    ],
    "hashtags": ["tag1", "tag2", "tag3", "tag4", "tag5"],
    "changeDiff": "Clear description of what changed from the original",
    "changeReason": "Why you made these changes - max 1000 characters (1-2 sentences)",
    "changeCategories": ["INGREDIENT_SUBSTITUTION", "QUANTITY_ADJUSTMENT", "COOKING_METHOD", "SEASONING_CHANGE", "DIETARY_ADAPTATION", "TIME_OPTIMIZATION", "EQUIPMENT_CHANGE", "PRESENTATION"]
}}

{unit_codes}

Requirements:
- Write EVERYTHING in {lang}
- IMPORTANT: Keep title under 100 characters, description under 1000 characters, each step under 1000 characters, changeReason under 1000 characters
- Make meaningful, noticeable changes (not just minor tweaks)
- Keep the dish recognizable as a variant of the original
- IMPORTANT: Ingredient names must be plain nouns only (e.g., "chicken breast", "onion", "garlic"). Do NOT include adjectives or preparation methods (NO "fresh", "diced", "minced", "boneless", "organic", etc.)
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
        rating: int,
        locale: str,
        persona_background: str,
    ) -> str:
        """Generate prompt for creating a cooking log.

        Args:
            recipe_title: Title of the recipe cooked
            recipe_description: Description of the recipe
            rating: Star rating 1-5
            locale: User's locale for language
            persona_background: Bot persona's background story

        Returns:
            Prompt string for log generation
        """
        lang = _get_language_from_locale(locale)

        # Rating-based tone instructions
        rating_instructions = {
            5: "You made this dish and it turned out EXCELLENT! Enthusiastic, highly positive tone. "
               "Everything went perfectly - the flavors, texture, presentation. You're thrilled!",
            4: "You made this dish and it turned out great! Positive tone with maybe one minor note. "
               "Overall very satisfied with the result.",
            3: "You made this dish and it turned out good. Balanced, neutral-positive tone. "
               "Decent result, some things worked well, maybe a few things to improve.",
            2: "You made this dish but had mixed feelings. Some things didn't go as planned. "
               "Fair result with notable issues or disappointments.",
            1: "The cooking attempt didn't go well. Disappointed tone. "
               "Describe what went wrong - burnt, undercooked, wrong measurements, etc.",
        }

        return f"""You just cooked "{recipe_title}" - {recipe_description}

Rating: {rating}/5 stars
Tone guidance: {rating_instructions.get(rating, rating_instructions[3])}

Your background: {persona_background}

Write a cooking log entry in JSON format:
{{
    "content": "Max 1000 characters. 2-4 paragraphs describing your cooking experience. Include:
        - How the cooking process went
        - Any challenges or surprises
        - How it tasted/looked
        - Tips for others or what you'd do differently
        - Personal touch reflecting your personality",
    "hashtags": ["tag1", "tag2", "tag3", "tag4", "tag5"]
}}

Requirements:
- Write EVERYTHING in {lang}
- IMPORTANT: Keep content under 1000 characters
- Be authentic and personal - this is YOUR cooking experience
- Match the {rating}-star rating in your tone and content
- Include specific details that make it feel real
- 5 relevant hashtags (without #)

Return ONLY valid JSON, no additional text."""

    @staticmethod
    def generate_failed_log_details(locale: str) -> str:
        """Generate realistic failure scenarios."""
        lang = _get_language_from_locale(locale)

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
