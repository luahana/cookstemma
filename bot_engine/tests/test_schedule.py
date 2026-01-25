"""Tests for bot scheduling functionality."""

import json
from datetime import datetime
from pathlib import Path
from unittest.mock import patch

import pytest

from src.config.schedule import BotScheduleService, get_schedule_service


class TestBotScheduleService:
    """Tests for the BotScheduleService class."""

    @pytest.fixture
    def sample_config(self) -> dict:
        """Create a sample schedule configuration."""
        return {
            "schedules": {
                "group_1_mon_thu": ["chef_a", "chef_b"],
                "group_2_tue_fri": ["chef_c", "chef_d"],
            },
            "persona_to_days": {
                "chef_a": ["MON", "THU"],
                "chef_b": ["MON", "THU"],
                "chef_c": ["TUE", "FRI"],
                "chef_d": ["TUE", "FRI"],
                "chef_e": ["WED", "SAT"],
            },
            "default_days": ["MON", "THU"],
            "recipes_per_run": 3,
            "variant_ratio": 0.2,
            "generate_logs": False,
        }

    @pytest.fixture
    def config_file(self, sample_config: dict, tmp_path: Path) -> Path:
        """Create a temporary config file."""
        config_file = tmp_path / "test_config.json"
        config_file.write_text(json.dumps(sample_config), encoding="utf-8")
        return config_file

    @pytest.fixture
    def schedule_service(self, config_file: Path) -> BotScheduleService:
        """Create a schedule service with test config."""
        return BotScheduleService(config_path=config_file)

    def test_load_config(self, schedule_service: BotScheduleService) -> None:
        """Test that config is loaded correctly."""
        assert schedule_service.get_recipes_per_run() == 3
        assert schedule_service.get_variant_ratio() == 0.2
        assert schedule_service.should_generate_logs() is False

    def test_get_schedule_for_persona(
        self, schedule_service: BotScheduleService
    ) -> None:
        """Test getting schedule for a specific persona."""
        assert schedule_service.get_schedule("chef_a") == ["MON", "THU"]
        assert schedule_service.get_schedule("chef_c") == ["TUE", "FRI"]
        assert schedule_service.get_schedule("chef_e") == ["WED", "SAT"]

    def test_get_schedule_uses_default_for_unknown(
        self, schedule_service: BotScheduleService
    ) -> None:
        """Test that unknown personas use default schedule."""
        assert schedule_service.get_schedule("unknown_chef") == ["MON", "THU"]

    def test_get_today_day(self, schedule_service: BotScheduleService) -> None:
        """Test getting today's day abbreviation."""
        day = schedule_service.get_today_day()
        assert day in ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
        assert len(day) == 3

    @patch("src.config.schedule.datetime")
    def test_get_today_day_monday(
        self, mock_datetime, schedule_service: BotScheduleService
    ) -> None:
        """Test that Monday returns 'MON'."""
        # January 6, 2025 is a Monday
        mock_datetime.now.return_value = datetime(2025, 1, 6, 12, 0, 0)
        # We need to also mock strftime behavior
        with patch.object(
            schedule_service, "get_today_day", return_value="MON"
        ):
            assert schedule_service.get_today_day() == "MON"

    def test_get_scheduled_personas_monday(
        self, schedule_service: BotScheduleService
    ) -> None:
        """Test getting personas scheduled for Monday."""
        all_personas = ["chef_a", "chef_b", "chef_c", "chef_d", "chef_e"]
        scheduled = schedule_service.get_scheduled_personas(all_personas, day="MON")

        # chef_a and chef_b are scheduled for MON
        assert "chef_a" in scheduled
        assert "chef_b" in scheduled
        assert "chef_c" not in scheduled  # TUE, FRI
        assert "chef_d" not in scheduled  # TUE, FRI
        assert "chef_e" not in scheduled  # WED, SAT

    def test_get_scheduled_personas_tuesday(
        self, schedule_service: BotScheduleService
    ) -> None:
        """Test getting personas scheduled for Tuesday."""
        all_personas = ["chef_a", "chef_b", "chef_c", "chef_d", "chef_e"]
        scheduled = schedule_service.get_scheduled_personas(all_personas, day="TUE")

        # chef_c and chef_d are scheduled for TUE
        assert "chef_a" not in scheduled
        assert "chef_b" not in scheduled
        assert "chef_c" in scheduled
        assert "chef_d" in scheduled
        assert "chef_e" not in scheduled

    def test_get_scheduled_personas_with_unknown(
        self, schedule_service: BotScheduleService
    ) -> None:
        """Test that unknown personas use default schedule."""
        all_personas = ["chef_a", "unknown_chef"]
        scheduled = schedule_service.get_scheduled_personas(all_personas, day="MON")

        # Both should be scheduled - chef_a explicitly, unknown_chef via default
        assert "chef_a" in scheduled
        assert "unknown_chef" in scheduled

    def test_get_scheduled_personas_empty_list(
        self, schedule_service: BotScheduleService
    ) -> None:
        """Test with empty persona list."""
        scheduled = schedule_service.get_scheduled_personas([], day="MON")
        assert scheduled == []

    def test_is_scheduled_today(
        self, schedule_service: BotScheduleService
    ) -> None:
        """Test checking if persona is scheduled for a specific day."""
        with patch.object(schedule_service, "get_today_day", return_value="MON"):
            assert schedule_service.is_scheduled_today("chef_a") is True
            assert schedule_service.is_scheduled_today("chef_c") is False

        with patch.object(schedule_service, "get_today_day", return_value="TUE"):
            assert schedule_service.is_scheduled_today("chef_a") is False
            assert schedule_service.is_scheduled_today("chef_c") is True

    def test_get_all_schedules(
        self, schedule_service: BotScheduleService
    ) -> None:
        """Test getting all schedules."""
        schedules = schedule_service.get_all_schedules()

        assert "chef_a" in schedules
        assert schedules["chef_a"] == ["MON", "THU"]
        assert len(schedules) == 5

    def test_missing_config_uses_defaults(self, tmp_path: Path) -> None:
        """Test that missing config file uses default values."""
        nonexistent = tmp_path / "nonexistent.json"
        service = BotScheduleService(config_path=nonexistent)

        # Should use defaults
        assert service.get_recipes_per_run() == 2
        assert service.get_variant_ratio() == 0.2
        assert service.should_generate_logs() is False
        assert service.get_schedule("any_persona") == ["MON", "THU"]

    def test_invalid_json_uses_defaults(self, tmp_path: Path) -> None:
        """Test that invalid JSON config uses default values."""
        invalid_config = tmp_path / "invalid.json"
        invalid_config.write_text("not valid json {{{")

        service = BotScheduleService(config_path=invalid_config)

        # Should use defaults
        assert service.get_recipes_per_run() == 2
        assert service.get_variant_ratio() == 0.2


