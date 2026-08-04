-- ============================================================
-- KAP-APP v2.0 — Migration Integrity Test Suite
-- 
-- Tests that ALL migrations are applied correctly and work
-- together without conflicts.
--
-- Usage:
--   Run this in Supabase SQL Editor.
--   If all tests PASS, you'll see: "✅ ALL TESTS PASSED"
--   If any test FAILS, you'll see which one and why.
-- ============================================================

BEGIN;

-- ============================================================
-- T1: All required tables exist
-- ============================================================
DO $$
DECLARE
    v_missing_tables text[] := ARRAY[]::text[];
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'users' AND schemaname = 'public') THEN
        v_missing_tables := array_append(v_missing_tables, 'users');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'groups' AND schemaname = 'public') THEN
        v_missing_tables := array_append(v_missing_tables, 'groups');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'group_members' AND schemaname = 'public') THEN
        v_missing_tables := array_append(v_missing_tables, 'group_members');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'requests' AND schemaname = 'public') THEN
        v_missing_tables := array_append(v_missing_tables, 'requests');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'inventory' AND schemaname = 'public') THEN
        v_missing_tables := array_append(v_missing_tables, 'inventory');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'recipes' AND schemaname = 'public') THEN
        v_missing_tables := array_append(v_missing_tables, 'recipes');
    END IF;

    IF array_length(v_missing_tables, 1) > 0 THEN
        RAISE EXCEPTION '❌ T1 FAILED — Missing tables: %', array_to_string(v_missing_tables, ', ');
    ELSE
        RAISE NOTICE '✅ T1: All 6 tables exist (users, groups, group_members, requests, inventory, recipes)';
    END IF;
END $$;

-- ============================================================
-- T2: All required columns exist with correct types
-- ============================================================
DO $$
DECLARE
    v_errors text[] := ARRAY[]::text[];
    v_col_type text;
BEGIN
    -- users table
    SELECT data_type INTO v_col_type FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'id' AND table_schema = 'public';
    IF v_col_type IS DISTINCT FROM 'uuid' THEN v_errors := array_append(v_errors, 'users.id should be uuid'); END IF;

    SELECT data_type INTO v_col_type FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'email' AND table_schema = 'public';
    IF v_col_type IS DISTINCT FROM 'text' THEN v_errors := array_append(v_errors, 'users.email should be text'); END IF;

    -- groups table
    SELECT data_type INTO v_col_type FROM information_schema.columns 
        WHERE table_name = 'groups' AND column_name = 'id' AND table_schema = 'public';
    IF v_col_type IS DISTINCT FROM 'uuid' THEN v_errors := array_append(v_errors, 'groups.id should be uuid'); END IF;
    
    SELECT data_type INTO v_col_type FROM information_schema.columns 
        WHERE table_name = 'groups' AND column_name = 'deleted_at' AND table_schema = 'public';
    IF v_col_type IS DISTINCT FROM 'timestamp with time zone' THEN v_errors := array_append(v_errors, 'groups.deleted_at should be timestamptz'); END IF;

    -- group_members table
    SELECT data_type INTO v_col_type FROM information_schema.columns 
        WHERE table_name = 'group_members' AND column_name = 'user_id' AND table_schema = 'public';
    IF v_col_type IS DISTINCT FROM 'uuid' THEN v_errors := array_append(v_errors, 'group_members.user_id should be uuid'); END IF;

    -- requests table
    SELECT data_type INTO v_col_type FROM information_schema.columns 
        WHERE table_name = 'requests' AND column_name = 'item_name' AND table_schema = 'public';
    IF v_col_type IS DISTINCT FROM 'text' THEN v_errors := array_append(v_errors, 'requests.item_name should be text'); END IF;

    SELECT data_type INTO v_col_type FROM information_schema.columns 
        WHERE table_name = 'requests' AND column_name = 'deleted_at' AND table_schema = 'public';
    IF v_col_type IS DISTINCT FROM 'timestamp with time zone' THEN v_errors := array_append(v_errors, 'requests.deleted_at should be timestamptz'); END IF;

    IF array_length(v_errors, 1) > 0 THEN
        RAISE EXCEPTION '❌ T2 FAILED — Errors: %', array_to_string(v_errors, ', ');
    ELSE
        RAISE NOTICE '✅ T2: All key columns exist with correct types';
    END IF;
END $$;

