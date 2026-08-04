-- ============================================================
-- KAP-APP v2.0 — Migration 12: Fix requests SELECT RLS
-- to filter out requests from soft-deleted groups
-- ============================================================
-- 
-- Problem:
-- "Allow members to read requests" policy checks 
--   is_group_member(group_id) AND (privacy checks) AND deleted_at IS NULL
-- but does NOT check whether the group itself is soft-deleted.
-- After groups.deleted_at is set, members can still see all requests.
--
-- Fix:
-- Add AND EXISTS (SELECT 1 FROM groups WHERE id = group_id AND deleted_at IS NULL)
-- to the SELECT policy.
--
-- Risk:
-- 🟢 Low. Only affects SELECT visibility. No recursion risk because
--    the subquery queries groups table directly (not group_members),
--    so it does NOT call is_group_member() which could cause deadlock.

-- Drop the existing policy
DROP POLICY IF EXISTS "Allow members to read requests" ON public.requests;

-- Recreate with group deleted_at check
CREATE POLICY "Allow members to read requests"
ON public.requests FOR SELECT
TO authenticated
USING (
    public.is_group_member(group_id)
    AND (
        is_private = false
        OR requested_by = auth.uid()
        OR private_to = auth.uid()
    )
    AND deleted_at IS NULL
    AND EXISTS (
        SELECT 1 FROM public.groups g
        WHERE g.id = group_id
          AND g.deleted_at IS NULL
    )
);
