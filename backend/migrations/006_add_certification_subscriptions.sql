-- Migration: Add certification-based subscriptions
-- Description: 자격증별 구독 시스템 구현

-- 1. subscriptions 테이블 생성
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clerk_user_id TEXT NOT NULL,
    certification_id UUID NOT NULL REFERENCES certifications(id) ON DELETE CASCADE,
    exam_date DATE NOT NULL,
    subscription_start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    subscription_end_date TIMESTAMPTZ NOT NULL,
    payment_key TEXT,
    order_id TEXT,
    amount INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. study_sets 테이블에 certification_id 컬럼 추가
ALTER TABLE study_sets
ADD COLUMN IF NOT EXISTS certification_id UUID REFERENCES certifications(id) ON DELETE SET NULL;

-- 3. 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_cert
ON subscriptions(clerk_user_id, certification_id);

CREATE INDEX IF NOT EXISTS idx_subscriptions_status
ON subscriptions(status);

CREATE INDEX IF NOT EXISTS idx_subscriptions_end_date
ON subscriptions(subscription_end_date);

CREATE INDEX IF NOT EXISTS idx_study_sets_certification
ON study_sets(certification_id);

-- 4. 구독 상태 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_subscription_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.subscription_end_date < NOW() THEN
        NEW.status = 'expired';
    END IF;
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. 트리거 생성
DROP TRIGGER IF EXISTS trigger_update_subscription_status ON subscriptions;
CREATE TRIGGER trigger_update_subscription_status
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_subscription_status();

-- 6. 사용자의 자격증별 구독 확인 함수
CREATE OR REPLACE FUNCTION has_active_subscription(
    p_clerk_user_id TEXT,
    p_certification_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM subscriptions
        WHERE clerk_user_id = p_clerk_user_id
        AND certification_id = p_certification_id
        AND status = 'active'
        AND subscription_end_date >= NOW()
    );
END;
$$ LANGUAGE plpgsql;

-- 7. 사용자의 활성 구독 목록 조회 함수
CREATE OR REPLACE FUNCTION get_user_subscriptions(p_clerk_user_id TEXT)
RETURNS TABLE (
    subscription_id UUID,
    certification_id UUID,
    certification_name TEXT,
    exam_date DATE,
    subscription_end_date TIMESTAMPTZ,
    days_remaining INTEGER,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id,
        s.certification_id,
        c.name,
        s.exam_date,
        s.subscription_end_date,
        EXTRACT(DAY FROM (s.subscription_end_date - NOW()))::INTEGER,
        s.status
    FROM subscriptions s
    JOIN certifications c ON s.certification_id = c.id
    WHERE s.clerk_user_id = p_clerk_user_id
    AND s.status = 'active'
    ORDER BY s.subscription_end_date ASC;
END;
$$ LANGUAGE plpgsql;

-- 8. RLS (Row Level Security) 정책
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 구독만 볼 수 있음
CREATE POLICY subscriptions_select_policy ON subscriptions
    FOR SELECT
    USING (clerk_user_id = current_setting('app.current_user_id', true));

-- 사용자는 자신의 구독만 삽입 가능
CREATE POLICY subscriptions_insert_policy ON subscriptions
    FOR INSERT
    WITH CHECK (clerk_user_id = current_setting('app.current_user_id', true));

-- 9. 샘플 데이터 (테스트용 - 필요시 주석 해제)
-- INSERT INTO subscriptions (clerk_user_id, certification_id, exam_date, subscription_end_date, amount)
-- VALUES (
--     'user_test123',
--     (SELECT id FROM certifications WHERE name LIKE '%사회복지사%' LIMIT 1),
--     '2025-03-08',
--     '2025-03-08',
--     10000
-- );

COMMENT ON TABLE subscriptions IS '사용자 자격증별 구독 정보';
COMMENT ON COLUMN subscriptions.certification_id IS '구독한 자격증 ID';
COMMENT ON COLUMN subscriptions.exam_date IS '선택한 시험 날짜';
COMMENT ON COLUMN subscriptions.subscription_end_date IS '구독 종료일 (시험일과 동일)';
COMMENT ON COLUMN subscriptions.status IS 'active: 활성, expired: 만료, cancelled: 취소';