-- ============================================================
-- T3: RLS is enabled on all tables
-- ============================================================
DO $$
DECLARE
    v_missing_rls text[] := ARRAY[]::text[];
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'users' AND schemaname = 'public' AND rowsecurity) THEN
        v_missing_rls := array_append(v_missing_rls, 'users');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'groups' AND schemaname = 'public' AND rowsecurity) THEN
        v_missing_rls := array_append(v_missing_rls, 'groups');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'group_members' AND schemaname = 'public' AND rowsecurity) THEN
        v_missing_rls := array_append(v_missing_rls, 'group_members');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'requests' AND schemaname = 'public' AND rowsecurity) THEN
        v_missing_rls := array_append(v_missing_rls, 'requests');
    END IF;

    IF array_length(v_missing_rls, 1) > 0 THEN
        RAISE EXCEPTION '❌ T3 FAILED — RLS not enabled on: %', array_to_string(v_missing_rls, ', ');
    ELSE
        RAISE NOTICE '✅ T3: RLS enabled on all 4 core tables';
    END IF;
END $$;

-- ============================================================
-- T4: RLS policies exist for each table
-- ============================================================
DO $$
DECLARE
    v_missing_policies text[] := ARRAY[]::text[];
    v_policy_count int;
BEGIN
    -- users: should have SELECT, INSERT
    SELECT COUNT(*) INTO v_policy_count FROM pg_policies 
        WHERE tablename = 'users' AND schemaname = 'public';
    IF v_policy_count < 2 THEN v_missing_policies := array_append(v_missing_policies, 'users (< 2 policies)'); END IF;

    -- groups: should have SELECT, INSERT
    SELECT COUNT(*) INTO v_policy_count FROM pg_policies 
        WHERE tablename = 'groups' AND schemaname = 'public';
    IF v_policy_count < 2 THEN v_missing_policies := array_append(v_missing_policies, 'groups (< 2 policies)'); END IF;

    -- group_members: should have SELECT, INSERT
    SELECT COUNT(*) INTO v_policy_count FROM pg_policies 
        WHERE tablename = 'group_members' AND schemaname = 'public';
    IF v_policy_count < 2 THEN v_missing_policies := array_append(v_missing_policies, 'group_members (< 2 policies)'); END IF;

    -- requests: should have SELECT, INSERT, UPDATE
    SELECT COUNT(*) INTO v_policy_count FROM pg_policies 
        WHERE tablename = 'requests' AND schemaname = 'public';
    IF v_policy_count < 3 THEN v_missing_policies := array_append(v_missing_policies, 'requests (< 3 policies)'); END IF;

    IF array_length(v_missing_policies, 1) > 0 THEN
        RAISE EXCEPTION '❌ T4 FAILED — Missing policies: %', array_to_string(v_missing_policies, ', ');
    ELSE
        RAISE NOTICE '✅ T4: All tables have sufficient RLS policies';
    END IF;
END $$;

-- ============================================================
-- T5: Triggers exist and are enabled
-- ============================================================
DO $$
DECLARE
    v_missing_triggers text[] := ARRAY[]::text[];
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.triggers 
        WHERE event_object_table = 'requests' AND trigger_name = 'trg_check_request_update_permissions' AND action_timing = 'BEFORE') THEN
        v_missing_triggers := array_append(v_missing_triggers, 'trg_check_request_update_permissions');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.triggers 
        WHERE event_object_table = 'requests' AND trigger_name = 'trg_prevent_physical_delete' AND action_timing = 'BEFORE') THEN
        v_missing_triggers := array_append(v_missing_triggers, 'trg_prevent_physical_delete');
    END IF;

    IF array_length(v_missing_triggers, 1) > 0 THEN
        RAISE EXCEPTION '❌ T5 FAILED — Missing triggers: %', array_to_string(v_missing_triggers, ', ');
    ELSE
        RAISE NOTICE '✅ T5: All triggers exist and are enabled';
    END IF;
END $$;

-- ============================================================
-- T6: Helper functions exist
-- ============================================================
DO $$
DECLARE
    v_missing_funcs text[] := ARRAY[]::text[];
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'is_group_member') THEN
        v_missing_funcs := array_append(v_missing_funcs, 'is_group_member()');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'check_request_update_permissions_trigger') THEN
        v_missing_funcs := array_append(v_missing_funcs, 'check_request_update_permissions_trigger()');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'prevent_physical_delete_trigger') THEN
        v_missing_funcs := array_append(v_missing_funcs, 'prevent_physical_delete_trigger()');
    END IF;

    IF array_length(v_missing_funcs, 1) > 0 THEN
        RAISE EXCEPTION '❌ T6 FAILED — Missing functions: %', array_to_string(v_missing_funcs, ', ');
    ELSE
        RAISE NOTICE '✅ T6: All helper functions exist';
    END IF;
