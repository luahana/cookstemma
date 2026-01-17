#!/usr/bin/env python3
"""Script to create bot users via the admin API.

This script creates bot user accounts for each persona defined in the registry.
Run this after the backend is started and you have an admin token.

Usage:
    python scripts/setup_bot_users.py --admin-token YOUR_ADMIN_TOKEN

Or set environment variable:
    export ADMIN_TOKEN=your_token
    python scripts/setup_bot_users.py
"""

import argparse
import os
import sys
from pathlib import Path

import httpx

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from personas import get_persona_registry

BACKEND_BASE_URL = os.getenv("BACKEND_BASE_URL", "http://localhost:4000/api/v1")


def create_bot_user(
    admin_token: str,
    username: str,
    persona_public_id: str,
) -> dict:
    """Create a bot user and return the API key."""
    response = httpx.post(
        f"{BACKEND_BASE_URL}/admin/bots/users",
        headers={
            "Authorization": f"Bearer {admin_token}",
            "Content-Type": "application/json",
        },
        json={
            "username": username,
            "personaPublicId": persona_public_id,
        },
        timeout=30.0,
    )

    if response.status_code == 201:
        return response.json()
    elif response.status_code == 409:
        print(f"  User {username} already exists, skipping...")
        return None
    else:
        print(f"  Error creating {username}: {response.status_code} - {response.text}")
        return None


def get_or_create_personas(admin_token: str) -> dict:
    """Get existing personas or create them."""
    # First try to get existing personas
    response = httpx.get(
        f"{BACKEND_BASE_URL}/admin/bots/personas",
        headers={"Authorization": f"Bearer {admin_token}"},
        timeout=30.0,
    )

    if response.status_code == 200:
        personas = response.json()
        if personas:
            return {p["name"]: p["publicId"] for p in personas}

    # If no personas exist, they should be seeded by V30 migration
    print("No personas found. Make sure V30 migration has run.")
    return {}


def main():
    parser = argparse.ArgumentParser(description="Create bot users")
    parser.add_argument(
        "--admin-token",
        default=os.getenv("ADMIN_TOKEN"),
        help="Admin JWT token",
    )
    parser.add_argument(
        "--base-url",
        default=BACKEND_BASE_URL,
        help="Backend base URL",
    )
    args = parser.parse_args()

    if not args.admin_token:
        print("Error: Admin token required. Set ADMIN_TOKEN env var or use --admin-token")
        sys.exit(1)

    global BACKEND_BASE_URL
    BACKEND_BASE_URL = args.base_url

    print(f"Backend URL: {BACKEND_BASE_URL}")
    print("Fetching personas...")

    # Get persona public IDs from backend
    persona_ids = get_or_create_personas(args.admin_token)

    if not persona_ids:
        print("Error: No personas found in database.")
        print("Make sure the V30__seed_bot_personas.sql migration has run.")
        sys.exit(1)

    print(f"Found {len(persona_ids)} personas")

    # Create bot users
    registry = get_persona_registry()
    api_keys = {}

    print("\nCreating bot users...")
    for persona in registry.get_all():
        if persona.name not in persona_ids:
            print(f"  Skipping {persona.name}: persona not in database")
            continue

        print(f"  Creating user for {persona.name}...")
        result = create_bot_user(
            admin_token=args.admin_token,
            username=persona.name,
            persona_public_id=persona_ids[persona.name],
        )

        if result and "apiKey" in result:
            api_keys[persona.name] = result["apiKey"]
            print(f"    API Key: {result['apiKeyPrefix']}...")

    if api_keys:
        print("\n" + "=" * 60)
        print("Add these to your .env file:")
        print("=" * 60)
        for name, key in api_keys.items():
            env_name = f"BOT_API_KEY_{name.upper()}"
            print(f"{env_name}={key}")
        print("=" * 60)
    else:
        print("\nNo new API keys generated (users may already exist)")


if __name__ == "__main__":
    main()
