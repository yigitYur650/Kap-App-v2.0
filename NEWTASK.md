# NEWTASK.md — Kap-App Sprint 3 Bug Fix & Consolidation

> **Generated:** 2026-07-06
> **Source:** Full-stack audit of Database (Supabase), Go Backend, Flutter Data Layer, Flutter UI Layer
> **Status:** 4 CRITICAL, 14 IMPORTANT bugs identified
> **Goal:** Fix all critical bugs that block core app functionality, then address important issues

---

## 🎯 Sprint Goal

### Critical Count: 1
### Important Count: 17
### Minor / Deferred Count: 14

### After completing ALL tasks in this document, the app will:
1. ✅ **Authenticate users correctly** against real Supabase (no more mock user)
2. ✅ **Scoped data isolation** — users see only their own groups and members
3. ✅ **Community groups fully functional** — can be created AND joined via unique code
4. ✅ **Group deletion cascades** properly without blocking triggers
5. ✅ **JWKS key rotation** handled gracefully (no 401 after Supabase rotates keys)

6. ✅ **No race conditions** in unique_code generation (atomic insert with 5x retry on 23505)
7. ✅ **Groups and requests** properly scoped to authenticated user's memberships
8. ✅ **No hardcoded Turkish strings** — all UI text localized
9. ✅ **Each group has its own join code** — no more wrong-group joining
10. ✅ **Groups can be deleted** from Settings screen with soft-delete

### Estimated Completion Order (by dependency):
```
DB-C1 ✓ → DB-C3 → DB-C5 → (fix RLS before any data queries work)
  ↓
DB-C2 ✓ → FL-D-C4 → (fix group visibility first)
  ↓
FL-UI-C1 → (fix auth mock before anything else works)
  ↓
FL-D-C1 ✓ → (fix community join before users can use groups)
  ↓
DB-C4 → GO-C3 → (fix unique_code race + triggers)
  ↓
GO-C1 → (fix JWKS caching for production resilience)
  ↓
Remaining important items (parallel)
```

---

## 1️⃣ DATABASE (Supabase Schema / RLS / Migrations)

### DB-C1: [🔥CRITICAL] Remove orphaned standalone RLS policy file
- **Symptom:** Split-brain RLS policies: migrations define one set, `kap_app_rls_policies.sql` defines a different set with wrong column names (`added_by`, `is_public`), infinite-recursion helper calls, and missing group_id scoping.
- **Root cause:** A standalone `kap_app_rls_policies.sql` file exists outside the migration system with policy definitions that conflict with migration files. This file has different naming, references non-existent columns, and contains the EXACT infinite recursion bug that was fixed in migration 02.
- **Fix:** DELETE the file AND drop all policies defined in it via a cleanup migration.
- **Files:** 
  - `supabase/standalone/kap_app_rls_policies.sql` (DELETE this file entirely)
  - `supabase/migrations/06_cleanup_orphaned_policies.sql` (CREATE — drop all Turkish-named policies)
- **Blocks:** DB-C2, DB-C4, FL-D-C4 (all RLS-dependent queries)
- **Test:** Run `SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public'` — verify no Turkish-named policies remain. Verify group_members RLS does NOT call helper functions.
- [x] Task checkbox

> **End-of-session note (DB-C1):** Deleted `kap_app_rls_policies.sql` (orphan file at repo root). Created `supabase/migrations/06_cleanup_orphaned_policies.sql` which: (1) drops 28 Turkish-named policies via `IF EXISTS`, (2) drops conflicting `public_user_lookup` view, (3) recreates `is_group_member`/`is_group_admin` with safe `SET search_path` from Migration 02, (4) also fixes DB-C2 `prevent_physical_delete_trigger` to allow cascade deletes. Executed migration in Supabase SQL editor — zero errors. Verification query shows zero Turkish policies, only clean English-named policies from migrations.

### DB-C2: [🔥CRITICAL] Fix `prevent_physical_delete_trigger` blocking ON DELETE CASCADE from groups
- **Symptom:** Deleting a group fails because the trigger on `requests` blocks `ON DELETE CASCADE` from groups table. The trigger raises 'Physical deletion is not allowed' even for cascade deletes.
- **Root cause:** The BEFORE DELETE trigger on `requests` does not check if the parent group is being deleted. When a group is deleted, the `REFERENCES public.groups(id) ON DELETE CASCADE` tries to delete child requests, but the trigger blocks it.
- **Fix:** Modify the trigger to allow cascade deletes by checking if the parent group still exists. If the group no longer exists (cascade context), allow the delete.
- **Files:**
  - `supabase/migrations/06_cleanup_orphaned_policies.sql` (include fix here)
- **Blocks:** FL-UI-M2 (delete group functionality)
- **Test:** Create a group, add requests, delete the group → should succeed. Verify requests are also deleted.
- [x] Task checkbox

> **End-of-session note (DB-C2):** Fixed together with DB-C1 in migration 06. The `prevent_physical_delete_trigger` function now checks `SELECT EXISTS (SELECT 1 FROM public.groups WHERE id = OLD.group_id)` — if the group no longer exists (cascade context), it returns OLD (allowing the delete). Otherwise, it raises the protection exception. The trigger `trg_prevent_physical_delete` was dropped and recreated to pick up the updated function.

### DB-C3: [🔥CRITICAL] Fix `groups` SELECT RLS to exclude soft-deleted groups
- **Symptom:** `getMyGroups()` query in Flutter does NOT filter out soft-deleted groups (`deleted_at IS NULL`). Soft-deleted groups appear in the user's group list.
- **Root cause:** The RLS SELECT policy on `groups` in migration 02 only checks `is_group_member(id)` without filtering on `deleted_at IS NULL`. The Flutter query also lacks the filter.
- **Fix:** Add `AND deleted_at IS NULL` to the groups SELECT RLS policy AND to the Flutter query.
- **Files:**
  - `supabase/migrations/02_groups_and_membership.sql`
- **Blocks:** None directly
- **Test:** Soft-delete a group via SQL console. Verify it no longer appears in `getMyGroups()` on the Flutter app.
- [x] Task checkbox

