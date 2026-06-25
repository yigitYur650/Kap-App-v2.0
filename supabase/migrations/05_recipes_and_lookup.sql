-- ============================================================
-- KAP-APP v2.0 — Migration 05: Recipes & Lookup View
-- ============================================================

-- 1. Create Recipes Table
CREATE TABLE public.recipes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id uuid NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    title text NOT NULL,
    description text,
    instructions text,
    created_by uuid REFERENCES public.users(id) ON DELETE SET NULL, -- Nullable to support ON DELETE SET NULL
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz,
    deleted_at timestamptz
);

-- Enable RLS on recipes
ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;


-- 2. Create Recipe Items Table
CREATE TABLE public.recipe_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id uuid NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
    group_id uuid NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    item_name text NOT NULL,
    quantity_hint text,
    required_status text CONSTRAINT chk_recipe_item_required_status CHECK (required_status IN ('var', 'azaldı', 'yok')),
    created_at timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS on recipe_items
ALTER TABLE public.recipe_items ENABLE ROW LEVEL SECURITY;


-- 3. Triggers and Functions

-- Trigger function for updating updated_at on recipes
CREATE OR REPLACE FUNCTION public.recipes_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_recipes_updated_at
BEFORE UPDATE ON public.recipes
FOR EACH ROW
EXECUTE FUNCTION public.recipes_set_updated_at();

-- Trigger function for autofilling created_by on recipes insertion
CREATE OR REPLACE FUNCTION public.recipes_set_created_by()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
    NEW.created_by = auth.uid();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_recipes_created_by
BEFORE INSERT ON public.recipes
FOR EACH ROW
EXECUTE FUNCTION public.recipes_set_created_by();

-- Trigger function for autofilling recipe_items group_id
CREATE OR REPLACE FUNCTION public.recipe_items_autofill_group_id()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
    NEW.group_id = (
        SELECT group_id FROM public.recipes
        WHERE id = NEW.recipe_id
    );
    -- Integrity check: ensure recipe exists
    IF NEW.group_id IS NULL THEN
        RAISE EXCEPTION 'Invalid recipe_id. Associated recipe does not exist.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_recipe_items_autofill_group_id
BEFORE INSERT OR UPDATE OF recipe_id, group_id ON public.recipe_items
FOR EACH ROW
EXECUTE FUNCTION public.recipe_items_autofill_group_id();


-- 4. RLS Policies for Recipes

-- SELECT: members of the group can view active recipes
CREATE POLICY "Allow group members to select active recipes"
ON public.recipes FOR SELECT
TO authenticated
USING (
    public.is_group_member(group_id)
    AND deleted_at IS NULL
);

-- INSERT: authenticated group members can insert recipes
CREATE POLICY "Allow group members to insert recipes"
ON public.recipes FOR INSERT
TO authenticated
WITH CHECK (
    public.is_group_member(group_id)
    AND auth.uid() IS NOT NULL
);

-- UPDATE: only the creator can update the recipe
CREATE POLICY "Allow creators to update own recipes"
ON public.recipes FOR UPDATE
TO authenticated
USING (
    public.is_group_member(group_id)
    AND created_by = auth.uid()
)
WITH CHECK (
    public.is_group_member(group_id)
    AND created_by = auth.uid()
);


-- 5. RLS Policies for Recipe Items

-- SELECT: group members can view items of active recipes
CREATE POLICY "Allow group members to select recipe items"
ON public.recipe_items FOR SELECT
TO authenticated
USING (
    public.is_group_member(group_id)
    AND EXISTS (
        SELECT 1 FROM public.recipes r
        WHERE r.id = recipe_id
          AND r.deleted_at IS NULL
    )
);

-- INSERT: group members can insert if they own the recipe or are group admins
CREATE POLICY "Allow creator or admin to insert recipe items"
ON public.recipe_items FOR INSERT
TO authenticated
WITH CHECK (
    public.is_group_member(group_id)
    AND auth.uid() IS NOT NULL
    AND (
        EXISTS (
            SELECT 1 FROM public.recipes r
            WHERE r.id = recipe_id
              AND r.created_by = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.recipes r
            WHERE r.id = recipe_id
              AND public.is_group_admin(r.group_id)
        )
    )
);

-- UPDATE: creator or group admin can update recipe items
CREATE POLICY "Allow creator or admin to update recipe items"
ON public.recipe_items FOR UPDATE
TO authenticated
USING (
    public.is_group_member(group_id)
    AND auth.uid() IS NOT NULL
    AND (
        EXISTS (
            SELECT 1 FROM public.recipes r
            WHERE r.id = recipe_id
              AND r.created_by = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.recipes r
            WHERE r.id = recipe_id
              AND public.is_group_admin(r.group_id)
        )
    )
)
WITH CHECK (
    public.is_group_member(group_id)
    AND auth.uid() IS NOT NULL
    AND (
        EXISTS (
            SELECT 1 FROM public.recipes r
            WHERE r.id = recipe_id
              AND r.created_by = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.recipes r
            WHERE r.id = recipe_id
              AND public.is_group_admin(r.group_id)
        )
    )
);

-- DELETE: creator or group admin can delete recipe items
CREATE POLICY "Allow creator or admin to delete recipe items"
ON public.recipe_items FOR DELETE
TO authenticated
USING (
    public.is_group_member(group_id)
    AND auth.uid() IS NOT NULL
    AND (
        EXISTS (
            SELECT 1 FROM public.recipes r
            WHERE r.id = recipe_id
              AND r.created_by = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.recipes r
            WHERE r.id = recipe_id
              AND public.is_group_admin(r.group_id)
        )
    )
);


-- 6. Leakproof User Lookup View
CREATE OR REPLACE VIEW public.public_user_lookup
WITH (security_barrier = true)
AS
SELECT id, display_name, unique_code
FROM public.users
WHERE is_invitable = true
  AND account_status = 'active'
  AND deleted_at IS NULL
  AND (auth.uid() IS NULL OR id <> auth.uid());

-- Grant SELECT permission on the view to authenticated role
GRANT SELECT ON public.public_user_lookup TO authenticated;
