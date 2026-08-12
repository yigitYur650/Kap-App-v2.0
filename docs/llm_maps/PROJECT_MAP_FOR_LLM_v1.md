# 🗺️ Kap-App — Complete Project Map for LLM Agents

> **Purpose:** This file is designed to be read by an LLM agent at the start of every session.
> It contains the full structural fingerprint of the project, all architectural decisions,
> known technical debt, error handling patterns, and database schema — so the LLM can
> operate without reading every single file first.
>
> **Last updated:** 2026-06-26
> **Status:** Sprint 2 ready (Inventory UI pending)

---

## 1. 🏗️ PROJECT OVERVIEW

**Kap-App** is a shared household/community shopping and inventory management app.
Users join groups via a unique code, manage shared shopping requests, track home inventory
(in stock / low / out), and send private requests visible only to a specific member.

| Layer | Technology |
|---|---|
| Mobile | **Flutter 3.x** (Dart) — iOS + Android |
| State management | **Riverpod 3** (`flutter_riverpod` — `AsyncNotifier`, `Notifier`, `FutureProvider.family`) |
| Auth + DB + Realtime | **Supabase** (`supabase_flutter` — Auth, PostgreSQL, Realtime streams) |
| Business logic API | **Go** (Fiber v2 framework) — runs separately |
| Navigation | **go_router** |
| Validation | **formz** |
| Local persistence | **shared_preferences** |
| i18n | **flutter_localizations** + **intl** (`.arb` files for `en` and `tr`) |
| Testing (Flutter) | **flutter_test** + **mocktail** — 14 test files, ~113 tests |
| Testing (Go) | **stdlib testing** + **testify** — 3 test files |
| Functional error handling | **fpdart** (`Either<Failure, T>`) — no exceptions thrown to UI |

---

## 2. 📁 FOLDER STRUCTURE