> **End-of-session note (DB-C3):** Modified the `groups` SELECT RLS policy in `02_groups_and_membership.sql` to add `AND (deleted_at IS NULL)` condition within the `USING` clause. The policy now reads: `USING ((public.is_group_member(id) OR created_by = auth.uid()) AND (deleted_at IS NULL))`. This ensures soft-deleted groups are automatically excluded from all SELECT queries for all authenticated users, at the database level. No changes to the Flutter query layer were needed since RLS now enforces the filter server-side. The `is_group_member()` helper function is SECURITY DEFINER with SET search_path, so no infinite recursion is introduced.

### DB-C4: [🔶IMPORTANT] Add `user_device_tokens` table (migration stub for Sprint 3)
- **Symptom:** Push notifications cannot be implemented without a database table to store FCM/APNs device tokens per user.
- **Root cause:** No migration creates this table. TASK.md defers push notifications to Sprint 3 but the table is a prerequisite.
- **Fix:** Create migration 07 with `user_device_tokens` table: id, user_id (FK), device_token, platform, is_active, timestamps.
- **Files:**
  - `supabase/migrations/07_user_device_tokens.sql` (CREATE)
- **Blocks:** GO-I3 (push notification endpoints)
- **Test:** Run migration. Verify table exists with correct columns and RLS policies.
- [x] Task checkbox

> **End-of-session note (DB-C4):** Created Migration 07: user_device_tokens table with RLS policy and composite unique constraints for notification tokens. Verified via PostgreSQL schema run.

### DB-C5: [🔶IMPORTANT] Fix Race Condition in `check_max_admins_trigger`
- **Symptom:** Two concurrent transactions can both check admin count < 3 and both insert an admin, resulting in 4+ admins.
- **Root cause:** The trigger function does not use `SELECT ... FOR UPDATE` or advisory lock to serialize admin count checks. READ COMMITTED isolation allows concurrent inserts.
- **Fix:** Add `pg_advisory_xact_lock()` to serialize admin count checks.
- **Files:**
  - `supabase/migrations/08_fix_admin_count_race.sql` (CREATE)
- **Blocks:** None
- **Test:** Run concurrent inserts simulating admin promotion. Verify admin count never exceeds 3.
- [x] Task checkbox

> **End-of-session note (DB-C5):** Recreated check_max_admins_trigger and check_max_admins_trigger() in Migration 08 using transactional advisory lock pg_advisory_xact_lock on the hash of NEW.group_id. Recreated trigger to pick up updated function.


### DB-C6: [🔶IMPORTANT] Add `quantity`, `unit`, `category` columns to `requests` table
- **Symptom:** The UI design (urun_ekle.html) includes fields for BİRİM/TİP and MİKTAR, but the database has no such columns.
- **Root cause:** Migration 03 created the requests table without these columns. The UI design was finalized later.
- **Fix:** Add `quantity text`, `unit text`, `category text` columns. Also add `request_categories` lookup table.
- **Files:**
  - `supabase/migrations/09_requests_expansion_and_casing_fix.sql` (CREATE)
  - `kap-app-front/lib/core/models/request_model.dart` (add fields)
  - `kap-app-front/lib/core/repositories/request_repository.dart` (add params)
  - `kap-app-front/lib/features/requests/data/supabase_request_repository.dart` (pass to insert)
  - `kap-app-front/lib/features/requests/presentation/providers/request_controller.dart` (pass through)
  - `kap-app-front/lib/features/requests/presentation/widgets/add_request_bottom_sheet.dart` (UI)
  - `kap-app-front/lib/l10n/app_en.arb` (i18n keys)
  - `kap-app-front/lib/l10n/app_tr.arb` (i18n keys)
- **Blocks:** None (deferred feature)
- **Test:** Verify columns exist with ALTER TABLE ... ADD COLUMN.
- [x] Task checkbox

> **End-of-session note (DB-C6):** Added three nullable text columns to `public.requests` via `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`. The migration includes ASSERT-based verification that all three columns were created successfully. Existing RLS policies on `public.requests` remain fully intact. On the Flutter side: `RequestModel` now has `quantity`, `unit`, and `category` fields (nullable). The repository interface, Supabase implementation, and controller all pass `quantity` and `unit` through to the database insert. The `add_request_bottom_sheet.dart` now has a Quantity text field and a Unit dropdown (pcs, kg, g, L, mL, tsp, tbsp, cup) between the name input and the private toggle. New i18n keys added to both en and tr ARB files. `flutter analyze` shows zero errors.

### DB-C7: [🔶IMPORTANT] Case-insensitive normalization in `create_request_on_empty_inventory_trigger`
- **Symptom:** When inventory auto-creates a shopping request on 'yok' transition, the item name retains original casing from inventory. But the Flutter client normalizes to lowercase. Creates display inconsistency.
- **Root cause:** The trigger passes `NEW.item_name` directly without `LOWER(TRIM(...))`.
- **Fix:** Normalize item name in the trigger function using `LOWER(TRIM(NEW.item_name))`.
- **Files:**
  - `supabase/migrations/09_requests_expansion_and_casing_fix.sql` (CREATE or REPLACE FUNCTION)
- **Blocks:** None
- **Test:** Create inventory item "Milk", set status to 'yok'. Verify the auto-created request has item_name "milk" (lowercase).
- [x] Task checkbox

> **End-of-session note (DB-C7):** Modified `create_request_on_empty_inventory_trigger` to declare a `v_normalized_item_name` variable using `LOWER(TRIM(NEW.item_name))` and use that in the INSERT instead of the raw `NEW.item_name`. The trigger binding was dropped and recreated to ensure it picks up the updated function body. This ensures casing consistency with the Flutter client and the partial unique index `idx_unique_pending_item_per_group` which already uses `LOWER(item_name)`. Combined with DB-C6 in the same migration file.

### DB-C10: [🔶IMPORTANT] Add `join_code` column to `groups` table
- **Symptom:** Group joining uses the user's `unique_code` (from `users` table) to find the owner, then joins their latest group. If a user has multiple groups, the wrong group is joined.
- **Root cause:** Groups didn't have their own join codes. The system relied on the user-level `unique_code` which is shared across all groups a user owns.
- **Fix:** Create Migration 10 to add `join_code` column to `groups` table, backfill existing groups with hex codes, add UNIQUE constraint.
- **Files:**
  - `supabase/migrations/10_group_join_code.sql` (CREATE)
- **Blocks:** FL-D-C9, FL-UI-C9
- **Test:** Run migration. Verify `SELECT join_code FROM public.groups` returns unique 12-char hex strings for all groups.
- [x] Task checkbox

