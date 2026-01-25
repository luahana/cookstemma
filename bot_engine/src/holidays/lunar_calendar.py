"""Lunar calendar date calculations."""

from datetime import date, timedelta
from typing import Optional

import structlog

logger = structlog.get_logger()


def lunar_to_gregorian(
    year: int,
    lunar_month: int,
    lunar_day: int,
    calendar_type: str = "korean",
) -> Optional[date]:
    """Convert lunar date to Gregorian date.

    Args:
        year: Gregorian year to calculate for
        lunar_month: Lunar month (1-12)
        lunar_day: Lunar day (1-30)
        calendar_type: Type of lunar calendar ('korean', 'chinese', 'vietnamese')

    Returns:
        Gregorian date, or None if conversion fails
    """
    try:
        if calendar_type == "korean":
            from korean_lunar_calendar import KoreanLunarCalendar

            cal = KoreanLunarCalendar()
            cal.setLunarDate(year, lunar_month, lunar_day, False)
            return date(cal.solarYear, cal.solarMonth, cal.solarDay)
        else:
            # Generic lunar calendar (Chinese, Vietnamese, etc.)
            from lunardate import LunarDate

            lunar = LunarDate(year, lunar_month, lunar_day)
            solar = lunar.toSolarDate()
            return date(solar.year, solar.month, solar.day)
    except Exception as e:
        logger.warning(
            "lunar_conversion_failed",
            year=year,
            lunar_month=lunar_month,
            lunar_day=lunar_day,
            calendar_type=calendar_type,
            error=str(e),
        )
        return None


def calculate_easter(year: int) -> date:
    """Calculate Easter Sunday for a given year using the Anonymous Gregorian algorithm.

    Args:
        year: The year to calculate Easter for

    Returns:
        Date of Easter Sunday
    """
    a = year % 19
    b = year // 100
    c = year % 100
    d = b // 4
    e = b % 4
    f = (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19 * a + b - d - g + 15) % 30
    i = c // 4
    k = c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) // 451
    month = (h + l - 7 * m + 114) // 31
    day = ((h + l - 7 * m + 114) % 31) + 1
    return date(year, month, day)


def calculate_nth_weekday(
    year: int,
    month: int,
    weekday: int,
    n: int,
) -> date:
    """Calculate the nth occurrence of a weekday in a month.

    Args:
        year: The year
        month: The month (1-12)
        weekday: Day of week (0=Monday, 6=Sunday)
        n: Which occurrence (1=first, 2=second, etc.)

    Returns:
        The calculated date
    """
    first_day = date(year, month, 1)
    # Find first occurrence of the weekday
    days_until_weekday = (weekday - first_day.weekday()) % 7
    first_occurrence = first_day + timedelta(days=days_until_weekday)
    # Add weeks to get nth occurrence
    return first_occurrence + timedelta(weeks=n - 1)


def calculate_last_weekday(
    year: int,
    month: int,
    weekday: int,
) -> date:
    """Calculate the last occurrence of a weekday in a month.

    Args:
        year: The year
        month: The month (1-12)
        weekday: Day of week (0=Monday, 6=Sunday)

    Returns:
        The calculated date
    """
    # Find last day of month
    if month == 12:
        last_day = date(year + 1, 1, 1) - timedelta(days=1)
    else:
        last_day = date(year, month + 1, 1) - timedelta(days=1)

    # Find last occurrence of the weekday
    days_since_weekday = (last_day.weekday() - weekday) % 7
    return last_day - timedelta(days=days_since_weekday)


def calculate_winter_solstice(year: int) -> date:
    """Calculate approximate winter solstice date (Northern Hemisphere).

    Args:
        year: The year

    Returns:
        Approximate date of winter solstice (usually Dec 21-22)
    """
    # Winter solstice is typically December 21 or 22
    # Using a simple approximation
    return date(year, 12, 21)


def calculate_summer_solstice(year: int) -> date:
    """Calculate approximate summer solstice date (Northern Hemisphere).

    Args:
        year: The year

    Returns:
        Approximate date of summer solstice (usually June 20-21)
    """
    return date(year, 6, 21)


def calculate_sambok(year: int) -> list[date]:
    """Calculate Korean Sambok (three hottest days) dates.

    Sambok consists of:
    - Chobok (초복): First hot day, ~11 days after summer solstice
    - Jungbok (중복): Middle hot day, 10 days after Chobok
    - Malbok (말복): Last hot day, 10-20 days after Jungbok

    Args:
        year: The year

    Returns:
        List of three dates [Chobok, Jungbok, Malbok]
    """
    summer_solstice = calculate_summer_solstice(year)
    # Simplified calculation - actual calculation involves 干支 (stem-branch)
    # Chobok is typically around July 11-22
    chobok = summer_solstice + timedelta(days=20)
    jungbok = chobok + timedelta(days=10)
    malbok = jungbok + timedelta(days=10)
    return [chobok, jungbok, malbok]