```
kap-app/
├── .agent/
│   ├── PROJECT_BRIEF.md              ← Master brief (injected at session start)
│   ├── TASK.md                        ← Sprint tasks + daily progress
│   ├── bug-and-fix.md                 ← All bugs logged before fix
│   └── PROJECT_MAP_FOR_LLM.md        ← THIS FILE
├── kap-app-front/                    ← Flutter mobile app
│   └── lib/
│       ├── main.dart
│       ├── l10n/                      ← Generated localization files
│       ├── core/
│       │   ├── errors/
│       │   │   ├── failure.dart       ← Failure hierarchy (see §6)
│       │   │   └── app_error.dart     ← AppError wrapper
│       │   ├── models/
│       │   │   ├── app_user.dart      ← AppUser model
│       │   │   ├── group_model.dart   ← GroupModel
│       │   │   └── request_model.dart ← RequestModel
│       │   ├── navigation/
│       │   │   └── router.dart        ← GoRouter + auth redirect guard
│       │   ├── network/
│       │   │   └── supabase_client.dart ← SupabaseClient provider
│       │   ├── providers/
│       │   │   └── shared_preferences_provider.dart
│       │   └── repositories/         ← Abstract interfaces only
│       │       ├── auth_repository.dart
│       │       ├── group_repository.dart
│       │       └── request_repository.dart
│       ├── features/
│       │   ├── auth/
│       │   │   ├── data/
│       │   │   │   └── supabase_auth_repository.dart
│       │   │   ├── presentation/
│       │   │   │   ├── models/         ← Formz inputs
│       │   │   │   │   ├── email_input.dart
│       │   │   │   │   ├── password_input.dart
│       │   │   │   │   ├── display_name_input.dart
│       │   │   │   │   └── confirmed_password_input.dart
│       │   │   │   ├── providers/
│       │   │   │   │   ├── auth_provider.dart        ← AuthNotifier (ghost session fix)
│       │   │   │   │   ├── login_controller.dart
│       │   │   │   │   ├── login_state.dart
│       │   │   │   │   ├── register_controller.dart
│       │   │   │   │   └── register_state.dart
│       │   │   │   └── screens/
│       │   │   │       ├── login_screen.dart
│       │   │   │       └── register_screen.dart
│       │   │   └── providers/         ← Repository provider
│       │   │       └── auth_repository_provider.dart
│       │   ├── groups/
│       │   │   ├── data/
│       │   │   │   └── supabase_group_repository.dart
│       │   │   ├── presentation/
│       │   │   │   ├── providers/
│       │   │   │   │   ├── active_group_provider.dart
│       │   │   │   │   ├── user_groups_provider.dart
│       │   │   │   │   └── group_members_provider.dart
│       │   │   │   ├── screens/
│       │   │   │   │   └── group_members_screen.dart
│       │   │   │   └── widgets/
│       │   │   │       ├── group_switcher_widget.dart
│       │   │   │       └── group_switcher_bottom_sheet.dart
│       │   │   └── providers/
│       │   │       └── group_repository_provider.dart
│       │   ├── requests/
│       │   │   ├── data/
│       │   │   │   └── supabase_request_repository.dart
│       │   │   ├── presentation/
│       │   │   │   ├── providers/
│       │   │   │   │   └── request_controller.dart
│       │   │   │   ├── screens/
│       │   │   │   │   └── shopping_list_screen.dart
│       │   │   │   └── widgets/
│       │   │   │       ├── add_request_bottom_sheet.dart
│       │   │   │       └── request_card.dart
│       │   │   └── providers/
│       │   │       └── request_repository_provider.dart
│       │   └── home/
│       │       └── presentation/screens/home_screen.dart  ← Placeholder
│       └── shared/
│           ├── theme/
│           │   ├── app_colors.dart
│           │   ├── app_typography.dart
│           │   ├── app_theme.dart
│           │   └── app_shapes.dart    ← BlobPainter (organic background)
│           └── widgets/
├── kap-app-backend/                  ← Go API server
│   ├── cmd/server/main.go
│   ├── config/config.go
│   ├── internal/
│   │   ├── domain/
│   │   │   └── auth.go               ← UserRepository + AuthService interfaces
│   │   ├── handler/
│   │   │   ├── auth_handler.go       ← GenerateCode handler
│   │   │   └── auth_handler_test.go
│   │   ├── service/
│   │   │   ├── auth_service.go       ← GenerateUniqueCode + collision retry
│   │   │   └── auth_service_test.go
│   │   ├── repository/
│   │   │   └── supabase_user_repository.go
│   │   └── middleware/
│   │       ├── auth.go              ← JWT validation middleware
│   │       └── auth_test.go
│   └── pkg/supabase/
│       └── client.go                ← Supabase admin HTTP client wrapper
└── supabase/
    └── migrations/
        ├── 01_base_infrastructure.sql
        ├── 02_groups_and_membership.sql
        ├── 03_shopping_requests.sql
        ├── 04_inventory_management.sql
        └── 05_recipes_and_lookup.sql
```

---

## 3. 🔄 RIVERPOD STATE LAYOUT (Critical — LLMs must understand this)

### 3.1 Provider Dependency Graph

```
authProvider (AsyncNotifier<AppUser?>)
  ├── builds: checks supabaseClient.auth.currentSession
  │            → fetches profile from public.users
  │            → if profile null → signOut() [GHOST SESSION HOTFIX]
  └── used by: router redirect guard, LoginScreen, RegisterScreen

activeGroupProvider (Notifier<GroupModel?>)
  ├── watches: userGroupsProvider + sharedPreferencesProvider
  ├── build: finds groups from userGroupsProvider, checks cached ID
  ├── cache invalidation: removes stale cached IDs asynchronously
  └── used by: requestControllerProvider, ShoppingListScreen

userGroupsProvider (FutureProvider<List<GroupModel>>)
  └── calls: groupRepository.getMyGroups()

groupMembersProvider (FutureProvider.family<List<GroupMemberWithProfile>, String>)
  └── param: groupId → queries group_members + users join

requestControllerProvider (AsyncNotifier<List<RequestModel>>)
  ├── watches: activeGroupProvider (only — NOT userGroupsProvider)
  ├── builds: subscribes to repository.getRequestsStream(groupId)
  ├── auto-disposes stream via ref.onDispose()
  └── methods: createRequest, updateRequestStatus, deleteRequest
```

### 3.2 Key Architectural Rule — Request Stream Separation

`requestControllerProvider` depends on `activeGroupProvider` (a single GroupModel?), NOT on
`userGroupsProvider` (the full list). This prevents infinite rebuild loops:
- `userGroupsProvider` fetches all groups → could change activeGroup → triggers rebuild
- If requests depended on userGroupsProvider, any group change would re-subscribe ALL streams

### 3.3 Auto-Dispose Controllers