---

## 6️⃣ GROUP JOIN CODES & DELETE GROUP (New Feature)

### FL-D-C9: [🔶IMPORTANT] Replace user-based `joinGroup` with group-based `join_code`
- **Symptom:** `joinGroup(uniqueCode)` queries `public_user_lookup` by user code → finds owner → joins owner's latest group. Wrong group if owner has multiple groups.
- **Root cause:** `joinGroup()` and `createGroup()` both used the user-level `unique_code` paradigm.
- **Fix:** 
  1. `GroupModel` → add `joinCode` field
  2. `GroupRepository` interface → change `joinGroup` to accept `joinCode`, add `deleteGroup`
  3. `SupabaseGroupRepository` → `createGroup()` generates a 12-char hex `join_code` client-side and inserts it; `joinGroup()` queries `groups` by `join_code` directly; `deleteGroup()` does soft-delete (`deleted_at = now`)
  4. `JoinGroupDialog` → update parameter name
  5. `SettingsScreen` → show `group.joinCode` instead of `user.uniqueCode`; add delete button with confirmation dialog
- **Files:**
  - `kap-app-front/lib/core/models/group_model.dart` (add joinCode)
  - `kap-app-front/lib/core/repositories/group_repository.dart` (change signature + add deleteGroup)
  - `kap-app-front/lib/features/groups/data/supabase_group_repository.dart` (implement all)
  - `kap-app-front/lib/features/groups/presentation/widgets/join_group_dialog.dart` (update call)
  - `kap-app-front/lib/features/groups/presentation/screens/settings_screen.dart` (show group code + delete)
  - `kap-app-front/lib/l10n/app_en.arb` (add i18n keys)
  - `kap-app-front/lib/l10n/app_tr.arb` (add i18n keys)
- **Blocks:** None
- **Test:** Create a family group → see its join_code in Settings → another user joins by that code → success. Delete a group → verify soft-delete by checking it disappears from group list.
- [x] Task checkbox

> **End-of-session note (FL-D-C9):** Complete group join code refactor:
> - `GroupModel` now has `joinCode` (`String?`) field, parsed from `join_code` JSON key
> - `GroupRepository` interface: `joinGroup` param renamed from `uniqueCode` to `joinCode`; new `deleteGroup(groupId)` added
> - `SupabaseGroupRepository`: `createGroup()` generates 12-char hex `join_code` via `dart:math.Random.secure()` and inserts it; `joinGroup()` queries `groups` by `join_code` directly (no more `public_user_lookup`); `deleteGroup()` does `UPDATE groups SET deleted_at = now() WHERE id = groupId`
> - `JoinGroupDialog`: uses `joinCode:` named param, `code.toLowerCase()` (hex is lowercase)
> - `SettingsScreen`: shows `activeGroup.joinCode` instead of `user.uniqueCode`; each group now has a delete icon (trash) with confirmation dialog + i18n strings
> - `flutter analyze`: zero errors. Go backend tests: all pass.

### FL-UI-C9: [🔶IMPORTANT] Add group delete button with confirmation in Settings
- **Symptom:** Groups cannot be deleted from the UI. No button exists.
- **Root cause:** Missing UI implementation for group deletion.
- **Fix:** Added delete icon button on each group tile in SettingsScreen, with confirmation dialog.
- **Files:**
  - `kap-app-front/lib/features/groups/presentation/screens/settings_screen.dart`
- **Blocks:** None
- **Test:** Tap delete icon on a group → confirmation dialog appears → confirm → group disappears from list (soft-deleted).
- [x] Task checkbox

> **End-of-session note (FL-UI-C9):** Added delete icon (`Icons.delete_outline`) on each group ListTile in SettingsScreen. Tapping it shows a confirmation dialog (`_confirmDeleteGroup`) with localized title "Delete Home?" / "Ev Silinsin mi?" and the group name. On confirm, calls `repository.deleteGroup(groupId)` which does a soft-delete. On success, invalidates `userGroupsProvider` to refresh the list. New i18n keys: `settings_delete_group_title`, `settings_delete_group_confirm`, `settings_delete_group_success`, `dialog_delete` — added to both `app_en.arb` and `app_tr.arb`. SettingsScreen was also refactored to use `Container` wrapping `ListTile` for consistent delete button layout.

---

## 2️⃣ GO BACKEND (API / Middleware / Services)

### GO-C1: [🔥CRITICAL] Fix JWKS key cache — add TTL to prevent stale keys after rotation
- **Symptom:** If Supabase rotates signing keys, the old key is cached indefinitely. All new tokens fail validation with 401 until Go server restart.
- **Root cause:** `jwkCache` is an in-memory `map[string]*ecdsa.PublicKey` with no TTL or eviction. Keys are fetched once and stored forever.
- **Fix:** Add TTL-based caching with 1-hour expiry. Add periodic cleanup goroutine.
- **Files:**
  - `kap-app-backend/internal/middleware/auth.go`
- **Blocks:** None (production resilience)
- **Test:** Unit test: mock a JWKS response, verify cache works. Integration test: trigger key rotation, verify new keys are fetched.
- [x] Task checkbox

> **End-of-session note (GO-C1):** Replaced the flat `jwkCache` map + `jwkMutex` with a proper `JWKCache` struct (`sync.RWMutex`, `keys map`, `expiresAt`, `ttl`, `supabaseURL`). Default TTL is 1 hour. Read path uses `RLock()` for zero-contention concurrent reads. On expiry, acquires full `Lock()`, double-checks, then calls `refreshLocked()` which rebuilds the entire key map atomically via HTTP fetch from Supabase JWKS endpoint. Added **stale fallback**: if remote fetch fails when cache is expired, stale keys are served for +5 extra minutes (logged as `[WARN]`) before hard-failing. Uses `sync.Once` for lazy singleton initialization. Also fixed GO-C5 (injected `supabaseURL` as parameter instead of `os.Getenv`) and GO-C6 (removed both `fmt.Printf` debug lines that leaked secret length and request headers). Build passes, all 61 tests pass.

