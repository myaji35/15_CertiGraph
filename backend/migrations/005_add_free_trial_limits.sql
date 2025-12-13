-- Migration 005: Add free trial limitations
-- Limits free users to 2 practice sessions per uploaded PDF

-- ============================================
-- User subscription and trial tracking
-- ============================================

-- Add subscription status to study_sets
ALTER TABLE study_sets
ADD COLUMN IF NOT EXISTS is_free_trial BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS practice_sessions_used INTEGER DEFAULT 0;

-- Create practice_sessions table to track each session
CREATE TABLE IF NOT EXISTS practice_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    study_set_id UUID NOT NULL REFERENCES study_sets(id) ON DELETE CASCADE,
    clerk_user_id TEXT NOT NULL,
    session_type TEXT NOT NULL CHECK (session_type IN ('practice', 'mock_exam')),
    questions_attempted INTEGER DEFAULT 0,
    questions_correct INTEGER DEFAULT 0,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    time_spent_seconds INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for practice sessions
CREATE INDEX IF NOT EXISTS idx_practice_sessions_study_set ON practice_sessions(study_set_id);
CREATE INDEX IF NOT EXISTS idx_practice_sessions_user ON practice_sessions(clerk_user_id);
CREATE INDEX IF NOT EXISTS idx_practice_sessions_created ON practice_sessions(created_at DESC);

-- Enable RLS
ALTER TABLE practice_sessions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- User tier and limits
-- ============================================

-- Create user_limits table to track per-user subscription status
CREATE TABLE IF NOT EXISTS user_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clerk_user_id TEXT UNIQUE NOT NULL,
    subscription_tier TEXT NOT NULL DEFAULT 'free' CHECK (subscription_tier IN ('free', 'basic', 'pro', 'enterprise')),
    max_pdfs_per_month INTEGER DEFAULT 1,  -- Free: 1 PDF per month
    max_practice_sessions_per_pdf INTEGER DEFAULT 2,  -- Free: 2 sessions per PDF
    current_month_pdfs_uploaded INTEGER DEFAULT 0,
    subscription_start_date TIMESTAMPTZ,
    subscription_end_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for user lookup
CREATE INDEX IF NOT EXISTS idx_user_limits_clerk_user_id ON user_limits(clerk_user_id);

-- Enable RLS
ALTER TABLE user_limits ENABLE ROW LEVEL SECURITY;

-- ============================================
-- Functions to check and enforce limits
-- ============================================

-- Function to check if user can start new practice session
CREATE OR REPLACE FUNCTION can_start_practice_session(
    p_study_set_id UUID,
    p_clerk_user_id TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_is_free_trial BOOLEAN;
    v_sessions_used INTEGER;
    v_max_sessions INTEGER;
    v_subscription_tier TEXT;
BEGIN
    -- Get study set trial status
    SELECT is_free_trial, practice_sessions_used
    INTO v_is_free_trial, v_sessions_used
    FROM study_sets
    WHERE id = p_study_set_id;

    -- If not found, return false
    IF NOT FOUND THEN
        RETURN false;
    END IF;

    -- Get user subscription tier and limits
    SELECT subscription_tier, max_practice_sessions_per_pdf
    INTO v_subscription_tier, v_max_sessions
    FROM user_limits
    WHERE clerk_user_id = p_clerk_user_id;

    -- If user limits not found, create default free tier
    IF NOT FOUND THEN
        INSERT INTO user_limits (clerk_user_id)
        VALUES (p_clerk_user_id)
        RETURNING max_practice_sessions_per_pdf INTO v_max_sessions;
    END IF;

    -- Paid users have unlimited sessions
    IF v_subscription_tier != 'free' THEN
        RETURN true;
    END IF;

    -- Free users check session limit
    IF v_is_free_trial AND v_sessions_used >= v_max_sessions THEN
        RETURN false;
    END IF;

    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Function to increment practice session counter
CREATE OR REPLACE FUNCTION increment_practice_session(
    p_study_set_id UUID
)
RETURNS VOID AS $$
BEGIN
    UPDATE study_sets
    SET practice_sessions_used = practice_sessions_used + 1
    WHERE id = p_study_set_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Comments: Free Trial System Design
-- ============================================
--
-- Free Trial Limits:
-- - 1 PDF upload per month
-- - 2 practice sessions per uploaded PDF
-- - After 2 sessions, user must upgrade to continue
--
-- Practice Session Definition:
-- - Any test/practice mode started with questions from the study set
-- - Counted when session is started (not completed)
-- - Mock exams also count as practice sessions
--
-- Upgrade Path:
-- - Free → Basic: Unlimited practice sessions, 10 PDFs/month
-- - Basic → Pro: AI analysis, knowledge graph, unlimited PDFs
--
-- Implementation Flow:
-- 1. User uploads PDF → Check if within monthly limit
-- 2. User starts practice → Call can_start_practice_session()
-- 3. If allowed → Create practice_session record → increment_practice_session()
-- 4. If not allowed → Show upgrade modal with pricing
--
