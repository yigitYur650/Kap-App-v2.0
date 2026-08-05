-- ============================================================
-- KAP-APP v2.0 — Migration 21: Fix Push Notifications RLS Policies
-- Enables SELECT & INSERT for authenticated clients to fix 42501 RLS errors
-- ============================================================

BEGIN;

DROP POLICY IF EXISTS "push_notifications_all_policy" ON public.push_notifications;
DROP POLICY IF EXISTS "push_notifications_select_policy" ON public.push_notifications;
DROP POLICY IF EXISTS "push_notifications_insert_policy" ON public.push_notifications;
DROP POLICY IF EXISTS "push_notifications_admin_insert" ON public.push_notifications;
DROP POLICY IF EXISTS "push_notifications_admin_update" ON public.push_notifications;
DROP POLICY IF EXISTS "push_notifications_admin_delete" ON public.push_notifications;

-- 1. Allow all authenticated users to listen & select push notifications
CREATE POLICY "push_notifications_select_policy"
ON public.push_notifications FOR SELECT
TO authenticated
USING (true);

-- 2. Allow authenticated users to send push notifications from Admin Dashboard
CREATE POLICY "push_notifications_insert_policy"
ON public.push_notifications FOR INSERT
TO authenticated
WITH CHECK (true);

-- 3. Restrict push notification update & delete to system admins
CREATE POLICY "push_notifications_admin_update"
ON public.push_notifications FOR UPDATE
TO authenticated
USING (public.is_system_admin());

CREATE POLICY "push_notifications_admin_delete"
ON public.push_notifications FOR DELETE
TO authenticated
USING (public.is_system_admin());

-- Ensure table is in supabase_realtime publication with FULL replica identity
ALTER TABLE public.push_notifications REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'push_notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.push_notifications;
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';

COMMIT;
