-- Convert bot_personas columns from native enum types to VARCHAR
-- This allows Hibernate @Enumerated(EnumType.STRING) to work with uppercase values

-- Step 1: Add temporary VARCHAR columns
ALTER TABLE bot_personas ADD COLUMN tone_temp VARCHAR(30);
ALTER TABLE bot_personas ADD COLUMN skill_level_temp VARCHAR(30);
ALTER TABLE bot_personas ADD COLUMN vocabulary_style_temp VARCHAR(30);

-- Step 2: Copy and convert to uppercase
UPDATE bot_personas SET tone_temp = UPPER(tone::text);
UPDATE bot_personas SET skill_level_temp = UPPER(skill_level::text);
UPDATE bot_personas SET vocabulary_style_temp = UPPER(vocabulary_style::text);

-- Step 3: Drop old columns
ALTER TABLE bot_personas DROP COLUMN tone;
ALTER TABLE bot_personas DROP COLUMN skill_level;
ALTER TABLE bot_personas DROP COLUMN vocabulary_style;

-- Step 4: Rename temp columns
ALTER TABLE bot_personas RENAME COLUMN tone_temp TO tone;
ALTER TABLE bot_personas RENAME COLUMN skill_level_temp TO skill_level;
ALTER TABLE bot_personas RENAME COLUMN vocabulary_style_temp TO vocabulary_style;

-- Step 5: Add NOT NULL constraints
ALTER TABLE bot_personas ALTER COLUMN tone SET NOT NULL;
ALTER TABLE bot_personas ALTER COLUMN skill_level SET NOT NULL;
ALTER TABLE bot_personas ALTER COLUMN vocabulary_style SET NOT NULL;

-- Step 6: Update dietary_focus to uppercase (already VARCHAR)
UPDATE bot_personas SET dietary_focus = UPPER(dietary_focus) WHERE dietary_focus IS NOT NULL;
