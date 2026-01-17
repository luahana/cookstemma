#!/usr/bin/env python3
"""Mock seeder for testing bot engine without OpenAI API.

Creates test recipes and logs using predefined mock data.
This allows testing the full pipeline without AI generation costs.

Usage:
    python scripts/mock_seed.py --recipes 5 --logs 10
"""

import argparse
import asyncio
import os
import random
import sys
from enum import Enum
from typing import List, Optional

import httpx
from pydantic import BaseModel, Field


# Inline models to avoid import issues
class IngredientType(str, Enum):
    MAIN = "MAIN"
    SECONDARY = "SECONDARY"
    SEASONING = "SEASONING"


class LogOutcome(str, Enum):
    SUCCESS = "SUCCESS"
    PARTIAL = "PARTIAL"
    FAILED = "FAILED"


class RecipeIngredient(BaseModel):
    name: str
    amount: str
    type: IngredientType = IngredientType.MAIN
    order: int = 0


class RecipeStep(BaseModel):
    step_number: int = Field(alias="stepNumber")
    description: str
    image_public_id: Optional[str] = Field(default=None, alias="imagePublicId")

    class Config:
        populate_by_name = True


class CreateRecipeRequest(BaseModel):
    title: str
    description: str
    locale: str = "ko"
    culinary_locale: str = Field(default="ko", alias="culinaryLocale")
    new_food_name: Optional[str] = Field(default=None, alias="newFoodName")
    ingredients: List[RecipeIngredient] = Field(default_factory=list)
    steps: List[RecipeStep] = Field(default_factory=list)
    image_public_ids: List[str] = Field(default_factory=list, alias="imagePublicIds")
    hashtags: List[str] = Field(default_factory=list)
    servings: Optional[int] = None
    cooking_time_range: Optional[str] = Field(default=None, alias="cookingTimeRange")

    class Config:
        populate_by_name = True


class CreateLogRequest(BaseModel):
    recipe_public_id: str = Field(alias="recipePublicId")
    title: str
    content: str
    outcome: LogOutcome
    image_public_ids: List[str] = Field(default_factory=list, alias="imagePublicIds")
    hashtags: List[str] = Field(default_factory=list)

    class Config:
        populate_by_name = True

BACKEND_BASE_URL = os.getenv("BACKEND_BASE_URL", "http://localhost:4000/api/v1")

# Placeholder image ID from existing images in the database
# Used when no images are generated
PLACEHOLDER_IMAGE_ID = "8123d728-baee-4269-a68a-bab1dbd6ad8e"

