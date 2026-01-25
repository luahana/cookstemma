"""Holiday service for retrieving holiday-based food suggestions."""

import json
import random
from datetime import date, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import structlog

from .lunar_calendar import (
    calculate_easter,
    calculate_last_weekday,
    calculate_nth_weekday,
    calculate_sambok,
    calculate_winter_solstice,
    lunar_to_gregorian,
)
from .models import Holiday, HolidayData

logger = structlog.get_logger()

# Weekday name to int mapping (Monday=0)
WEEKDAY_MAP = {
    "MON": 0,
    "TUE": 1,
    "WED": 2,
    "THU": 3,
    "FRI": 4,
    "SAT": 5,
    "SUN": 6,
}


class HolidayService:
    """Service for managing holidays and suggesting holiday foods."""

    # Cache for loaded holiday data by locale
    _cache: Dict[str, HolidayData] = {}
    # Cache for calculated holiday dates: (locale, year) -> list[(date, Holiday)]
    _date_cache: Dict[Tuple[str, int], List[Tuple[date, Holiday]]] = {}

    def __init__(self, locale: str):
        """Initialize the holiday service.

        Args:
            locale: Locale code (e.g., 'ko-KR', 'en-US')
        """
        self.locale = locale
        self.language_code = locale.split("-")[0]
        self.holiday_data = self._load_holidays()

    def _get_data_path(self) -> Path:
        """Get the path to the holiday data directory."""
        return Path(__file__).parent / "data"

    def _load_holidays(self) -> HolidayData:
        """Load holiday data for the current locale."""
        if self.locale in self._cache:
            return self._cache[self.locale]

        data_path = self._get_data_path() / f"{self.locale}.json"

        if not data_path.exists():
            logger.warning("holiday_data_not_found", locale=self.locale, path=str(data_path))
            # Return empty data
            return HolidayData(locale=self.locale, holidays=[])

        try:
            with open(data_path, "r", encoding="utf-8") as f:
                raw_data = json.load(f)
            holiday_data = HolidayData(**raw_data)
            self._cache[self.locale] = holiday_data
            logger.debug(
                "holiday_data_loaded",
                locale=self.locale,
                holiday_count=len(holiday_data.holidays),
            )
            return holiday_data
        except Exception as e:
            logger.error("holiday_data_load_error", locale=self.locale, error=str(e))
            return HolidayData(locale=self.locale, holidays=[])

    def _calculate_holiday_date(
        self,
        holiday: Holiday,
        year: int,
    ) -> Optional[date]:
        """Calculate the actual date of a holiday for a given year.

        Date rule formats:
        - fixed:MM-DD - Fixed date (e.g., fixed:01-01)
        - lunar:MM-DD - Lunar calendar date (e.g., lunar:01-01)
        - nth:N-DAY-MON - Nth weekday of month (e.g., nth:4-THU-NOV)
        - easter:+N - Easter-relative (e.g., easter:0, easter:-2)
        - last:DAY-MON - Last weekday of month (e.g., last:MON-MAY)
        - solstice:winter - Winter solstice
        - sambok - Korean three hottest days (returns first date)

        Args:
            holiday: The holiday to calculate
            year: The year to calculate for

        Returns:
            The calculated date, or None if calculation fails
        """
        rule = holiday.date_rule

        try:
            if rule.startswith("fixed:"):
                # Fixed date: fixed:MM-DD
                parts = rule[6:].split("-")
                month, day = int(parts[0]), int(parts[1])
                return date(year, month, day)

            elif rule.startswith("lunar:"):
                # Lunar date: lunar:MM-DD
                parts = rule[6:].split("-")
                lunar_month, lunar_day = int(parts[0]), int(parts[1])
                # Use appropriate lunar calendar based on locale
                calendar_type = "korean" if self.locale.startswith("ko") else "chinese"
                return lunar_to_gregorian(year, lunar_month, lunar_day, calendar_type)

            elif rule.startswith("nth:"):
                # Nth weekday: nth:N-DAY-MON
                parts = rule[4:].split("-")
                n = int(parts[0])
                weekday = WEEKDAY_MAP.get(parts[1], 0)
                month = self._month_name_to_number(parts[2])
                return calculate_nth_weekday(year, month, weekday, n)

            elif rule.startswith("easter:"):
                # Easter-relative: easter:+N or easter:-N or easter:0
                offset_str = rule[7:]
                offset = int(offset_str)
                easter = calculate_easter(year)
                return easter + timedelta(days=offset)

            elif rule.startswith("last:"):
                # Last weekday: last:DAY-MON
                parts = rule[5:].split("-")
                weekday = WEEKDAY_MAP.get(parts[0], 0)
                month = self._month_name_to_number(parts[1])
                return calculate_last_weekday(year, month, weekday)

            elif rule.startswith("solstice:"):
                # Solstice: solstice:winter or solstice:summer
                solstice_type = rule[9:]
                if solstice_type == "winter":
                    return calculate_winter_solstice(year)
                # Add summer solstice if needed
                return None

            elif rule == "sambok":
                # Korean Sambok - return first date (Chobok)
                dates = calculate_sambok(year)
                return dates[0] if dates else None

            else:
                logger.warning("unknown_date_rule", rule=rule, holiday=holiday.key)
                return None

        except Exception as e:
            logger.error(
                "date_calculation_error",
                holiday=holiday.key,
                rule=rule,
                year=year,
                error=str(e),
            )
            return None

    def _month_name_to_number(self, month_name: str) -> int:
        """Convert month abbreviation to number."""
        months = {
            "JAN": 1, "FEB": 2, "MAR": 3, "APR": 4,
            "MAY": 5, "JUN": 6, "JUL": 7, "AUG": 8,
            "SEP": 9, "OCT": 10, "NOV": 11, "DEC": 12,
        }
        return months.get(month_name.upper(), 1)

    def _get_calculated_dates(self, year: int) -> List[Tuple[date, Holiday]]:
        """Get all calculated holiday dates for a year (with caching)."""
        cache_key = (self.locale, year)
        if cache_key in self._date_cache:
            return self._date_cache[cache_key]

        results = []
        for holiday in self.holiday_data.holidays:
            holiday_date = self._calculate_holiday_date(holiday, year)
            if holiday_date:
                results.append((holiday_date, holiday))

        self._date_cache[cache_key] = results
        return results

    def get_upcoming_holidays(
        self,
        days_ahead: int = 10,
        reference_date: Optional[date] = None,
    ) -> List[Tuple[date, Holiday]]:
        """Get holidays within the relevance window.

        Args:
            days_ahead: Maximum days to look ahead
            reference_date: Date to check from (defaults to today)

        Returns:
            List of (date, Holiday) tuples sorted by priority
        """
        today = reference_date or date.today()
        current_year = today.year

        # Check current year and next year (for year-end holidays)
        all_dates = self._get_calculated_dates(current_year)
        if today.month >= 11:
            all_dates = all_dates + self._get_calculated_dates(current_year + 1)

        upcoming = []
        for holiday_date, holiday in all_dates:
            days_until = (holiday_date - today).days
            # Check if within relevance window
            if -holiday.relevance_days_after <= days_until <= days_ahead:
                # Only include if within the holiday's specific before window
                if days_until <= holiday.relevance_days_before:
                    upcoming.append((holiday_date, holiday))

        # Sort by priority (highest first), then by date
        upcoming.sort(key=lambda x: (-x[1].priority, x[0]))
        return upcoming

    def get_holiday_foods(
        self,
        limit: int = 5,
        reference_date: Optional[date] = None,
    ) -> List[str]:
        """Get suggested holiday foods for upcoming holidays.

        Args:
            limit: Maximum number of food suggestions to return
            reference_date: Date to check from (defaults to today)

        Returns:
            List of food names in the locale's language
        """
        upcoming = self.get_upcoming_holidays(reference_date=reference_date)
        foods = []

        for _, holiday in upcoming:
            for food in holiday.foods:
                # Get food name in the appropriate language
                food_name = food.name.get(self.language_code)
                if not food_name:
                    # Fallback to English or first available
                    food_name = food.name.get("en") or next(iter(food.name.values()), None)
                if food_name and food_name not in foods:
                    foods.append(food_name)

        return foods[:limit]

    def should_suggest_holiday_food(
        self,
        probability_min: float = 0.5,
        probability_max: float = 0.6,
    ) -> bool:
        """Determine whether to suggest holiday foods based on probability.

        Args:
            probability_min: Minimum probability (default 50%)
            probability_max: Maximum probability (default 60%)

        Returns:
            True if holiday foods should be suggested
        """
        # Only suggest if there are upcoming holidays
        upcoming = self.get_upcoming_holidays()
        if not upcoming:
            return False

        # Random selection within probability range
        probability = random.uniform(probability_min, probability_max)
        return random.random() < probability

    def get_temporal_context(
        self,
        reference_date: Optional[date] = None,
    ) -> Dict[str, any]:
        """Get temporal context for content generation.

        Args:
            reference_date: Date to check from (defaults to today)

        Returns:
            Dict with temporal context information
        """
        today = reference_date or date.today()
        upcoming = self.get_upcoming_holidays(reference_date=today)
        holiday_foods = self.get_holiday_foods(reference_date=today)

        # Get holiday names in locale's language
        holiday_names = []
        for _, holiday in upcoming[:2]:  # Limit to top 2 holidays
            name = holiday.name.get(self.language_code)
            if not name:
                name = holiday.name.get("en") or next(iter(holiday.name.values()), "")
            if name:
                holiday_names.append(name)

        return {
            "date": today.isoformat(),
            "upcoming_holidays": holiday_names,
            "holiday_foods": holiday_foods,
            "has_holidays": len(upcoming) > 0,
        }

    def build_prompt_context(
        self,
        reference_date: Optional[date] = None,
    ) -> str:
        """Build a prompt context string for AI content generation.

        Args:
            reference_date: Date to check from (defaults to today)

        Returns:
            Formatted string for inclusion in AI prompts
        """
        context = self.get_temporal_context(reference_date)

        if not context["has_holidays"]:
            return ""

        holidays_str = ", ".join(context["upcoming_holidays"]) or "None"
        foods_str = ", ".join(context["holiday_foods"]) or "None"

        return f"""
TEMPORAL CONTEXT:
- Today's date: {context["date"]}
- Upcoming holidays: {holidays_str}
- Suggested holiday foods: {foods_str}

When there are upcoming holidays, there is a 50-60% chance you should include
traditional holiday foods in your suggestions. This creates timely, culturally
relevant content that resonates with users.
"""
