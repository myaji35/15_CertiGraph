-- Migration 002: Add PDF hash for duplicate detection and questions table
-- Run this in Supabase SQL Editor after 001_initial_schema.sql

-- ============================================
-- Modify study_sets table for duplicate detection
-- ============================================

-- Add new columns to study_sets
ALTER TABLE study_sets
ADD COLUMN IF NOT EXISTS pdf_hash TEXT,
ADD COLUMN IF NOT EXISTS pdf_path TEXT,
ADD COLUMN IF NOT EXISTS source_study_set_id UUID REFERENCES study_sets(id),
ADD COLUMN IF NOT EXISTS progress INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS current_step TEXT;

-- Update status check constraint to include new statuses
ALTER TABLE study_sets
DROP CONSTRAINT IF EXISTS study_sets_status_check;

ALTER TABLE study_sets
ADD CONSTRAINT study_sets_status_check
CHECK (status IN ('uploading', 'parsing', 'processing', 'ready', 'failed'));

-- Index for fast hash lookup (duplicate detection)
CREATE INDEX IF NOT EXISTS idx_study_sets_pdf_hash ON study_sets(pdf_hash);

-- Index for source study set (cached copies)
CREATE INDEX IF NOT EXISTS idx_study_sets_source ON study_sets(source_study_set_id);

-- ============================================
-- Questions table (stores parsed questions from PDFs)
-- ============================================
CREATE TABLE IF NOT EXISTS questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    study_set_id UUID NOT NULL REFERENCES study_sets(id) ON DELETE CASCADE,
    question_number INTEGER NOT NULL,
    question_text TEXT NOT NULL,
    options JSONB NOT NULL,  -- Array of option objects: [{number: 1, text: "..."}, ...]
    correct_answer INTEGER NOT NULL CHECK (correct_answer BETWEEN 1 AND 5),
    explanation TEXT,
    subject TEXT,  -- 과목 (e.g., "사회복지기초", "사회복지실천론")
    topic TEXT,    -- 세부 주제
    difficulty INTEGER CHECK (difficulty BETWEEN 1 AND 5),
    embedding_id TEXT,  -- Pinecone vector ID
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for questions
CREATE INDEX IF NOT EXISTS idx_questions_study_set_id ON questions(study_set_id);
CREATE INDEX IF NOT EXISTS idx_questions_subject ON questions(subject);
CREATE INDEX IF NOT EXISTS idx_questions_topic ON questions(topic);

-- Composite index for efficient ordering
CREATE INDEX IF NOT EXISTS idx_questions_study_set_order
ON questions(study_set_id, question_number);

-- Enable RLS
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- Temporary user ID mapping for clerk_id
-- Since we might not have users synced yet, allow clerk_id as user_id
-- ============================================

-- Make user_id nullable temporarily (or use clerk_id directly)
-- For MVP, we'll use clerk_id as text in user_id field
-- This will be refactored when proper user sync is implemented

ALTER TABLE study_sets
ALTER COLUMN user_id DROP NOT NULL;

-- Add clerk_user_id directly to study_sets for easier querying
ALTER TABLE study_sets
ADD COLUMN IF NOT EXISTS clerk_user_id TEXT;

-- Update the user_id to be TEXT type for now (stores clerk_id)
-- Note: In production, you'd want proper foreign key to users table
-- This is a pragmatic MVP approach

-- Create index for clerk_user_id lookup
CREATE INDEX IF NOT EXISTS idx_study_sets_clerk_user_id ON study_sets(clerk_user_id);

-- ============================================
-- Comment: Schema Design Notes
-- ============================================
--
-- PDF Duplicate Detection Flow:
-- 1. When PDF is uploaded, compute SHA-256 hash
-- 2. Check if study_sets with same pdf_hash exists (status='ready', source_study_set_id IS NULL)
-- 3. If found:
--    - Create new study_set with source_study_set_id pointing to original
--    - Copy questions from source to new study_set
--    - Show fake processing UI while copying happens in background
-- 4. If not found:
--    - Process PDF normally (Upstage + Claude parsing)
--
-- Benefits:
-- - Saves Upstage/Claude API costs
-- - Faster user experience for duplicate PDFs
-- - Users still get their own study_set for tracking progress
--
-- The is_cached flag in API responses indicates if cached results were used.
