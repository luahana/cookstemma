"""Command-line interface for the bot engine."""

import argparse
import asyncio
import sys
from typing import Dict

import structlog

from .config import get_settings
from .orchestrator import ContentScheduler


def setup_logging(level: str = "INFO") -> None:
    """Configure structured logging."""
    # Fix Windows console encoding for non-ASCII characters (Korean, etc.)
    if sys.stdout and hasattr(sys.stdout, "reconfigure"):
        try:
            sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        except (AttributeError, OSError):
            pass  # Not supported on this platform/stream

    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.dev.ConsoleRenderer(colors=True),
        ],
        wrapper_class=structlog.stdlib.BoundLogger,
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )

    import logging

    logging.basicConfig(
        format="%(message)s",
        level=getattr(logging, level.upper()),
    )


def load_api_keys_from_env() -> Dict[str, str]:
    """Load persona API keys from environment variables.

    Expects format: BOT_API_KEY_<PERSONA_NAME>=pp_bot_xxx
    e.g., BOT_API_KEY_CHEF_PARK_SOOJIN=pp_bot_xxx
    """
    import os

    keys: Dict[str, str] = {}
    prefix = "BOT_API_KEY_"

    for key, value in os.environ.items():
        if key.startswith(prefix) and value:
            persona_name = key[len(prefix) :].lower()
            keys[persona_name] = value

    return keys


async def run_seed(args: argparse.Namespace) -> None:
    """Run initial content seeding."""
    logger = structlog.get_logger()

    api_keys = load_api_keys_from_env()
    if not api_keys:
        logger.error("no_api_keys", hint="Set BOT_API_KEY_<PERSONA_NAME> env vars")
        sys.exit(1)

    logger.info(
        "seed_starting",
        personas=list(api_keys.keys()),
        recipes=args.recipes,
        logs=args.logs,
        images=not args.no_images,
    )

    scheduler = ContentScheduler(
        persona_api_keys=api_keys,
        generate_images=not args.no_images,
    )

    await scheduler.run_initial_seed(
        total_recipes=args.recipes,
        total_logs=args.logs,
    )


async def run_daily(args: argparse.Namespace) -> None:
    """Run daily content generation once."""
    logger = structlog.get_logger()

    api_keys = load_api_keys_from_env()
    if not api_keys:
        logger.error("no_api_keys")
        sys.exit(1)

    run_all = getattr(args, "all", False)
    scheduler = ContentScheduler(
        persona_api_keys=api_keys,
        generate_images=not args.no_images,
        run_all=run_all,
    )

    await scheduler.generate_daily_content()


async def run_scheduler(args: argparse.Namespace) -> None:
    """Run the content scheduler daemon."""
    logger = structlog.get_logger()

    api_keys = load_api_keys_from_env()
    if not api_keys:
        logger.error("no_api_keys")
        sys.exit(1)

    run_all = getattr(args, "all", False)
    scheduler = ContentScheduler(
        persona_api_keys=api_keys,
        generate_images=not args.no_images,
        run_all=run_all,
    )

    scheduler.start_scheduler(
        daily_time=args.time,
        timezone=args.timezone,
    )

    logger.info("scheduler_running", time=args.time, tz=args.timezone)

    # Keep running until interrupted
    try:
        while True:
            await asyncio.sleep(3600)
    except KeyboardInterrupt:
        logger.info("scheduler_stopping")
        scheduler.stop_scheduler()


def main() -> None:
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Cookstemma Bot Engine - AI content generation",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose logging",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    # Seed command
    seed_parser = subparsers.add_parser(
        "seed",
        help="Run initial content seeding",
    )
    seed_parser.add_argument(
        "--recipes",
        type=int,
        default=500,
        help="Target number of recipes (default: 500)",
    )
    seed_parser.add_argument(
        "--logs",
        type=int,
        default=2000,
        help="Target number of logs (default: 2000)",
    )
    seed_parser.add_argument(
        "--no-images",
        action="store_true",
        help="Skip image generation",
    )

    # Daily command
    daily_parser = subparsers.add_parser(
        "daily",
        help="Run daily content generation once",
    )
    daily_parser.add_argument(
        "--no-images",
        action="store_true",
        help="Skip image generation",
    )
    daily_parser.add_argument(
        "--all",
        action="store_true",
        help="Run all bots regardless of schedule",
    )

    # Scheduler command
    scheduler_parser = subparsers.add_parser(
        "scheduler",
        help="Run content scheduler daemon",
    )
    scheduler_parser.add_argument(
        "--time",
        default="09:00",
        help="Daily generation time (HH:MM, default: 09:00)",
    )
    scheduler_parser.add_argument(
        "--timezone",
        default="Asia/Seoul",
        help="Timezone (default: Asia/Seoul)",
    )
    scheduler_parser.add_argument(
        "--no-images",
        action="store_true",
        help="Skip image generation",
    )
    scheduler_parser.add_argument(
        "--all",
        action="store_true",
        help="Run all bots regardless of schedule",
    )

    args = parser.parse_args()

    # Setup logging
    log_level = "DEBUG" if args.verbose else get_settings().log_level
    setup_logging(log_level)

    # Run the appropriate command
    if args.command == "seed":
        asyncio.run(run_seed(args))
    elif args.command == "daily":
        asyncio.run(run_daily(args))
    elif args.command == "scheduler":
        asyncio.run(run_scheduler(args))


if __name__ == "__main__":
    main()
