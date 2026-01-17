-- =============================================================================
-- UTILITY FUNCTIONS - Repeatable Migration
-- Purpose: Functions that can be safely recreated on every deployment
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_timestamp() IS 'Trigger function to auto-update updated_at column';

-- Validate JSONB has locale structure
CREATE OR REPLACE FUNCTION is_valid_locale_jsonb(data JSONB)
RETURNS BOOLEAN AS $$
BEGIN
    IF data IS NULL OR jsonb_typeof(data) != 'object' THEN
        RETURN FALSE;
    END IF;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION is_valid_locale_jsonb(JSONB) IS 'Validates JSONB contains locale-keyed object';

-- Validate locale JSONB has at least one supported locale key
CREATE OR REPLACE FUNCTION has_valid_locale_key(data JSONB)
RETURNS BOOLEAN AS $$
BEGIN
    IF data IS NULL OR jsonb_typeof(data) != 'object' THEN
        RETURN FALSE;
    END IF;
    -- Empty object is valid (optional fields)
    IF data = '{}'::jsonb THEN
        RETURN TRUE;
    END IF;
    -- Must have at least one valid locale key
    RETURN (
        data ? 'ko-KR' OR data ? 'en-US' OR data ? 'ja-JP' OR
        data ? 'zh-CN' OR data ? 'es-ES' OR data ? 'fr-FR'
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION has_valid_locale_key(JSONB) IS 'Validates JSONB has at least one supported locale key';
