-- ============================================================
-- KAP-APP v2.0 — Migration 11: Fix Request Status Update Permissions
-- ============================================================

DROP TRIGGER IF EXISTS trg_check_request_update_permissions ON public.requests;
DROP FUNCTION IF EXISTS public.check_request_update_permissions_trigger() CASCADE;

CREATE OR REPLACE FUNCTION public.check_request_update_permissions_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_is_admin boolean;
    v_group_type text;
BEGIN
    v_is_admin := public.is_group_admin(OLD.group_id);
    v_group_type := (SELECT type FROM public.groups WHERE id = OLD.group_id);

    -- Case 1: Owner editing their own request (only permitted when OLD.status is 'pending')
    IF OLD.requested_by = auth.uid() AND OLD.status = 'pending' THEN
        
        -- In 'community' groups, only admins can change the status field
        IF v_group_type = 'community' AND NEW.status IS DISTINCT FROM OLD.status AND NOT v_is_admin THEN
            RAISE EXCEPTION 'Only administrators can change the status of a request in community groups';
        END IF;

        -- Protect immutable fields
        IF NEW.group_id <> OLD.group_id OR NEW.requested_by <> OLD.requested_by OR NEW.created_at <> OLD.created_at THEN
            RAISE EXCEPTION 'Cannot modify group_id, requested_by, or created_at fields';
        END IF;

        RETURN NEW;
    END IF;

    -- Case 2: Admin editing any request in the group
    -- Admins are restricted to only modifying the status field
    IF v_is_admin THEN
        IF NEW.id <> OLD.id 
           OR NEW.group_id <> OLD.group_id 
           OR NEW.requested_by <> OLD.requested_by 
           OR NEW.item_name <> OLD.item_name 
           OR NEW.is_private <> OLD.is_private 
           OR NEW.private_to IS DISTINCT FROM OLD.private_to
           OR NEW.created_at <> OLD.created_at
           OR NEW.deleted_at IS DISTINCT FROM OLD.deleted_at
        THEN
            RAISE EXCEPTION 'Administrators can only modify the status field';
        END IF;
        RETURN NEW;
    END IF;

    -- Case 3: Unauthorized
    RAISE EXCEPTION 'Unauthorized to update this request';
END;
$$;

CREATE TRIGGER trg_check_request_update_permissions
BEFORE UPDATE ON public.requests
FOR EACH ROW
EXECUTE FUNCTION public.check_request_update_permissions_trigger();
