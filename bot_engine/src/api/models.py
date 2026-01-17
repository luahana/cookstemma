"""API data models matching backend DTOs."""

from enum import Enum
from typing import Any, List, Optional, Union

from pydantic import BaseModel, Field, field_validator


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

    step_number: int = Field(alias="stepNumber", description="Step number (1-based)")
    description: str = Field(description="Step instructions")
    image_public_id: Optional[str] = Field(default=None, alias="imagePublicId")

    model_config = {"populate_by_name": True}


class CreateRecipeRequest(BaseModel):
    """Request to create a new recipe."""

    title: str = Field(max_length=100)
    description: str = Field(max_length=2000)
    locale: str = Field(default="ko-KR")
    culinary_locale: str = Field(default="KR", alias="culinaryLocale")
    new_food_name: Optional[str] = Field(default=None, alias="newFoodName")
    food_public_id: Optional[str] = Field(default=None, alias="foodPublicId")
    ingredients: List[RecipeIngredient] = Field(default_factory=list)
    steps: List[RecipeStep] = Field(default_factory=list)
    image_public_ids: List[str] = Field(default_factory=list, alias="imagePublicIds")
    hashtags: List[str] = Field(default_factory=list)
    servings: Optional[int] = Field(default=None, ge=1, le=100)
    cooking_time_range: Optional[str] = Field(default=None, alias="cookingTimeRange")
    # Variant fields
    parent_public_id: Optional[str] = Field(default=None, alias="parentPublicId")
    change_diff: Optional[str] = Field(default=None, alias="changeDiff")
    change_reason: Optional[str] = Field(default=None, alias="changeReason")
    change_categories: List[ChangeCategory] = Field(default_factory=list, alias="changeCategories")

    model_config = {"populate_by_name": True}


class Hashtag(BaseModel):
    """Hashtag response from API."""
    public_id: str = Field(alias="publicId")
    name: str

    model_config = {"populate_by_name": True}


class RecipeImage(BaseModel):
    """Image in recipe response from API."""
    image_public_id: str = Field(alias="imagePublicId")
    image_url: str = Field(alias="imageUrl")

    model_config = {"populate_by_name": True}


class Recipe(BaseModel):
    """Recipe response from API."""

    public_id: str = Field(alias="publicId")
    title: str
    description: Optional[str] = None
    locale: Optional[str] = None
    culinary_locale: Optional[str] = Field(default=None, alias="culinaryLocale")
    creator_public_id: Optional[str] = Field(default=None, alias="creatorPublicId")
    creator_username: Optional[str] = Field(default=None, alias="creatorUsername")
    ingredients: List[RecipeIngredient] = Field(default_factory=list)
    steps: List[RecipeStep] = Field(default_factory=list)
    images: List[RecipeImage] = Field(default_factory=list)
    hashtags: List[Union[Hashtag, str]] = Field(default_factory=list)
    servings: Optional[int] = None
    cooking_time_range: Optional[str] = Field(default=None, alias="cookingTimeRange")
    parent_public_id: Optional[str] = Field(default=None, alias="parentPublicId")
    root_public_id: Optional[str] = Field(default=None, alias="rootPublicId")
    log_count: int = Field(default=0, alias="logCount")
    variant_count: int = Field(default=0, alias="variantCount")

    model_config = {"populate_by_name": True, "extra": "ignore"}

    @field_validator("hashtags", mode="before")
    @classmethod
    def normalize_hashtags(cls, v: Any) -> List[Union[Hashtag, str]]:
        """Handle both string and Hashtag object formats from API."""
        if not v:
            return []
        result = []
        for item in v:
            if isinstance(item, str):
                result.append(item)
            elif isinstance(item, dict):
                # Try to create Hashtag, fallback to name string
                result.append(item.get("name", str(item)))
            else:
                result.append(item)
        return result


class CreateLogRequest(BaseModel):
    """Request to create a cooking log."""

    recipe_public_id: str = Field(description="Recipe that was cooked")
    title: str = Field(max_length=100)
    content: str = Field(max_length=500, description="Log notes/description")
    outcome: LogOutcome = Field(description="Cooking outcome")
    image_public_ids: List[str] = Field(
        default_factory=list,
        description="Log photo IDs",
    )
    hashtags: List[str] = Field(default_factory=list)


class LogPostImage(BaseModel):
    """Image in log post response."""
    image_public_id: str = Field(alias="imagePublicId")
    image_url: str = Field(alias="imageUrl")

    model_config = {"populate_by_name": True}


class LinkedRecipeSummary(BaseModel):
    """Summary of linked recipe in log post response."""
    public_id: str = Field(alias="publicId")
    title: str
    food_name: Optional[str] = Field(default=None, alias="foodName")

    model_config = {"populate_by_name": True, "extra": "ignore"}


class LogPost(BaseModel):
    """Log post response from API."""

    public_id: str = Field(alias="publicId")
    title: Optional[str] = None
    content: str
    outcome: LogOutcome
    images: List[LogPostImage] = Field(default_factory=list)
    linked_recipe: Optional[LinkedRecipeSummary] = Field(default=None, alias="linkedRecipe")
    created_at: Optional[str] = Field(default=None, alias="createdAt")
    hashtags: List[Union[Hashtag, str]] = Field(default_factory=list)
    is_saved_by_current_user: Optional[bool] = Field(default=None, alias="isSavedByCurrentUser")
    creator_public_id: Optional[str] = Field(default=None, alias="creatorPublicId")
    user_name: Optional[str] = Field(default=None, alias="userName")
    title_translations: Optional[dict] = Field(default=None, alias="titleTranslations")
    content_translations: Optional[dict] = Field(default=None, alias="contentTranslations")

    model_config = {"populate_by_name": True, "extra": "ignore"}

    @field_validator("hashtags", mode="before")
    @classmethod
    def normalize_hashtags(cls, v: Any) -> List[Union[Hashtag, str]]:
        """Handle both string and Hashtag object formats from API."""
        if not v:
            return []
        result = []
        for item in v:
            if isinstance(item, str):
                result.append(item)
            elif isinstance(item, dict):
                result.append(item.get("name", str(item)))
            else:
                result.append(item)
        return result

    @property
    def recipe_public_id(self) -> Optional[str]:
        """Get recipe public ID from linked recipe."""
        return self.linked_recipe.public_id if self.linked_recipe else None

    @property
    def recipe_title(self) -> Optional[str]:
        """Get recipe title from linked recipe."""
        return self.linked_recipe.title if self.linked_recipe else None

    @property
    def image_urls(self) -> List[str]:
        """Get list of image URLs."""
        return [img.image_url for img in self.images]


class ImageUploadResponse(BaseModel):
    """Response from image upload."""

    public_id: str
    url: str
    thumbnail_url: Optional[str] = None


class AuthResponse(BaseModel):
    """Authentication response."""

    access_token: str = Field(alias="accessToken")
    refresh_token: str = Field(alias="refreshToken")
    user_public_id: str = Field(alias="userPublicId")
    username: str
    persona_public_id: Optional[str] = Field(default=None, alias="personaPublicId")
    persona_name: Optional[str] = Field(default=None, alias="personaName")

    model_config = {"populate_by_name": True}
