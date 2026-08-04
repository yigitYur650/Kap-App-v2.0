-- ============================================================
-- KAP-APP v2.0 — Migration 06: Cleanup Orphaned RLS Policies
--               & Fix Cascade Delete Trigger
-- ============================================================
--
-- Purpose:
--   1. Drop ALL Turkish-named RLS policies that were defined in
--      the standalone file `kap_app_rls_policies.sql` (which was
--      located outside the migration system and has been deleted).
--      These policies conflict with the English-named policies
--      defined in migrations 01-05, creating split-brain RLS.
--
--   2. Drop the conflicting public_user_lookup view if it exists
--      (Migration 05 creates a security_barrier version instead).
--
--   3. Recreate helper functions (is_group_member, is_group_admin)
--      to ensure they use the safe, schema-qualified, SECURITY
--      DEFINER definition from Migration 02 (the orphan file
--      redefined them WITHOUT SET search_path, risking infinite
--      recursion).
--
--   4. Fix the prevent_physical_delete_trigger on the requests
--      table (DB-C2): allow cascade deletes when the parent
--      group is being deleted.
--
-- ============================================================
-- DROPPED POLICY INVENTORY
-- ============================================================
-- All policies below were defined in kap_app_rls_policies.sql
-- (Turkish names). They duplicate the English-named policies
-- from migrations 01-05 and must be removed.
--
-- users table (4 policies):
--   "users: kendi profilini gör"
--   "users: aynı gruptaki üyeleri gör"
--   "users: kendi profilini güncelle"
--   "users: kayıt sırasında oluştur"
--
-- groups table (4 policies):
--   "groups: üyesi olduğun veya oluşturduğun grupları gör"
--   "groups: grup oluştur"
--   "groups: admin güncelleyebilir"
--   "groups: admin silebilir"
--
-- group_members table (4 policies):
--   "group_members: aynı gruptakileri gör"
--   "group_members: gruba katıl"
--   "group_members: admin rol değiştirir"
--   "group_members: gruptan ayrıl veya çıkar"
--
-- requests table (4 policies):
--   "requests: listele (özel istekler gizli)"
--   "requests: istek oluştur"
--   "requests: kendi isteğini güncelle"
--   "requests: sil"
--
-- inventory table (4 policies):
--   "inventory: üyeler görebilir"
--   "inventory: üye ürün ekler"
--   "inventory: üye stok günceller"
--   "inventory: sil"
--
-- recipes table (4 policies):
--   "recipes: herkese açık tarifleri gör"
--   "recipes: üye tarif ekler"
--   "recipes: tarifi oluşturan günceller"
--   "recipes: sil"
--
-- recipe_items table (4 policies):
--   "recipe_items: tarifi görenler malzemeleri de görebilir"
--   "recipe_items: tarif sahibi malzeme ekler"
--   "recipe_items: tarif sahibi günceller"
--   "recipe_items: sil"
--
-- Total: 28 Turkish-named policies dropped.
-- ============================================================


-- ============================================================
-- STEP 1: Drop Turkish-named RLS policies (IF EXISTS)
-- ============================================================

-- users table
DROP POLICY IF EXISTS "users: kendi profilini gör" ON public.users;
DROP POLICY IF EXISTS "users: aynı gruptaki üyeleri gör" ON public.users;
DROP POLICY IF EXISTS "users: kendi profilini güncelle" ON public.users;
DROP POLICY IF EXISTS "users: kayıt sırasında oluştur" ON public.users;

-- groups table
DROP POLICY IF EXISTS "groups: üyesi olduğun veya oluşturduğun grupları gör" ON public.groups;
DROP POLICY IF EXISTS "groups: grup oluştur" ON public.groups;
DROP POLICY IF EXISTS "groups: admin güncelleyebilir" ON public.groups;
DROP POLICY IF EXISTS "groups: admin silebilir" ON public.groups;