# Mock recipe data - Korean
KOREAN_RECIPES = [
    {
        "foodName": "김치찌개",
        "title": "엄마표 묵은지 김치찌개 - 깊은 맛의 비결",
        "description": "돼지고기와 잘 익은 김치로 만든 깊은 맛의 한국식 찌개입니다. 밥과 함께 먹으면 최고예요!",
        "ingredients": [
            {"name": "묵은지", "amount": "300g", "type": "MAIN"},
            {"name": "돼지고기 목살", "amount": "200g", "type": "MAIN"},
            {"name": "두부", "amount": "1/2모", "type": "SECONDARY"},
            {"name": "대파", "amount": "1대", "type": "SECONDARY"},
            {"name": "고춧가루", "amount": "1큰술", "type": "SEASONING"},
            {"name": "다진 마늘", "amount": "1큰술", "type": "SEASONING"},
        ],
        "steps": [
            {"stepNumber": 1, "description": "김치를 먹기 좋은 크기로 썰어주세요."},
            {"stepNumber": 2, "description": "냄비에 참기름을 두르고 돼지고기를 볶아주세요."},
            {"stepNumber": 3, "description": "김치를 넣고 함께 볶다가 물을 붓고 끓여주세요."},
            {"stepNumber": 4, "description": "두부와 대파를 넣고 한소끔 더 끓이면 완성!"},
        ],
        "hashtags": ["김치찌개", "한식", "집밥", "찌개"],
        "servings": 2,
        "cookingTimeRange": "30_TO_60_MIN",
    },
    {
        "foodName": "제육볶음",
        "title": "매콤달콤 제육볶음 황금레시피 - 밥도둑 보장",
        "description": "매콤달콤한 양념에 볶은 돼지고기 요리입니다. 밥도둑이에요!",
        "ingredients": [
            {"name": "돼지고기 앞다리살", "amount": "400g", "type": "MAIN"},
            {"name": "양파", "amount": "1개", "type": "SECONDARY"},
            {"name": "대파", "amount": "1대", "type": "SECONDARY"},
            {"name": "고추장", "amount": "2큰술", "type": "SEASONING"},
            {"name": "고춧가루", "amount": "1큰술", "type": "SEASONING"},
            {"name": "간장", "amount": "1큰술", "type": "SEASONING"},
        ],
        "steps": [
            {"stepNumber": 1, "description": "돼지고기를 먹기 좋은 크기로 썰어주세요."},
            {"stepNumber": 2, "description": "양념 재료를 모두 섞어 고기에 재워주세요."},
            {"stepNumber": 3, "description": "팬에 기름을 두르고 센 불에서 볶아주세요."},
            {"stepNumber": 4, "description": "야채를 넣고 함께 볶으면 완성!"},
        ],
        "hashtags": ["제육볶음", "한식", "밥도둑", "매콤"],
        "servings": 3,
        "cookingTimeRange": "15_TO_30_MIN",
    },
    {
        "foodName": "된장찌개",
        "title": "구수한 시골식 된장찌개 - 할머니 레시피",
        "description": "구수한 된장과 신선한 야채로 만든 건강한 한국 전통 찌개입니다.",
        "ingredients": [
            {"name": "된장", "amount": "2큰술", "type": "MAIN"},
            {"name": "두부", "amount": "1/2모", "type": "MAIN"},
            {"name": "감자", "amount": "1개", "type": "SECONDARY"},
            {"name": "호박", "amount": "1/4개", "type": "SECONDARY"},
            {"name": "청양고추", "amount": "1개", "type": "SEASONING"},
            {"name": "다진 마늘", "amount": "1작은술", "type": "SEASONING"},
        ],
        "steps": [
            {"stepNumber": 1, "description": "야채를 먹기 좋은 크기로 썰어주세요."},
            {"stepNumber": 2, "description": "멸치 육수에 된장을 풀어주세요."},
            {"stepNumber": 3, "description": "감자를 먼저 넣고 익히다가 나머지 재료를 넣어주세요."},
            {"stepNumber": 4, "description": "두부를 넣고 한소끔 끓이면 완성!"},
        ],
        "hashtags": ["된장찌개", "한식", "건강식", "찌개"],
        "servings": 2,
        "cookingTimeRange": "30_TO_60_MIN",
    },
]

# Mock recipe data - English
ENGLISH_RECIPES = [
    {
        "foodName": "Carbonara",
        "title": "Classic Roman-Style Spaghetti Carbonara with Crispy Pancetta",
        "description": "A creamy Italian pasta dish made with eggs, cheese, pancetta, and black pepper. Simple yet incredibly satisfying!",
        "ingredients": [
            {"name": "Spaghetti", "amount": "400g", "type": "MAIN"},
            {"name": "Pancetta", "amount": "200g", "type": "MAIN"},
            {"name": "Eggs", "amount": "4 large", "type": "SECONDARY"},
            {"name": "Pecorino Romano", "amount": "100g", "type": "SECONDARY"},
            {"name": "Black pepper", "amount": "2 tsp", "type": "SEASONING"},
            {"name": "Salt", "amount": "to taste", "type": "SEASONING"},
        ],
        "steps": [
            {"stepNumber": 1, "description": "Bring a large pot of salted water to boil and cook spaghetti until al dente."},
            {"stepNumber": 2, "description": "While pasta cooks, fry pancetta until crispy."},
            {"stepNumber": 3, "description": "Whisk eggs with grated cheese and pepper in a bowl."},
            {"stepNumber": 4, "description": "Toss hot pasta with pancetta, remove from heat, add egg mixture and toss quickly."},
        ],
        "hashtags": ["carbonara", "italian", "pasta", "comfort food"],
        "servings": 4,
        "cookingTimeRange": "15_TO_30_MIN",
    },
    {
        "foodName": "Honey Garlic Chicken",
        "title": "Crispy Honey Garlic Chicken Thighs - Weeknight Favorite",
        "description": "Tender chicken thighs glazed with a sweet and savory honey garlic sauce. Perfect for busy weeknights!",
        "ingredients": [
            {"name": "Chicken thighs", "amount": "6 pieces", "type": "MAIN"},
            {"name": "Honey", "amount": "1/4 cup", "type": "MAIN"},
            {"name": "Garlic", "amount": "6 cloves", "type": "SECONDARY"},
            {"name": "Soy sauce", "amount": "3 tbsp", "type": "SEASONING"},
            {"name": "Olive oil", "amount": "2 tbsp", "type": "SEASONING"},
            {"name": "Red pepper flakes", "amount": "1/2 tsp", "type": "SEASONING"},
        ],
        "steps": [
            {"stepNumber": 1, "description": "Season chicken with salt and pepper."},
            {"stepNumber": 2, "description": "Sear chicken in a hot pan until golden on both sides."},
            {"stepNumber": 3, "description": "Mix honey, soy sauce, and minced garlic."},
            {"stepNumber": 4, "description": "Pour sauce over chicken, simmer until cooked through and glazed."},
        ],
        "hashtags": ["chicken", "easy dinner", "honey garlic", "weeknight meal"],
        "servings": 4,
        "cookingTimeRange": "30_TO_60_MIN",
    },
]

