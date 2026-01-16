# Pairing Planet Bot Engine

AI-driven bot fleet for generating realistic recipes, variants, and cooking logs.

## Overview

The Bot Engine generates synthetic content to seed Pairing Planet with realistic data:
- **500 recipes** (50% originals, 50% variants)
- **2000 cooking logs** with authentic experiences
- **10 bot personas** (5 Korean, 5 English)

## Architecture

```
bot_engine/
├── src/
│   ├── api/           # Backend API client
│   ├── config/        # Settings management
│   ├── generators/
│   │   ├── text/      # ChatGPT recipe/log generation
│   │   └── image/     # AI image generation
│   ├── orchestrator/  # Pipelines and scheduler
│   └── personas/      # Bot personality definitions
└── tests/
```

## Setup

### 1. Install Dependencies

```bash
cd bot_engine
pip install -e ".[dev]"
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your API keys
```

### 3. Create Bot Users (Admin Required)

Use the admin API to create bot users and get API keys:

```bash
# Create a bot user
curl -X POST http://localhost:4001/api/v1/admin/bots/users \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "chef_park_soojin",
    "personaPublicId": "<persona-uuid>"
  }'
```

The response contains the API key (shown only once):
```json
{
  "userPublicId": "...",
  "apiKey": "pp_bot_xxxxx",
  "apiKeyPrefix": "pp_bot_x"
}
```

Add each API key to your `.env`:
```
BOT_API_KEY_CHEF_PARK_SOOJIN=pp_bot_xxxxx
```

## Usage

### Initial Seeding

Generate the initial content batch:

```bash
# Full seeding (500 recipes, 2000 logs)
bot-engine seed

# Custom amounts
bot-engine seed --recipes 100 --logs 400

# Without image generation (faster, for testing)
bot-engine seed --no-images
```

### Daily Content Drip

Run once to generate daily content:

```bash
bot-engine daily
```

### Scheduled Generation

Run as a daemon for automated daily content:

```bash
# Default: 9:00 AM Seoul time
bot-engine scheduler

# Custom time and timezone
bot-engine scheduler --time 10:00 --timezone America/New_York
```

## Bot Personas

### Korean Personas
| Name | Archetype | Specialty |
|------|-----------|-----------|
| chef_park_soojin | Professional Chef | Fine dining, fusion |
| yoriking_minsu | College Student | Budget, quick meals |
| healthymom_hana | Health Parent | Kid-friendly healthy |
| bakingmom_jieun | Home Baker | Korean bakery |
| worldfoodie_junhyuk | Cultural Enthusiast | Global cuisines |

### English Personas
| Name | Archetype | Specialty |
|------|-----------|-----------|
| chef_marcus_stone | Professional Chef | Farm-to-table |
| broke_college_cook | College Student | Dorm hacks, budget |
| fitfamilyfoods | Health Parent | Meal prep |
| sweettoothemma | Home Baker | American pastry |
| globaleatsalex | Cultural Enthusiast | International |

## Content Generation Pipeline

```
1. Text Generation (ChatGPT)
   └─> title, description, ingredients, steps, hashtags

2. Image Generation (Nano Banana Pro / DALL-E)
   └─> Cover images (1-3), optional step images

3. Image Upload
   └─> POST /api/v1/images/upload → imagePublicIds

4. Recipe Creation
   └─> POST /api/v1/recipes

5. Log Generation (for existing recipes)
   └─> POST /api/v1/log_posts
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENAI_API_KEY` | (required) | OpenAI API key |
| `OPENAI_MODEL` | gpt-4o | Model for text generation |
| `RECIPES_PER_DAY` | 3 | Daily recipe generation target |
| `LOGS_PER_DAY` | 8 | Daily log generation target |
| `VARIANT_RATIO` | 0.5 | Ratio of variants (50%) |
| `LOG_SUCCESS_RATIO` | 0.7 | SUCCESS outcome ratio |
| `LOG_PARTIAL_RATIO` | 0.2 | PARTIAL outcome ratio |

## Development

```bash
# Run tests
pytest

# Type checking
mypy src

# Linting
ruff check src
```

## License

MIT
