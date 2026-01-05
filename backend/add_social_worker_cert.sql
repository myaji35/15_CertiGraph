-- 사회복지사 1급 자격증 및 시험일정 추가

-- 사회복지사 1급 자격증 추가
INSERT INTO public.certifications (id, name, description, provider) VALUES
    ('d1e1f1a1-4444-4444-4444-444444444444', '사회복지사 1급', '사회복지 분야 국가자격증', '한국산업인력공단')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    provider = EXCLUDED.provider;

-- 2026년 1월 17일 시험일정 추가
INSERT INTO public.exam_dates (certification_id, exam_date, registration_start, registration_end) VALUES
    ('d1e1f1a1-4444-4444-4444-444444444444', '2026-01-17', '2025-11-15', '2025-12-15')
ON CONFLICT DO NOTHING;

-- 확인 쿼리
SELECT
    c.id,
    c.name,
    c.description,
    c.provider,
    ed.exam_date,
    ed.registration_start,
    ed.registration_end
FROM certifications c
LEFT JOIN exam_dates ed ON c.id = ed.certification_id
WHERE c.name LIKE '%사회복지사%'
ORDER BY ed.exam_date;