`loginControllerProvider` and `registerControllerProvider` are `NotifierProvider.autoDispose`
— they are automatically disposed when no longer watched (e.g., after navigation).

---

## 4. ⚡ DATA FLOW PATTERNS

### 4.1 Mutation Flow (All mutations follow this exact pattern)

```
Widget/Call
  → Provider method (e.g., requestController.createRequest)
    → Repository method (returns Either<Failure, T>)
      → .fold(
          (failure) => state = AsyncError(failure, StackTrace.current),
          (_) => {/* success — stream auto-updates state */},
        )
```

### 4.2 Read Flow (Stream-based)

```
build()
  → activeGroupProvider.watch
    → repository.getRequestsStream(groupId)
      → .listen() → state = AsyncData(requests)
      → onError → state = AsyncError(err, stack)
```

### 4.3 ❗ KNOWN ANTIPATTERN (DO NOT REPLICATE)

`add_request_bottom_sheet.dart` still has a `try/catch` around `createRequest()`:
```dart
try {
  await ref.read(requestControllerProvider.notifier).createRequest(...);
  if (mounted) Navigator.of(context).pop();
} catch (e) {
  // THIS NEVER FIRES — createRequest no longer throws
}
```
This is **Technical Debt TB-1**: the `catch` block is dead code because `createRequest`
now uses `state = AsyncError(...)` instead of `throw`. Fix needed.

---

## 5. 🗄️ DATABASE SCHEMA (Supabase PostgreSQL)

### 5.1 Tables

#### `users` (01_base_infrastructure.sql)
| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK → auth.users(id) ON DELETE CASCADE |
| display_name | text | NOT NULL |
| unique_code | text | UNIQUE NOT NULL |
| email | text | UNIQUE NOT NULL |
| email_verified | boolean | DEFAULT false |
| is_invitable | boolean | DEFAULT true |
| account_status | text | CHECK ('active','suspended','deleted') |
| created_at | timestamptz | DEFAULT now() |
| deleted_at | timestamptz | nullable |

**RLS:** Own profile read/update, authenticated SELECT on active users (deleted_at IS NULL)

#### `groups` (02_groups_and_membership.sql)
| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK DEFAULT gen_random_uuid() |
| name | text | NOT NULL |
| type | text | CHECK ('family','community') |
| created_by | uuid | → users(id) |
| created_at | timestamptz | DEFAULT now() |
| deleted_at | timestamptz | nullable |

#### `group_members` (02_groups_and_membership.sql)
| Column | Type | Constraints |
|---|---|---|
| user_id | uuid | PK → users(id) ON DELETE CASCADE |
| group_id | uuid | PK → groups(id) ON DELETE CASCADE |
| role | text | CHECK ('admin','member') |
| joined_at | timestamptz | DEFAULT now() |

**RLS:** EXISTS subqueries (NO function calls to avoid recursion).
**Creator protection:** DELETE/UPDATE policies prevent creator demotion/removal.
**Triggers:** Max 3 admins, auto-ensure-admin-exists on delete.

#### `requests` (03_shopping_requests.sql)
| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| group_id | uuid | NOT NULL → groups(id) ON DELETE CASCADE |
| requested_by | uuid | NOT NULL → users(id) |
| item_name | text | NOT NULL |
| is_private | boolean | DEFAULT false |
| private_to | uuid | → users(id) |
| status | text | DEFAULT 'pending', CHECK ('pending','done') |
| created_at | timestamptz | DEFAULT now() |
| deleted_at | timestamptz | nullable |

**Unique index:** `idx_unique_pending_item_per_group` on `(group_id, LOWER(item_name))` WHERE `status='pending' AND deleted_at IS NULL AND is_private=false`
**RLS:** Members see non-private + own private + private_to. Private requests require `private_to` in group_members.
**Triggers:** 
- `check_request_update_permissions_trigger`: Admin can only change `status`; owner (pending) can change non-status fields but status change requires admin.
- `prevent_physical_delete_trigger`: Blocks DELETE, forces soft-delete via `deleted_at`.

#### `inventory` (04_inventory_management.sql)
| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| group_id | uuid | NOT NULL → groups(id) ON DELETE CASCADE |
| item_name | text | NOT NULL |
| status | text | DEFAULT 'var', CHECK ('var','azaldı','yok') |
| last_updated_by | uuid | → users(id) ON DELETE SET NULL |
| last_updated_at | timestamptz | |
| created_at | timestamptz | DEFAULT now() |
| deleted_at | timestamptz | nullable |

