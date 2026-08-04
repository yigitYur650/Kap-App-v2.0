-- ============================================================
-- KAP-APP v2.0 — Migration 15: Remove Admin Role & Group Type
-- ============================================================
-- Goal: Remove admin/member role distinction and groups.type (family/community)
-- distinction completely, giving all members equal rights in a group.

-- ============================================================
-- STEP 1: Remove Admin-related Triggers and Trigger Functions
-- ============================================================
DROP TRIGGER IF EXISTS trg_check_max_admins ON public.group_members;
DROP FUNCTION IF EXISTS public.check_max_admins_trigger();

DROP TRIGGER IF EXISTS trg_ensure_admin_exists ON public.group_members;
DROP FUNCTION IF EXISTS public.ensure_admin_exists_trigger();

-- Note: is_group_admin(uuid) will be dropped after dependent policies are updated below.


-- ============================================================
-- STEP 2: Update group_members Policies & Drop 'role' Column
-- ============================================================
-- 2.1 MUST drop policies depending on 'role' column BEFORE dropping the column
DROP POLICY IF EXISTS "Allow group creator to update member roles" ON public.group_members;
DROP POLICY IF EXISTS "Allow users to leave or admins to remove members" ON public.group_members;
DROP POLICY IF EXISTS "Allow users to leave or members to remove members" ON public.group_members;
DROP POLICY IF EXISTS "group_members: admin rol değiştirir" ON public.group_members;
DROP POLICY IF EXISTS "group_members: gruptan ayrıl veya çıkar" ON public.group_members;

-- 2.2 Now safely drop 'role' column
ALTER TABLE public.group_members DROP COLUMN IF EXISTS role;

-- 2.3 Recreate DELETE policy on group_members
CREATE POLICY "Allow users to leave or members to remove members"
ON public.group_members FOR DELETE
TO authenticated
USING (
    user_id = auth.uid() 
    OR public.is_group_member(group_id)
);


-- ============================================================
-- STEP 3: Update groups Policies & Drop 'type' Column
-- ============================================================
-- 3.1 Drop policies depending on groups table BEFORE dropping column
DROP POLICY IF EXISTS "Allow group admins/creators to update group details" ON public.groups;
DROP POLICY IF EXISTS "Allow members to update group details" ON public.groups;
DROP POLICY IF EXISTS "Allow group admins to delete group" ON public.groups;
DROP POLICY IF EXISTS "Allow members to delete group" ON public.groups;
DROP POLICY IF EXISTS "groups: admin güncelleyebilir" ON public.groups;
DROP POLICY IF EXISTS "groups: admin silebilir" ON public.groups;

-- 3.2 Drop 'type' column
ALTER TABLE public.groups DROP COLUMN IF EXISTS type;

-- 3.3 Recreate UPDATE policy on groups
CREATE POLICY "Allow members to update group details"
ON public.groups FOR UPDATE
TO authenticated
USING (public.is_group_member(id))
WITH CHECK (public.is_group_member(id));

-- 3.4 Recreate DELETE policy on groups
CREATE POLICY "Allow members to delete group"
ON public.groups FOR DELETE
TO authenticated
USING (public.is_group_member(id));


-- ============================================================
-- STEP 4: Update requests Table Policies & Triggers
-- ============================================================
-- 4.1 Recreate INSERT policy with status = 'pending' check
DROP POLICY IF EXISTS "Allow members to insert requests" ON public.requests;
DROP POLICY IF EXISTS "requests: istek oluştur" ON public.requests;

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
    AND status = 'pending'
);

-- Ensure clean UPDATE policy without admin references
DROP POLICY IF EXISTS "Allow updates on requests" ON public.requests;
DROP POLICY IF EXISTS "Allow members to update requests" ON public.requests;
DROP POLICY IF EXISTS "requests: kendi isteğini güncelle" ON public.requests;

CREATE POLICY "Allow members to update requests"
ON public.requests FOR UPDATE
TO authenticated
USING (public.is_group_member(group_id))
WITH CHECK (public.is_group_member(group_id));

