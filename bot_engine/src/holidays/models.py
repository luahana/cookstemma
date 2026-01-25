"""Pydantic models for holiday data."""

from typing import Dict, List, Optional

from pydantic import BaseModel, Field


class FoodSuggestion(BaseModel):
    """A traditional food associated with a holiday."""

    name: Dict[str, str] = Field(
        ...,
        description="Food name in multiple languages (key = language code)",
    )
    significance: str = Field(
        default="",
        description="Cultural significance or meaning of this food",
    )


class Holiday(BaseModel):
    """A holiday with associated traditional foods."""

    key: str = Field(..., description="Unique identifier for the holiday")
    name: Dict[str, str] = Field(
        ...,
        description="Holiday name in multiple languages (key = language code)",
    )
    date_rule: str = Field(
        ...,
        description="Rule for calculating the holiday date",
    )
    relevance_days_before: int = Field(
        default=10,
        description="Days before the holiday when it becomes relevant",
    )
    relevance_days_after: int = Field(
        default=3,
        description="Days after the holiday when it remains relevant",
    )
    priority: int = Field(
        default=50,
        description="Priority for selection when multiple holidays overlap",
    )
    foods: List[FoodSuggestion] = Field(
        default_factory=list,
        description="Traditional foods associated with this holiday",
    )


class HolidayData(BaseModel):
    """Container for all holidays in a locale."""

    locale: str = Field(..., description="Locale code (e.g., 'ko-KR')")
    holidays: List[Holiday] = Field(
        default_factory=list,
        description="List of holidays for this locale",
    )
