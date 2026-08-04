-- ============================================================
-- KAP-APP v2.0 — Migration 08: Fix Admin Count Race Condition
-- ============================================================
--
-- Purpose:
--   Fix a race condition in check_max_admins_trigger where two
--   concurrent transactions could both read v_admin_count < 3
--   and both insert an admin, resulting in 4+ admins per group.
--
-- Root Cause:
--   The trigger function reads the admin count with a plain SELECT,
--   which operates at READ COMMITTED isolation level. Two concurrent
--   transactions can both see v_admin_count < 3 and both proceed,
--   bypassing the 3-admin limit.
--
-- Solution:
--   Inject pg_advisory_xact_lock(hashtext(NEW.group_id::text)) at
--   the start of the trigger function. This serializes concurrent
--   operations on the SAME group without introducing a global lock.
--
--   Why hashtext(NEW.group_id::text)?
--     - hashtext converts the UUID group_id into a bigint hash
--       suitable for pg_advisory_xact_lock's single-argument form.
--     - Different groups have different hash values → operations
--       on different groups proceed in parallel (no global lock).
--     - Same group always produces the same hash → operations on
--       the same group are serialized correctly.
--     - Advisory locks are automatically released at transaction
--       commit/rollback (xact = transactional) → no manual cleanup.
--
-- ============================================================

-- ============================================================
-- STEP 1: Recreate check_max_admins_trigger with advisory lock
-- ============================================================
CREATE OR REPLACE FUNCTION public.check_max_admins_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_admin_count int;
    v_lock_key bigint;
BEGIN
    -- ============================================================
    -- Advisory Lock: Serialize admin count checks per group
    -- ============================================================
    -- Compute a deterministic lock key from group_id using hashtext.
    -- This ensures:
    --   - Same group_id → same lock key → serialized execution
    --   - Different group_id → different lock key → parallel execution
    --   - Lock is automatically released at transaction end
    -- ============================================================
    v_lock_key := hashtext(NEW.group_id::text);
    PERFORM pg_advisory_xact_lock(v_lock_key);

    -- Check only if inserting an admin or updating a non-admin to admin
    IF NEW.role = 'admin' AND (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.role <> 'admin')) THEN
        SELECT COUNT(*)
        INTO v_admin_count
        FROM public.group_members
        WHERE group_id = NEW.group_id AND role = 'admin';

        IF v_admin_count >= 3 THEN
            RAISE EXCEPTION 'A group cannot have more than 3 administrators';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

-- ============================================================
-- STEP 2: Recreate trigger to pick up updated function
-- ============================================================
-- No change to the trigger definition itself — just recreating it
-- to ensure it references the latest function body.
DROP TRIGGER IF EXISTS trg_check_max_admins ON public.group_members;

CREATE TRIGGER trg_check_max_admins
BEFORE INSERT OR UPDATE ON public.group_members
FOR EACH ROW
EXECUTE FUNCTION public.check_max_admins_trigger();
