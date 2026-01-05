-- Migration: Add Study Materials Table
-- Purpose: Allow multiple PDF uploads per study set

-- Study Materials Table (학습자료)
-- Each material is a PDF uploaded to a study set
CREATE TABLE IF NOT EXISTS public.study_materials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    study_set_id UUID NOT NULL REFERENCES public.study_sets(id) ON DELETE CASCADE,
    clerk_id TEXT NOT NULL REFERENCES public.user_profiles(clerk_id) ON DELETE CASCADE,

    -- File information
    title TEXT NOT NULL,
    pdf_url TEXT NOT NULL,
    pdf_hash TEXT,  -- For deduplication
    file_size_bytes BIGINT,

    -- Processing status
    status TEXT DEFAULT 'uploaded',  -- uploaded, processing, completed, failed
    total_questions INTEGER DEFAULT 0,
    processing_progress INTEGER DEFAULT 0,
    processing_error TEXT,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_study_materials_study_set ON public.study_materials(study_set_id);
CREATE INDEX IF NOT EXISTS idx_study_materials_clerk_id ON public.study_materials(clerk_id);
CREATE INDEX IF NOT EXISTS idx_study_materials_status ON public.study_materials(status);

-- Update Study Sets Table
-- Remove pdf_url since materials are now in separate table
-- Add exam_date_id for easier querying
ALTER TABLE public.study_sets
    ADD COLUMN IF NOT EXISTS exam_date_id UUID REFERENCES public.exam_dates(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS total_materials INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_questions INTEGER DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_study_sets_exam_date ON public.study_sets(exam_date_id);

-- Row Level Security for Study Materials
ALTER TABLE public.study_materials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own study materials" ON public.study_materials
    FOR SELECT USING (clerk_id = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "Users can insert own study materials" ON public.study_materials
    FOR INSERT WITH CHECK (clerk_id = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "Users can update own study materials" ON public.study_materials
    FOR UPDATE USING (clerk_id = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "Users can delete own study materials" ON public.study_materials
    FOR DELETE USING (clerk_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Function to update study set totals when materials change
CREATE OR REPLACE FUNCTION update_study_set_totals()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.study_sets
    SET
        total_materials = (
            SELECT COUNT(*)
            FROM public.study_materials
            WHERE study_set_id = COALESCE(NEW.study_set_id, OLD.study_set_id)
        ),
        total_questions = (
            SELECT COALESCE(SUM(total_questions), 0)
            FROM public.study_materials
            WHERE study_set_id = COALESCE(NEW.study_set_id, OLD.study_set_id)
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.study_set_id, OLD.study_set_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update study set totals
DROP TRIGGER IF EXISTS trigger_update_study_set_totals ON public.study_materials;
CREATE TRIGGER trigger_update_study_set_totals
    AFTER INSERT OR UPDATE OR DELETE ON public.study_materials
    FOR EACH ROW
    EXECUTE FUNCTION update_study_set_totals();

COMMENT ON TABLE public.study_materials IS '학습자료 - 문제집에 업로드된 PDF 파일들';
COMMENT ON TABLE public.study_sets IS '문제집 - 여러 학습자료(PDF)를 담는 컨테이너';
COMMENT ON COLUMN public.study_sets.title IS '문제집명 (예: 2024년 대비)';
COMMENT ON COLUMN public.study_materials.title IS '학습자료명 (예: 1회 기출문제)';
