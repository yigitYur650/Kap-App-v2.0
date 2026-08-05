-- ============================================================
-- KAP-APP v2.0 — Migration 18: Complete RLS Purge & Soft-Delete Fix for requests Table
-- ============================================================
-- Problem:
-- When soft-deleting a request (`deleted_at = NOW()`), PostgREST checks the SELECT
-- policy on the updated row. If SELECT policy requires `deleted_at IS NULL`, setting
-- `deleted_at = NOW()` causes the updated row to fail SELECT RLS, throwing:
-- "new row violates row-level security policy for table requests".
--
-- Solution:
-- 1. Dynamically purge ALL existing RLS policies on `public.requests` regardless of name.
-- 2. Remove `deleted_at IS NULL` constraint from SELECT RLS policy (client filters soft-deleted).
-- 3. Re-create clean, non-conflicting policies for SELECT, INSERT, UPDATE, DELETE.
-- 4. Notify PostgREST to instantly reload schema cache.

-- Step 1: Dynamically purge ALL policies on public.requests table
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'requests' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.requests;', pol.policyname);
    END LOOP;
END $$;

-- Step 2: Ensure RLS is enabled
ALTER TABLE public.requests ENABLE ROW LEVEL SECURITY;

-- Step 3: Re-create clean SELECT policy (allows members to read, soft-delete filtering done by client/query)
CREATE POLICY "requests_select_policy"
ON public.requests FOR SELECT
TO authenticated
USING (public.is_group_member(group_id));

-- Step 4: Re-create clean INSERT policy
CREATE POLICY "requests_insert_policy"
ON public.requests FOR INSERT
TO authenticated
WITH CHECK (
    public.is_group_member(group_id) 
    AND requested_by = auth.uid()
);

-- Step 5: Re-create clean UPDATE policy (All group members can update status/check boxes/soft-delete)
CREATE POLICY "requests_update_policy"
ON public.requests FOR UPDATE
TO authenticated
USING (public.is_group_member(group_id))
WITH CHECK (public.is_group_member(group_id));

-- Step 6: Re-create clean DELETE policy
CREATE POLICY "requests_delete_policy"
ON public.requests FOR DELETE
TO authenticated
USING (public.is_group_member(group_id));

-- Step 7: Notify PostgREST to instantly reload schema cache
NOTIFY pgrst, 'reload schema';

-- Verification
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'requests' 
          AND policyname = 'requests_update_policy' 
          AND schemaname = 'public'
    ) THEN
        RAISE EXCEPTION 'Migration 18 failed: requests_update_policy was not created';
    END IF;
    RAISE NOTICE 'Migration 18 verified: Soft-delete RLS fix applied successfully!';
END $$;
