-- Migration: Add learning status tracking to study sets
-- This allows users to mark study sets as: not_learned, learned, or reset

-- Add learning_status column with default 'not_learned'
ALTER TABLE study_sets
ADD COLUMN IF NOT EXISTS learning_status TEXT DEFAULT 'not_learned' CHECK (learning_status IN ('not_learned', 'learned', 'reset'));

-- Add index for filtering by learning status
CREATE INDEX IF NOT EXISTS idx_study_sets_learning_status
ON study_sets(user_id, learning_status);

-- Add last_studied_at timestamp to track when user last studied
ALTER TABLE study_sets
ADD COLUMN IF NOT EXISTS last_studied_at TIMESTAMPTZ;

-- Update existing records to have default status
UPDATE study_sets
SET learning_status = 'not_learned'
WHERE learning_status IS NULL;

-- Add comment for documentation
COMMENT ON COLUMN study_sets.learning_status IS '학습 상태: not_learned(미학습), learned(학습됨), reset(초기화)';
COMMENT ON COLUMN study_sets.last_studied_at IS '마지막 학습 시간';
