# bug-and-fix.md — Kap-App

> Every bug encountered during development must be logged here before a fix is applied.
> Rule: Never patch. Understand the root cause fully, then fix safely.
> Format is strict — do not skip fields.

---

## Template

```
## [YYYY-MM-DD] Short descriptive title

**Symptom:**
What was observed. Error message, screen behavior, log output.

**Root cause:**
Why it happened. Be specific — which function, which assumption was wrong.

**Fix:**
What changed. Which file, which line, what was replaced with what.

**Risk:**
What other parts of the codebase could be affected by this fix.
List any tests that were re-run to confirm no regression.

**Status:** resolved / open / deferred
```

---

<!-- Entries below this line are added chronologically -->

## [2026-06-25] Flutter Localizations Synthetic Package Removal

**Symptom:**
Running `flutter gen-l10n` failed with:
`l10n.yaml: Cannot enable "synthetic-package", this feature has been removed. See http://flutter.dev/to/flutter-gen-deprecation.`

**Root cause:**
The "synthetic-package" feature (which generates localizations inside `.dart_tool/flutter_gen`) was deprecated and removed in recent Flutter versions. The localization generator now expects localizations to be generated directly in the local folder (`lib/l10n/`).

**Fix:**
Removed `synthetic-package: true` from `l10n.yaml` and updated the imports in `lib/main.dart` and `lib/core/navigation/router.dart` from `package:flutter_gen/gen_l10n/app_localizations.dart` to `package:kap_app_front/l10n/app_localizations.dart`.

**Risk:**
Generated files are now located under the `lib/l10n/` directory and will be committed to git. Clean build artifact tracking is maintained.

**Status:** resolved

---

## [2026-06-25] Non-Constant Element in Constant List literal in main.dart

**Symptom:**
`flutter analyze` failed with:
`error - The values in a const list literal must be constants. Try removing the keyword 'const' from the list literal - lib\main.dart:49:9 - non_constant_list_element`

**Root cause:**
The `AppLocalizations.delegate` class property is evaluated at runtime and is not a compile-time constant, so it cannot be included in a `const` list literal for `localizationsDelegates`.

**Fix:**
Removed the `const` keyword from the `localizationsDelegates` list literal in `lib/main.dart`.

**Risk:**
Very low. It just changes compile-time instantiation to runtime list instantiation for delegates.

**Status:** resolved

---

## [2026-06-25] Supabase.initialize anonKey Deprecation Warning

**Symptom:**
`flutter analyze` reported:
`info - 'anonKey' is deprecated and shouldn't be used. Use publishableKey instead. anonKey will be removed in a future major version. Try replacing the use of the deprecated member with the replacement - lib\main.dart:23:5 - deprecated_member_use`

**Root cause:**
In the latest version of `supabase_flutter` (`^2.15.0`), the `anonKey` parameter of `Supabase.initialize` has been deprecated and replaced with `publishableKey`.

**Fix:**
Changed `anonKey: supabaseAnonKey` to `publishableKey: supabaseAnonKey` in `lib/main.dart`.

**Risk:**
None. It complies with the latest API changes of the supabase package.

**Status:** resolved

---

## [2026-06-25] MyApp widget test compiler error after renaming to KapApp

**Symptom:**
`flutter analyze` failed with:
`error - The name 'MyApp' isn't a class. Try correcting the name to match an existing class - test\widget_test.dart:16:35 - creation_with_non_type`

**Root cause:**
The default `widget_test.dart` created by `flutter create` referenced the class `MyApp` and expected counter widget test behaviors. We renamed the app class in `main.dart` to `KapApp` and replaced the boilerplate layout, causing test errors.

**Fix:**
Updated `test/widget_test.dart` to a clean smoke test verifying the `KapApp` boilerplate compiles and mounts a `Placeholder` successfully.

**Risk:**
None. The test covers the initial boilerplate layout.

**Status:** resolved

---

## [2026-06-25] Hardening Supabase SQL search_path and users SELECT Policy

**Symptom:**
Database functions were subject to potential search path injection exploits when setting `search_path = ''`, preventing standard operators and internal schemas from resolving cleanly. Also, standard RLS policies for `users` blocked required authenticated lookup discovery for active group members.

**Root cause:**
1. Setting `search_path = ''` on `SECURITY DEFINER` database helper functions prevents standard types/functions (like `public` relation resolution and basic `pg_catalog` operations) from executing without full qualification, causing operational overhead or runtime query failures.
2. The initial restrictive SELECT policy on `users` (`id = auth.uid()`) prevented authenticated users from looking up other group members' display names and unique codes.

