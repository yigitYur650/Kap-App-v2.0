-- ============================================================
-- KAP-APP v2.0 — Migration 19: System Admins, App Versions & Push Notifications
-- ============================================================

-- 1. Create system_admins table
CREATE TABLE IF NOT EXISTS public.system_admins (
    user_id uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.system_admins ENABLE ROW LEVEL SECURITY;

-- Security Definer helper function to check if current user is system admin
CREATE OR REPLACE FUNCTION public.is_system_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_catalog
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.system_admins
        WHERE user_id = auth.uid()
    );
$$;

-- RLS for system_admins: Users can check if they themselves are system admins
DROP POLICY IF EXISTS "system_admins_select_policy" ON public.system_admins;
CREATE POLICY "system_admins_select_policy"
ON public.system_admins FOR SELECT
TO authenticated
USING (user_id = auth.uid());


-- 2. Create app_versions table (OTA In-App Auto-Updater)
CREATE TABLE IF NOT EXISTS public.app_versions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    version_code int NOT NULL UNIQUE,
    version_name text NOT NULL,
    apk_url text NOT NULL,
    sha256_hash text,
    changelog text,
    is_mandatory boolean NOT NULL DEFAULT false,
    created_by uuid REFERENCES public.users(id),
    created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

-- RLS for app_versions: All authenticated users can check latest versions
DROP POLICY IF EXISTS "app_versions_select_policy" ON public.app_versions;
CREATE POLICY "app_versions_select_policy"
ON public.app_versions FOR SELECT
TO authenticated
USING (true);

-- Admin mutation policies on app_versions
DROP POLICY IF EXISTS "app_versions_insert_policy" ON public.app_versions;
CREATE POLICY "app_versions_insert_policy"
ON public.app_versions FOR INSERT
TO authenticated
WITH CHECK (public.is_system_admin());

DROP POLICY IF EXISTS "app_versions_update_policy" ON public.app_versions;
CREATE POLICY "app_versions_update_policy"
ON public.app_versions FOR UPDATE
TO authenticated
USING (public.is_system_admin())
WITH CHECK (public.is_system_admin());

DROP POLICY IF EXISTS "app_versions_delete_policy" ON public.app_versions;
CREATE POLICY "app_versions_delete_policy"
ON public.app_versions FOR DELETE
TO authenticated
USING (public.is_system_admin());


-- 3. Create push_notifications table
CREATE TABLE IF NOT EXISTS public.push_notifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    body text NOT NULL,
    scheduled_at timestamptz NOT NULL DEFAULT now(),
    sent_at timestamptz,
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
    created_by uuid REFERENCES public.users(id),
    created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.push_notifications ENABLE ROW LEVEL SECURITY;

-- RLS for push_notifications: Only system admins can access notification logs
DROP POLICY IF EXISTS "push_notifications_all_policy" ON public.push_notifications;
CREATE POLICY "push_notifications_all_policy"
ON public.push_notifications FOR ALL
TO authenticated
USING (public.is_system_admin())
WITH CHECK (public.is_system_admin());


-- 4. Create Public Supabase Storage Bucket for App Releases (Limit set to 500 MB)
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('app-releases', 'app-releases', true, 524288000)
ON CONFLICT (id) DO UPDATE SET file_size_limit = 524288000;

-- Storage Policies for app-releases bucket
DROP POLICY IF EXISTS "app_releases_public_read" ON storage.objects;
CREATE POLICY "app_releases_public_read"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'app-releases');

DROP POLICY IF EXISTS "app_releases_admin_insert" ON storage.objects;
CREATE POLICY "app_releases_admin_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'app-releases' AND public.is_system_admin());

DROP POLICY IF EXISTS "app_releases_admin_delete" ON storage.objects;
CREATE POLICY "app_releases_admin_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'app-releases' AND public.is_system_admin());


-- 5. Notify PostgREST to instantly reload schema cache
NOTIFY pgrst, 'reload schema';

-- Verification
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'app_versions'
    ) THEN
        RAISE EXCEPTION 'Migration 19 failed: app_versions table was not created';
    END IF;
    RAISE NOTICE 'Migration 19 verified: System Admins, App Versions & Storage Bucket created successfully!';
END $$;
