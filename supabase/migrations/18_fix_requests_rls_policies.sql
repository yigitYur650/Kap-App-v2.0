-- ============================================================
-- KAP-APP v2.0 — Migration 18: Complete RLS Purge & Reset for requests Table
-- ============================================================
-- Problem:
-- Legacy or duplicate RLS policies on `public.requests` (e.g. with `requested_by = auth.uid()`
-- in WITH CHECK) caused PostgreSQL to reject updates on requests created by other group members,
-- throwing: "new row violates row-level security policy for table requests".
--
-- Solution:
-- 1. Dynamically purge ALL existing RLS policies on `public.requests` regardless of name.
-- 2. Re-create clean, non-conflicting policies for SELECT, INSERT, UPDATE, DELETE.
-- 3. Notify PostgREST to instantly reload schema cache.

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

-- Step 3: Re-create clean SELECT policy
CREATE POLICY "requests_select_policy"
ON public.requests FOR SELECT
TO authenticated
USING (
    public.is_group_member(group_id) 
    AND deleted_at IS NULL
);

-- Step 4: Re-create clean INSERT policy
CREATE POLICY "requests_insert_policy"
ON public.requests FOR INSERT
TO authenticated
WITH CHECK (
    public.is_group_member(group_id) 
    AND requested_by = auth.uid()
);

-- Step 5: Re-create clean UPDATE policy (All group members can update status/check boxes)
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
    RAISE NOTICE 'Migration 18 verified: ALL legacy policies purged and clean RLS policies applied!';
END $$;
