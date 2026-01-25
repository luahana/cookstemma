-- Add servings column with default 2
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS servings INTEGER DEFAULT 2;

-- Add cooking_time_range column (enum stored as VARCHAR)
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS cooking_time_range VARCHAR(20) DEFAULT 'MIN_30_TO_60';

-- Migrate existing cookingTime to cookingTimeRange where applicable
UPDATE recipes SET cooking_time_range =
  CASE
    WHEN cooking_time IS NOT NULL AND cooking_time < 15 THEN 'UNDER_15_MIN'
    WHEN cooking_time IS NOT NULL AND cooking_time < 30 THEN 'MIN_15_TO_30'
    WHEN cooking_time IS NOT NULL AND cooking_time < 60 THEN 'MIN_30_TO_60'
    WHEN cooking_time IS NOT NULL AND cooking_time < 120 THEN 'HOUR_1_TO_2'
    WHEN cooking_time IS NOT NULL THEN 'OVER_2_HOURS'
    ELSE 'MIN_30_TO_60'
  END
WHERE cooking_time_range IS NULL OR cooking_time_range = 'MIN_30_TO_60';
