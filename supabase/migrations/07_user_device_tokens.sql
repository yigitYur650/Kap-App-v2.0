-- ============================================================
-- KAP-APP v2.0 — Migration 07: User Device Tokens
--               Push Notification Token Storage
-- ============================================================
--
-- Purpose:
--   Create a secure table to store FCM/APNs device tokens
--   per user, enabling push notification delivery.
--
-- Requirements:
--   - Each user can have multiple device tokens (phone + tablet).
--   - RLS ensures users can ONLY read/insert/update their own tokens.
--   - ON DELETE CASCADE from auth.users for clean user deletion.
--   - Explicit index on user_id for performant lookups.
--
-- ============================================================

-- ============================================================
-- STEP 1: Create user_device_tokens table
-- ============================================================
CREATE TABLE public.user_device_tokens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_token text NOT NULL,
    platform text NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    -- Prevent duplicate tokens (same device re-registering)
    CONSTRAINT uq_device_token UNIQUE (device_token),

    -- Validate platform values
    CONSTRAINT chk_device_token_platform CHECK (platform IN ('ios', 'android', 'web'))
);

-- ============================================================
-- STEP 2: Add performance index on user_id
-- ============================================================
-- Why: All queries filter by user_id (fetch all tokens for a user).
-- Without this index, every query would seq-scan the entire table
-- as it grows. This B-tree index makes lookups O(log n).
CREATE INDEX idx_user_device_tokens_user_id
    ON public.user_device_tokens (user_id);

-- ============================================================
-- STEP 3: Enable Row-Level Security
-- ============================================================
ALTER TABLE public.user_device_tokens ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 4: RLS Policies — Strict User Isolation
-- ============================================================

-- Policy: Users can only SELECT their own device tokens
-- Prevents any cross-user token leakage (privacy requirement).
CREATE POLICY "Users can read their own device tokens"
ON public.user_device_tokens FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy: Users can only INSERT their own device tokens
-- Prevents a malicious actor from registering a token under another user's ID.
CREATE POLICY "Users can insert their own device tokens"
ON public.user_device_tokens FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only UPDATE their own device tokens
-- Allows users to toggle is_active (e.g., on logout) or update platform info.
CREATE POLICY "Users can update their own device tokens"
ON public.user_device_tokens FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only DELETE their own device tokens
-- Allows users to clean up old tokens on logout or device removal.
CREATE POLICY "Users can delete their own device tokens"
ON public.user_device_tokens FOR DELETE
TO authenticated
USING (auth.uid() = user_id);
