# 🗺️ Kap-App — Complete Project Map for LLM Agents (v2)

> **Purpose:** This file is designed to be read by an LLM agent at the start of every session.
> It contains the full structural fingerprint of the project, all architectural decisions,
> known technical debt, error handling patterns, and database schema — so the LLM can
> operate without reading every single file first.
>
> **Last updated:** 2026-06-26 (v2)
> **Status:** Sprint 1 complete. **CRITICAL: CORS issue blocks register flow.**
>
> **⚠️ NOTE:** This is v2. An older `PROJECT_MAP_FOR_LLM.md` exists alongside this file.
> This v2 file is the AUTHORITATIVE version. The old file is kept for reference only.
> Why v2 exists: The LLM agent's `edit_existing_file` tool could not modify the original
> file due to encoding issues (UTF-8 special characters in folder structure diagrams).
> A new file was created instead of risking data corruption.

---

## 1. 🏗️ PROJECT OVERVIEW

**Kap-App** is a shared household/community shopping and inventory management app.
Users join groups via a unique code, manage shared shopping requests, track home inventory
(in stock / low / out), and send private requests visible only to a specific member.

| Layer | Technology |
|---|---|
| Mobile | **Flutter 3.x** (Dart) — Web (currently tested), iOS + Android target |
| State management | **Riverpod 3** (`flutter_riverpod` — `AsyncNotifier`, `Notifier`, `FutureProvider.family`) |
| Auth + DB + Realtime | **Supabase** (`supabase_flutter` — Auth, PostgreSQL, Realtime streams) |
| Business logic API | **Go** (Fiber v2 framework) — runs separately on port 8080 |
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
│   ├── PROJECT_MAP_FOR_LLM.md        ← OLD v1 (kept for reference)
│   └── PROJECT_MAP_FOR_LLM_v2.md    ← THIS FILE (authoritative)
├── kap-app-front/                    ← Flutter mobile app
│   └── lib/
│       ├── main.dart
│       ├── l10n/                      ← Generated localization files
│       ├── core/
│       │   ├── errors/
│       │   │   ├── failure.dart       ← Failure hierarchy
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

### 4.3 ✅ RESOLVED — TB-1 FIXED

~~KNOWN ANTIPATTERN~~ — `AddRequestBottomSheet._submit()` try/catch dead code issue.
**Fixed in [2026-06-26] bug-and-fix entry #13.** 
The `_submit()` method now:
- Uses `_isSubmitting` state variable to prevent double-submit
- Uses `ref.listen(requestControllerProvider)` to catch errors globally
- Uses localized strings instead of hardcoded text
- Disables submit button when `isPrivate && _selectedMemberId == null`

Do NOT reintroduce try/catch pattern in Riverpod controllers. Always use `state = AsyncError()`.

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
- `maintain_inventory_metadata_trigger`: Sets `last_updated_at = now()`, `last_updated_by = COALESCE(auth.uid(), OLD.last_updated_by)`
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

**⚠️ CRITICAL RULE:** `group_members` RLS policies MUST use pure SQL `EXISTS` subqueries,
NOT call `is_group_member()` or `is_group_admin()` — this would cause infinite recursion
deadlocks. This was fixed in migration 02.

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
├── ServerFailure              — "A server error occurred." (from TB fix)
└── CollisionFailure           — "Unique code collision limit reached." (from TB fix)
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

## 8. 🎨 THEME SYSTEM

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

## 9. 🔍 TECHNICAL DEBT + RUNTIME ISSUES

### 9.1 🔴 KRİTİK — RUNTIME BLOKER (CORS)

| ID | Issue | File | Root Cause | Status |
|---|---|---|---|---|
| **CORS-1** | Go Fiber backend'de CORS middleware eksik | `cmd/server/main.go` | Flutter web (localhost:49825) Go backend'e (localhost:8080) istek atıyor. Fiber OPTIONS preflight isteklerine `Access-Control-Allow-Origin` header'ı eklemiyor. Tarayıcı isteği blokluyor. | **❌ AÇIK** |

**CORS hatasının register akışına etkisi:**
```
RegisterController.submit()
  → supabase.auth.signUp()                    → ✅ Başarılı (Auth'a yazılır)
  → POST http://localhost:8080/api/v1/auth/unique-code
    → Tarayıcı: OPTIONS preflight gönderir
    → Go Fiber: CORS header'ı olmadığı için yanıt vermez
    → Tarayıcı: İSTEĞİ BLOKLAR (net::ERR_FAILED)
    → Flutter: SocketException → NetworkFailure döner
    → public.users insert'i HİÇ ÇALIŞMAZ
```

**Sonuç:** Kullanıcı Auth'da var ama `public.users`'da yok → login'de "User profile not found in database" hatası.

