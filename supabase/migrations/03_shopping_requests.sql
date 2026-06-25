-- ============================================================
-- KAP-APP v2.0 — Migration 03: Shopping Requests
-- ============================================================

-- 1. Create Requests Table
CREATE TABLE public.requests (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id uuid NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    requested_by uuid NOT NULL REFERENCES public.users(id),
    item_name text NOT NULL,
    is_private boolean NOT NULL DEFAULT false,
    private_to uuid REFERENCES public.users(id),
    status text NOT NULL DEFAULT 'pending',
    created_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz,
    CONSTRAINT chk_request_status CHECK (status IN ('pending', 'done')),
    CONSTRAINT chk_privacy_consistency CHECK (
        (is_private = false AND private_to IS NULL) OR 
        (is_private = true AND private_to IS NOT NULL)
    )
);

-- Enable RLS on requests
ALTER TABLE public.requests ENABLE ROW LEVEL SECURITY;


-- 2. Create Partial Unique Index
-- This index prevents duplicate pending items in the same group, ignoring case.
CREATE UNIQUE INDEX idx_unique_pending_item_per_group 
ON public.requests (group_id, LOWER(item_name)) 
WHERE status = 'pending' AND deleted_at IS NULL AND is_private = false;


-- 3. RLS Policies for requests table
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
);

CREATE POLICY "Allow members to insert requests"
ON public.requests FOR INSERT
TO authenticated
WITH CHECK (
    public.is_group_member(group_id)
    AND requested_by = auth.uid()
    AND (
        is_private = false
        OR (
            is_private = true
            AND EXISTS (
                SELECT 1 FROM public.group_members gm
                WHERE gm.group_id = requests.group_id
                  AND gm.user_id = requests.private_to
            )
        )
    )
    AND (
        public.is_group_admin(group_id)
        OR status = 'pending'
    )
);

CREATE POLICY "Allow updates on requests"
ON public.requests FOR UPDATE
TO authenticated
USING (
    public.is_group_member(group_id)
    AND (
        requested_by = auth.uid()
        OR public.is_group_admin(group_id)
    )
)
WITH CHECK (
    public.is_group_member(group_id)
    AND (
        requested_by = auth.uid()
        OR public.is_group_admin(group_id)
    )
);


-- 4. Trigger: Restrict UPDATE permissions and enforce column constraints
CREATE OR REPLACE FUNCTION public.check_request_update_permissions_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_is_admin boolean;
BEGIN
    v_is_admin := public.is_group_admin(OLD.group_id);

    -- Owner permission: Can edit only their own pending requests, but status changes require admin roles
    IF OLD.requested_by = auth.uid() AND OLD.status = 'pending' THEN
        IF NEW.status <> 'pending' AND NOT v_is_admin THEN
            RAISE EXCEPTION 'Only administrators can change the status of a request';
        END IF;
        IF NEW.group_id <> OLD.group_id OR NEW.requested_by <> OLD.requested_by THEN
            RAISE EXCEPTION 'Cannot modify group_id or requested_by fields';
        END IF;
        RETURN NEW;
    END IF;

    -- Admin permission: Can modify ONLY the status field
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

    RAISE EXCEPTION 'Unauthorized to update this request';
END;
$$;

CREATE TRIGGER trg_check_request_update_permissions
BEFORE UPDATE ON public.requests
FOR EACH ROW
EXECUTE FUNCTION public.check_request_update_permissions_trigger();


-- 5. Trigger: Block Physical Deletion
CREATE OR REPLACE FUNCTION public.prevent_physical_delete_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
    RAISE EXCEPTION 'Physical deletion is not allowed. Please use soft delete (set deleted_at).';
END;
$$;

CREATE TRIGGER trg_prevent_physical_delete
BEFORE DELETE ON public.requests
FOR EACH ROW
EXECUTE FUNCTION public.prevent_physical_delete_trigger();