**Triggers:**
- `maintain_inventory_metadata_trigger`: Sets `last_updated_at = now()`, `last_updated_by = COALESCE(auth.uid(), OLD.last_updated_by)` (preserves human updater on system updates)
- `log_inventory_status_change_trigger`: INSERT -> initial log; UPDATE -> log on status change
- `create_request_on_empty_inventory_trigger`: When status becomes 'yok' → auto-insert pending shopping request (ON CONFLICT DO NOTHING)

**NOTE:** Flutter `InventoryRepository` is NOT YET IMPLEMENTED (Sprint 2 W1-4).

#### `recipes` + `recipe_items` (05_recipes_and_lookup.sql)
- Created for future Sprint 3+ use
- `recipes.created_by` is NULLABLE (ON DELETE SET NULL fix from bug-and-fix.md)
- `recipe_items` has DELETE policies for creator/admin
- `public_user_lookup` view: security_barrier view filtering active, invitable users excluding self

### 5.2 Helper Functions

```sql
is_group_member(p_group_id uuid) → boolean  -- SECURITY DEFINER, STABLE
is_group_admin(p_group_id uuid) → boolean   -- SECURITY DEFINER, STABLE
```
Both use `SET search_path = public, pg_catalog`

### 5.3 Indexes

| Index | Table | Columns | Condition |
|---|---|---|---|
| `idx_users_lookup` | users | (is_invitable, account_status, id) | WHERE is_invitable=true AND account_status='active' AND deleted_at IS NULL |
| `idx_unique_pending_item_per_group` | requests | (group_id, LOWER(item_name)) | WHERE status='pending' AND deleted_at IS NULL AND is_private=false |
| `idx_unique_active_inventory` | inventory | (group_id, LOWER(item_name)) | WHERE deleted_at IS NULL |
| `idx_inventory_log_group` | inventory_log | (group_id) | — |

---

## 6. ❌ ERROR HANDLING HIERARCHY

### 6.1 Flutter Failure Types (`lib/core/errors/failure.dart`)

```
Failure (abstract)
├── EmailAlreadyInUseFailure    — "The email address is already in use..."
├── NetworkFailure             — "A network error occurred..."
├── InvalidCredentialsFailure  — "Invalid email or password."
├── UnknownFailure             — Wraps raw error messages
├── ServerFailure              — "A server error occurred." (NEW — from TB fix)
└── CollisionFailure           — "Unique code collision limit reached." (NEW — from TB fix)
```

### 6.2 Repository Error Mapping Rules

| Source Exception | Mapped Failure |
|---|---|
| `AuthException` with "already registered/exists" | `EmailAlreadyInUseFailure` |
| `AuthException` with "invalid credentials" | `InvalidCredentialsFailure` |
| `PostgrestException` code '23505' (auth) | `EmailAlreadyInUseFailure` (if email) |
| `PostgrestException` code '23505' (request) | ❌ **BUG:** Still `UnknownFailure` (TB-3) |
| `SocketException` / network errors | `NetworkFailure` |
| Go backend collision response | `CollisionFailure` |
| Go backend 500 error | `ServerFailure` (with parsed message) |
| Everything else | `UnknownFailure` |

### 6.3 Go Error Handling

- Every service method returns `(T, error)` — never panics
- Errors wrapped with `fmt.Errorf("context: %w", err)` — never swallowed
- Handlers convert errors to HTTP responses (never panic)
- Collision detection: `errors.Is(err, service.ErrCollisionLimitReached)` → `{"error": "collision_limit_reached"}`

---

## 7. 🌐 ROUTE DEFINITIONS

### 7.1 Flutter Routes (GoRouter)

| Path | Screen | Auth Required |
|---|---|---|
| `/` | ShoppingListScreen | Yes (redirects to /login) |
| `/members` | GroupMembersScreen | Yes |
| `/login` | LoginScreen | No (redirects to / if logged in) |
| `/register` | RegisterScreen | No (redirects to / if logged in) |

**Guard logic:**
```
if authState.isLoading → return null (wait)
if !isLoggedIn && !isLoggingIn && !isRegistering → redirect /login
if isLoggedIn && (isLoggingIn || isRegistering) → redirect /
```