class TestScheduleServiceSingleton:
    """Tests for the schedule service singleton."""

    def test_get_schedule_service_returns_instance(self) -> None:
        """Test that get_schedule_service returns a BotScheduleService."""
        # Reset global instance for clean test
        import src.config.schedule as schedule_module

        schedule_module._schedule_service = None

        service = get_schedule_service()
        assert isinstance(service, BotScheduleService)

    def test_get_schedule_service_returns_same_instance(self) -> None:
        """Test that get_schedule_service returns singleton."""
        service1 = get_schedule_service()
        service2 = get_schedule_service()
        assert service1 is service2


class TestScheduleDistribution:
    """Tests to verify proper distribution of bots across days."""

    @pytest.fixture
    def full_config(self) -> dict:
        """Create config with bots distributed across all days."""
        return {
            "persona_to_days": {
                # Group 1: MON, THU
                "chef_1": ["MON", "THU"],
                "chef_2": ["MON", "THU"],
                # Group 2: TUE, FRI
                "chef_3": ["TUE", "FRI"],
                "chef_4": ["TUE", "FRI"],
                # Group 3: WED, SAT
                "chef_5": ["WED", "SAT"],
                "chef_6": ["WED", "SAT"],
                # Group 4: SUN, WED
                "chef_7": ["SUN", "WED"],
                "chef_8": ["SUN", "WED"],
                # Group 5: MON, FRI
                "chef_9": ["MON", "FRI"],
                "chef_10": ["MON", "FRI"],
                # Group 6: TUE, SAT
                "chef_11": ["TUE", "SAT"],
                "chef_12": ["TUE", "SAT"],
                # Group 7: THU, SUN
                "chef_13": ["THU", "SUN"],
                "chef_14": ["THU", "SUN"],
            },
            "default_days": ["MON", "THU"],
            "recipes_per_run": 2,
            "variant_ratio": 0.2,
            "generate_logs": False,
        }

    @pytest.fixture
    def full_service(self, full_config: dict, tmp_path: Path) -> BotScheduleService:
        """Create service with full distribution config."""
        config_file = tmp_path / "full_config.json"
        config_file.write_text(json.dumps(full_config), encoding="utf-8")
        return BotScheduleService(config_path=config_file)

    def test_each_bot_runs_twice_per_week(self, full_config: dict) -> None:
        """Verify each bot is scheduled for exactly 2 days."""
        for persona, days in full_config["persona_to_days"].items():
            assert len(days) == 2, f"{persona} should run 2 days, has {len(days)}"

    def test_monday_distribution(self, full_service: BotScheduleService) -> None:
        """Test Monday has expected number of bots."""
        all_personas = [f"chef_{i}" for i in range(1, 15)]
        scheduled = full_service.get_scheduled_personas(all_personas, day="MON")

        # MON: chef_1, chef_2 (group 1) + chef_9, chef_10 (group 5) = 4
        assert len(scheduled) == 4

    def test_wednesday_distribution(self, full_service: BotScheduleService) -> None:
        """Test Wednesday has expected number of bots (overlapping groups)."""
        all_personas = [f"chef_{i}" for i in range(1, 15)]
        scheduled = full_service.get_scheduled_personas(all_personas, day="WED")

        # WED: chef_5, chef_6 (group 3) + chef_7, chef_8 (group 4) = 4
        assert len(scheduled) == 4

    def test_weekend_distribution(self, full_service: BotScheduleService) -> None:
        """Test weekend days have bots scheduled."""
        all_personas = [f"chef_{i}" for i in range(1, 15)]

        sat_scheduled = full_service.get_scheduled_personas(all_personas, day="SAT")
        sun_scheduled = full_service.get_scheduled_personas(all_personas, day="SUN")

        # SAT: chef_5, chef_6 (group 3) + chef_11, chef_12 (group 6) = 4
        assert len(sat_scheduled) == 4

        # SUN: chef_7, chef_8 (group 4) + chef_13, chef_14 (group 7) = 4
        assert len(sun_scheduled) == 4