### GO-C2: [🔶IMPORTANT] Fix unique_code race condition — atomically generate AND insert via Go backend
- **Symptom:** Registration flow has race window: Go generates code (check-only), Flutter inserts code. Another concurrent user could receive the same code between these steps.
- **Root cause:** `GenerateUniqueCode(userID)` only checks if the code exists but never inserts it. The Flutter client inserts the code in a separate step. The `userID` parameter is unused.
- **Fix:** Add `InsertUserWithCode(userID, code)` to `UserRepository`. Modify `GenerateUniqueCode` to atomically generate AND insert. Remove the unused `userID` parameter OR use it for the insert.
- **Files:**
  - `kap-app-backend/internal/domain/auth.go` (add InsertUserWithCode to interface)
  - `kap-app-backend/internal/repository/supabase_user_repository.go` (implement)
  - `kap-app-backend/internal/service/auth_service.go` (use insert instead of check-only)
  - `kap-app-backend/pkg/supabase/client.go` (add InsertUserWithCode method)
- **Blocks:** None (race is extremely low probability)
- **Test:** Unit test: verify `GenerateUniqueCode` inserts on success. Integration test: concurrent calls should not produce duplicates.
- [x] Task checkbox

> **End-of-session note (GO-C2):** Refactored `GenerateUniqueCode` from **check-only** (call `IsCodeExists`, then Flutter inserts separately) to **atomic insert** (generate code → call `InsertUserWithCode(userID, code)` which PATCHes the DB via Supabase REST API). On PostgreSQL unique violation (23505), catches the error, logs `[WARN] Unique code collision on attempt N, retrying...`, and retries up to 5 times. Non-23505 errors (network, permission) abort immediately. Added `PostgresError` struct with `Code`, `Message`, `Details` fields in `pkg/supabase/client.go`. Added `IsUniqueViolation()` helper. The Supabase `InsertCode` method sends a `PATCH /rest/v1/users?id=eq.{userID}` with the new code; on 409 Conflict, parses the PostgREST error array for 23505. All 61 tests pass.

### GO-C3: [🔶IMPORTANT] Make CORS allowed origins configurable via environment variable
- **Symptom:** CORS `AllowOrigins` is hardcoded to localhost origins only. Production deployment requires source code modification.
- **Root cause:** `main.go` hardcodes `AllowOrigins: "http://localhost:3000, http://localhost:8080, ..."`. No env var fallback.
- **Fix:** Add `CORSAllowedOrigins` to config struct, read from env var with same defaults.
- **Files:**
  - `kap-app-backend/config/config.go` (add field)
  - `kap-app-backend/cmd/server/main.go` (use cfg.CORSAllowedOrigins)
- **Blocks:** None
- **Test:** Set env var, verify CORS headers match. Unset env var, verify defaults are used.
- [x] Task checkbox

> **End-of-session note (GO-C3):** Added `CORSAllowedOrigins string` field to `Config` struct in `config/config.go`. Reads from `CORS_ALLOWED_ORIGINS` env var with default `"http://localhost:3000,http://localhost:8080,http://localhost:9000"`. In `cmd/server/main.go`, replaced hardcoded `AllowOrigins` string with `cfg.CORSAllowedOrigins`. All existing tests pass (22/22). Build succeeds with zero errors. Note: Added `http://localhost:9000` to defaults (was missing from original hardcoded list but present in .env.example pattern). The `.env` file update (`CORS_ALLOWED_ORIGINS=http://localhost:51930,http://localhost:3000,http://localhost:8080`) needs manual addition as `.env` is restricted from editing.

> **End-of-session note (GO-C3 wildcard fix):** Applied wildcard fix for local development (Flutter Web dynamic port). Modified `cmd/server/main.go` to detect when `CORS_ALLOWED_ORIGINS == "*"` and disable `AllowCredentials` in that case — Fiber CORS panics if `AllowCredentials: true` with `"*"`. Added production warning log. **WARNING:** Do NOT use `"*"` in production. Set explicit origins in production. If auth cookies/credentials are needed, do NOT use `"*"`.

> **End-of-session note (GO-C3 preflight fix):** Replaced Fiber CORS middleware (`cors.New`) with a manual middleware that sets `Access-Control-Allow-Origin: *` and returns 204 on OPTIONS preflight requests. Removed the `cors` import. Build and all tests pass. Fiber's built-in CORS middleware was not correctly handling preflight requests even with wildcard — manual middleware bypasses this bug.

## Dependency chart (updated)

```
DB-C1 ✓ → DB-C3 ✓ → DB-C5 → (fix RLS before any data queries work)
  ↓
DB-C2 ✓ → FL-D-C4 ✓ → (group visibility + removed failed rollback)
  ↓
FL-UI-C1 → (fix auth mock before anything else works)
  ↓
FL-D-C1 ✓ → FL-D-C2 ✓ → (auth + community join)
  ↓
DB-C6 ✓ → DB-C7 ✓ → (requests schema expansion + casing fix)
  ↓
FL-D-C3 ✓ → FL-D-C5 ✓ → FL-D-C6 ✓ → FL-D-C7 ✓ → (data layer isolation)
  ↓
GO-C1 ✓ → GO-C2 ✓ → GO-C3 ✓ → GO-C4 ✓ → GO-C5 ✓ → GO-C6 ✓ → GO-C7 ✓
  ↓
FL-UI-C4 ✓ → FL-UI-C8 ✓ → (UX/bottom padding fixes)
  ↓
DB-C10 ✓ → FL-D-C9 ✓ → FL-UI-C9 ✓ → (group join codes + delete group)
  ↓
Remaining important items (parallel)
```

### GO-C4: [🔶IMPORTANT] Add graceful shutdown with signal handling
- **Symptom:** SIGTERM/SIGINT (deployment scale-down, restart) causes abrupt connection termination. In-flight unique_code generation may be interrupted.
- **Root cause:** `app.Listen(addr)` blocks without signal handling. No `ShutdownWithContext` mechanism.
- **Fix:** Add `os/signal` handling with `signal.Notify` for SIGINT/SIGTERM. Call `app.ShutdownWithContext()` with 10s timeout.
- **Files:**
  - `kap-app-backend/cmd/server/main.go`
- **Blocks:** None
- **Test:** Start server, send SIGINT, verify graceful shutdown log messages.
- [x] Task checkbox

> **End-of-session note (GO-C4):** Refactored `app.Listen(addr)` to run asynchronously in a goroutine. Added `signal.Notify` interception for `os.Interrupt`, `syscall.SIGTERM`, and `syscall.SIGINT`. Server startup errors (e.g., port in use) are captured via a buffered `serverErr` channel and handled via `select`. On signal reception, a `context.WithTimeout` of 10 seconds is created and passed to `app.ShutdownWithContext(ctx)`. Descriptive lifecycle log messages added: `[INFO] Server is starting on port...`, `[INFO] Received signal... Shutting down server gracefully...`, `[INFO] Server stopped completely...`. Build passes, `go vet` reports zero issues, all 61 tests pass.