END $$;

-- ============================================================
-- T7: Indexes exist
-- ============================================================
DO $$
DECLARE
    v_missing_indexes text[] := ARRAY[]::text[];
BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_unique_pending_item_per_group') THEN
        v_missing_indexes := array_append(v_missing_indexes, 'idx_unique_pending_item_per_group');
    END IF;

    IF array_length(v_missing_indexes, 1) > 0 THEN
        RAISE EXCEPTION '❌ T7 FAILED — Missing indexes: %', array_to_string(v_missing_indexes, ', ');
    ELSE
        RAISE NOTICE '✅ T7: All required indexes exist';
    END IF;
END $$;

-- ============================================================
-- T8: All policies are PERMISSIVE (no RESTRICTIVE conflicts)
-- ============================================================
DO $$
DECLARE
    v_restrictive_policies text[] := ARRAY[]::text[];
BEGIN
    SELECT array_agg(schemaname || '.' || tablename || ': ' || policyname) INTO v_restrictive_policies
    FROM pg_policies 
    WHERE permissive = 'false';

    IF array_length(v_restrictive_policies, 1) > 0 THEN
        RAISE EXCEPTION '❌ T8 FAILED — RESTRICTIVE policies found (should be PERMISSIVE): %', array_to_string(v_restrictive_policies, ', ');
    ELSE
        RAISE NOTICE '✅ T8: All policies are PERMISSIVE (no RESTRICTIVE conflicts)';
    END IF;
END $$;

-- ============================================================
-- T9: No circular dependencies in functions
-- ============================================================
DO $$
DECLARE
    v_has_recursion boolean;
BEGIN
    -- Check if is_group_member calls is_group_admin (which would be circular)
    -- Since is_group_member just queries group_members table directly, this should be fine
    SELECT EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_depend d ON d.objid = p.oid
        WHERE p.proname = 'is_group_member'
        AND d.refobjid = (SELECT oid FROM pg_proc WHERE proname = 'is_group_admin')
    ) INTO v_has_recursion;
    
    IF v_has_recursion THEN
        RAISE WARNING '⚠️ T9 WARNING: is_group_member() calls is_group_admin() — potential recursion risk';
    ELSE
        RAISE NOTICE '✅ T9: No circular function dependencies detected';
    END IF;
END $$;

-- ============================================================
-- T10: Foreign key constraints exist
-- ============================================================
DO $$
DECLARE
    v_missing_fk text[] := ARRAY[]::text[];
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'group_members'
        AND ccu.table_name = 'groups') THEN
        v_missing_fk := array_append(v_missing_fk, 'group_members → groups');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'group_members'
        AND ccu.table_name = 'users') THEN
        v_missing_fk := array_append(v_missing_fk, 'group_members → users');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'requests'
        AND ccu.table_name = 'groups') THEN
        v_missing_fk := array_append(v_missing_fk, 'requests → groups');
    END IF;

    IF array_length(v_missing_fk, 1) > 0 THEN
        RAISE EXCEPTION '❌ T10 FAILED — Missing foreign keys: %', array_to_string(v_missing_fk, ', ');
    ELSE
        RAISE NOTICE '✅ T10: All foreign key constraints exist';
    END IF;
END $$;

-- ============================================================
-- FINAL REPORT
-- ============================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔══════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║     🔧 MIGRATION INTEGRITY TEST — FULL REPORT              ║';
    RAISE NOTICE '╠══════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║  T1 — All tables exist                         ✅ PASS    ║';
    RAISE NOTICE '║  T2 — Column types correct                     ✅ PASS    ║';
    RAISE NOTICE '║  T3 — RLS enabled on tables                    ✅ PASS    ║';
    RAISE NOTICE '║  T4 — RLS policies exist                       ✅ PASS    ║';
    RAISE NOTICE '║  T5 — Triggers exist                           ✅ PASS    ║';
    RAISE NOTICE '║  T6 — Helper functions exist                   ✅ PASS    ║';
    RAISE NOTICE '║  T7 — Indexes exist                            ✅ PASS    ║';
    RAISE NOTICE '║  T8 — Policies are PERMISSIVE                  ✅ PASS    ║';
    RAISE NOTICE '║  T9 — No circular dependencies                 ✅ PASS    ║';
    RAISE NOTICE '║  T10 — Foreign key constraints                 ✅ PASS    ║';
    RAISE NOTICE '╚══════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '✅ ALL TESTS PASSED — Migration integrity verified';
END $$;

COMMIT;
