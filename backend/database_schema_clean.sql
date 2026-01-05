-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User Profiles Table
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clerk_id TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_profiles_clerk_id ON public.user_profiles(clerk_id);

-- Certifications Table
CREATE TABLE IF NOT EXISTS public.certifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    provider TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Exam Dates Table
CREATE TABLE IF NOT EXISTS public.exam_dates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certification_id UUID REFERENCES public.certifications(id) ON DELETE CASCADE,
    exam_date DATE NOT NULL,
    registration_start DATE,
    registration_end DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_exam_dates_certification ON public.exam_dates(certification_id);

-- Subscriptions Table
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clerk_id TEXT NOT NULL REFERENCES public.user_profiles(clerk_id) ON DELETE CASCADE,
    certification_id UUID REFERENCES public.certifications(id) ON DELETE CASCADE,
    exam_date_id UUID REFERENCES public.exam_dates(id) ON DELETE CASCADE,
    payment_amount INTEGER DEFAULT 0,
    payment_method TEXT,
    payment_status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_clerk_id ON public.subscriptions(clerk_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_certification ON public.subscriptions(certification_id);

-- Study Sets Table
CREATE TABLE IF NOT EXISTS public.study_sets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clerk_id TEXT NOT NULL REFERENCES public.user_profiles(clerk_id) ON DELETE CASCADE,
    certification_id UUID REFERENCES public.certifications(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    pdf_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_study_sets_clerk_id ON public.study_sets(clerk_id);

-- Enable Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.certifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_dates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_sets ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (clerk_id = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "Certifications are viewable by everyone" ON public.certifications
    FOR SELECT USING (true);

CREATE POLICY "Exam dates are viewable by everyone" ON public.exam_dates
    FOR SELECT USING (true);

CREATE POLICY "Users can view own subscriptions" ON public.subscriptions
    FOR SELECT USING (clerk_id = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "Users can view own study sets" ON public.study_sets
    FOR SELECT USING (clerk_id = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "Users can insert own study sets" ON public.study_sets
    FOR INSERT WITH CHECK (clerk_id = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "Users can update own study sets" ON public.study_sets
    FOR UPDATE USING (clerk_id = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "Users can delete own study sets" ON public.study_sets
    FOR DELETE USING (clerk_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Sample Data
INSERT INTO public.certifications (id, name, description, provider) VALUES
    ('d1e1f1a1-1111-1111-1111-111111111111', '정보처리기사', 'IT 분야 국가기술자격증', '한국산업인력공단'),
    ('d1e1f1a1-2222-2222-2222-222222222222', 'SQLD', 'SQL 개발자 자격증', '한국데이터산업진흥원'),
    ('d1e1f1a1-3333-3333-3333-333333333333', 'AWS Solutions Architect', 'AWS 클라우드 아키텍트 자격증', 'Amazon Web Services')
ON CONFLICT DO NOTHING;

INSERT INTO public.exam_dates (certification_id, exam_date, registration_start, registration_end) VALUES
    ('d1e1f1a1-1111-1111-1111-111111111111', '2025-03-09', '2025-01-15', '2025-02-15'),
    ('d1e1f1a1-1111-1111-1111-111111111111', '2025-06-15', '2025-04-15', '2025-05-15'),
    ('d1e1f1a1-2222-2222-2222-222222222222', '2025-04-20', '2025-02-20', '2025-03-20'),
    ('d1e1f1a1-3333-3333-3333-333333333333', '2025-05-10', '2025-03-10', '2025-04-10')
ON CONFLICT DO NOTHING;
