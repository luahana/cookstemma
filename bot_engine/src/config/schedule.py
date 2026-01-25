"""Bot scheduling configuration."""

import json
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

import pytz
import structlog

logger = structlog.get_logger()


class BotScheduleService:
    """Service for managing bot schedules.

    Loads schedule configuration from a JSON file and provides methods to
    determine which bots should run on a given day.
    """

    def __init__(self, config_path: Optional[Path] = None) -> None:
        """Initialize the schedule service.

        Args:
            config_path: Path to the schedule config JSON file.
                        Defaults to bot_schedules.json in the same directory.
        """
        self.config_path = config_path or Path(__file__).parent / "bot_schedules.json"
        self._schedules: Dict[str, List[str]] = {}
        self._default_days: List[str] = ["MON", "THU"]
        self._recipes_per_run: int = 2
        self._variant_ratio: float = 0.2  # 20% variants, 80% originals
        self._generate_logs: bool = False  # No log posts
        self._load_config()

    def _load_config(self) -> None:
        """Load schedule configuration from JSON file."""
        if not self.config_path.exists():
            logger.warning(
                "schedule_config_not_found",
                path=str(self.config_path),
                using_defaults=True,
            )
            return

        try:
            with open(self.config_path, "r", encoding="utf-8") as f:
                config = json.load(f)

            # Load persona-to-days mapping
            self._schedules = config.get("persona_to_days", {})
            self._default_days = config.get("default_days", ["MON", "THU"])
            self._recipes_per_run = config.get("recipes_per_run", 2)
            self._variant_ratio = config.get("variant_ratio", 0.2)
            self._generate_logs = config.get("generate_logs", False)

            logger.info(
                "schedule_config_loaded",
                config_path=str(self.config_path),
                total_scheduled_bots=len(self._schedules),
                recipes_per_run=self._recipes_per_run,
                variant_ratio=self._variant_ratio,
                generate_logs=self._generate_logs,
            )
        except json.JSONDecodeError as e:
            logger.error(
                "schedule_config_parse_error",
                path=str(self.config_path),
                error=str(e),
            )
        except Exception as e:
            logger.error(
                "schedule_config_load_error",
                path=str(self.config_path),
                error=str(e),
            )

    def get_today_day(self, timezone: str = "Asia/Seoul") -> str:
        """Get today's day abbreviation in the specified timezone.

        Args:
            timezone: Timezone for determining the current day.

        Returns:
            Three-letter day abbreviation (MON, TUE, WED, THU, FRI, SAT, SUN).
        """
        tz = pytz.timezone(timezone)
        now = datetime.now(tz)
        return now.strftime("%a").upper()[:3]

    def get_scheduled_personas(
        self,
        all_persona_names: List[str],
        day: Optional[str] = None,
        timezone: str = "Asia/Seoul",
    ) -> List[str]:
        """Get personas scheduled to run on a given day.

        Args:
            all_persona_names: List of all available persona names.
            day: Day to check (e.g., "MON"). Defaults to today.
            timezone: Timezone for determining today's day.

        Returns:
            List of persona names scheduled for that day.
        """
        if day is None:
            day = self.get_today_day(timezone)

        scheduled = []
        for name in all_persona_names:
            days = self._schedules.get(name, self._default_days)
            if day in days:
                scheduled.append(name)

        logger.info(
            "scheduled_personas_for_day",
            day=day,
            total_available=len(all_persona_names),
            scheduled_count=len(scheduled),
            scheduled_personas=scheduled,
        )
        return scheduled

    def is_scheduled_today(
        self,
        persona_name: str,
        timezone: str = "Asia/Seoul",
    ) -> bool:
        """Check if a specific persona is scheduled for today.

        Args:
            persona_name: Name of the persona to check.
            timezone: Timezone for determining today's day.

        Returns:
            True if the persona is scheduled for today.
        """
        today = self.get_today_day(timezone)
        scheduled_days = self._schedules.get(persona_name, self._default_days)
        return today in scheduled_days

    def get_recipes_per_run(self) -> int:
        """Get the number of recipes each bot should generate per run.

        Returns:
            Number of recipes per bot per run.
        """
        return self._recipes_per_run

    def get_variant_ratio(self) -> float:
        """Get variant ratio.

        Returns:
            Variant ratio (0.2 = 20% variants, 80% originals).
        """
        return self._variant_ratio

    def should_generate_logs(self) -> bool:
        """Check if log posts should be generated.

        Returns:
            True if log posts should be generated.
        """
        return self._generate_logs

    def get_schedule(self, persona_name: str) -> List[str]:
        """Get the schedule for a specific persona.

        Args:
            persona_name: Name of the persona.

        Returns:
            List of day abbreviations when the persona runs.
        """
        return self._schedules.get(persona_name, self._default_days)

    def get_all_schedules(self) -> Dict[str, List[str]]:
        """Get all persona schedules.

        Returns:
            Dictionary mapping persona names to their scheduled days.
        """
        return self._schedules.copy()


# Global instance
_schedule_service: Optional[BotScheduleService] = None


def get_schedule_service() -> BotScheduleService:
    """Get the global schedule service instance.

    Returns:
        BotScheduleService singleton instance.
    """
    global _schedule_service
    if _schedule_service is None:
        _schedule_service = BotScheduleService()
    return _schedule_service
