-- ============================================================
-- KAP-APP v2.0 — Migration 16: Add Text Column Length Constraints
-- ============================================================

-- ------------------------------------------------------------
-- STEP 1: Pre-Migration Data Integrity Check
-- (Returns empty result set if all data is valid)
-- ------------------------------------------------------------
SELECT 'users.display_name' AS column_name, count(*) AS invalid_count 
FROM public.users WHERE char_length(display_name) < 1 OR char_length(display_name) > 100 HAVING count(*) > 0
UNION ALL
SELECT 'groups.name' AS column_name, count(*) AS invalid_count 
FROM public.groups WHERE char_length(name) < 1 OR char_length(name) > 100 HAVING count(*) > 0
UNION ALL
SELECT 'requests.item_name' AS column_name, count(*) AS invalid_count 
FROM public.requests WHERE char_length(item_name) < 1 OR char_length(item_name) > 200 HAVING count(*) > 0;

-- ------------------------------------------------------------
-- STEP 2: Idempotent Constraint Additions using DROP CONSTRAINT IF EXISTS
-- ------------------------------------------------------------

-- 2.1 users.display_name constraint
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS chk_users_display_name_length;
ALTER TABLE public.users ADD CONSTRAINT chk_users_display_name_length 
  CHECK (char_length(display_name) >= 1 AND char_length(display_name) <= 100);

-- 2.2 groups.name constraint
ALTER TABLE public.groups DROP CONSTRAINT IF EXISTS chk_groups_name_length;
ALTER TABLE public.groups ADD CONSTRAINT chk_groups_name_length 
  CHECK (char_length(name) >= 1 AND char_length(name) <= 100);

-- 2.3 requests.item_name constraint
ALTER TABLE public.requests DROP CONSTRAINT IF EXISTS chk_requests_item_name_length;
ALTER TABLE public.requests ADD CONSTRAINT chk_requests_item_name_length 
  CHECK (char_length(item_name) >= 1 AND char_length(item_name) <= 200);

-- 2.4 inventory.item_name constraint (if inventory table exists)
DO $$
BEGIN
    IF to_regclass('public.inventory') IS NOT NULL THEN
        ALTER TABLE public.inventory DROP CONSTRAINT IF EXISTS chk_inventory_item_name_length;
        ALTER TABLE public.inventory ADD CONSTRAINT chk_inventory_item_name_length 
          CHECK (char_length(item_name) >= 1 AND char_length(item_name) <= 200);
    END IF;
END $$;

-- 2.5 recipes constraints (if recipes table exists)
DO $$
BEGIN
    IF to_regclass('public.recipes') IS NOT NULL THEN
        ALTER TABLE public.recipes DROP CONSTRAINT IF EXISTS chk_recipes_title_length;
        ALTER TABLE public.recipes ADD CONSTRAINT chk_recipes_title_length 
          CHECK (char_length(title) >= 1 AND char_length(title) <= 200);

        ALTER TABLE public.recipes DROP CONSTRAINT IF EXISTS chk_recipes_description_length;
        ALTER TABLE public.recipes ADD CONSTRAINT chk_recipes_description_length 
          CHECK (description IS NULL OR char_length(description) <= 1000);

        ALTER TABLE public.recipes DROP CONSTRAINT IF EXISTS chk_recipes_instructions_length;
        ALTER TABLE public.recipes ADD CONSTRAINT chk_recipes_instructions_length 
          CHECK (instructions IS NULL OR char_length(instructions) <= 5000);
    END IF;
END $$;

-- 2.6 recipe_items constraint (if recipe_items table exists)
DO $$
BEGIN
    IF to_regclass('public.recipe_items') IS NOT NULL THEN
        ALTER TABLE public.recipe_items DROP CONSTRAINT IF EXISTS chk_recipe_items_item_name_length;
        ALTER TABLE public.recipe_items ADD CONSTRAINT chk_recipe_items_item_name_length 
          CHECK (char_length(item_name) >= 1 AND char_length(item_name) <= 200);
    END IF;
END $$;
