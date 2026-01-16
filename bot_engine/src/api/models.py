"""API data models matching backend DTOs."""

from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field


class IngredientType(str, Enum):
    """Type of ingredient."""

    MAIN = "MAIN"
    SECONDARY = "SECONDARY"
    SEASONING = "SEASONING"


class ChangeCategory(str, Enum):
    """Categories of changes for recipe variants."""

    INGREDIENT_SUBSTITUTION = "INGREDIENT_SUBSTITUTION"
    QUANTITY_ADJUSTMENT = "QUANTITY_ADJUSTMENT"
    COOKING_METHOD = "COOKING_METHOD"
    SEASONING_CHANGE = "SEASONING_CHANGE"
    DIETARY_ADAPTATION = "DIETARY_ADAPTATION"
    TIME_OPTIMIZATION = "TIME_OPTIMIZATION"
    EQUIPMENT_CHANGE = "EQUIPMENT_CHANGE"
    PRESENTATION = "PRESENTATION"


class LogOutcome(str, Enum):
    """Outcome of a cooking attempt."""

    SUCCESS = "SUCCESS"
    PARTIAL = "PARTIAL"
    FAILED = "FAILED"


class RecipeIngredient(BaseModel):
    """Ingredient for a recipe."""

    name: str = Field(description="Ingredient name")
    amount: str = Field(description="Amount/quantity (e.g., '2 cups', '100g')")
    type: IngredientType = Field(default=IngredientType.MAIN)
    order: int = Field(default=0, description="Display order")


class RecipeStep(BaseModel):
    """Step in a recipe."""

    order: int = Field(description="Step number (1-based)")
    description: str = Field(description="Step instructions")
    image_public_ids: List[str] = Field(
        default_factory=list,
        description="Optional image IDs for this step",
    )


class CreateRecipeRequest(BaseModel):
    """Request to create a new recipe."""

    title: str = Field(max_length=100)
    description: str = Field(max_length=2000)
    locale: str = Field(default="ko-KR", description="Recipe language locale")
    culinary_locale: str = Field(
        default="KR",
        description="Culinary style country code",
    )
    ingredients: List[RecipeIngredient] = Field(default_factory=list)
    steps: List[RecipeStep] = Field(default_factory=list)
    image_public_ids: List[str] = Field(
        default_factory=list,
        description="Cover image IDs",
    )
    hashtags: List[str] = Field(default_factory=list)
    servings: Optional[int] = Field(default=None, ge=1, le=100)
    cooking_time_range: Optional[str] = Field(
        default=None,
        description="e.g., 'UNDER_15', 'UNDER_30', 'UNDER_60', 'OVER_60'",
    )
    # Variant fields
    parent_public_id: Optional[str] = Field(
        default=None,
        description="Parent recipe ID for variants",
    )
    change_diff: Optional[str] = Field(
        default=None,
        description="Description of changes from parent",
    )
    change_reason: Optional[str] = Field(
        default=None,
        description="Reason for the changes",
    )
    change_categories: List[ChangeCategory] = Field(
        default_factory=list,
        description="Categories of changes",
    )


class Recipe(BaseModel):
    """Recipe response from API."""

    public_id: str
    title: str
    description: str
    locale: str
    culinary_locale: str
    creator_id: str
    creator_username: str
    ingredients: List[RecipeIngredient] = Field(default_factory=list)
    steps: List[RecipeStep] = Field(default_factory=list)
    image_urls: List[str] = Field(default_factory=list)
    hashtags: List[str] = Field(default_factory=list)
    servings: Optional[int] = None
    cooking_time_range: Optional[str] = None
    parent_public_id: Optional[str] = None
    root_public_id: Optional[str] = None
    log_count: int = 0
    variant_count: int = 0


class CreateLogRequest(BaseModel):
    """Request to create a cooking log."""

    recipe_public_id: str = Field(description="Recipe that was cooked")
    title: str = Field(max_length=100)
    content: str = Field(max_length=2000, description="Log notes/description")
    outcome: LogOutcome = Field(description="Cooking outcome")
    locale: str = Field(default="ko-KR")
    image_public_ids: List[str] = Field(
        default_factory=list,
        description="Log photo IDs",
    )
    hashtags: List[str] = Field(default_factory=list)


class LogPost(BaseModel):
    """Log post response from API."""

    public_id: str
    title: str
    content: str
    outcome: LogOutcome
    locale: str
    creator_id: str
    creator_username: str
    recipe_public_id: str
    recipe_title: str
    image_urls: List[str] = Field(default_factory=list)
    hashtags: List[str] = Field(default_factory=list)


class ImageUploadResponse(BaseModel):
    """Response from image upload."""

    public_id: str
    url: str
    thumbnail_url: Optional[str] = None


class AuthResponse(BaseModel):
    """Authentication response."""

    access_token: str
    refresh_token: str
    user_public_id: str
    username: str
    persona_public_id: Optional[str] = None
    persona_name: Optional[str] = None
