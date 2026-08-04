-- ============================================================
-- KAP-APP v2.0 — Migration 09: Requests Schema Expansion
--               & Inventory Trigger Casing Fix
-- ============================================================
--
-- Purpose:
--   1. (DB-C6) Add quantity, unit, category columns to the
--      public.requests table. These are nullable text columns
--      supporting the UI design which includes fields for
--      BIRIM/TIP and MIKTAR.
--
--   2. (DB-C7) Fix the create_request_on_empty_inventory_trigger
--      function to normalize item_name using LOWER(TRIM(...))
--      when auto-creating shopping requests. This prevents
--      casing inconsistency between inventory items and their
--      corresponding shopping requests.
--
-- Risk Mitigation:
--   - ALTER TABLE ... ADD COLUMN does NOT drop or modify any
--     existing RLS policies. All existing SELECT/INSERT/UPDATE
--     policies on public.requests remain fully intact.
--   - The trigger function is recreated using CREATE OR REPLACE,
--     which preserves the existing trigger binding.
--   - No data is migrated or transformed — new columns are
--     added as nullable with no default value.
-- ============================================================


-- ============================================================
-- PART 1 (DB-C6): Add quantity, unit, category columns
-- ============================================================
-- These columns are nullable and have no default value to
-- maintain backward compatibility with existing requests.
-- The UI will populate them for new requests going forward.
ALTER TABLE public.requests
  ADD COLUMN IF NOT EXISTS quantity text,
  ADD COLUMN IF NOT EXISTS unit text,
  ADD COLUMN IF NOT EXISTS category text;

-- Verify columns were added (optional, informational only)
DO $$
BEGIN
    ASSERT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'requests'
          AND column_name = 'quantity'
    ), 'Column quantity was not added to public.requests';

    ASSERT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'requests'
          AND column_name = 'unit'
    ), 'Column unit was not added to public.requests';

    ASSERT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'requests'
          AND column_name = 'category'
    ), 'Column category was not added to public.requests';
END $$;


-- ============================================================
-- PART 2 (DB-C7): Fix casing in inventory empty trigger
-- ============================================================
-- Problem: When an inventory item transitions to 'yok', the
-- trigger function copies NEW.item_name directly into the
-- requests table. But inventory items may have mixed casing
-- (e.g., "Milk", "MILK", "milk") while the Flutter client
-- normalizes to lowercase. This creates display inconsistency.
--
-- Fix: Apply LOWER(TRIM(NEW.item_name)) when inserting the
-- auto-created shopping request. The partial unique index
-- idx_unique_pending_item_per_group already uses LOWER(item_name),
-- so this also makes the ON CONFLICT matching more consistent.
--
-- The trigger binding (trg_inventory_request_on_empty) is
-- recreated to ensure it tracks the updated function signature.
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_request_on_empty_inventory_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_requested_by uuid;
    v_normalized_item_name text;
BEGIN
    -- Only trigger when status transitions to 'yok'
    IF NEW.status = 'yok' AND (OLD.status IS DISTINCT FROM 'yok' OR OLD.status IS NULL) THEN
        v_requested_by := NEW.last_updated_by;

        -- Fallback: If last_updated_by is null (e.g. system update), find oldest member in the group
        IF v_requested_by IS NULL THEN
            SELECT user_id
            INTO v_requested_by
            FROM public.group_members
            WHERE group_id = NEW.group_id
            ORDER BY joined_at ASC, user_id ASC
            LIMIT 1;
        END IF;

        -- Normalize item_name: lowercase + trim whitespace
        -- This ensures casing consistency with the Flutter client
        -- and matches the partial unique index expression.
        v_normalized_item_name := LOWER(TRIM(NEW.item_name));

        -- If a valid user is found, attempt to insert a shopping request
        -- Uses targeted ON CONFLICT matching the exact partial unique index to avoid duplication errors
        IF v_requested_by IS NOT NULL THEN
            INSERT INTO public.requests (group_id, requested_by, item_name, is_private, status)
            VALUES (NEW.group_id, v_requested_by, v_normalized_item_name, false, 'pending')
            ON CONFLICT (group_id, LOWER(item_name))
            WHERE status = 'pending' AND deleted_at IS NULL AND is_private = false
            DO NOTHING;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

-- Recreate the trigger to ensure it picks up the updated function body
DROP TRIGGER IF EXISTS trg_inventory_request_on_empty ON public.inventory;
CREATE TRIGGER trg_inventory_request_on_empty
AFTER UPDATE ON public.inventory
FOR EACH ROW
EXECUTE FUNCTION public.create_request_on_empty_inventory_trigger();


-- ============================================================
-- VERIFICATION QUERIES (run manually after migration)
-- ============================================================
--
-- 1. Verify new columns exist:
--    SELECT column_name, data_type, is_nullable
--    FROM information_schema.columns
--    WHERE table_schema = 'public'
--      AND table_name = 'requests'
--      AND column_name IN ('quantity', 'unit', 'category');
--
-- 2. Verify RLS policies are intact:
--    SELECT schemaname, tablename, policyname, permissive, cmd
--    FROM pg_policies
--    WHERE tablename = 'requests'
--    ORDER BY policyname;
--    Expected: 3 policies (Allow members to read/insert, Allow updates)
--
-- 3. Test trigger casing:
--    -- Simulate inventory update
--    UPDATE public.inventory
--    SET status = 'yok'
--    WHERE item_name = 'Milk' AND group_id = '<group_id>';
--    -- Then check: SELECT item_name FROM public.requests
--    -- WHERE group_id = '<group_id>' ORDER BY created_at DESC LIMIT 1;
--    -- Expected: 'milk' (lowercase, not 'Milk')