**⚠️ Missing:** No `email_verified` check in guard (TB-5 — deferred to post-MVP)

### 7.2 Go API Endpoints

| Method | Path | Auth | Handler | Description |
|---|---|---|---|---|
| GET | `/health` | No | inline | `{"status": "ok"}` |
| POST | `/api/v1/auth/unique-code` | JWT | `AuthHandler.GenerateCode` | Generate unique code for new user |
| GET | `/api/v1/protected/user` | JWT | inline | Echoes userID |

---

## 8. 🎨 THEME SYSTEM (How We Feel)

### 8.1 Color Tokens

| Token | Light | Dark |
|---|---|---|
| Background | `#F5F5F3` | `#0D0D0D` |
| Surface | `#FFFFFF` | `#1A1A1A` |
| Surface Variant | `#EFEFED` | `#242424` |
| Primary (Teal) | `#0D9488` | `#2DD4BF` |
| Secondary (Coral) | `#FF6B6B` | `#FF8E8E` |
| Amber | `#D97706` | `#FBBF24` |
| Purple | `#7C3AED` | `#A78BFA` |
| Green | `#059669` | `#34D399` |
| Blue | `#2563EB` | `#60A5FA` |
| Error | `#DC2626` | `#F87171` |

### 8.2 Typography

| Style | Size | Weight | Usage |
|---|---|---|---|
| `display` | 48px | 700 | Hero screen titles ("Evde ne var?") |
| `headline` | 32px | 700 | Section headers |
| `title` | 20px | 600 | Card titles |
| `body` | 16px | 400 | Content text |
| `label` | 13px | 500 | Badges, tags |

### 8.3 BlobPainter

`BlobPainter extends CustomPainter` — organic cubic bezier shape used as decorative
background on hero screens (LoginScreen, RegisterScreen). Parametric: color, opacity,
scale, offset. No hardcoded values.

---

## 9. 🔍 TECHNICAL DEBT INVENTORY (Known Issues)

### 9.1 🔴 CRITICAL (Fix before Sprint 2 work)

| ID | Issue | File | Root Cause | Fix Time |
|---|---|---|---|---|
| **TB-1** | `AddRequestBottomSheet._submit()` try/catch is dead code — `createRequest` no longer throws | `add_request_bottom_sheet.dart` | Bug fix changed controller to `state=AsyncError` but sheet wasn't updated | ~10 min |
| **TB-2** | 3 hardcoded strings in `GroupSwitcherBottomSheet` — i18n rule violation | `group_switcher_bottom_sheet.dart` | Placeholder never localized | ~15 min |
| **TB-3** | `SupabaseRequestRepository._mapException()` maps 23505 to `UnknownFailure` instead of a semantic failure | `supabase_request_repository.dart` | Only auth repository was updated during TB sweep | ~10 min |

### 9.2 🟡 MEDIUM

| ID | Issue | File | Status |
|---|---|---|---|
| **TB-4** | TASK.md marks GroupMembersScreen as `[ ]` but full implementation exists | `TASK.md` | Just needs checkbox update |
| **TB-5** | `email_verified` not checked in route guard | `router.dart` | Deferred to post-MVP |
| **TB-6** | `getRequestsStream` filters soft-deleted items client-side (performance tradeoff) | `supabase_request_repository.dart` | Documented, accepted |
| **TB-7** | Go `GenerateUniqueCode(userID)` unused parameter | `auth_service.go` | Low impact |

### 9.3 🟢 LOW (Sprint 3+ backlog)

| ID | Issue | Status |
|---|---|---|
| **TB-8** | Inventory feature: SQL exists, Flutter UI missing | Sprint 2 W1-4 `[ ]` |
| **TB-9** | Recipes feature: SQL exists, Flutter UI missing | Sprint 3+ |
| **TB-10** | `security_logs` table inaccessible (no RLS polices) | Intentional |
| **TB-11** | Go integration tests missing (`supabase_user_repository_test.go`) | Optional |

---

## 10. 🧪 TEST INVENTORY

### 10.1 Flutter Tests (14 files)

