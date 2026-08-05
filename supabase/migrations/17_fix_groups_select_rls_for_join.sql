-- ============================================================
-- KAP-APP v2.0 — Migration 17: Fix Groups SELECT RLS Policy for Join Code Lookup
-- ============================================================
-- Goal:
--   Allow authenticated users to SELECT active groups (deleted_at IS NULL).
--   Previously, "Allow members to select groups" required is_group_member(id)
--   or created_by = auth.uid(), which prevented non-members from looking up
--   groups by join_code when attempting to join a group.

-- Drop existing restrictive SELECT policies on public.groups
DROP POLICY IF EXISTS "Allow members to select groups" ON public.groups;
DROP POLICY IF EXISTS "groups: grupları oku" ON public.groups;
DROP POLICY IF EXISTS "Allow authenticated to select active groups" ON public.groups;

-- Create updated permissive SELECT policy allowing authenticated users to lookup active groups
CREATE POLICY "Allow authenticated to select active groups"
ON public.groups FOR SELECT
TO authenticated
USING (deleted_at IS NULL);

-- Notify PostgREST to instantly reload its schema cache
NOTIFY pgrst, 'reload schema';

-- Verification
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'groups' 
          AND policyname = 'Allow authenticated to select active groups' 
          AND schemaname = 'public'
    ) THEN
        RAISE EXCEPTION 'Migration 17 failed: SELECT policy on groups was not created';
    END IF;
    RAISE NOTICE 'Migration 17 verified: Active groups SELECT policy created successfully';
END $$;
