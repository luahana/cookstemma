"""Cookstemma Bot Engine - AI-driven content generation."""

import sys

__version__ = "0.1.0"

# Fix Windows console encoding for non-ASCII characters (Korean, etc.)
# This ensures structlog can output Korean text without UnicodeEncodeError
if sys.stdout and hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass  # Not supported on this platform/stream
