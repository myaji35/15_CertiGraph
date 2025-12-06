-- Migration 003: Add exam metadata for hierarchical organization
-- Run this in Supabase SQL Editor after 002_add_pdf_hash_and_questions.sql

-- ============================================
-- Study Sets: Add exam metadata fields
-- ============================================

-- Add exam metadata columns to study_sets
ALTER TABLE study_sets
ADD COLUMN IF NOT EXISTS exam_name TEXT,           -- 자격증 시험명 (e.g., "사회복지사 1급")
ADD COLUMN IF NOT EXISTS exam_year INTEGER,        -- 시험 년도 (e.g., 2024)
ADD COLUMN IF NOT EXISTS exam_round INTEGER,       -- n차 시험 (e.g., 1, 2, 3)
ADD COLUMN IF NOT EXISTS exam_session INTEGER,     -- 교시 (e.g., 1교시, 2교시)
ADD COLUMN IF NOT EXISTS exam_session_name TEXT,   -- 교시 명칭 (e.g., "1교시 - 사회복지기초")
ADD COLUMN IF NOT EXISTS tags TEXT[];              -- 태그 배열 (e.g., ["기출문제", "모의고사"])

-- Indexes for filtering and searching
CREATE INDEX IF NOT EXISTS idx_study_sets_exam_name ON study_sets(exam_name);
CREATE INDEX IF NOT EXISTS idx_study_sets_exam_year ON study_sets(exam_year);
CREATE INDEX IF NOT EXISTS idx_study_sets_exam_round ON study_sets(exam_round);
CREATE INDEX IF NOT EXISTS idx_study_sets_exam_session ON study_sets(exam_session);

-- Composite index for efficient hierarchical queries
CREATE INDEX IF NOT EXISTS idx_study_sets_exam_hierarchy
ON study_sets(exam_name, exam_year DESC, exam_round DESC, exam_session);

-- GIN index for tags array search
CREATE INDEX IF NOT EXISTS idx_study_sets_tags ON study_sets USING GIN (tags);

-- ============================================
-- Example data structure:
-- ============================================
--
-- Study Set 1:
--   name: "2024년 제1회 사회복지사 1급 1교시"
--   exam_name: "사회복지사 1급"
--   exam_year: 2024
--   exam_round: 1
--   exam_session: 1
--   exam_session_name: "1교시 - 사회복지기초"
--   tags: ["기출문제", "2024년"]
--
-- Study Set 2:
--   name: "2024년 제1회 사회복지사 1급 2교시"
--   exam_name: "사회복지사 1급"
--   exam_year: 2024
--   exam_round: 1
--   exam_session: 2
--   exam_session_name: "2교시 - 사회복지실천"
--   tags: ["기출문제", "2024년"]
--
-- Study Set 3:
--   name: "2023년 제2회 사회복지사 1급 1교시"
--   exam_name: "사회복지사 1급"
--   exam_year: 2023
--   exam_round: 2
--   exam_session: 1
--   exam_session_name: "1교시 - 사회복지기초"
--   tags: ["기출문제", "2023년"]
-- ============================================

-- ============================================
-- Add comment for documentation
-- ============================================
COMMENT ON COLUMN study_sets.exam_name IS '자격증 시험명 (예: 사회복지사 1급, 정보처리기사)';
COMMENT ON COLUMN study_sets.exam_year IS '시험 년도';
COMMENT ON COLUMN study_sets.exam_round IS 'n차 시험 (1차, 2차, 3차 등)';
COMMENT ON COLUMN study_sets.exam_session IS '교시 (1교시, 2교시 등)';
COMMENT ON COLUMN study_sets.exam_session_name IS '교시 명칭 (예: 1교시 - 사회복지기초)';
COMMENT ON COLUMN study_sets.tags IS '태그 배열 (기출문제, 모의고사, 예상문제 등)';

-- ============================================
-- View: Exam hierarchy for easy browsing
-- ============================================
CREATE OR REPLACE VIEW exam_hierarchy AS
SELECT
    exam_name,
    exam_year,
    exam_round,
    COUNT(DISTINCT id) as study_set_count,
    SUM(total_questions) as total_questions,
    array_agg(DISTINCT exam_session ORDER BY exam_session) as sessions
FROM study_sets
WHERE exam_name IS NOT NULL
  AND status = 'ready'
GROUP BY exam_name, exam_year, exam_round
ORDER BY exam_name, exam_year DESC, exam_round DESC;

COMMENT ON VIEW exam_hierarchy IS '시험 계층 구조 뷰 - 시험명, 년도, 차수별로 학습세트를 그룹화';