# Mock log content
LOG_TEMPLATES = {
    "ko": {
        "SUCCESS": [
            "오늘 {recipe}을(를) 만들어봤어요! 정말 맛있게 됐어요. 가족들도 다 좋아했습니다.",
            "{recipe} 완성! 레시피대로 했더니 완벽하게 나왔어요. 다음에 또 만들 거예요.",
            "드디어 {recipe}에 도전했어요. 생각보다 쉽고 맛도 좋아서 대만족입니다!",
        ],
        "PARTIAL": [
            "{recipe} 만들었는데 간이 조금 셌어요. 다음엔 양념을 줄여야겠어요.",
            "첫 {recipe} 도전! 모양은 좀 아쉽지만 맛은 괜찮았어요.",
            "{recipe} 시도했어요. 불 조절이 어려웠지만 그래도 먹을만 했어요.",
        ],
        "FAILED": [
            "{recipe} 실패... 불이 너무 세서 다 탔어요. 다시 도전해볼게요.",
            "오늘 {recipe} 망했어요 ㅠㅠ 재료 비율을 잘못 맞춘 것 같아요.",
        ],
    },
    "en": {
        "SUCCESS": [
            "Made {recipe} today and it turned out amazing! My family loved it.",
            "{recipe} was a complete success! Followed the recipe exactly and it was perfect.",
            "Finally tried making {recipe}. Easier than expected and so delicious!",
        ],
        "PARTIAL": [
            "Made {recipe} but it was a bit too salty. Will adjust seasoning next time.",
            "First attempt at {recipe}! Presentation could be better but taste was good.",
            "Tried {recipe} today. Had trouble with the heat but it was still edible.",
        ],
        "FAILED": [
            "{recipe} disaster... burned it completely. Will try again soon.",
            "Today's {recipe} was a fail. I think I got the proportions wrong.",
        ],
    },
}


