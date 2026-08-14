-- Migration 29: AI Usage Quota, Subscriptions, RevenueCat Webhook & Referral Infrastructure

-- 1. Table: user_ai_usage
CREATE TABLE IF NOT EXISTS public.user_ai_usage (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    is_pro BOOLEAN NOT NULL DEFAULT false,
    free_daily_limit INT NOT NULL DEFAULT 2,
    bonus_credits INT NOT NULL DEFAULT 0,
    used_count_today INT NOT NULL DEFAULT 0,
    last_reset_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Table: user_subscriptions
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'free', -- 'active', 'expired', 'cancelled', 'trial', 'free'
    store VARCHAR(30) NOT NULL DEFAULT 'none', -- 'app_store', 'play_store', 'manual', 'referral'
    product_id VARCHAR(100) DEFAULT '',
    original_transaction_id VARCHAR(100) DEFAULT '',
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Table: referral_codes
CREATE TABLE IF NOT EXISTS public.referral_codes (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    code VARCHAR(20) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Table: referral_logs
CREATE TABLE IF NOT EXISTS public.referral_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    referred_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reward_claimed BOOLEAN NOT NULL DEFAULT false,
    reward_type VARCHAR(50) NOT NULL DEFAULT 'pro_7_days',
    device_hash VARCHAR(128) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Table: processed_webhook_events
CREATE TABLE IF NOT EXISTS public.processed_webhook_events (
    event_id VARCHAR(128) PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_status ON public.user_subscriptions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_referral_codes_code ON public.referral_codes(code);
CREATE INDEX IF NOT EXISTS idx_referral_logs_device_hash ON public.referral_logs(device_hash);
CREATE INDEX IF NOT EXISTS idx_referral_logs_referred_id ON public.referral_logs(referred_id);

-- Enable RLS
ALTER TABLE public.user_ai_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.processed_webhook_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can read own ai usage" ON public.user_ai_usage;
CREATE POLICY "Users can read own ai usage" ON public.user_ai_usage
    FOR SELECT TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can read own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can read own subscriptions" ON public.user_subscriptions
    FOR SELECT TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can read referral codes" ON public.referral_codes;
CREATE POLICY "Users can read referral codes" ON public.referral_codes
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Users can read own referral logs" ON public.referral_logs;
CREATE POLICY "Users can read own referral logs" ON public.referral_logs
    FOR SELECT TO authenticated USING (auth.uid() = referrer_id OR auth.uid() = referred_id);

-- Service Role full access policies (for backend Go service)
DROP POLICY IF EXISTS "Service role full access on user_ai_usage" ON public.user_ai_usage;
CREATE POLICY "Service role full access on user_ai_usage" ON public.user_ai_usage
    FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access on user_subscriptions" ON public.user_subscriptions;
CREATE POLICY "Service role full access on user_subscriptions" ON public.user_subscriptions
    FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access on referral_codes" ON public.referral_codes;
CREATE POLICY "Service role full access on referral_codes" ON public.referral_codes
    FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access on referral_logs" ON public.referral_logs;
CREATE POLICY "Service role full access on referral_logs" ON public.referral_logs
    FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access on processed_webhook_events" ON public.processed_webhook_events;
CREATE POLICY "Service role full access on processed_webhook_events" ON public.processed_webhook_events
    FOR ALL TO service_role USING (true) WITH CHECK (true);


-- ============================================================
-- Atomic Function: consume_ai_credit
-- ============================================================
CREATE OR REPLACE FUNCTION public.consume_ai_credit(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_usage RECORD;
    v_remaining INT;
    v_is_pro BOOLEAN;
BEGIN
    -- 1. Lock row FOR UPDATE or INSERT default row if missing
    SELECT * INTO v_usage
    FROM public.user_ai_usage
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        INSERT INTO public.user_ai_usage (user_id, is_pro, free_daily_limit, bonus_credits, used_count_today, last_reset_date)
        VALUES (p_user_id, false, 2, 0, 0, CURRENT_DATE)
        ON CONFLICT (user_id) DO NOTHING;

        SELECT * INTO v_usage
        FROM public.user_ai_usage
        WHERE user_id = p_user_id
        FOR UPDATE;
    END IF;

    -- 2. Daily reset check
    IF v_usage.last_reset_date < CURRENT_DATE THEN
        UPDATE public.user_ai_usage
        SET used_count_today = 0,
            last_reset_date = CURRENT_DATE,
            updated_at = NOW()
        WHERE user_id = p_user_id;

        v_usage.used_count_today := 0;
        v_usage.last_reset_date := CURRENT_DATE;
    END IF;

    v_is_pro := v_usage.is_pro;

    -- 3. Pro user logic (Unlimited usage)
    IF v_is_pro THEN
        UPDATE public.user_ai_usage
        SET used_count_today = used_count_today + 1,
            updated_at = NOW()
        WHERE user_id = p_user_id;

        RETURN jsonb_build_object(
            'success', true,
            'is_pro', true,
            'remaining_credits', 999999,
            'reason', 'pro_unlimited'
        );
    END IF;

    -- 4. Free user logic
    IF v_usage.used_count_today < v_usage.free_daily_limit THEN
        UPDATE public.user_ai_usage
        SET used_count_today = used_count_today + 1,
            updated_at = NOW()
        WHERE user_id = p_user_id;

        v_remaining := (v_usage.free_daily_limit - (v_usage.used_count_today + 1)) + v_usage.bonus_credits;

        RETURN jsonb_build_object(
            'success', true,
            'is_pro', false,
            'remaining_credits', v_remaining,
            'reason', 'daily_free'
        );
    ELSIF v_usage.bonus_credits > 0 THEN
        UPDATE public.user_ai_usage
        SET bonus_credits = bonus_credits - 1,
            updated_at = NOW()
        WHERE user_id = p_user_id;

        v_remaining := v_usage.bonus_credits - 1;

        RETURN jsonb_build_object(
            'success', true,
            'is_pro', false,
            'remaining_credits', v_remaining,
            'reason', 'bonus_credit'
        );
    ELSE
        RETURN jsonb_build_object(
            'success', false,
            'is_pro', false,
            'remaining_credits', 0,
            'reason', 'quota_exceeded'
        );
    END IF;
END;
$$;


-- ============================================================
-- Atomic Function: claim_referral_reward
-- ============================================================
CREATE OR REPLACE FUNCTION public.claim_referral_reward(
    p_referrer_code TEXT,
    p_new_user_id UUID,
    p_device_hash TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_referrer_id UUID;
    v_clean_code TEXT;
BEGIN
    v_clean_code := UPPER(TRIM(p_referrer_code));

    -- 1. Verify code exists
    SELECT user_id INTO v_referrer_id
    FROM public.referral_codes
    WHERE code = v_clean_code;

    IF v_referrer_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'reason', 'invalid_code');
    END IF;

    -- 2. Anti-Self-Referral Check
    IF v_referrer_id = p_new_user_id THEN
        RETURN jsonb_build_object('success', false, 'reason', 'self_referral_not_allowed');
    END IF;

    -- 3. Check if referred user already claimed a referral
    IF EXISTS (SELECT 1 FROM public.referral_logs WHERE referred_id = p_new_user_id) THEN
        RETURN jsonb_build_object('success', false, 'reason', 'already_claimed');
    END IF;

    -- 4. Device Fingerprinting Anti-Fraud Check
    IF EXISTS (SELECT 1 FROM public.referral_logs WHERE device_hash = p_device_hash) THEN
        RETURN jsonb_build_object('success', false, 'reason', 'device_already_used');
    END IF;

    -- 5. Record Referral
    INSERT INTO public.referral_logs (referrer_id, referred_id, reward_claimed, reward_type, device_hash)
    VALUES (v_referrer_id, p_new_user_id, true, 'pro_7_days', p_device_hash);

    -- 6. Grant Rewards (+7 days Pro or +10 bonus credits)
    -- Referrer: grant 7 days pro subscription
    INSERT INTO public.user_subscriptions (user_id, status, store, product_id, expires_at)
    VALUES (v_referrer_id, 'active', 'referral', 'pro_7_days_reward', NOW() + INTERVAL '7 days');

    -- Referrer: update user_ai_usage to is_pro = true
    INSERT INTO public.user_ai_usage (user_id, is_pro, free_daily_limit, bonus_credits)
    VALUES (v_referrer_id, true, 2, 10)
    ON CONFLICT (user_id) DO UPDATE SET is_pro = true, bonus_credits = public.user_ai_usage.bonus_credits + 10;

    -- New User: grant 7 days pro subscription
    INSERT INTO public.user_subscriptions (user_id, status, store, product_id, expires_at)
    VALUES (p_new_user_id, 'active', 'referral', 'pro_7_days_reward', NOW() + INTERVAL '7 days');

    -- New User: update user_ai_usage to is_pro = true
    INSERT INTO public.user_ai_usage (user_id, is_pro, free_daily_limit, bonus_credits)
    VALUES (p_new_user_id, true, 2, 10)
    ON CONFLICT (user_id) DO UPDATE SET is_pro = true, bonus_credits = public.user_ai_usage.bonus_credits + 10;

    RETURN jsonb_build_object('success', true, 'reason', 'reward_granted');
END;
$$;


-- ============================================================
-- Helper Function & Trigger: Auto-generate referral code for new users
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_or_create_referral_code(p_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_code TEXT;
BEGIN
    SELECT code INTO v_code
    FROM public.referral_codes
    WHERE user_id = p_user_id;

    IF v_code IS NULL THEN
        -- Generate KAP- + 6 random alphanumeric chars
        v_code := 'KAP-' || UPPER(SUBSTRING(MD5(p_user_id::text || NOW()::text) FROM 1 FOR 6));
        INSERT INTO public.referral_codes (user_id, code)
        VALUES (p_user_id, v_code)
        ON CONFLICT (user_id) DO NOTHING;

        SELECT code INTO v_code FROM public.referral_codes WHERE user_id = p_user_id;
    END IF;

    RETURN v_code;
END;
$$;