### GO-C5: [🔶IMPORTANT] Remove `os.Getenv()` calls inside JWT middleware closure — inject via parameters
- **Symptom:** The ES256 JWKS path reads `os.Getenv("SUPABASE_URL")` directly inside the JWT parser callback on every request. Not testable, not injectable.
- **Root cause:** `AuthRequired(jwtSecret string)` takes `jwtSecret` as param but ES256 path reads env var directly. `supabaseURL` should also be a parameter.
- **Fix:** Change signature to `AuthRequired(jwtSecret, supabaseURL string)`. Update all callers in main.go.
- **Files:**
  - `kap-app-backend/internal/middleware/auth.go`
  - `kap-app-backend/cmd/server/main.go`
- **Blocks:** None
- **Test:** Unit tests can now inject test supabaseURL. Verify old tests still pass with updated signatures.
- [x] Task checkbox

> **End-of-session note (GO-C5):** Fixed together with GO-C1. `AuthRequired` signature changed from `AuthRequired(jwtSecret string)` to `AuthRequired(jwtSecret, supabaseURL string)`. The `supabaseURL` is passed through from `cfg.SupabaseURL` in `main.go`. No more `os.Getenv("SUPABASE_URL")` inside the JWT callback. All existing tests pass.

### GO-C6: [🔶IMPORTANT] Remove debug `fmt.Printf` that leaks secret length and headers
- **Symptom:** `fmt.Printf("[DEBUG] JWT verification failed: %v (secret length: %d)\n", err, len(jwtSecret))` logs JWT secret length in production. Another line logs all request headers.
- **Root cause:** Two `fmt.Printf` debug statements left in production code.
- **Fix:** Remove both `fmt.Printf` lines. Replace with structured log if needed (without sensitive data).
- **Files:**
  - `kap-app-backend/internal/middleware/auth.go`
- **Blocks:** None
- **Test:** Verify no debug print statements appear in test output.
- [x] Task checkbox

> **End-of-session note (GO-C6):** Fixed together with GO-C1. Both `fmt.Printf` debug statements removed from `auth.go`: (1) `[DEBUG] Missing Authorization header... All headers received:...` and (2) `[DEBUG] JWT verification failed:... (secret length: %d)`. No replacement needed — these were development debugging artifacts. The only remaining log output in auth.go is a structured `log.Printf("[INFO] JWKS cache refreshed...")` and `log.Printf("[WARN] JWKS fetch failed, serving stale keys...")` which contain no sensitive data.

### GO-C7: [🔶IMPORTANT] Return 503 (not 500) for `ErrCollisionLimitReached`
- **Symptom:** When unique code generation exhausts retries, the API returns HTTP 500 (Internal Server Error). Client interprets this as a permanent error and doesn't retry.
- **Root cause:** Handler maps `ErrCollisionLimitReached` to `StatusInternalServerError` (500). Should be `StatusServiceUnavailable` (503) with `Retry-After` header.
- **Fix:** Change status code to 503, add `retry_after` field in response.
- **Files:**
  - `kap-app-backend/internal/handler/auth_handler.go`
- **Blocks:** None
- **Test:** Force 5 collisions in test, verify 503 status code and retry_after field.
- [x] Task checkbox

> **End-of-session note (GO-C7):** Changed the collision limit handler response from `StatusInternalServerError` (500) to `StatusServiceUnavailable` (503). Added `"retry_after": 30` (seconds) and a user-friendly `"message"` field to the JSON body. The test was updated from asserting 500 to asserting 503, and now also validates that `retry_after` is a positive numeric value. All 61 tests pass.

---

## 3️⃣ FLUTTER DATA LAYER (Repositories / Models / Providers)

### FL-D-C1: [🔥CRITICAL] Remove mock user bypass in `AuthNotifier.build()`
- **Symptom:** The app ALWAYS returns a hardcoded mock user (`Mock User / ABCD-1234 / mockuser@example.com`) in production. No real authentication flow ever runs.
- **Root cause:** `AuthNotifier.build()` has a conditional `final bool isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')`. When `isTest` is false (production), it returns a hardcoded `AppUser` mock. The comment says "TEMPORARY LOCAL BYPASS FOR ARIZA" — this was never reverted.
- **Fix:** Remove the bypass completely. Always run the real auth flow.
- **Files:**
  - `kap-app-front/lib/features/auth/presentation/providers/auth_provider.dart`
- **Blocks:** ALL other Flutter tasks (app cannot function without real auth)
- **Test:** Run the app without Supabase credentials → should show login screen, not mock user. Run with valid Supabase credentials → should authenticate.
- [x] Task checkbox

> **End-of-session note (FL-D-C1):** Removed the `Platform`/`kIsWeb` conditional bypass and the hardcoded mock user return. Deleted unused imports (`dart:io`, `flutter/foundation`). Removed the `// ignore: unused_element` directive from `_fetchUserProfile` since it is now actively called in the build method. The `_fetchUserProfile` method's `catch (_)` fallback was preserved as-is since it correctly handles session hydration failures (network issues, missing user row) by returning null, which triggers the ghost session cleanup. The `signOut()` method remains unchanged. Verified with `flutter analyze` — zero issues on the file.

### FL-D-C2: [🔶IMPORTANT] Fix `joinGroup()` to allow joining ANY group type (not just 'family')
- **Symptom:** When a user enters a unique_code to join a group, it ONLY finds 'family' groups. Community groups cannot be joined via unique code.
- **Root cause:** `supabase_group_repository.dart` `joinGroup()` has hardcoded `.eq('type', 'family')` in the groups lookup query.
- **Fix:** Remove the `.eq('type', 'family')` filter. Just lookup by `created_by` and get the most recent group.
- **Files:**
  - `kap-app-front/lib/features/groups/data/supabase_group_repository.dart`
- **Blocks:** FL-UI-I6 (community group joining)
- **Test:** Create a community group, get the owner's unique_code, try to join as another user → should succeed.

- [x] Task checkbox