-- 4.2 Simplify request update permissions trigger function
CREATE OR REPLACE FUNCTION public.check_request_update_permissions_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
    IF NEW.id <> OLD.id 
       OR NEW.group_id <> OLD.group_id 
       OR NEW.requested_by <> OLD.requested_by 
       OR NEW.created_at <> OLD.created_at 
    THEN
        RAISE EXCEPTION 'Cannot modify id, group_id, requested_by, or created_at fields';
    END IF;

    IF NOT public.is_group_member(OLD.group_id) THEN
        RAISE EXCEPTION 'Unauthorized to update this request';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_request_update_permissions ON public.requests;
CREATE TRIGGER trg_check_request_update_permissions
BEFORE UPDATE ON public.requests
FOR EACH ROW
EXECUTE FUNCTION public.check_request_update_permissions_trigger();


-- ============================================================
-- STEP 5: Update recipes & recipe_items Policies & Drop Helper Function
-- ============================================================
-- 5.1 Recreate recipe_items INSERT policy without is_group_admin
DROP POLICY IF EXISTS "Allow creator or admin to insert recipe items" ON public.recipe_items;
DROP POLICY IF EXISTS "Allow creator to insert recipe items" ON public.recipe_items;

CREATE POLICY "Allow creator to insert recipe items"
ON public.recipe_items FOR INSERT
TO authenticated
WITH CHECK (
    public.is_group_member(group_id)
    AND auth.uid() IS NOT NULL
    AND EXISTS (
        SELECT 1 FROM public.recipes r
        WHERE r.id = recipe_id
          AND r.created_by = auth.uid()
    )
);

-- 5.2 Recreate recipe_items UPDATE policy without is_group_admin
DROP POLICY IF EXISTS "Allow creator or admin to update recipe items" ON public.recipe_items;
DROP POLICY IF EXISTS "Allow creator to update recipe items" ON public.recipe_items;

CREATE POLICY "Allow creator to update recipe items"
ON public.recipe_items FOR UPDATE
TO authenticated
USING (
    public.is_group_member(group_id)
    AND auth.uid() IS NOT NULL
    AND EXISTS (
        SELECT 1 FROM public.recipes r
        WHERE r.id = recipe_id
          AND r.created_by = auth.uid()
    )
)
WITH CHECK (
    public.is_group_member(group_id)
    AND auth.uid() IS NOT NULL
    AND EXISTS (
        SELECT 1 FROM public.recipes r
        WHERE r.id = recipe_id
          AND r.created_by = auth.uid()
    )
);

-- 5.3 Recreate recipe_items DELETE policy without is_group_admin
DROP POLICY IF EXISTS "Allow creator or admin to delete recipe items" ON public.recipe_items;
DROP POLICY IF EXISTS "Allow creator to delete recipe items" ON public.recipe_items;

CREATE POLICY "Allow creator to delete recipe items"
ON public.recipe_items FOR DELETE
TO authenticated
USING (
    public.is_group_member(group_id)
    AND auth.uid() IS NOT NULL
    AND EXISTS (
        SELECT 1 FROM public.recipes r
        WHERE r.id = recipe_id
          AND r.created_by = auth.uid()
    )
);

-- 5.4 Safely drop is_group_admin function now that all policy dependencies are cleared
DROP FUNCTION IF EXISTS public.is_group_admin(uuid);


-- ============================================================
-- STEP 6: Verification ASSERT Block
-- ============================================================
DO $$
BEGIN
    -- 6.1 Assert 'type' column no longer exists in public.groups
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'groups' AND column_name = 'type'
    ) THEN
        RAISE EXCEPTION 'Verification failed: column groups.type still exists';
    END IF;

    -- 6.2 Assert 'role' column no longer exists in public.group_members
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'group_members' AND column_name = 'role'
    ) THEN
        RAISE EXCEPTION 'Verification failed: column group_members.role still exists';
    END IF;

    -- 6.3 Assert is_group_admin function no longer exists in pg_proc
    IF EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' AND p.proname = 'is_group_admin'
    ) THEN
        RAISE EXCEPTION 'Verification failed: function is_group_admin still exists';
    END IF;
END $$;