-- group_members table
DROP POLICY IF EXISTS "group_members: aynı gruptakileri gör" ON public.group_members;
DROP POLICY IF EXISTS "group_members: gruba katıl" ON public.group_members;
DROP POLICY IF EXISTS "group_members: admin rol değiştirir" ON public.group_members;
DROP POLICY IF EXISTS "group_members: gruptan ayrıl veya çıkar" ON public.group_members;

-- requests table
DROP POLICY IF EXISTS "requests: listele (özel istekler gizli)" ON public.requests;
DROP POLICY IF EXISTS "requests: istek oluştur" ON public.requests;
DROP POLICY IF EXISTS "requests: kendi isteğini güncelle" ON public.requests;
DROP POLICY IF EXISTS "requests: sil" ON public.requests;

-- inventory table
DROP POLICY IF EXISTS "inventory: üyeler görebilir" ON public.inventory;
DROP POLICY IF EXISTS "inventory: üye ürün ekler" ON public.inventory;
DROP POLICY IF EXISTS "inventory: üye stok günceller" ON public.inventory;
DROP POLICY IF EXISTS "inventory: sil" ON public.inventory;

-- recipes table
DROP POLICY IF EXISTS "recipes: herkese açık tarifleri gör" ON public.recipes;
DROP POLICY IF EXISTS "recipes: üye tarif ekler" ON public.recipes;
DROP POLICY IF EXISTS "recipes: tarifi oluşturan günceller" ON public.recipes;
DROP POLICY IF EXISTS "recipes: sil" ON public.recipes;

-- recipe_items table
DROP POLICY IF EXISTS "recipe_items: tarifi görenler malzemeleri de görebilir" ON public.recipe_items;
DROP POLICY IF EXISTS "recipe_items: tarif sahibi malzeme ekler" ON public.recipe_items;
DROP POLICY IF EXISTS "recipe_items: tarif sahibi günceller" ON public.recipe_items;
DROP POLICY IF EXISTS "recipe_items: sil" ON public.recipe_items;


-- ============================================================
-- STEP 2: Drop conflicting public_user_lookup view
-- ============================================================
-- Migration 05 creates this view WITH security_barrier.
-- The orphan file created a simpler version WITH security_invoker.
-- Drop the orphan version (which may not exist if only migration
-- 05 was applied) to ensure clean state.
DROP VIEW IF EXISTS public.public_user_lookup;


-- ============================================================
-- STEP 3: Recreate helper functions from Migration 02
-- ============================================================
-- The orphan file redefined these functions WITHOUT SET search_path,
-- creating infinite recursion risk when called within RLS policies.
-- We recreate them exactly as Migration 02 defined them.
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


-- ============================================================
-- STEP 4: Fix prevent_physical_delete_trigger (DB-C2)
-- ============================================================
-- Problem: The BEFORE DELETE trigger on requests table raises
-- 'Physical deletion is not allowed' for ALL deletions, including
-- cascade deletes from groups table (ON DELETE CASCADE).
--
-- Fix: Check if the parent group still exists. If it doesn't
-- (cascade context), allow the delete. Otherwise, block it.
CREATE OR REPLACE FUNCTION public.prevent_physical_delete_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_group_exists boolean;
BEGIN
    -- Check if the parent group still exists
    SELECT EXISTS (
        SELECT 1 FROM public.groups WHERE id = OLD.group_id
    ) INTO v_group_exists;

    -- If the group no longer exists, this is a cascade delete — allow it
    IF NOT v_group_exists THEN
        RETURN OLD;
    END IF;

    -- Otherwise, block direct physical deletion
    RAISE EXCEPTION 'Physical deletion is not allowed. Please use soft delete (set deleted_at).';
END;
$$;

-- Recreate the trigger to pick up the updated function
DROP TRIGGER IF EXISTS trg_prevent_physical_delete ON public.requests;
CREATE TRIGGER trg_prevent_physical_delete
BEFORE DELETE ON public.requests
FOR EACH ROW
EXECUTE FUNCTION public.prevent_physical_delete_trigger();
