-- ============================================================
-- KAP-APP v2.0 — Migration 01: Base Infrastructure
-- ============================================================

-- 1. Security Audit Log Table
CREATE TABLE public.security_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name text NOT NULL,
    operation text NOT NULL,
    old_data jsonb,
    new_data jsonb,
    performed_by uuid,
    performed_at timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS on security_logs
ALTER TABLE public.security_logs ENABLE ROW LEVEL SECURITY;

-- Note: No policies are created for security_logs, resulting in complete isolation.
-- Direct API SELECT/INSERT/UPDATE/DELETE actions are fully blocked for all public/authenticated roles.


-- 2. Users Table
CREATE TABLE public.users (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name text NOT NULL,
    unique_code text UNIQUE NOT NULL,
    email text UNIQUE NOT NULL,
    email_verified boolean NOT NULL DEFAULT false,
    is_invitable boolean NOT NULL DEFAULT true,
    account_status text NOT NULL DEFAULT 'active',
    created_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz,
    CONSTRAINT chk_account_status CHECK (account_status IN ('active', 'suspended', 'deleted'))
);

-- Enable RLS on users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Allow authenticated insert"
ON public.users FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow users to update own profile"
ON public.users FOR UPDATE
TO authenticated
USING (id = auth.uid() AND deleted_at IS NULL)
WITH CHECK (id = auth.uid() AND deleted_at IS NULL);

CREATE POLICY "Allow users to read own profile"
ON public.users FOR SELECT
TO authenticated
USING (id = auth.uid());

CREATE POLICY "Allow authenticated SELECT on active users"
ON public.users FOR SELECT
TO authenticated
USING (deleted_at IS NULL);


-- 3. Performance Partial Index
CREATE INDEX idx_users_lookup
ON public.users (is_invitable, account_status, id)
WHERE is_invitable = true AND account_status = 'active' AND deleted_at IS NULL;


-- 4. Base Global Helper Functions (Security Hardened)
CREATE OR REPLACE FUNCTION public.is_group_member(p_group_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
    -- Stub implementation for Packet 1 (returns false since group_members does not exist yet)
    RETURN false;
END;
$$;

CREATE OR REPLACE FUNCTION public.is_group_admin(p_group_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
    -- Stub implementation for Packet 1 (returns false since group_members does not exist yet)
    RETURN false;
END;
$$;
