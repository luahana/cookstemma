-- Add default_food_style column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS default_food_style VARCHAR(5);

-- Migrate existing recipe culinary_locale values to ISO country codes
UPDATE recipes SET culinary_locale = 'KR' WHERE culinary_locale = 'ko-KR';
UPDATE recipes SET culinary_locale = 'US' WHERE culinary_locale = 'en-US';
UPDATE recipes SET culinary_locale = 'JP' WHERE culinary_locale = 'ja-JP';
UPDATE recipes SET culinary_locale = 'CN' WHERE culinary_locale = 'zh-CN';
UPDATE recipes SET culinary_locale = 'IT' WHERE culinary_locale = 'it-IT';
UPDATE recipes SET culinary_locale = 'MX' WHERE culinary_locale = 'es-MX';
UPDATE recipes SET culinary_locale = 'TH' WHERE culinary_locale = 'th-TH';
UPDATE recipes SET culinary_locale = 'IN' WHERE culinary_locale = 'hi-IN';
UPDATE recipes SET culinary_locale = 'FR' WHERE culinary_locale = 'fr-FR';
-- 'other' stays as 'other'