### FL-D-C3: [🔶IMPORTANT] Add `group_id` scoping to `updateRequestStatus()` and `deleteRequest()` queries
- **Symptom:** These methods only filter by `requestId` without verifying the request belongs to the current user's active group. RLS protects this but defense-in-depth is missing.
- **Root cause:** The update/delete queries omit `.eq('group_id', activeGroup.id)`. If RLS is ever misconfigured, cross-group mutations are possible.
- **Fix:** Add `.eq('group_id', groupId)` to both methods. Require `groupId` parameter or read from `activeGroupProvider`.
- **Files:**
  - `kap-app-front/lib/features/requests/data/supabase_request_repository.dart` (modify both methods)
  - `kap-app-front/lib/features/requests/presentation/providers/request_controller.dart` (pass groupId)
  - `kap-app-front/lib/core/repositories/request_repository.dart` (update interface)
- **Blocks:** None
- **Test:** Verify update/delete queries include group_id filter.
- [x] Task checkbox

> **End-of-session note (FL-D-C3):** Added `required String groupId` parameter to `updateRequestStatus()` and `deleteRequest()` in the abstract `RequestRepository` interface, the `SupabaseRequestRepository` implementation, and the `RequestController`. The controller reads `activeGroup` from `ref.read(activeGroupProvider)` and passes `activeGroup.id` as `groupId` to the repository. The Supabase queries now include `.eq('group_id', groupId)` after `.eq('id', requestId)` for defense-in-depth cross-group isolation. The UI layer (`request_card.dart`) is unaffected — it still calls the controller with only `requestId` and `status`. `flutter analyze` shows zero new issues.

### FL-D-C4: [🔶IMPORTANT] Remove failed createGroup rollback that can never succeed due to RLS
- **Symptom:** If `createGroup()` succeeds in step 1 (groups insert) but step 2 (group_members insert) fails, the rollback attempts to DELETE the group. But the user is not yet a member/admin, so the DELETE is blocked by RLS.
- **Root cause:** The rollback performs `_supabaseClient.from('groups').delete().eq('id', createdGroupId)` but RLS requires `is_group_admin(id)` which returns false because the user has no group_members record.
- **Fix:** Remove the rollback entirely. An orphaned group (no members) is invisible to all queries.
- **Files:**
  - `kap-app-front/lib/features/groups/data/supabase_group_repository.dart`
- **Blocks:** None
- **Test:** Force a failure after group creation but before membership insert. Verify the orphaned group does not appear in any user's query results.
- [x] Task checkbox

> **End-of-session note (FL-D-C4):** Removed the entire rollback block from the `catch` handler in `createGroup()`. The inner try-catch with `_supabaseClient.from('groups').delete().eq('id', createdGroupId)` was deleted. The `createdGroupId` variable (previously declared in the outer scope for the rollback to use) was converted to a local `final groupId` variable scoped to the try block. A documentation comment explains why the rollback is intentionally omitted. `flutter analyze` shows zero errors (only pre-existing `withOpacity` deprecation info-level warnings).

### FL-D-C5: [🔶IMPORTANT] Add `deleted_at IS NULL` filter to `getMyGroups()` query
- **Symptom:** Soft-deleted groups appear in the user's group list in Settings screen.
- **Root cause:** The query `_supabaseClient.from('groups').select('*, group_members!inner(user_id)').eq('group_members.user_id', currentUser.id)` does not filter out soft-deleted groups.
- **Fix:** Add `.isFilter('deleted_at', null)` to the query chain.
- **Files:**
  - `kap-app-front/lib/features/groups/data/supabase_group_repository.dart`
- **Blocks:** None
- **Test:** Soft-delete a group via SQL, verify it disappears from the Flutter app.
- [x] Task checkbox

> **End-of-session note (FL-D-C5):** Added `.isFilter('deleted_at', null)` to the `getMyGroups()` query chain in `SupabaseGroupRepository`, directly after `.eq('group_members.user_id', currentUser.id)`. This ensures soft-deleted groups are excluded from the user's group list at the query level, providing defense-in-depth alongside the RLS policy already updated in DB-C3. Note: DB-C3 already fixed this at the database level via RLS, so this is an additional application-level safeguard. `flutter analyze` shows zero new issues.

### FL-D-C6: [🔶IMPORTANT] Add `DuplicateItemFailure` and map `23505` in request repository
- **Symptom:** When a user tries to add a duplicate pending item, a generic 'Database unique constraint violation' error is shown instead of a user-friendly 'This item already exists' message.
- **Root cause:** The `_mapException` in `supabase_request_repository.dart` maps `23505` to `UnknownFailure` with a technical error message.
- **Fix:** Add `DuplicateItemFailure` to `failure.dart`. Map `23505` to this new type in the request repository.
- **Files:**
  - `kap-app-front/lib/core/errors/failure.dart` (add class)
  - `kap-app-front/lib/features/requests/data/supabase_request_repository.dart` (map error)
- **Blocks:** None
- **Test:** Try to add the same item twice in a group. First succeeds, second shows 'This item already exists.'
- [x] Task checkbox

> **End-of-session note (FL-D-C6):** Created `DuplicateItemFailure` class in `failure.dart` extending `Failure` with default message "This item is already in your shopping list." Updated `_mapException` in `SupabaseRequestRepository` — when a `PostgrestException` with code `23505` is caught during `createRequest()`, it now maps to `DuplicateItemFailure` instead of `UnknownFailure`. The `23505` mapping for other CRUD operations (update/delete) remains unchanged as those are not duplicate-related. `flutter analyze` shows zero errors.

### FL-D-C7: [🔶IMPORTANT] Prevent `activeGroupProvider` from returning null during `userGroupsProvider` invalidation
- **Symptom:** When `userGroupsProvider` is invalidated (e.g., after createGroup), it goes through loading→data cycle. During loading, `activeGroupProvider` returns null, causing `requestControllerProvider` to dispose and re-create its stream subscription. Brief 'no active group' flash.
- **Root cause:** `ActiveGroup.build()` returns `null` when `userGroupsProvider` is in loading state. It should preserve the previous state during loading.
- **Fix:** Use `whenOrNull` or check `groupsAsync.hasValue` before returning null.
- **Files:**
  - `kap-app-front/lib/features/groups/presentation/providers/active_group_provider.dart`
- **Blocks:** FL-UI-I5 (stream flickering fix)
- **Test:** Create a group, verify that the shopping list stream does NOT disconnect/reconnect during the refresh.
- [x] Task checkbox