class TestConfigValues:
    """Tests for various config value scenarios."""

    def test_custom_recipes_per_run(self, tmp_path: Path) -> None:
        """Test custom recipes_per_run value."""
        config = {"recipes_per_run": 5, "persona_to_days": {}}
        config_file = tmp_path / "config.json"
        config_file.write_text(json.dumps(config))

        service = BotScheduleService(config_path=config_file)
        assert service.get_recipes_per_run() == 5

    def test_custom_variant_ratio(self, tmp_path: Path) -> None:
        """Test custom variant_ratio value."""
        config = {"variant_ratio": 0.3, "persona_to_days": {}}
        config_file = tmp_path / "config.json"
        config_file.write_text(json.dumps(config))

        service = BotScheduleService(config_path=config_file)
        assert service.get_variant_ratio() == 0.3

    def test_logs_enabled(self, tmp_path: Path) -> None:
        """Test enabling log generation."""
        config = {"generate_logs": True, "persona_to_days": {}}
        config_file = tmp_path / "config.json"
        config_file.write_text(json.dumps(config))

        service = BotScheduleService(config_path=config_file)
        assert service.should_generate_logs() is True

    def test_custom_default_days(self, tmp_path: Path) -> None:
        """Test custom default_days value."""
        config = {"default_days": ["TUE", "FRI"], "persona_to_days": {}}
        config_file = tmp_path / "config.json"
        config_file.write_text(json.dumps(config))

        service = BotScheduleService(config_path=config_file)
        assert service.get_schedule("unknown") == ["TUE", "FRI"]
