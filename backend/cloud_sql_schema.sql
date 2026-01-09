-- CertiGraph Database Schema for Cloud SQL
-- Modified from Supabase schema (removed RLS policies)

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- User Profiles Table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clerk_id TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_profiles_clerk_id ON public.user_profiles(clerk_id);

-- =====================================================
-- Certifications Table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.certifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    provider TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- Exam Dates Table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.exam_dates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certification_id UUID REFERENCES public.certifications(id) ON DELETE CASCADE,
    exam_date DATE NOT NULL,
    registration_start DATE,
    registration_end DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_exam_dates_certification ON public.exam_dates(certification_id);

-- =====================================================
-- Subscriptions Table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clerk_id TEXT NOT NULL,
    certification_id UUID REFERENCES public.certifications(id) ON DELETE CASCADE,
    exam_date DATE,
    subscription_start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    subscription_end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    payment_key TEXT,
    order_id TEXT,
    amount INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (clerk_id) REFERENCES public.user_profiles(clerk_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_clerk_id ON public.subscriptions(clerk_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_certification ON public.subscriptions(certification_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status);

-- =====================================================
-- Study Sets Table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.study_sets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clerk_id TEXT NOT NULL,
    certification_id UUID REFERENCES public.certifications(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    pdf_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (clerk_id) REFERENCES public.user_profiles(clerk_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_study_sets_clerk_id ON public.study_sets(clerk_id);

-- =====================================================
-- Study Materials Table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.study_materials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    study_set_id UUID NOT NULL REFERENCES public.study_sets(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content_type TEXT NOT NULL,
    file_path TEXT,
    page_number INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_study_materials_study_set ON public.study_materials(study_set_id);

-- =====================================================
-- Test Sessions Table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.test_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clerk_id TEXT NOT NULL,
    study_set_id UUID REFERENCES public.study_sets(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    total_questions INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    FOREIGN KEY (clerk_id) REFERENCES public.user_profiles(clerk_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_test_sessions_clerk_id ON public.test_sessions(clerk_id);
CREATE INDEX IF NOT EXISTS idx_test_sessions_study_set ON public.test_sessions(study_set_id);

-- =====================================================
-- Free Trial Sessions Table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.free_trial_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clerk_id TEXT NOT NULL,
    pdf_hash TEXT NOT NULL,
    session_count INTEGER DEFAULT 0,
    last_session_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(clerk_id, pdf_hash),
    FOREIGN KEY (clerk_id) REFERENCES public.user_profiles(clerk_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_free_trial_clerk_id ON public.free_trial_sessions(clerk_id);
CREATE INDEX IF NOT EXISTS idx_free_trial_pdf_hash ON public.free_trial_sessions(pdf_hash);

-- =====================================================
-- Functions for subscription checking
-- =====================================================

-- Check if user has active subscription
CREATE OR REPLACE FUNCTION has_active_subscription(
    p_clerk_user_id TEXT,
    p_certification_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.subscriptions
        WHERE clerk_id = p_clerk_user_id
        AND certification_id = p_certification_id
        AND status = 'active'
        AND subscription_end_date > NOW()
    );
END;
$$ LANGUAGE plpgsql;

-- Get user subscriptions with details
CREATE OR REPLACE FUNCTION get_user_subscriptions(
    p_clerk_user_id TEXT
) RETURNS TABLE (
    subscription_id UUID,
    certification_id UUID,
    certification_name TEXT,
    exam_date DATE,
    subscription_start_date TIMESTAMP WITH TIME ZONE,
    subscription_end_date TIMESTAMP WITH TIME ZONE,
    days_remaining INTEGER,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id,
        s.certification_id,
        c.name,
        s.exam_date,
        s.subscription_start_date,
        s.subscription_end_date,
        GREATEST(0, EXTRACT(DAY FROM (s.subscription_end_date - NOW()))::INTEGER),
        s.status,
        s.created_at
    FROM public.subscriptions s
    JOIN public.certifications c ON s.certification_id = c.id
    WHERE s.clerk_id = p_clerk_user_id
    AND s.status = 'active'
    ORDER BY s.subscription_end_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO certigraph_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO certigraph_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO certigraph_user;