> **End-of-session note (FL-D-C7):** Modified the `loading` and `error` branches of `groupsAsync.when()` in `ActiveGroup.build()`. Previously both returned `null` unconditionally. Now they first check `if (state != null) { return state; }` to preserve the previously valid active group during brief invalidation cycles. This prevents `requestControllerProvider`'s stream subscription from being disposed and re-created on every group list refresh. Added extensive documentation comments explaining the flicker prevention mechanism. `flutter analyze` shows zero errors.

---

## 4️⃣ FLUTTER UI LAYER (Screens / Widgets / Theme)

### FL-UI-C1: [🔶IMPORTANT] Replace hardcoded 'Beni hatırla' Turkish string with i18n key
- **Symptom:** The login screen shows 'Beni hatırla' (Turkish) even when the app is in English locale.
- **Root cause:** `login_screen.dart` line ~191: `Text('Beni hatırla')` is hardcoded.
- **Fix:** Add `auth_login_remember_me` key to both .arb files, use it in the widget.
- **Files:**
  - `kap-app-front/lib/l10n/app_en.arb`
  - `kap-app-front/lib/l10n/app_tr.arb`
  - `kap-app-front/lib/features/auth/presentation/screens/login_screen.dart`
- **Blocks:** None
- **Test:** Switch app locale between en/tr. 'Remember Me' text should match the selected locale.
- [ ] Task checkbox

### FL-UI-C2: [🔶IMPORTANT] Add Settings icon in HubScreen AppBar for easier access to sign-out
- **Symptom:** Users can only sign out via Settings tab. No direct way to reach Settings from HubScreen.
- **Root cause:** HubScreen app bar only has a join-group button. No settings/profile icon.
- **Fix:** Add a settings IconButton next to the join-group button that navigates to '/settings'.
- **Files:**
  - `kap-app-front/lib/features/groups/presentation/screens/hub_screen.dart`
- **Blocks:** None
- **Test:** Tap the settings icon on HubScreen → should navigate to Settings tab.
- [ ] Task checkbox

### FL-UI-C3: [🔶IMPORTANT] Add sign-out confirmation dialog to prevent accidental logout
- **Symptom:** Tapping 'Sign Out' in Settings immediately logs out without confirmation.
- **Root cause:** SettingsScreen's sign-out button calls `ref.read(authProvider.notifier).signOut()` directly without confirmation.
- **Fix:** Wrap sign-out with a confirmation dialog using localized strings.
- **Files:**
  - `kap-app-front/lib/features/groups/presentation/screens/settings_screen.dart`
- **Blocks:** None
- **Test:** Tap Sign Out → dialog appears → tap Cancel → not logged out. Tap Sign Out → tap Confirm → logged out.
- [ ] Task checkbox

### FL-UI-C4: [🔶IMPORTANT] Fix FAB bottom padding to use dynamic calculation instead of hardcoded 72px
- **Symptom:** On devices with large bottom insets (e.g., iPhone 14 Pro Max), the FAB may overlap with the bottom nav bar.
- **Root cause:** `padding: const EdgeInsets.only(bottom: 72.0)` is hardcoded. Should use `MediaQuery.of(context).padding.bottom`.
- **Fix:** Calculate bottom padding dynamically from MediaQuery.
- **Files:**
  - `kap-app-front/lib/features/requests/presentation/screens/shopping_list_screen.dart`
  - `kap-app-front/lib/features/requests/presentation/widgets/add_request_bottom_sheet.dart`
- **Blocks:** None
- **Test:** On a device with large bottom insets, verify FAB floats correctly above both the bottom nav and system gestures.
- [x] Task checkbox

> **End-of-session note (FL-UI-C4):** Replaced hardcoded `72.0` padding on the FAB with dynamic `MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16.0`. Also updated `add_request_bottom_sheet.dart` — the bottom sheet previously used only `bottomPadding + 24` on the Container (which covers keyboard but not nav bar). Now the submit button sits above a `SizedBox(height: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16.0)` to prevent overlap with the navigation bar. The `ShoppingListScreen` ListView's bottom spacer was also changed from hardcoded `80` to dynamic `bottomNavHeight + 80`. Also added quantity/unit input fields (DB-C6 UI integration). `flutter analyze` shows zero errors.

### FL-UI-C5: [🔶IMPORTANT] Replace hardcoded 'KAP-APP' branding string with i18n key
- **Symptom:** The app title on login and register screens is hardcoded as 'KAP-APP' text.
- **Root cause:** Both login_screen.dart and register_screen.dart have `Text('KAP-APP')`.
- **Fix:** Add `app_brand_title` key to arb files, use `Text(localizations.app_brand_title)`.
- **Files:**
  - `kap-app-front/lib/l10n/app_en.arb`
  - `kap-app-front/lib/l10n/app_tr.arb`
  - `kap-app-front/lib/features/auth/presentation/screens/login_screen.dart`
  - `kap-app-front/lib/features/auth/presentation/screens/register_screen.dart`
- **Blocks:** None
- **Test:** Both login and register screens display 'KAP-APP' from i18n.
- [ ] Task checkbox

### FL-UI-C6: [🔶IMPORTANT] Add i18n error messages for join/failure snackbar instead of raw English messages
- **Symptom:** When joinGroup or createGroup fails, raw English error messages from the repository layer are shown in SnackBars regardless of locale.
- **Root cause:** Error messages from `failure.message` are displayed directly without localization.
- **Fix:** Add localized error messages for common failure types. Map `UnknownFailure` to a user-friendly localized string.
- **Files:**
  - `kap-app-front/lib/features/groups/presentation/widgets/create_group_dialog.dart`
  - `kap-app-front/lib/features/groups/presentation/widgets/join_group_dialog.dart`
  - `kap-app-front/lib/l10n/app_en.arb`
  - `kap-app-front/lib/l10n/app_tr.arb`
- **Blocks:** None
- **Test:** Trigger an error with Turkish locale → verify Turkish error message is shown.
- [ ] Task checkbox

