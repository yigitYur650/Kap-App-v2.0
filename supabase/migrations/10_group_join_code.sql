-- ============================================================
-- KAP-APP v2.0 — Migration 10: Group Join Codes
-- ============================================================
--
-- Purpose:
--   Replace user-based group joining (joinGroup uses user.unique_code
--   to find the group owner, then joins the owner's latest group) with
--   group-based joining (each group has its own join_code).
--
--   This fixes the bug where a user with multiple groups (e.g., "House 1"
--   and "Community 1") has only one unique_code, so the wrong group is
--   joined.
--
-- Changes:
--   1. Add `join_code` column to `public.groups` (UNIQUE, nullable).
--   2. Backfill existing groups with a generated join_code using
--      encode(gen_random_bytes(6), 'hex') → 12-char hex string.
--   3. Create a partial unique index so soft-deleted groups don't
--      block reuse.
--   4. Add NOT NULL constraint after backfill (new groups always have
--      a join_code).
-- ============================================================

-- Step 1: Add join_code column (nullable initially for backfill)
ALTER TABLE public.groups
ADD COLUMN IF NOT EXISTS join_code text;

-- Step 2: Backfill existing groups (non-deleted) with a unique join_code
DO $$
DECLARE
    v_group RECORD;
    v_join_code text;
    v_attempts int;
BEGIN
    FOR v_group IN
        SELECT id FROM public.groups WHERE join_code IS NULL AND deleted_at IS NULL
    LOOP
        v_attempts := 0;
        LOOP
            v_attempts := v_attempts + 1;
            -- Generate a 12-char hex join code (6 random bytes → 12 hex chars)
            v_join_code := encode(gen_random_bytes(6), 'hex');
            
            BEGIN
                UPDATE public.groups
                SET join_code = v_join_code
                WHERE id = v_group.id;
                EXIT; -- Success, exit inner loop
            EXCEPTION WHEN unique_violation THEN
                -- Collision — retry (max 5 attempts)
                IF v_attempts >= 5 THEN
                    RAISE WARNING 'Failed to generate unique join_code for group % after % attempts', v_group.id, v_attempts;
                    EXIT;
                END IF;
            END;
        END LOOP;
    END LOOP;
END $$;

-- Step 3: Add NOT NULL constraint (all new groups must have a join_code)
ALTER TABLE public.groups
ALTER COLUMN join_code SET NOT NULL;

-- Step 4: Partial unique index — ensures unique join_code among active groups
-- and allows join_code reuse after soft delete.
-- NOTE: We do NOT add a standard UNIQUE constraint because that would also
-- cover soft-deleted rows, preventing join_code reuse after deletion.
CREATE UNIQUE INDEX IF NOT EXISTS idx_groups_join_code_active
ON public.groups (join_code)
WHERE deleted_at IS NULL;

-- ============================================================
-- Verification
-- ============================================================
DO $$
DECLARE
    v_null_count int;
    v_duplicate_count int;
BEGIN
    -- Verify no NULL join_codes remain
    SELECT COUNT(*) INTO v_null_count
    FROM public.groups
    WHERE join_code IS NULL;

    IF v_null_count > 0 THEN
        RAISE EXCEPTION 'Backfill failed: % groups still have NULL join_code', v_null_count;
    END IF;

    -- Verify no duplicates among active groups
    SELECT COUNT(*) INTO v_duplicate_count
    FROM (
        SELECT join_code FROM public.groups
        WHERE deleted_at IS NULL
        GROUP BY join_code
        HAVING COUNT(*) > 1
    ) dups;

    IF v_duplicate_count > 0 THEN
        RAISE EXCEPTION 'Duplicate join_code found among active groups';
    END IF;

    RAISE NOTICE 'Migration 10 verified: All groups have unique join_code';
END $$;

