-- ============================================================
-- KAP-APP v2.0 — Migration 14: Complete RLS Reset & Soft-Delete Trigger Fix
-- ============================================================
-- Problem:
-- Multiple leftover RLS policies on `public.requests` (e.g. from earlier setup steps)
-- had restrictive `WITH CHECK` conditions like `requested_by = auth.uid()`, causing
-- PostgREST to return 403 Forbidden when deleting/updating requests created by others
-- or updated by admins.
--
-- Solution:
-- 1. Dynamically find and DROP ALL existing policies on `public.requests`.
-- 2. Re-establish clean, non-conflicting RLS policies for SELECT, INSERT, and UPDATE.
-- 3. Update the SECURITY DEFINER trigger `check_request_update_permissions_trigger()`
--    to handle fine-grained permissions for soft-deletes, status changes, and field edits.

-- Step 1: Dynamically purge ALL existing RLS policies on public.requests
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
        WHERE g.id = group_id AND g.deleted_at IS NULL
    )
);

-- Step 4: Re-create clean INSERT policy
CREATE POLICY "Allow members to insert requests"
ON public.requests FOR INSERT
TO authenticated
WITH CHECK (
    public.is_group_member(group_id)
    AND requested_by = auth.uid()
);

-- Step 5: Re-create clean UPDATE policy (Broad access for group members; trigger handles field security)
CREATE POLICY "Allow members to update requests"
ON public.requests FOR UPDATE
TO authenticated
USING (
    public.is_group_member(group_id)
)
WITH CHECK (
    public.is_group_member(group_id)
);

-- Step 6: Re-create SECURITY DEFINER Trigger Function (Enforces fine-grained rules safely)
CREATE OR REPLACE FUNCTION public.check_request_update_permissions_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_is_admin boolean;
    v_is_member boolean;
    v_group_type text;
BEGIN
    v_is_admin := public.is_group_admin(OLD.group_id);
    v_is_member := public.is_group_member(OLD.group_id);
    SELECT COALESCE(type, 'family') INTO v_group_type FROM public.groups WHERE id = OLD.group_id;

    -- Protect immutable fields on ALL updates
    IF NEW.id <> OLD.id 
       OR NEW.group_id <> OLD.group_id 
       OR NEW.requested_by <> OLD.requested_by 
       OR NEW.created_at <> OLD.created_at 
    THEN
        RAISE EXCEPTION 'Cannot modify id, group_id, requested_by, or created_at fields';
    END IF;

    -- Case 1: Soft Delete (setting deleted_at)
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
        -- Owner, Admin, or Family group member can soft-delete
        IF OLD.requested_by = auth.uid() OR v_is_admin OR (v_group_type = 'family' AND v_is_member) THEN
            RETURN NEW;
        ELSE
            RAISE EXCEPTION 'Unauthorized to delete this request';
        END IF;
    END IF;

    -- Case 2: Owner updating their own request
    IF OLD.requested_by = auth.uid() THEN
        IF v_group_type = 'community' AND NEW.status IS DISTINCT FROM OLD.status AND NOT v_is_admin THEN
            RAISE EXCEPTION 'Only administrators can change the status of a request in community groups';
        END IF;
        RETURN NEW;
    END IF;

    -- Case 3: Admin updating any request in the group
    IF v_is_admin THEN
        RETURN NEW;
    END IF;

    -- Case 4: Family group member updating status (pending <-> done)
    IF v_group_type = 'family' AND v_is_member THEN
        IF NEW.item_name = OLD.item_name 
           AND NEW.is_private = OLD.is_private 
           AND NEW.private_to IS NOT DISTINCT FROM OLD.private_to
        THEN
            RETURN NEW;
        END IF;
    END IF;

    -- Case 5: Fallback - Default allow for group members if no violations
    IF v_is_member THEN
        RETURN NEW;
    END IF;

    -- Case 6: Unauthorized
    RAISE EXCEPTION 'Unauthorized to update this request';
END;
$$;

DROP TRIGGER IF EXISTS trg_check_request_update_permissions ON public.requests;
CREATE TRIGGER trg_check_request_update_permissions
BEFORE UPDATE ON public.requests
FOR EACH ROW
EXECUTE FUNCTION public.check_request_update_permissions_trigger();