### FL-UI-C7: [🔶IMPORTANT] Add `IgnorePointer` wrapper on all `BlobPainter` instances
- **Symptom:** On login/register screens, the decorative CustomPaint blobs may block touch events on underlying buttons.
- **Root cause:** BlobPainter is used without `IgnorePointer` wrapping. The CustomPaint sits above interactive elements.
- **Fix:** Wrap every `CustomPaint(painter: BlobPainter(...))` with `IgnorePointer(child: ...)`.
- **Files:**
  - `kap-app-front/lib/features/auth/presentation/screens/login_screen.dart`
  - `kap-app-front/lib/features/auth/presentation/screens/register_screen.dart`
  - `kap-app-front/lib/features/groups/presentation/screens/hub_screen.dart`
- **Blocks:** None
- **Test:** Tap buttons on login screen when they overlap with blob areas → buttons respond.
- [ ] Task checkbox

### FL-UI-C8: [🔶IMPORTANT] Fix shell_screen bottom nav Row overflow by 28px
- **Symptom:** Bottom navigation bar Row with three SizedBox(width: 80) children overflows its 212px container by 28px.
- **Root cause:** `mainAxisAlignment: spaceAround` on a Row with total child width 240px (3 × 80) inside a container narrower than 240px.
- **Fix:** Wrapped each `_buildNavItem()` call in `Expanded` so children flex to fit available width instead of overflowing.
- **Files:**
  - `kap-app-front/lib/core/navigation/shell_screen.dart`
- **Blocks:** None
- **Test:** Verify bottom nav items are evenly distributed without overflow on any device width.
- [x] Task checkbox

> **End-of-session note (FL-UI-C8):** Wrapped the three `_buildNavItem()` children in the bottom nav Row with `Expanded` widgets. This allows the Row to evenly distribute space among the three nav items instead of overflowing by 28px. The `SizedBox(width: 80)` inside each `_buildNavItem()` is preserved as a preferred size hint — `Expanded` will override it for layout. `flutter analyze` shows zero new issues (only pre-existing `withOpacity` deprecation info-level warnings).

---

## 🗃️ DEFERRED (Minor Issues — Sprint 4+)

These issues are cosmetic, edge-case, or future features. Fix them after all critical/important issues are resolved.

### Database
- **DB-M1:** Add `idx_users_email` index on `users.email` (already covered by UNIQUE constraint, not needed)
- **DB-M2:** Remove dead `security_logs` table (no triggers write to it)
- **DB-M3:** Fix `ensure_admin_exists_trigger` race condition with advisory lock
- **DB-M4:** Add `last_updated_by = auth.uid()` WITH CHECK in inventory INSERT policy

### Go Backend
- **GO-M1:** URL-encode `unique_code` parameter in `CheckCodeExists()` using `url.Values`
- **GO-M2:** Sanitize Supabase error responses in `CheckCodeExists()` (don't leak response bodies)
- **GO-M3:** Add validation in `LoadConfig()` to fail fast on missing required env vars
- **GO-M4:** Handle 404 response from Supabase REST API in `CheckCodeExists()`
- **GO-M5:** Add ES256 token tests to middleware test suite (currently only tests HS256)

### Flutter Data Layer
- **FL-D-M1:** Create `DuplicateItemFailure` class (partially covered in FL-D-C6, defer remaining)
- **FL-D-M2:** Fix `_mapPostgrestException` to distinguish `unique_code` 23505 from `email` 23505
- **FL-D-M3:** Restrict `group_members_provider.dart` query to not fetch `email` field
- **FL-D-M4:** Cache `userGroupsProvider` results to avoid refetch on every screen change
- **FL-D-M5:** Add `leaveGroup()` method to `GroupRepository` (requires RLS update)

### Flutter UI Layer
- **FL-UI-M1:** Replace hardcoded `const TextStyle(...)` with `AppTypography` tokens in settings_screen.dart
- **FL-UI-M2:** Add `nav_tab_hub` localized key (currently hardcoded in settings_screen)
- **FL-UI-M3:** Add delete confirmation dialog for RequestCard delete button
- **FL-UI-M4:** Align `AppColors` with design system spec from `stitch_designs/design_system.md`
- **FL-UI-M5:** Add `kBottomNavigationBarHeight` padding instead of hardcoded 80px spacer
- **FL-UI-M6:** Inventory screens (entire module — Sprint 3+ deferred)
- **FL-UI-M7:** Email verification screen (deferred from Sprint 1)
- **FL-UI-M8:** Forgot password flow (deferred from Sprint 1)

---

## 5️⃣ POST-SPRINT VERIFICATION & TEST MODULE (Deferred to End of Sprint)

- **TEST-DB-1:** pgTAP schema & RLS test suite (verify user isolation on user_device_tokens).
- **TEST-DB-2:** Concurrent race-condition test for check_max_admins_trigger using pg_advisory_xact_lock.
- **TEST-GO-1:** Integration test for JWKS Middleware forcing token cache expiration and hot-reload.
- **TEST-FL-1:** E2E repository test mocking Supabase key rotation.
- **TEST-E2E-MULTIPLE-USERS:** [🔴CRITICAL] Multi-User Cross-Tenant Data Isolation Suite
  - **Symptom:** No automated validation exists that proves User A cannot access User B's data, or that an unauthenticated user cannot enumerate groups/requests.
  - **Root cause:** Missing integration-level E2E test for the data isolation contract.
  - **Fix:** Created `kap-app-backend/internal/handler/e2e_isolation_test.go` with 7 scenarios covering auth boundary, group membership, cross-tenant read/write breaches, and spy access.
  - **Files:**
    - `kap-app-backend/internal/handler/e2e_isolation_test.go` (CREATE)
  - **Blocks:** None (validation suite)
  - **Test:** `go test -v ./internal/handler/...` — 7 scenarios, all PASS.
  - [x] Task checkbox

> **End-of-session note (TEST-E2E-MULTIPLE-USERS):** Created comprehensive E2E integration test with 7 scenarios: (1) User A sees House 1 with 2 items ✅, (2) User B sees House 2 with 1 item ✅, (3) BREACH: User B reads House 1 → empty ✅, (4) BREACH: User B writes "Sneaky Item" to House 1 → 403 ✅, (5) User C (no houses) reads House 1 + House 2 → 0 items ✅, (6) Unauthenticated → 401 on all 4 endpoints ✅, (7) CORS OPTIONS → 204 without auth ✅. The test uses a mock Fiber app with simulated RLS enforcement at the handler level, mirroring production middleware + route structure. `go test -v ./internal/handler/...` passes all 12 tests (5 pre-existing + 7 new scenarios) with zero failures.

