-- ============================================================
-- KAP-APP v2.0 — Migration 18: Permissive & Clean RLS for requests Table
-- ============================================================
-- Goal: Fix "new row violates row-level security policy for table requests"
-- when adding, checking, or updating requests.

-- Purge existing policies on requests table
DROP POLICY IF EXISTS "Allow members to insert requests" ON public.requests;
DROP POLICY IF EXISTS "Allow members to update requests" ON public.requests;
DROP POLICY IF EXISTS "Allow members to read requests" ON public.requests;

-- 1. SELECT Policy: Members can read active requests in their group
CREATE POLICY "Allow members to read requests"
ON public.requests FOR SELECT
TO authenticated
USING (
    public.is_group_member(group_id) 
    AND deleted_at IS NULL
);

-- 2. INSERT Policy: Group members can insert requests
CREATE POLICY "Allow members to insert requests"
ON public.requests FOR INSERT
TO authenticated
WITH CHECK (
    public.is_group_member(group_id) 
    AND requested_by = auth.uid()
);

-- 3. UPDATE Policy: Group members can update request status / details
CREATE POLICY "Allow members to update requests"
ON public.requests FOR UPDATE
TO authenticated
USING (public.is_group_member(group_id))
WITH CHECK (public.is_group_member(group_id));

-- Notify PostgREST to instantly reload schema cache
NOTIFY pgrst, 'reload schema';

-- Verification
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'requests' 
          AND policyname = 'Allow members to update requests' 
          AND schemaname = 'public'
    ) THEN
        RAISE EXCEPTION 'Migration 18 failed: UPDATE policy on requests was not created';
    END IF;
    RAISE NOTICE 'Migration 18 verified successfully!';
END $$;
