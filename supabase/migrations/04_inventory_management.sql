-- ============================================================
-- KAP-APP v2.0 — Migration 04: Inventory Management
-- ============================================================

-- 1. Create Inventory Table
CREATE TABLE public.inventory (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id uuid NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    item_name text NOT NULL,
    status text NOT NULL DEFAULT 'var',
    last_updated_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
    last_updated_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz,
    CONSTRAINT chk_inventory_status CHECK (status IN ('var', 'azaldı', 'yok'))
);

-- Enable RLS on inventory
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;

-- Partial unique index to prevent duplicate active items in a group
CREATE UNIQUE INDEX idx_unique_active_inventory 
ON public.inventory (group_id, LOWER(item_name)) 
WHERE deleted_at IS NULL;


-- 2. Create Inventory Log Table
CREATE TABLE public.inventory_log (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    inventory_id uuid NOT NULL REFERENCES public.inventory(id) ON DELETE CASCADE,
    group_id uuid NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    old_status text,
    new_status text,
    changed_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
    changed_at timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS on inventory_log
ALTER TABLE public.inventory_log ENABLE ROW LEVEL SECURITY;

-- Index for RLS policies optimization
CREATE INDEX idx_inventory_log_group ON public.inventory_log (group_id);


-- 3. Trigger A: Automatically maintain last_updated metadata
CREATE OR REPLACE FUNCTION public.maintain_inventory_metadata_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
    NEW.last_updated_at = now();
    
    IF TG_OP = 'INSERT' THEN
        NEW.last_updated_by = auth.uid();
    ELSIF TG_OP = 'UPDATE' THEN
        -- Preserve previous updater if updated programmatically / system context where auth.uid() is null
        NEW.last_updated_by = COALESCE(auth.uid(), OLD.last_updated_by);
    END IF;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_inventory_last_updated
BEFORE INSERT OR UPDATE ON public.inventory
FOR EACH ROW
EXECUTE FUNCTION public.maintain_inventory_metadata_trigger();


-- 4. Trigger B: Automatically log status changes
CREATE OR REPLACE FUNCTION public.log_inventory_status_change_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.inventory_log (inventory_id, group_id, old_status, new_status, changed_by)
        VALUES (NEW.id, NEW.group_id, NULL, NEW.status, NEW.last_updated_by);
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status IS DISTINCT FROM NEW.status THEN
            INSERT INTO public.inventory_log (inventory_id, group_id, old_status, new_status, changed_by)
            VALUES (NEW.id, NEW.group_id, OLD.status, NEW.status, NEW.last_updated_by);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_inventory_log_status_change
AFTER INSERT OR UPDATE ON public.inventory
FOR EACH ROW
EXECUTE FUNCTION public.log_inventory_status_change_trigger();


-- 5. Trigger C: Automatically create shopping requests when inventory status becomes 'yok'
CREATE OR REPLACE FUNCTION public.create_request_on_empty_inventory_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_requested_by uuid;
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
        
        -- If a valid user is found, attempt to insert a shopping request
        -- Uses targeted ON CONFLICT matching the exact partial unique index to avoid duplication errors
        IF v_requested_by IS NOT NULL THEN
            INSERT INTO public.requests (group_id, requested_by, item_name, is_private, status)
            VALUES (NEW.group_id, v_requested_by, NEW.item_name, false, 'pending')
            ON CONFLICT (group_id, LOWER(item_name)) 
            WHERE status = 'pending' AND deleted_at IS NULL AND is_private = false 
            DO NOTHING;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_inventory_request_on_empty
AFTER UPDATE ON public.inventory
FOR EACH ROW
EXECUTE FUNCTION public.create_request_on_empty_inventory_trigger();


-- 6. RLS Policies for inventory table
CREATE POLICY "Allow group members to read active inventory items"
ON public.inventory FOR SELECT
TO authenticated
USING (public.is_group_member(group_id) AND deleted_at IS NULL);

CREATE POLICY "Allow group members to insert inventory items"
ON public.inventory FOR INSERT
TO authenticated
WITH CHECK (public.is_group_member(group_id) AND auth.uid() IS NOT NULL);

CREATE POLICY "Allow group members to update inventory items"
ON public.inventory FOR UPDATE
TO authenticated
USING (public.is_group_member(group_id))
WITH CHECK (public.is_group_member(group_id));

-- Note: Physical deletions are fully blocked as no DELETE policy is declared.
-- Soft deletes are accomplished by updating the deleted_at timestamp.


-- 7. RLS Policies for inventory_log table
CREATE POLICY "Allow group members to read inventory logs"
ON public.inventory_log FOR SELECT
TO authenticated
USING (public.is_group_member(group_id));

-- Note: INSERT, UPDATE, and DELETE directly via API are fully blocked.
-- Log insertions are managed strictly via the security definer trigger logic.