| Test File | Coverage | Priority |
|---|---|---|
| `auth/data/supabase_auth_repository_test.dart` | registerUser (7), loginUser (5) | ✅ Comprehensive |
| `auth/presentation/providers/auth_provider_test.dart` | Ghost session, session restore, signOut | ✅ Added per TST-F3 |
| `auth/presentation/providers/login_controller_test.dart` | Login form validation, error states | ✅ Added per TST-F1 |
| `auth/presentation/providers/register_controller_test.dart` | Registration validation, cross-field, errors | ✅ Added per TST-F2 |
| `auth/presentation/models/input_models_test.dart` | Email, Password, DisplayName, ConfirmedPassword | ✅ Added per TST-F5 |
| `groups/data/supabase_group_repository_test.dart` | createGroup (2), joinGroup (3), getMyGroups (1) | ✅ Comprehensive |
| `groups/presentation/providers/active_group_provider_test.dart` | Init (empty/valid cache), stale eviction, switchGroup | ✅ Comprehensive |
| `groups/presentation/widgets/group_switcher_widget_test.dart` | Null activeGroup, active group display, tap opens sheet | ✅ Added per TST-F6 |
| `requests/data/supabase_request_repository_test.dart` | CRUD + stream operations | ✅ Comprehensive |
| `requests/presentation/providers/request_controller_test.dart` | Stream actions, create/delete/update, error states | ✅ Added per TST-F4 |
| `requests/presentation/widgets/request_card_test.dart` | Pending/done display, private lock, toggle, delete | ✅ Added per TST-F7 |
| `requests/presentation/screens/shopping_list_screen_test.dart` | No group, loading, empty, pending+done, FAB | ✅ Added per TST-F8 |
| `shared/theme/app_theme_test.dart` | Light + dark token resolution | ✅ Comprehensive |
| `widget_test.dart` | KapApp smoke test | ✅ Minimal |

### 10.2 Go Tests (3 files)

| Test File | Scenarios | Status |
|---|---|---|
| `service/auth_service_test.go` | Code format (100 runs), collision retry (3 scenarios) | ✅ Comprehensive |
| `middleware/auth_test.go` | Valid token, missing header, malformed, wrong secret, expired, missing sub | ✅ Comprehensive |
| `handler/auth_handler_test.go` | Success (200), missing userID (401), collision limit (500), generic error (500) | ✅ Comprehensive |

**Missing (TST-G2):** Go `supabase_user_repository_test.go` (integration test — low priority)

---

## 11. ✅ VERIFIED FIXES (bug-and-fix.md validation)

All **12 bug entries** in bug-and-fix.md have been code-verified. Status: **✅ ALL RESOLVED**

| Date | Bug | Verification |
|---|---|---|
| 2026-06-25 | Flutter Localizations Synthetic Package | ✅ `l10n.yaml` clean, imports correct |
| 2026-06-25 | Non-Constant List Literal | ✅ `const` removed from delegates list |
| 2026-06-25 | anonKey → publishableKey | ✅ `publishableKey:` in `main.dart` |
| 2026-06-25 | MyApp → KapApp widget test | ✅ `widget_test.dart` uses `KapApp` |
| 2026-06-25 | SQL search_path + SELECT policy | ✅ `01_base_infrastructure.sql` correct |
| 2026-06-25 | Groups RLS + Triggers | ✅ `02_groups_and_membership.sql` correct |
| 2026-06-25 | Shopping Requests RLS + Index | ✅ `03_shopping_requests.sql` correct |
| 2026-06-25 | Inventory Management | ✅ `04_inventory_management.sql` correct |
| 2026-06-25 | Recipes + Lookup View | ✅ `05_recipes_and_lookup.sql` correct |
| 2026-06-26 | Ghost Session Deadlock | ✅ `auth_provider.dart` signOut on null profile |
| 2026-06-26 | Lowercase Index Mapping | ✅ `toLowerCase().trim()` in repository |
| 2026-06-26 | Technical Debt Sweep (4 fixes) | ✅ All verified |

---

## 12. 🔐 HELPER FUNCTIONS (SQL)

```sql
-- These are used across ALL RLS policies. DO NOT MODIFY without full migration.

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
```

**⚠️ CRITICAL RULE:** `group_members` RLS policies MUST use pure SQL `EXISTS` subqueries,
NOT call `is_group_member()` or `is_group_admin()` — this would cause infinite recursion
deadlocks. This was fixed in migration 02.

---

## 13. ⚙️ GO BACKEND ARCHITECTURE DETAILS

### 13.1 Middleware Chain

```
Request → AuthRequired(jwtSecret) → Handler
```

