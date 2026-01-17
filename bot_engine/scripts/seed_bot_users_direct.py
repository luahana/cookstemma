#!/usr/bin/env python3
"""Direct database seeding for bot users.

This script creates bot users and API keys directly in the database,
bypassing the admin API. Use this for initial setup/testing only.

Usage:
    python scripts/seed_bot_users_direct.py
"""

import hashlib
import os
import secrets
import sys
from datetime import datetime, timezone
from pathlib import Path

import psycopg2
from psycopg2.extras import RealDictCursor

# Database connection settings (match docker-compose / application-dev.yml)
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "mydatabase")
DB_USER = os.getenv("DB_USER", "myuser")
DB_PASSWORD = os.getenv("DB_PASSWORD", "mypassword")

# Bot persona definitions to create
BOT_PERSONAS = [
    {
        "name": "chef_park_soojin",
        "display_name": '{"ko": "박수진 셰프", "en": "Chef Park Soojin"}',
        "tone": "PROFESSIONAL",
        "skill_level": "EXPERT",
        "dietary_focus": None,
        "vocabulary_style": "TECHNICAL",
        "locale": "ko",
        "culinary_locale": "ko",
        "kitchen_style_prompt": "Modern Korean fine dining kitchen with professional equipment, clean stainless steel surfaces",
    },
    {
        "name": "yoriking_minsu",
        "display_name": '{"ko": "요리킹 민수", "en": "Cooking King Minsu"}',
        "tone": "CASUAL",
        "skill_level": "BEGINNER",
        "dietary_focus": None,
        "vocabulary_style": "COLLOQUIAL",
        "locale": "ko",
        "culinary_locale": "ko",
        "kitchen_style_prompt": "Small Korean studio apartment kitchen, budget-friendly setup",
    },
]


def generate_api_key() -> tuple[str, str, str]:
    """Generate a new API key.

    Returns:
        Tuple of (full_key, prefix, hash)
    """
    # Generate random key
    random_part = secrets.token_hex(24)
    full_key = f"pp_bot_{random_part}"

    # Get prefix (first 8 chars for storage)
    prefix = full_key[:8]  # "pp_bot_x"

    # Hash for storage
    key_hash = hashlib.sha256(full_key.encode()).hexdigest()

    return full_key, prefix, key_hash


def seed_database():
    """Seed bot personas and users directly in the database."""
    print(f"Connecting to database: {DB_HOST}:{DB_PORT}/{DB_NAME}")

    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
    )

    api_keys = {}

    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            # Check if personas exist
            cur.execute("SELECT COUNT(*) as count FROM bot_personas")
            persona_count = cur.fetchone()["count"]

            if persona_count == 0:
                print("No personas found. Seeding personas...")
                for persona in BOT_PERSONAS:
                    cur.execute("""
                        INSERT INTO bot_personas
                        (name, display_name, tone, skill_level, dietary_focus,
                         vocabulary_style, locale, culinary_locale, kitchen_style_prompt)
                        VALUES (%s, %s::jsonb, %s, %s, %s, %s, %s, %s, %s)
                        ON CONFLICT (name) DO NOTHING
                        RETURNING id, public_id, name
                    """, (
                        persona["name"],
                        persona["display_name"],
                        persona["tone"],
                        persona["skill_level"],
                        persona["dietary_focus"],
                        persona["vocabulary_style"],
                        persona["locale"],
                        persona["culinary_locale"],
                        persona["kitchen_style_prompt"],
                    ))
                    row = cur.fetchone()
                    if row:
                        print(f"  Created persona: {row['name']}")
                conn.commit()
            else:
                print(f"Found {persona_count} existing personas")

            # Get all personas
            cur.execute("SELECT id, public_id, name, locale FROM bot_personas WHERE is_active = TRUE")
            personas = {row["name"]: row for row in cur.fetchall()}
            print(f"Active personas: {list(personas.keys())}")

            # Create bot users for each persona
            for persona_name, persona in personas.items():
                # Check if user exists
                cur.execute(
                    "SELECT id, public_id, username FROM users WHERE username = %s",
                    (persona_name,)
                )
                user = cur.fetchone()

                if not user:
                    print(f"\nCreating bot user: {persona_name}")
                    locale = persona.get("locale", "ko")
                    cur.execute("""
                        INSERT INTO users
                        (username, email, is_bot, persona_id, role, locale)
                        VALUES (%s, %s, TRUE, %s, 'BOT', %s)
                        RETURNING id, public_id, username
                    """, (
                        persona_name,
                        f"{persona_name}@bot.pairingplanet.com",
                        persona["id"],
                        locale,
                    ))
                    user = cur.fetchone()
                    print(f"  Created user: {user['username']} (id: {user['id']})")
                else:
                    print(f"\nUser exists: {persona_name}")

                # Check for existing API key
                cur.execute(
                    "SELECT key_prefix FROM bot_api_keys WHERE bot_user_id = %s AND is_active = TRUE",
                    (user["id"],)
                )
                existing_key = cur.fetchone()

                if existing_key:
                    print(f"  Existing API key: {existing_key['key_prefix']}...")
                else:
                    # Create new API key
                    full_key, prefix, key_hash = generate_api_key()
                    cur.execute("""
                        INSERT INTO bot_api_keys
                        (key_prefix, key_hash, bot_user_id, name)
                        VALUES (%s, %s, %s, %s)
                        RETURNING public_id
                    """, (
                        prefix,
                        key_hash,
                        user["id"],
                        f"Default key for {persona_name}",
                    ))
                    api_keys[persona_name] = full_key
                    print(f"  Created API key: {prefix}...")

            conn.commit()

    finally:
        conn.close()

    if api_keys:
        print("\n" + "=" * 60)
        print("NEW API KEYS (save these - shown only once!):")
        print("=" * 60)
        for name, key in api_keys.items():
            env_name = f"BOT_API_KEY_{name.upper()}"
            print(f"{env_name}={key}")
        print("=" * 60)

        # Also output for .env file
        print("\nAdd to bot_engine/.env:")
        for name, key in api_keys.items():
            env_name = f"BOT_API_KEY_{name.upper()}"
            print(f"{env_name}={key}")
    else:
        print("\nNo new API keys generated.")

    return api_keys


if __name__ == "__main__":
    try:
        seed_database()
    except psycopg2.Error as e:
        print(f"Database error: {e}")
        sys.exit(1)
