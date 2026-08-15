-- ============================================================
-- KAP-APP v2.0 — Migration 30: Security Hardening & Privacy Fixes
-- ============================================================

-- 1. Restrict product_price_pool RLS policies (Remove FOR ALL policy to prevent bulk DELETE)
DROP POLICY IF EXISTS "Allow authenticated write price pool" ON public.product_price_pool;

CREATE POLICY "Allow authenticated insert price pool"
ON public.product_price_pool FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow authenticated update price pool"
ON public.product_price_pool FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- 2. Personal Health Profiles Privacy Hardening (GDPR / KVKK Compliance)
-- Change default privacy setting to private (is_public = false)
ALTER TABLE public.health_profiles 
ALTER COLUMN is_public SET DEFAULT false;

-- Add DELETE policy to allow users to erase their own health profile data (Right to Erasure)
DROP POLICY IF EXISTS "Users can delete own health profile" ON public.health_profiles;
CREATE POLICY "Users can delete own health profile"
ON public.health_profiles FOR DELETE
TO authenticated
USING (auth.uid() = user_id);