- Extracts `Authorization: Bearer <supabase_jwt>` header
- Validates HMAC signing method + claims parsing
- Extracts `sub` claim → injects into `c.Locals("userID", sub)`
- Returns 401 on: missing header, malformed format, invalid/expired token, missing sub

### 13.2 Unique Code Generation

```
GenerateUniqueCode(userID) → string, error
  └─ 5 attempts max
       ├─ generateRawCode() → "XXXX-XXXX" (8 chars from charset: ABCDEFGHJKMNPQRSTUVWXYZ23456789)
       ├─ userRepo.IsCodeExists(code) → Supabase REST query
       └─ if collision → retry
  └─ After 5 collisions → ErrCollisionLimitReached
  └─ On DB error → immediate abort with wrapped error
```

### 13.3 Service Layer Dependency Injection

```
main.go
  → config.LoadConfig()
    → supabase.NewClient(URL, ServiceRoleKey)
      → repository.NewSupabaseUserRepository(client)
        → service.NewAuthService(userRepo)
          → handler.NewAuthHandler(authService)
            → app.Group("/api/v1/auth", AuthRequired(secret))
              → authHandler.RegisterRoutes(group)
```

### 13.4 Environment Variables (Go)

| Variable | Purpose |
|---|---|
| `PORT` | Server port (default: 8080) |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key (admin operations) |
| `SUPABASE_JWT_SECRET` | JWT secret for token validation |

### 13.5 Supabase Admin Client (Go)

`pkg/supabase/client.go` wraps HTTP-based Supabase REST API using service_role key.
Not a full SDK — only implements `CheckCodeExists(code)` for unique code collision checking.
Uses `Authorization: Bearer <ServiceRoleKey>` and `apikey: <ServiceRoleKey>` headers.

---

## 14. 📐 ARCHITECTURAL RULES (LLMs must follow)

### 14.1 Do NOT

- **Never use `dynamic` in Dart** without an explanatory comment (existing usages already have them)
- **Never use `interface{}` in Go** without an explanatory comment
- **Never patch an RLS rule** — find root cause, reproduce locally, fix properly via migration
- **Never put business logic in a Go handler** — delegate to service layer immediately
- **Never add a library** outside the approved stack (Flutter: flutter_riverpod, go_router, formz, shared_preferences, fpdart, mocktail, supabase_flutter / Go: fiber, godotenv, golang-jwt, testify, supabase-go)
- **Never add a task to TASK.md mid-sprint**
- **Never modify `core/errors/`, `core/repositories/`, or `pkg/supabase/`** without explicit instruction
- **Never hardcode strings** in Flutter — all user-facing text via `.arb` i18n files
- **Never produce more than one micro unit per session** unless explicitly asked

### 14.2 Always

- **Every repository method returns `Either<Failure, T>`** — never throw to UI
- **Every Go service method returns `(T, error)`** — never panic
- **All bugs go to `bug-and-fix.md`** with full template before fix
- **Task scope is atomic** — one task = one micro unit = one testable piece
- **Write test immediately after code** — test-first preferred

---

## 15. 🚀 NEXT STEPS (Sprint 2 — Week 1 Remaining)

### Must fix before continuing:
1. 🔴 **TB-1:** Fix `_submit()` in `add_request_bottom_sheet.dart` — replace try/catch with `state` monitoring or SnackBar from AsyncError listener
2. 🔴 **TB-2:** Localize hardcoded strings in `group_switcher_bottom_sheet.dart`
3. 🔴 **TB-3:** Add `DuplicateItemFailure` or similar to `failure.dart`, map `23505` in request repository

### Sprint 2 tasks:
4. 🟡 **W1-4:** `InventoryRepository` interface + `SupabaseInventoryRepository` + `inventoryProvider`
5. 🟡 **W2-1:** `InventoryScreen` + `InventoryItemCard` + `StockStatusChip` + `AddInventoryBottomSheet`

---

## 16. 📄 FILE REFERENCE (Quick Stats)

| Category | Count |
|---|---|
| Flutter `.dart` files | ~45 |
| Flutter test files | 14 |
| Go `.go` files | 10 |
| Go test files | 3 |
| SQL migrations | 5 |
| `.arb` locale files | 2 (en, tr) |

---

*End of PROJECT_MAP_FOR_LLM.md — An LLM agent can start working after reading this file.*