**Fix:**
1. Modified `is_group_member` and `is_group_admin` stubs to configure `SET search_path = public, pg_catalog` to allow standard and secure schema resolution.
2. Added the balanced RLS policy `Allow authenticated SELECT on active users` with `USING (deleted_at IS NULL)` to `users` to permit lookup capabilities while keeping deleted accounts isolated.
3. Created the migration SQL script [01_base_infrastructure.sql](file:///c:/Users/yigit/OneDrive/Desktop/kap-app-full/supabase/migrations/01_base_infrastructure.sql).

**Risk:**
Allowing authenticated select on all active users exposes `display_name`, `email`, and `unique_code` to other logged-in users. However, since this is a community app where users must interact via display names and unique codes, this exposure is intentional. Sensitive data fields (like auth hashes or roles) remain fully protected under `auth` schema or audit logs.

**Status:** resolved

---

## [2026-06-25] Hardening Groups & Membership RLS and Triggers

**Symptom:**
1. RLS policies on `group_members` using helper functions `is_group_member()` or `is_group_admin()` caused infinite recursion loop deadlocks.
2. Group administrators could demote or evict the original group creator.
3. Updating non-role fields of an admin failed if the group already had 3 admins due to the check_max_admins_trigger.
4. Cascading deletes of a group caused ensure_admin_exists_trigger to fail.

**Root cause:**
1. RLS policies evaluate conditions by querying the same table. If helper functions are called, they execute new SELECT queries which re-trigger RLS recursively.
2. `group_members` policies did not distinguish the group creator (`groups.created_by`) from other admins.
3. The check_max_admins_trigger evaluated `NEW.role = 'admin'` during updates without checking if the role was *already* 'admin' before the update.
4. The admin backup trigger did not check if the parent group still existed, failing when the entire group relation was cascades-deleted.

**Fix:**
1. Rewrote `group_members` RLS policies using pure SQL `EXISTS` subqueries instead of function calls.
2. Updated the `group_members` DELETE policy to block anyone from deleting the user who matches the `groups.created_by` field.
3. Updated the `group_members` UPDATE policy `WITH CHECK` constraint to ensure the creator's role must always be `admin`.
4. Fixed `check_max_admins_trigger` to run only on `INSERT` or when the role actually changes to admin (`OLD.role <> 'admin'`).
5. Added a group existence check (`public.groups` exists) and an empty-group member count check (`v_total_count = 0`) to `ensure_admin_exists_trigger` to exit gracefully.
6. Created migration script [02_groups_and_membership.sql](file:///c:/Users/yigit/OneDrive/Desktop/kap-app-full/supabase/migrations/02_groups_and_membership.sql).

**Risk:**
None. These adjustments prevent infinite loops and protect group owners from admin takeovers, while ensuring correct trigger execution during cascading deletes.

**Status:** resolved

---

## [2026-06-25] Hardening Shopping Requests RLS and Case-Insensitive Unique Check

**Symptom:**
1. Administrators could potentially alter non-status columns (such as `item_name` or `requested_by`) of shopping requests they do not own.
2. Duplicate pending items could be inserted with varying cases (e.g. "Milk" vs "milk"), causing duplicate items on lists.
3. Physical deletions could remove audit records.

**Root cause:**
1. Standard PostgreSQL RLS policies operate at the row level. A simple UPDATE policy allowing admins to update a row lets them update any column unless guarded.
2. Case-sensitive indexes permit variations in casing for duplicate items.
3. Defining standard DELETE policies allows physical delete, violating auditable data retention guidelines.

**Fix:**
1. Implemented [03_shopping_requests.sql](file:///c:/Users/yigit/OneDrive/Desktop/kap-app-full/supabase/migrations/03_shopping_requests.sql).
2. Restricted UPDATE policies using a BEFORE UPDATE trigger: if an admin (who is not the owner) updates the row, the trigger throws an exception if any column other than `status` is modified.
3. Hardened the owner's UPDATE checks in the trigger: blocked non-admin owners from changing the `status` column (must remain 'pending'), while allowing owners who are also group administrators to do so.
4. Created a partial unique index `idx_unique_pending_item_per_group` using `LOWER(item_name)` to enforce case-insensitivity on pending items.
5. Added an architectural rule: All application queries matching or checking `item_name` duplicates MUST use the `LOWER()` function to utilize the index.
6. Implemented a BEFORE DELETE trigger `trg_prevent_physical_delete` to block physical deletes, forcing soft deletes by setting `deleted_at = now()`.

**Risk:**
Strictly enforcing case-insensitivity via LOWER() requires all database insertions/searches for duplicates to use LOWER(). The frontend and backend service code must adhere to this rule.

**Status:** resolved

---

## [2026-06-25] Hardening Inventory Management RLS, Auditing, and Automated Request Triggers

**Symptom:**
1. RLS SELECT policy on `inventory_log` required a performance-intensive subquery join against the `inventory` table.
2. System-triggered programmatic updates (where `auth.uid()` is null) overwrote existing human metadata for `last_updated_by` with NULL.
3. Automated request insertion trigger would fail on `ON CONFLICT` due to targeted expression mismatch with the partial unique index.

**Root cause:**
1. The initial log table design did not store `group_id` directly, requiring joining `inventory` to evaluate `is_group_member()`.
2. A simple `NEW.last_updated_by = auth.uid()` statement in a BEFORE UPDATE trigger unconditionally overwrites the column even if the current operation is from a system context.
3. PostgreSQL requires the `ON CONFLICT` clause to exactly replicate index target columns, expressions, and where conditions of partial unique indexes.

**Fix:**
1. Implemented [04_inventory_management.sql](file:///c:/Users/yigit/OneDrive/Desktop/kap-app-full/supabase/migrations/04_inventory_management.sql).
2. Added the redundant `group_id` column to `inventory_log` to optimize SELECT RLS policies.
3. Used `NEW.last_updated_by = COALESCE(auth.uid(), OLD.last_updated_by)` in `maintain_inventory_metadata_trigger` during updates to preserve the last human updater.
4. Hardened `log_inventory_status_change_trigger` to run on `INSERT` to record initial creation logs (with `old_status = NULL`).
5. Added exact partial target parameters to the trigger's `ON CONFLICT` clause to match `idx_unique_pending_item_per_group`.

**Risk:**
None. Performance is optimized, metadata audit trails are preserved, and syntax errors during conflict resolution are resolved.

**Status:** resolved

---

## [2026-06-25] Hardening Recipes & Lookup View RLS, Null FK Actions, and Lookup Filters

**Symptom:**
1. Potential crash on user deletion due to NOT NULL constraint on `recipes.created_by` combined with `ON DELETE SET NULL`.
2. Usability lock on `recipe_items` preventing owners or group admins from editing or removing ingredients.
3. Lookup view returned zero rows when executed in session-less contexts due to `id <> auth.uid()`.

**Root cause:**
1. A database foreign key defined as `ON DELETE SET NULL` on a `NOT NULL` column triggers a constraint violation exception during parent row deletion.
2. The initial design completely blocked physical deletion on `recipe_items` without providing a soft delete (`deleted_at`) field, making ingredients permanent.
3. In SQL, comparison with NULL (e.g. `id <> NULL`) evaluates to `UNKNOWN` (treated as false), filtering out all records if `auth.uid()` is NULL.

**Fix:**
1. Removed `NOT NULL` constraint from `recipes.created_by` to let `ON DELETE SET NULL` work.
2. Added `DELETE` RLS policies for `recipe_items` granting access to the recipe creator and group administrators.
3. Configured the `public_user_lookup` view with `(auth.uid() IS NULL OR id <> auth.uid())` to bypass session filters if executed outside an authenticated user session.
4. Created migration script [05_recipes_and_lookup.sql](file:///c:/Users/yigit/OneDrive/Desktop/kap-app-full/supabase/migrations/05_recipes_and_lookup.sql).

**Risk:**
None. User deletes are safe from crashes, recipe editing is fully functional, and lookup view query behaviors are hardened.

**Status:** resolved

---

## [2026-06-26] Ghost Session Deadlock on startup

**Symptom:**
If a user account was suspended or soft-deleted in Supabase, but the user had a locally cached auth token, the app would enter a deadlock/loading loop on startup because `supabase.auth.currentSession` existed, but user profile fetching from `public.users` returned null.

**Root cause:**
The Riverpod `AuthProvider` notifier's `build()` method checked if a session was present and returned a profile lookup, but did not handle the case where the lookup returns `null` (suspended or deleted profile). This left the session active on the client but profile data missing, causing presentation deadlocks.

**Fix:**
Modified `AuthProvider.build()` initialization logic to check if profile lookup returns `null` when a session is active. If so, it calls `await supabaseClient.auth.signOut()` to programmatically clean up the client-side session and returns `null`.

**Risk:**
Low. Resolves startup deadlock loop. The user will be correctly logged out. Verified with unit and integration tests.

**Status:** resolved

---

## [2026-06-26] Request Repository functional lowercase index mapping

**Symptom:**
Inserting shopping requests with varying case or untrimmed whitespace might trigger unexpected unique constraint violations or bypass database optimization indexes designed to prevent duplicate pending list items.

**Root cause:**
The database is configured with a case-insensitive partial unique index `idx_unique_pending_item_per_group` on `LOWER(item_name)`. If the client does not normalize the item names when querying or inserting, PostgreSQL may not utilize the functional index efficiently or may throw duplicate errors on variations (e.g. "Milk" vs "milk").

**Fix:**
Enforced name normalization in the data layer inside `lib/features/requests/data/supabase_request_repository.dart` by executing `itemName.toLowerCase().trim()` before passing it to insert/update or check operations.

**Risk:**
Very low. It ensures all item requests are stored in a canonical, lowercase, and trimmed format which perfectly aligns with index constraints.

**Status:** resolved

---

## [2026-06-26] Technical Debt Clearance Sweep

**Symptom:**
Several code smell issues and architectural flaws were found during technical auditing:
1. `RequestController` was using `throw failure` inside folding, causing uncaught exceptions in the UI/Notifier layers (HATA-5).
2. `AddRequestBottomSheet` lacked validation to check if `_selectedMemberId` is null when `isPrivate` is enabled, bypassing check constraints and risking DB error crashes (HATA-6).
3. The auth repository masked all HTTP errors (such as unique code generation limits) as generic `NetworkFailure`, hiding collision errors (HATA-11).
4. `getRequestsStream` streamed all rows and relied on in-memory soft-delete filtering due to API limitations without documenting it (HATA-12).

**Root cause:**
1. Error handling in riverpod was not properly projecting failures using state assignment.
2. Form validator did not evaluate conditional inputs like private request recipients.
3. Backend Go endpoint errors were parsed globally as network failures instead of decoding the response payload error fields.
4. Supabase Realtime streams syntax only supports simple equality (`eq`) filters.

**Fix:**
1. Removed `throw failure` and assigned `state = AsyncError(failure, StackTrace.current)` in all mutations of `RequestController`.
2. Disabled the submit button and added visual warning labels in `AddRequestBottomSheet` when `isPrivate` is true and `_selectedMemberId` is null.
3. Added `ServerFailure` and `CollisionFailure` classes to `failure.dart` and implemented JSON decoding of error responses in `SupabaseAuthRepository`. Modified the Go handler in `auth_handler.go` to return specific `collision_limit_reached` JSON errors when appropriate.
4. Added tradeoff documentation to `supabase_request_repository.dart` headers regarding client-side soft-deleted filtering.

**Risk:**
No regressions. All 113 front-end tests and backend Go tests successfully passed.

**Status:** resolved

---

## [2026-06-26] AddRequestBottomSheet state sync and global error listener refactoring

**Symptom:**
Form submission in `AddRequestBottomSheet` resulted in unexpected sheet dismissal or incorrect loading/error states when reacting to concurrent mutations in the global requests stream.

**Root cause:**
The widget was previously listening to a global stream provider for sheet pop actions, meaning list changes caused by other users could trigger early or unintended pops. Additionally, the asynchronous submission used explicit try/catch blocks which bypassed proper state-driven Riverpod error propagation.

**Fix:**
1. Replaced the try/catch logic in the local `_submit()` method of `AddRequestBottomSheet` with local asynchronous execution.
2. Wrapped the execution trigger in a local state update `setState(() => _isSubmitting = true)`.
3. Verified failure via `ref.read(requestControllerProvider).hasError` post-await and only dismissed the bottom sheet if no error occurred and the widget is still `mounted`.
4. Utilized `ref.listen` on `requestControllerProvider` to catch errors globally and safely reset `_isSubmitting = false`.
5. Replaced all hardcoded string literals inside `AddRequestBottomSheet` with localization keys (`add_request_private_recipient_required`).

**Risk:**
None. All 113 front-end tests pass cleanly. Local submission state is fully isolated from concurrent global stream changes.

**Status:** resolved

---

## [2026-06-26] Supabase JWT verification failure on Go backend (401 Unauthorized)

**Symptom:**
Authenticated requests from the Flutter client (such as generating a unique sharing code during registration) failed with HTTP status `401 Unauthorized` in the Go backend.

**Root cause:**
Supabase JWT tokens are signed using the base64-decoded raw bytes of the `SUPABASE_JWT_SECRET`. However, the Go backend's `AuthRequired` middleware was parsing the secret as a raw ASCII string literal via `[]byte(jwtSecret)`. Due to this signature key mismatch, signature verification failed.

**Fix:**
Modified `internal/middleware/auth.go` to attempt base64 decoding of the `jwtSecret` first. If decoding fails (like with raw test secrets in unit tests), it falls back to the original `[]byte(jwtSecret)` conversion to maintain backwards compatibility.

**Risk:**
None. Checked with `go test ./...` and confirmed all unit tests pass. Fully local to the authentication middleware.

**Status:** resolved