**Çözüm için 3 seçenek:**
1. Go Fiber'a CORS middleware eklemek (main.go + `go get`) — en temiz
2. Flutter'ı native (Android/iOS) çalıştırmak — web'de CORS sorunu yok
3. Chrome'u CORS kapalı başlatmak (`flutter run -d chrome --web-browser-flag "--disable-web-security"`) — sadece geliştirme

### 9.2 🔴 KRİTİK (Code-level)

| ID | Issue | File | Status |
|---|---|---|---|
| **TB-1** | ~~AddRequestBottomSheet._submit() try/catch dead code~~ | `add_request_bottom_sheet.dart` | ✅ **ÇÖZÜLDÜ** (bug-and-fix #13) |
| **TB-2** | 3 hardcoded strings in GroupSwitcherBottomSheet | `group_switcher_bottom_sheet.dart` | ❌ AÇIK |
| **TB-3** | 23505 maps to UnknownFailure in request repo | `supabase_request_repository.dart` | ❌ AÇIK |

### 9.3 🟡 MEDIUM

| ID | Issue | Status |
|---|---|---|
| **TB-4** | TASK.md checkbox güncel değil | ❌ AÇIK |
| **TB-5** | `email_verified` route guard yok | Deferred |
| **TB-6** | Stream client-side soft-delete filtering | ✅ Documented |
| **TB-7** | Go `GenerateUniqueCode(userID)` unused param | ❌ AÇIK |

### 9.4 🟢 LOW

| ID | Issue | Status |
|---|---|---|
| **TB-8** | Inventory Flutter UI missing | Sprint 2 |
| **TB-9** | Recipes Flutter UI missing | Sprint 3+ |
| **TB-10** | `security_logs` inaccessible | Intentional |
| **TB-11** | Go integration test missing | Optional |

---

## 10. 🧪 TEST INVENTORY

### 10.1 Flutter Tests (14 files)

| Test File | Status |
|---|---|
| `auth/data/supabase_auth_repository_test.dart` | ✅ registerUser (7), loginUser (5) |
| `auth/presentation/providers/auth_provider_test.dart` | ✅ Ghost session, session restore, signOut |
| `auth/presentation/providers/login_controller_test.dart` | ✅ Login validation, error states |
| `auth/presentation/providers/register_controller_test.dart` | ✅ Registration validation, cross-field, errors |
| `auth/presentation/models/input_models_test.dart` | ✅ Email, Password, DisplayName, ConfirmedPassword |
| `groups/data/supabase_group_repository_test.dart` | ✅ createGroup, joinGroup, getMyGroups |
| `groups/presentation/providers/active_group_provider_test.dart` | ✅ Init, stale eviction, switchGroup |
| `groups/presentation/widgets/group_switcher_widget_test.dart` | ✅ Null, active display, tap opens sheet |
| `requests/data/supabase_request_repository_test.dart` | ✅ CRUD + stream |
| `requests/presentation/providers/request_controller_test.dart` | ✅ Stream, create/delete/update, errors |
| `requests/presentation/widgets/request_card_test.dart` | ✅ Pending/done, private lock, toggle, delete |
| `requests/presentation/screens/shopping_list_screen_test.dart` | ✅ No group, loading, empty, pending+done, FAB |
| `shared/theme/app_theme_test.dart` | ✅ Light + dark tokens |
| `widget_test.dart` | ✅ Smoke test |

### 10.2 Go Tests (3 files)

| Test File | Status |
|---|---|
| `service/auth_service_test.go` | ✅ Code format (100 runs), collision retry (3 scenarios) |
| `middleware/auth_test.go` | ✅ Valid token, missing header, malformed, wrong secret, expired, missing sub |
| `handler/auth_handler_test.go` | ✅ Success (200), missing userID (401), collision limit (500), generic error (500) |

**Missing:** Go `supabase_user_repository_test.go` (integration test — low priority)

---

## 11. ✅ VERIFIED FIXES (bug-and-fix.md validation)

13 bug entries verified:

| # | Date | Bug | Status |
|---|---|---|---|
| 1 | 2026-06-25 | Flutter Localizations Synthetic Package | ✅ |
| 2 | 2026-06-25 | Non-Constant List Literal | ✅ |
| 3 | 2026-06-25 | anonKey → publishableKey | ✅ |
| 4 | 2026-06-25 | MyApp → KapApp widget test | ✅ |
| 5 | 2026-06-25 | SQL search_path + SELECT policy | ✅ |
| 6 | 2026-06-25 | Groups RLS + Triggers | ✅ |
| 7 | 2026-06-25 | Shopping Requests RLS + Index | ✅ |
| 8 | 2026-06-25 | Inventory Management | ✅ |
| 9 | 2026-06-25 | Recipes + Lookup View | ✅ |
| 10 | 2026-06-26 | Ghost Session Deadlock | ✅ |
| 11 | 2026-06-26 | Lowercase Index Mapping | ✅ |
| 12 | 2026-06-26 | Technical Debt Sweep (4 fixes) | ✅ |
| 13 | 2026-06-26 | AddRequestBottomSheet state sync refactoring | ✅ |

---

## 12. ⚙️ GO BACKEND ARCHITECTURE DETAILS

### 12.1 Middleware Chain

```
Request → AuthRequired(jwtSecret) → Handler
```

- Extracts `Authorization: Bearer <supabase_jwt>` header
- Validates HMAC signing method + claims parsing
- Extracts `sub` claim → injects into `c.Locals("userID", sub)`
- Returns 401 on: missing header, malformed format, invalid/expired token, missing sub

### 12.2 Unique Code Generation

```
GenerateUniqueCode(userID) → string, error
  └─ 5 attempts max
       ├─ generateRawCode() → "XXXX-XXXX" (charset: ABCDEFGHJKMNPQRSTUVWXYZ23456789)
       ├─ userRepo.IsCodeExists(code) → Supabase REST query
       └─ if collision → retry
  └─ After 5 collisions → ErrCollisionLimitReached
```

### 12.3 Service Layer Dependency Injection

```
supabase.NewClient(URL, ServiceRoleKey)
  → repository.NewSupabaseUserRepository(client)
    → service.NewAuthService(userRepo)
      → handler.NewAuthHandler(authService)
        → app.Group("/api/v1/auth", AuthRequired(secret))
          → authHandler.RegisterRoutes(group)
```

### 12.4 Environment Variables (Go)

| Variable | Purpose |
|---|---|
| `PORT` | Server port (default: 8080) |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key (admin operations) |
| `SUPABASE_JWT_SECRET` | JWT secret for token validation |

---

## 13. 📐 ARCHITECTURAL RULES (LLMs must follow)

### 13.1 Do NOT

- **Never use `dynamic` in Dart** without explanatory comment
- **Never use `interface{}` in Go** without explanatory comment
- **Never patch an RLS rule** — find root cause, fix via migration
- **Never put business logic in a Go handler** — delegate to service layer
- **Never add a library** outside approved stack (listed in pubspec.yaml / go.mod)
- **Never add a task to TASK.md mid-sprint**
- **Never modify `core/errors/`, `core/repositories/`, or `pkg/supabase/`** without explicit instruction
- **Never hardcode strings in Flutter** — use `.arb` i18n files
- **Never produce more than one micro unit per session** unless asked

### 13.2 Always

- **Every repository method returns `Either<Failure, T>`** — never throw to UI
- **Every Go service method returns `(T, error)`** — never panic
- **All bugs go to `bug-and-fix.md`** with full template before fix
- **Task scope is atomic** — one task = one micro unit = one testable piece
- **Write test immediately after code** — test-first preferred

---

## 14. 🚀 NEXT STEPS (Güncel Öncelik Sırası)

### 0️⃣ 🔴 CRITICAL — CORS FIX
- [ ] **CORS-1:** Go backend'e CORS middleware ekle (`main.go` + `go get github.com/gofiber/fiber/v2/middleware/cors`)
- [ ] **CLEANUP:** Supabase Dashboard > Authentication > Users > yetim kullanıcıları sil
- [ ] **TEST:** Register + Login akışını doğrula

### 1️⃣ Must fix (code-level):
- [ ] **TB-2:** Localize hardcoded strings in `group_switcher_bottom_sheet.dart`
- [ ] **TB-3:** Add `DuplicateItemFailure` to `failure.dart`, map 23505 in request repository

### 2️⃣ Sprint 2 tasks:
- [ ] **W1-4:** InventoryRepository interface + SupabaseInventoryRepository + inventoryProvider
- [ ] **W2-1:** InventoryScreen + InventoryItemCard + StockStatusChip + AddInventoryBottomSheet

---

## 15. 🧪 RUNTIME DIAGNOSTICS (2026-06-26 — Observed Behavior)

### ✅ Currently Working:
- Flutter `--dart-define-from-file=.env` ile başlatılıyor
- `Supabase.initialize()` başarılı (log: `Supabase init completed`)
- `supabase.auth.signUp()` Supabase Auth'a kullanıcı yazıyor
- Login/Register ekranları render oluyor (teal/coral blob'lar, form card)
- Go backend `go run cmd/server/main.go` ile başlıyor (health check çalışıyor)
- Tüm SQL migration'ları Supabase'de mevcut

### ❌ Currently Broken:
- **Register:** Go backend'e CORS'tan dolayı istek gitmiyor → `public.users` insert'i çalışmıyor
- **Login:** `public.users`'da kayıt olmadığı için "User profile not found in database"
- **TB-2, TB-3:** Code-level debt (CORS'tan bağımsız, ama CORS fix'ten sonra da düzeltilmeli)

### Observed Error Logs:
```
Supabase init completed
CORS: Response to preflight request doesn't pass access control check
No 'Access-Control-Allow-Origin' header is present
POST /api/v1/auth/unique-code net::ERR_FAILED
```

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

*End of PROJECT_MAP_FOR_LLM_v2.md — This is the authoritative project map.*
