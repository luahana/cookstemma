-- Create autocomplete type enum
DO $$ BEGIN
    CREATE TYPE autocomplete_type AS ENUM ('DISH', 'MAIN_INGREDIENT', 'SECONDARY_INGREDIENT', 'SEASONING');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create dedicated autocomplete items table
CREATE TABLE IF NOT EXISTS autocomplete_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    type autocomplete_type NOT NULL,
    name JSONB NOT NULL DEFAULT '{}',  -- {"en-US": "...", "ko-KR": "...", etc.}
    score DOUBLE PRECISION DEFAULT 50.0,

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_autocomplete_type ON autocomplete_items(type);
CREATE INDEX IF NOT EXISTS idx_autocomplete_name_gin ON autocomplete_items USING GIN (name);
CREATE INDEX IF NOT EXISTS idx_autocomplete_score ON autocomplete_items(score DESC);
