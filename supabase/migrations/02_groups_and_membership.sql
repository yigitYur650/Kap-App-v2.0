-- ============================================================
-- KAP-APP v2.0 — Migration 02: Groups & Membership
-- ============================================================

-- 1. Create Groups Table
CREATE TABLE public.groups (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    type text NOT NULL,
    created_by uuid REFERENCES public.users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz,
    CONSTRAINT chk_group_type CHECK (type IN ('family', 'community'))
);

-- Enable RLS on groups
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;


-- 2. Create Group Members Table
CREATE TABLE public.group_members (
    user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
    group_id uuid REFERENCES public.groups(id) ON DELETE CASCADE,
    role text NOT NULL,
    joined_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, group_id),
    CONSTRAINT chk_member_role CHECK (role IN ('admin', 'member'))
);

-- Enable RLS on group_members
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;


-- 3. Redefine Global Helper Functions (Security Hardened)
-- These look up relationships securely with qualified public.group_members references.
CREATE OR REPLACE FUNCTION public.is_group_member(p_group_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_catalog
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.group_members
        WHERE group_id = p_group_id
          AND user_id  = auth.uid()
    );
$$;

CREATE OR REPLACE FUNCTION public.is_group_admin(p_group_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_catalog
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.group_members
        WHERE group_id = p_group_id
          AND user_id  = auth.uid()
          AND role     = 'admin'
    );
$$;


-- 4. RLS Policies for groups table
CREATE POLICY "Allow members to select groups"
ON public.groups FOR SELECT
TO authenticated
USING (public.is_group_member(id));

CREATE POLICY "Allow authenticated to create group"
ON public.groups FOR INSERT
TO authenticated
WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Allow group admins/creators to update group details"
ON public.groups FOR UPDATE
TO authenticated
USING (public.is_group_admin(id) OR created_by = auth.uid())
WITH CHECK (public.is_group_admin(id) OR created_by = auth.uid());

CREATE POLICY "Allow group admins to delete group"
ON public.groups FOR DELETE
TO authenticated
USING (public.is_group_admin(id));


-- 5. RLS Policies for group_members table (Preventing Infinite Recursion & Protecting Creator)
-- Note: Do NOT call functions (is_group_member/is_group_admin) here to avoid RLS loop deadlocks.
CREATE POLICY "Allow members to select group_members"
ON public.group_members FOR SELECT
TO authenticated
USING (
    user_id = auth.uid()
    OR EXISTS (
        SELECT 1 FROM public.group_members gm
        WHERE gm.group_id = group_members.group_id
          AND gm.user_id = auth.uid()
    )
);

CREATE POLICY "Allow users to join group"
ON public.group_members FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Allow group creator to update member roles"
ON public.group_members FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.groups g
        WHERE g.id = group_members.group_id
          AND g.created_by = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.groups g
        WHERE g.id = group_members.group_id
          AND g.created_by = auth.uid()
    )
    -- Creator Protection: The role of the group creator can never be changed or demoted.
    AND (
        NOT EXISTS (
            SELECT 1 FROM public.groups g
            WHERE g.id = group_members.group_id
              AND g.created_by = group_members.user_id
        )
        OR role = 'admin'
    )
);

CREATE POLICY "Allow users to leave or admins to remove members"
ON public.group_members FOR DELETE
TO authenticated
USING (
    -- Any user can leave a group
    user_id = auth.uid()
    -- Or group admins can remove other members, EXCEPT the group creator
    OR (
        EXISTS (
            SELECT 1 FROM public.group_members gm
            WHERE gm.group_id = group_members.group_id
              AND gm.user_id = auth.uid()
              AND gm.role = 'admin'
        )
        AND NOT EXISTS (
            SELECT 1 FROM public.groups g
            WHERE g.id = group_members.group_id
              AND g.created_by = group_members.user_id
        )
    )
);


-- 6. Trigger: Ensure Max 3 Admins per Group
CREATE OR REPLACE FUNCTION public.check_max_admins_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_admin_count int;
BEGIN
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

CREATE TRIGGER trg_check_max_admins
BEFORE INSERT OR UPDATE ON public.group_members
FOR EACH ROW
EXECUTE FUNCTION public.check_max_admins_trigger();


-- 7. Trigger: Automated Admin Backup Protection
CREATE OR REPLACE FUNCTION public.ensure_admin_exists_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_admin_count int;
    v_total_count int;
    v_group_exists boolean;
    v_oldest_member_id uuid;
BEGIN
    -- Check if the group still exists (to handle cascading deletes of the group itself)
    SELECT EXISTS (
        SELECT 1 FROM public.groups WHERE id = OLD.group_id
    ) INTO v_group_exists;

    IF NOT v_group_exists THEN
        RETURN OLD;
    END IF;

    -- Check total members left in the group after deletion (excluding OLD.user_id)
    SELECT COUNT(*)
    INTO v_total_count
    FROM public.group_members
    WHERE group_id = OLD.group_id AND user_id <> OLD.user_id;

    -- If no members are left, gracefully exit to prevent deadlock
    IF v_total_count = 0 THEN
        RETURN OLD;
    END IF;

    -- Check if any admins remain (excluding OLD.user_id)
    SELECT COUNT(*)
    INTO v_admin_count
    FROM public.group_members
    WHERE group_id = OLD.group_id AND role = 'admin' AND user_id <> OLD.user_id;

    IF v_admin_count = 0 THEN
        -- Find the oldest member in that group based on joined_at (excluding OLD.user_id)
        SELECT user_id
        INTO v_oldest_member_id
        FROM public.group_members
        WHERE group_id = OLD.group_id AND user_id <> OLD.user_id
        ORDER BY joined_at ASC, user_id ASC
        LIMIT 1;

        -- Promote the oldest member to admin
        IF v_oldest_member_id IS NOT NULL THEN
            UPDATE public.group_members
            SET role = 'admin'
            WHERE group_id = OLD.group_id AND user_id = v_oldest_member_id;
        END IF;
    END IF;
    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_ensure_admin_exists
BEFORE DELETE ON public.group_members
FOR EACH ROW
EXECUTE FUNCTION public.ensure_admin_exists_trigger();