class MockSeeder:
    """Seeds test data without AI generation."""

    def __init__(self, base_url: str, api_key: str):
        self.base_url = base_url
        self.api_key = api_key
        self.client = httpx.AsyncClient(timeout=30.0)
        self.access_token = None
        # Image storage for different purposes
        self.cover_images: List[str] = []
        self.step_images: List[str] = []
        self.log_images: List[str] = []

    async def _upload_single_image(self, image_type: str) -> Optional[str]:
        """Upload a single placeholder image of given type."""
        import base64

        # Create a simple 1x1 pixel JPEG (smallest valid JPEG)
        jpeg_bytes = base64.b64decode(
            "/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRof"
            "Hh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwh"
            "MjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAAR"
            "CAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAn/xAAUEAEAAAAAAAAAAAAAAAAA"
            "AAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMB"
            "AAIRAxEAPwCwAB//2Q=="
        )

        files = {"file": (f"placeholder_{image_type.lower()}.jpg", jpeg_bytes, "image/jpeg")}
        data = {"type": image_type}
        response = await self.client.post(
            f"{self.base_url}/images/upload",
            headers={"Authorization": f"Bearer {self.access_token}"},
            files=files,
            data=data,
        )

        if response.status_code in (200, 201):
            return response.json().get("imagePublicId")
        else:
            try:
                error_msg = response.text.encode('ascii', 'replace').decode('ascii')
                print(f"Failed to upload {image_type} image: {response.status_code} - {error_msg}")
            except Exception:
                print(f"Failed to upload {image_type} image: {response.status_code}")
            return None

    async def upload_placeholder_images(self, cover_count: int = 2, step_count: int = 4, log_count: int = 3) -> bool:
        """Upload multiple placeholder images for different purposes."""
        print("\nUploading placeholder images...")

        # Upload cover images
        for i in range(cover_count):
            image_id = await self._upload_single_image("COVER")
            if image_id:
                self.cover_images.append(image_id)
        print(f"  Uploaded {len(self.cover_images)} cover images")

        # Upload step images
        for i in range(step_count):
            image_id = await self._upload_single_image("STEP")
            if image_id:
                self.step_images.append(image_id)
        print(f"  Uploaded {len(self.step_images)} step images")

        # Upload log images
        for i in range(log_count):
            image_id = await self._upload_single_image("LOG_POST")
            if image_id:
                self.log_images.append(image_id)
        print(f"  Uploaded {len(self.log_images)} log images")

        # Need at least one cover image to proceed
        return len(self.cover_images) > 0

    async def login(self) -> bool:
        """Login with bot API key."""
        try:
            response = await self.client.post(
                f"{self.base_url}/auth/bot-login",
                json={"apiKey": self.api_key},
            )
            if response.status_code == 200:
                data = response.json()
                self.access_token = data["accessToken"]
                print(f"Logged in as: {data.get('username', 'unknown')}")
                return True
            else:
                print(f"Login failed: {response.status_code} - {response.text}")
                return False
        except Exception as e:
            print(f"Login error: {e}")
            return False

    async def create_recipe(self, recipe_data: dict, locale: str) -> dict:
        """Create a recipe via API."""
        ingredients = [
            RecipeIngredient(
                name=i["name"],
                amount=i["amount"],
                type=IngredientType(i["type"]),
                order=idx,
            )
            for idx, i in enumerate(recipe_data["ingredients"])
        ]

        # Create steps with random images (~50% chance for each step)
        steps = []
        for s in recipe_data["steps"]:
            step_image = None
            if self.step_images and random.random() > 0.5:
                step_image = random.choice(self.step_images)
            steps.append(
                RecipeStep(
                    step_number=s["stepNumber"],
                    description=s["description"],
                    image_public_id=step_image,
                )
            )

        # Select 1-2 random cover images
        cover_count = random.randint(1, min(2, len(self.cover_images)))
        cover_ids = random.sample(self.cover_images, cover_count) if self.cover_images else []

        request = CreateRecipeRequest(
            title=recipe_data["title"],  # Longer, descriptive title
            description=recipe_data["description"],
            locale=locale,
            culinary_locale="ko" if locale == "ko" else "en-US",
            new_food_name=recipe_data["foodName"],  # Short generic dish name
            ingredients=ingredients,
            steps=steps,
            image_public_ids=cover_ids,  # Multiple cover images
            hashtags=recipe_data["hashtags"],
            servings=recipe_data.get("servings"),
            cooking_time_range=recipe_data.get("cookingTimeRange"),
        )

        response = await self.client.post(
            f"{self.base_url}/recipes",
            headers={"Authorization": f"Bearer {self.access_token}"},
            json=request.model_dump(by_alias=True, exclude_none=True),
        )

        if response.status_code in (200, 201):
            return response.json()
        else:
            try:
                error_msg = response.text.encode('ascii', 'replace').decode('ascii')
                print(f"Failed to create recipe: {response.status_code} - {error_msg}")
            except Exception as e:
                print(f"Failed to create recipe: {response.status_code} - error displaying response")
            # Debug: print request data
            import json
            print(f"Request data: {json.dumps(request.model_dump(by_alias=True, exclude_none=True), default=str)[:500]}")
            return None

    async def create_log(self, recipe: dict, locale: str) -> dict:
        """Create a cooking log via API."""
        # Select random outcome
        rand = random.random()
        if rand < 0.7:
            outcome = LogOutcome.SUCCESS
        elif rand < 0.9:
            outcome = LogOutcome.PARTIAL
        else:
            outcome = LogOutcome.FAILED

        templates = LOG_TEMPLATES[locale][outcome.value]
        content = random.choice(templates).format(recipe=recipe["title"])

        # Select 1-2 random log images
        log_image_count = random.randint(1, min(2, len(self.log_images))) if self.log_images else 0
        log_image_ids = random.sample(self.log_images, log_image_count) if log_image_count > 0 else []

        request = CreateLogRequest(
            recipe_public_id=recipe["publicId"],
            title=f"Making {recipe['title']}" if locale == "en" else f"{recipe['title']} 만들기",
            content=content,
            outcome=outcome,
            image_public_ids=log_image_ids,  # Add images to logs
            hashtags=["cooking", "homemade"] if locale == "en" else ["요리", "집밥"],
        )

        response = await self.client.post(
            f"{self.base_url}/log_posts",
            headers={"Authorization": f"Bearer {self.access_token}"},
            json=request.model_dump(by_alias=True, exclude_none=True),
        )

        if response.status_code in (200, 201):
            return response.json()
        else:
            try:
                error_msg = response.text.encode('ascii', 'replace').decode('ascii')
                print(f"Failed to create log: {response.status_code} - {error_msg}")
            except Exception:
                print(f"Failed to create log: {response.status_code}")
            # Debug: print request data
            import json
            print(f"Request data: {json.dumps(request.model_dump(by_alias=True, exclude_none=True), default=str)[:500]}")
            return None

    async def seed(self, recipe_count: int, log_count: int) -> None:
        """Seed recipes and logs."""
        if not await self.login():
            print("Failed to login. Exiting.")
            return

        # Upload multiple placeholder images for recipes, steps, and logs
        if not await self.upload_placeholder_images():
            print("Failed to upload placeholder images. Exiting.")
            return

        # Mix of Korean and English recipes
        all_recipes = KOREAN_RECIPES + ENGLISH_RECIPES
        random.shuffle(all_recipes)

        created_recipes = []
        print(f"\nCreating {recipe_count} recipes...")

        for i in range(min(recipe_count, len(all_recipes))):
            recipe_data = all_recipes[i]
            # Use foodName to detect locale (foodName is always in the target language)
            locale = "ko" if recipe_data["foodName"][0].encode().isalpha() is False else "en"

            result = await self.create_recipe(recipe_data, locale)
            if result:
                created_recipes.append({"data": result, "locale": locale})
                title = recipe_data['title'].encode('ascii', 'replace').decode('ascii')
                print(f"  [{i + 1}/{recipe_count}] Created: {title}")

        if not created_recipes:
            print("No recipes created. Cannot create logs.")
            return

        print(f"\nCreating {log_count} logs...")
        for i in range(log_count):
            recipe_info = random.choice(created_recipes)
            result = await self.create_log(recipe_info["data"], recipe_info["locale"])
            if result:
                title = recipe_info['data']['title'].encode('ascii', 'replace').decode('ascii')
                print(f"  [{i + 1}/{log_count}] Log for: {title}")

        print(f"\nDone! Created {len(created_recipes)} recipes and {log_count} logs.")

    async def close(self):
        await self.client.aclose()


async def main():
    parser = argparse.ArgumentParser(description="Seed mock data for testing")
    parser.add_argument("--recipes", type=int, default=5, help="Number of recipes")
    parser.add_argument("--logs", type=int, default=10, help="Number of logs")
    parser.add_argument("--api-key", default=os.getenv("BOT_API_KEY"), help="Bot API key")
    parser.add_argument("--base-url", default=BACKEND_BASE_URL, help="Backend URL")
    args = parser.parse_args()

    if not args.api_key:
        print("Error: Bot API key required.")
        print("Set BOT_API_KEY env var or use --api-key")
        print("\nTo create bot users, run: python scripts/setup_bot_users.py")
        sys.exit(1)

    seeder = MockSeeder(args.base_url, args.api_key)
    try:
        await seeder.seed(args.recipes, args.logs)
    finally:
        await seeder.close()


if __name__ == "__main__":
    asyncio.run(main())
