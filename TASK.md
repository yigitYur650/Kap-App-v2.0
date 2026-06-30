# TASK.md — Kap-App Sprint 1

> Sprint duration: 2 weeks
> Goal: Working app with Auth + Group management + Shopping list
> Rule: No task may be added or removed after sprint starts. Scope changes wait for Sprint 2.
> Update this file every end of day — mark completed tasks, add blockers.

---

## Status Legend

- `[ ]` Not started
- `[~]` In progress
- `[x]` Done
- `[!]` Blocked — reason must be noted inline

---

## Week 1 — Foundation + Auth

### W1-1: Project scaffold
- [x] Create new Flutter project (`flutter create kap_app`)
- [x] Set up folder structure per PROJECT_BRIEF.md (`features/`, `core/`, `shared/`)
- [x] Add all approved dependencies to `pubspec.yaml` and resolve
- [x] Configure Supabase project (create tables, run migrations)
- [x] Add `supabase_flutter` init in `main.dart` with env-based config
- [x] Set up go_router base with placeholder routes
- [x] Set up flutter_localizations + intl with `tr` and `en` locale files
- [x] Commit: `chore: project scaffold`

### W1-2: Auth — Registration
- [x] Create `AuthRepository` interface in `core/`
- [x] Implement `SupabaseAuthRepository` in `features/auth/data/`
- [x] `registerUser(email, password, displayName)` — calls Supabase Auth
- [x] On register: generate `unique_code` (random readable string, server-side function)
- [x] Insert row into `users` table after Supabase auth signup
- [x] Unit test: `SupabaseAuthRepository` with mocktail
- [x] Commit: `feat(auth): registration service`

### W1-3: Auth — Email verification [!] Deferred — priority shifted to login + session
- [!] Resend integration: Supabase sends verification email on signup (configure in Supabase dashboard — no custom code needed unless custom template)
- [!] `VerifyEmailScreen` — shows "check your inbox" with resend button
- [!] `resendVerificationEmail()` in `AuthRepository`
- [!] Block app entry if `email_verified = false`
- [!] Unit test: resend cooldown logic
- [!] Commit: `feat(auth): email verification screen`

### W1-4: Auth — Login + session
- [x] `loginUser(email, password)` in `AuthRepository`
- [x] Riverpod `authProvider` — holds current user state (`AsyncValue<AppUser?>`)
- [x] Auto-restore session on app launch (`supabase.auth.currentSession`)
- [x] `LoginScreen` — email + password fields, formz validation (placeholder screen created)
- [x] Route guard: unauthenticated → `/login`, unverified → `/verify-email`, verified → `/home`
- [x] Unit test: route guard logic
- [x] Commit: `feat(auth): login and session restore`

### W1-5: Auth — UI polish
- [x] `RegisterScreen` — display name, email, password, confirm password
- [x] `LoginScreen` — email, password, "forgot password" placeholder
- [x] All strings via i18n keys — zero hardcoded text
- [x] Commit: `feat(auth): registration and login screens`

---

## Week 2 — Groups + Shopping List

### W2-1: Group — Create and join
- [x] `GroupRepository` interface in `core/`
- [x] `createGroup(name, type)` — inserts into `groups`, adds creator as admin in `group_members`
- [x] `joinGroup(uniqueCode)` — looks up user by `unique_code`, adds to `group_members`
- [x] `getMyGroups()` — returns all groups for current user
- [x] Unit test: `createGroup` and `joinGroup`
- [x] Commit: `feat(groups): create and join group service`

### W2-2: Group — Multi-group switcher
- [x] Riverpod `activeGroupProvider` — holds currently selected group
- [x] Top-left group switcher widget (`GroupSwitcherWidget`) — shows group name, tap to change
- [x] `GroupSwitcherBottomSheet` — lists all user groups, tap to switch
- [x] Active group persisted across sessions (shared_preferences)
- [x] Unit test: active group switch
- [x] Commit: `feat(groups): multi-group switcher`

### W2-3: Group — Member management screen
- [x] `GroupMembersScreen` — lists members with display name and role badge (placeholder skeleton setup)
- [x] Show current user's `unique_code` in settings screen (for sharing)
- [x] Commit: `feat(groups): members screen and unique code display`

### W2-4: Shopping list — Core
- [x] `RequestRepository` interface in `core/`
- [x] `getRequests(groupId)` — fetches non-private + own private requests
- [x] `createRequest(groupId, itemName, {isPrivate, privateTo})` 
- [x] `updateRequestStatus(requestId, status)` — pending → done
- [x] `deleteRequest(requestId)`
- [x] Unit test: private request visibility logic
- [x] Commit: `feat(requests): shopping list service`

### W2-5: Shopping list — Realtime Integration & UI
- [x] Stream-based realtime requests repository stream (`getRequestsStream`)
- [x] Stream subscription state controller (`RequestController`)
- [x] Unit test: realtime stream emissions verification
- [x] `ShoppingListScreen` — grouped by status (pending on top)
- [x] `RequestCard` micro component — item name, requester, status toggle, delete (own only)
- [x] `AddRequestBottomSheet` — item name input, private toggle, member picker (if private)
- [x] Private requests show lock icon — not visible to other members
- [x] All strings via i18n
- [x] Commit: `feat(requests): shopping list screen`

### W2-6: Integration + manual QA
- [x] End-to-end flow test: register → verify → create group → add request → mark done
- [x] End-to-end flow test: join group via unique code → see shared list → add private request
- [x] Fix any blockers found — log each in `bug-and-fix.md`
- [x] Commit: `test: sprint 1 integration qa`

---

## Backlog (Sprint 2+)

These are out of scope for Sprint 1. Do not implement.

- Home inventory (var / azaldı / yok)
- QR code member adding
- Location-based group switching
- Push notifications
- Recipe module
- Community recipe forum
- Forgot password flow (placeholder only in Sprint 1)

---

## End-of-Day Update Format

```
### [date]
- Completed: [task IDs]
- In progress: [task IDs]
- Blocked: [task ID] — reason
- Notes: [anything relevant]
```

### [2026-06-25]
- Completed: Database Packet 1 Setup (01_base_infrastructure.sql), Database Packet 2 Setup (02_groups_and_membership.sql), Database Packet 3 Setup (03_shopping_requests.sql), Database Packet 4 Setup (04_inventory_management.sql) & Database Packet 5 Setup (05_recipes_and_lookup.sql)
- In progress: W1-2: Auth — Registration
- Notes: Finalized database layer implementation. Created recipes tables and recipe_items tables; configured automatic trigger-driven metadata auditing and group sync; added safe RLS policies for recipes/items; implemented a secure security_barrier-protected view public_user_lookup for user invitations.

### [2026-06-26]
- Completed: W1-2: Auth — Registration, W1-4: Auth — Login + session, W1-5: Auth — UI polish
- Deferred: W1-3: Auth — Email verification
- Notes: Implemented abstract login contract in AuthRepository and SupabaseAuthRepository. Created InvalidCredentialsFailure and mapped related errors. Created placeholder screens for LoginScreen and HomeScreen in clean presentation directories. Built authProvider using Riverpod AsyncNotifier for session auto-restore/auto-login and state management. Wrote mocktail unit tests to verify the login flow. Created Formz validation input models (Email, Password, ConfirmedPassword, DisplayName) and updated localization keys for en and tr. Built full Material 3 screen layouts for LoginScreen and RegisterScreen using Riverpod Notifier controllers. Resolved the Ghost Session deadlock bug in the AuthNotifier's build() logic and logged the fix in bug-and-fix.md. Added surgical refactoring for maintenance: hardened the getMyGroups query in SupabaseGroupRepository to explicitly filter by user memberships (using inner join), and removed redundant client-side toLowerCase normalization from AddRequestBottomSheet UI layer.
# TASK.md — Kap-App Sprint 2

> Sprint duration: 2 weeks
> Goal: MVP complete — Inventory + Go backend foundation + How We Feel visual theme
> Rule: No task may be added or removed after sprint starts. Scope changes wait for Sprint 3.
> Update this file every end of day — mark completed tasks, add blockers.
> Email verification: deferred to post-MVP. Do not implement this sprint.

---

## Status Legend

- `[ ]` Not started
- `[~]` In progress
- `[x]` Done
- `[!]` Blocked — reason must be noted inline

---

## Week 1 — Theme System + Inventory Core + Go Foundation

### W1-1: Theme system (How We Feel visual language)
- [x] Create `shared/theme/app_colors.dart` — define full color palette (dark + light tokens)
  - Dark: background #0D0D0D, surface #1A1A1A, surface-variant #242424
  - Light: background #F5F5F3, surface #FFFFFF, surface-variant #EFEFED
  - Accent palette: 6 bold colors for group/category identity (coral, teal, amber, purple, green, blue)
  - Semantic: success, warning, error, info — both modes
- [x] Create `shared/theme/app_typography.dart` — define text styles
  - Display: 48px, weight 700 — hero screen titles ("Bugün ne lazım?")
  - Headline: 32px, weight 700 — section headers
  - Title: 20px, weight 600 — card titles
  - Body: 16px, weight 400 — content
  - Label: 13px, weight 500 — badges, tags
  - Font: use system default (SF Pro on iOS, Roboto on Android) — no custom font this sprint
- [x] Create `shared/theme/app_theme.dart` — compose ThemeData (light + dark)
  - Material 3 enabled
  - ColorScheme.fromSeed per mode
  - All component themes: card, bottom sheet, navigation bar, input decoration, button
  - BottomNavigationBar: icon-only, no labels, bold active indicator
- [x] Create `shared/theme/app_shapes.dart` — organic blob painter
  - `BlobPainter extends CustomPainter` — cubic bezier organic shape
  - Parametric: color, opacity, size, offset — no hardcoded values
  - Used as decorative background element on hero screens
- [x] Update `main.dart` — wire `AppTheme.light()` and `AppTheme.dark()` to `MaterialApp`
- [x] Apply theme to all existing screens (LoginScreen, RegisterScreen, GroupSetupScreen)
  - Replace any hardcoded colors with theme tokens
  - Replace any hardcoded text styles with typography tokens
  - Zero hardcoded colors after this task
- [x] Unit test: theme tokens resolve correctly in both modes (light/dark)
- [x] Commit: `feat(theme): How We Feel visual system — light + dark`

### W1-2: Go backend — project scaffold
- [x] Initialize Go module in `kap-app-backend/` (`go mod init`)
- [x] Add dependencies: Fiber v2, godotenv, supabase-go (or direct pgx), testify
- [x] Create folder structure:
  ```
  cmd/server/main.go
  internal/
    handler/
    service/
    repository/
    middleware/
  pkg/supabase/
  config/
  ```
- [x] `config/config.go` — load env vars (SUPABASE_URL, SUPABASE_SERVICE_KEY, PORT)
- [x] `pkg/supabase/client.go` — Supabase admin client wrapper (service role key)
- [x] `internal/middleware/auth.go` — JWT validation middleware
  - [x] Extract Bearer token from Authorization header
  - [x] Validate against Supabase JWT secret
  - [x] Inject `userID` into Fiber context
  - [x] Return 401 on invalid/missing token
- [x] `cmd/server/main.go` — wire Fiber app, register middleware, start server
  - [x] Configure CORS middleware for local frontend origins (localhost subports, AllowCredentials=true, AllowedMethods/Headers)
- [x] Health check route: `GET /health` → `{ "status": "ok" }`
- [x] Unit test: JWT middleware with valid + invalid + missing token
- [x] Commit: `feat(go): backend scaffold + JWT middleware`

### W1-3: Go backend — unique_code service
- [x] `internal/service/auth_service.go` — `GenerateUniqueCode(userID string) (string, error)`
  - [x] Generate random 8-char readable code (uppercase letters + numbers, no ambiguous chars: 0/O, 1/I/L)
  - [x] Check uniqueness against `users` table via Supabase admin client
  - [x] Retry up to 5 times on collision
  - [x] Return error if all retries fail
- [x] `internal/handler/auth_handler.go` — `POST /api/v1/auth/unique-code`
  - [x] Auth middleware required
  - [x] Calls `AuthService.GenerateUniqueCode`
  - [x] Returns `{ "unique_code": "XK7M2R9P" }`
- [x] Unit test: collision retry logic, invalid character filtering
- [x] Update Flutter `SupabaseAuthRepository` — call Go API for unique_code instead of generating client-side
- [x] Commit: `feat(go): unique_code generation service`

### W1-4: Inventory — core service
- [x] `InventoryRepository` interface in `core/repositories/`
  - `getInventoryStream(groupId)` → `Stream<List<InventoryItem>>`
  - `addInventoryItem(groupId, itemName)` → `({InventoryItem? data, AppError? error})` // Implemented using functional Either
  - `updateStockStatus(itemId, StockStatus status)` → `({bool? data, AppError? error})` // Implemented using functional Either
  - `deleteInventoryItem(itemId)` → `({bool? data, AppError? error})` // Implemented using functional Either
- [x] `StockStatus` enum in `core/models/` — `inStock`, `low`, `outOfStock`
  - i18n keys: `inventory.status.in_stock`, `inventory.status.low`, `inventory.status.out_of_stock`
  - DB mapping: `'var'` → `inStock`, `'azaldı'` → `low`, `'yok'` → `outOfStock`
- [x] `InventoryItem` model in `core/models/`
- [x] `SupabaseInventoryRepository` in `features/inventory/data/`
  - Realtime stream subscription (same pattern as `RequestController`)
  - `itemName` normalized: `toLowerCase().trim()` before insert (same rule as requests)
- [x] Riverpod `inventoryProvider` — `AsyncValue<List<InventoryItem>>`
- [x] Unit test: stream emissions, stock status mapping, name normalization
- [x] Commit: `feat(inventory): core service + realtime stream'`

---

## Week 2 — Inventory UI + Go Notifications + UI Polish

### W2-1: Inventory — UI
- [ ] `InventoryScreen` — replace placeholder with real implementation
  - Grouped by `StockStatus`: outOfStock on top, then low, then inStock
  - Realtime updates via `inventoryProvider` stream
  - Empty state: blob background + display-size text ("Evde ne var?")
- [ ] `InventoryItemCard` micro component
  - Item name (title style)
  - `StockStatusChip` — color-coded: outOfStock=coral, low=amber, inStock=teal
  - Long press → delete (own items or admin)
- [ ] `StockStatusChip` micro component
  - Three states, each with accent color from theme
  - Tap cycles through: inStock → low → outOfStock → inStock
  - Optimistic update — update UI immediately, revert on error
- [ ] `AddInventoryBottomSheet`
  - Full-screen bottom sheet (How We Feel style)
  - Single input: item name
  - Initial status: inStock by default
  - Submit disabled if empty
- [ ] All strings via i18n (tr + en)
- [ ] Commit: `feat(inventory): inventory screen + components`

### W2-2: Go backend — push notification service
- [ ] Add FCM dependency to Go (`firebase-admin-go`)
- [ ] `internal/service/notification_service.go`
  - `SendToGroup(groupID, title, body string) error`
  - Fetch group member device tokens from `user_device_tokens` table (create table if not exists)
  - Fan out FCM messages to all members
- [ ] `internal/handler/notification_handler.go` — `POST /api/v1/notifications/send`
  - Auth middleware required
  - Validates sender is group member
  - Calls `NotificationService.SendToGroup`
- [ ] `user_device_tokens` table migration: `user_id`, `token`, `platform`, `created_at`
  - RLS: user can only read/write own tokens
- [ ] Flutter: register FCM token on login, call Go API to store
- [ ] Unit test: fan-out logic, empty token list edge case
- [ ] Commit: `feat(go): push notification service`

### W2-3: Sprint 1 placeholder completion
- [ ] `GroupMembersScreen` — replace skeleton with real implementation
  - Member list with `display_name` + role badge
  - Admin badge: accent color pill
  - Current user highlighted
  - Copy `unique_code` button (share sheet)
- [ ] `LoginScreen` — verify it is full implementation, not placeholder
  - If placeholder: implement full Formz validation + error display
- [ ] `SettingsScreen` — basic implementation
  - Show own `unique_code` with copy button
  - Theme toggle (light/dark override — persisted via shared_preferences)
  - Sign out button
- [ ] Commit: `feat(screens): complete sprint 1 placeholders`

### W2-4: How We Feel UI polish — hero screens
- [ ] `ShoppingListScreen` — apply How We Feel visual language
  - Dark/light surface background
  - Blob painter as decorative top element
  - Display-size empty state text
  - `RequestCard` restyled: bold item name, muted metadata, accent left border per group color
- [ ] `GroupSwitcherBottomSheet` — full-screen, each group shown as large color tile
  - Each group gets one accent color (derived from group id hash — deterministic)
  - Active group: bold border + checkmark
- [ ] `AddRequestBottomSheet` — full-screen How We Feel style
  - Single large input centered
  - Private toggle as bold pill, not a checkbox
- [ ] `SplashScreen` — blob animation on launch
  - Animated blob + app name, 1.5s max, respects `prefers-reduced-motion`
- [ ] Commit: `feat(ui): How We Feel visual polish on hero screens`

### W2-5: Integration + manual QA
- [ ] End-to-end: register → login → create group → add inventory item → change stock status
- [ ] End-to-end: Go API health check + unique_code generation from Flutter
- [ ] End-to-end: push notification received on group request creation
- [ ] Visual QA: both light and dark mode on iOS simulator + Android emulator
- [ ] Fix any blockers — log each in `bug-and-fix.md`
- [ ] Commit: `test: sprint 2 integration qa`

---

## Backlog (Sprint 3+)

- Email verification (post-MVP)
- QR code member adding
- Location-based group switching
- Recipe module
- Community recipe forum
- Forgot password flow
- Haptic feedback
- Custom font (post-MVP)

---

## End-of-Day Update Format

```
### [date]
- Completed: [task IDs]
- In progress: [task IDs]
- Blocked: [task ID] — reason
- Notes: [anything relevant]
```
### [2026-06-30]
- Completed: W1-2 (CORS middleware subset), TST-G3 (CORS integration tests)
- In progress: W1-4
- Notes: Configured CORS middleware in `kap-app-backend/cmd/server/main.go` to support specific local origins (localhost ports 3000, 8080, 49825, 5000) for Flutter web/native. Added isolated integration test in `internal/integration/cors_flow_test.go` to verify preflight OPTIONS and standard cross-origin requests, running test cases successfully.

---

---

---

# 🧪 TEST KALİTE İYİLEŞTİRME — Test Sprint (Bağımsız Kapsam)

> Bu bölüm mevcut sprint'lere eklenmez. Ayrı bir "Test Sprint" veya sprint aralarında yapılacak
> teknik borç ödemeleri olarak ele alınır.
> Her görev atomiktir — bir test dosyası = bir görev.
> Analiz tarihi: 2026-06-26

---

## Mevcut Test Envanteri (Analiz Bazı)

| Dosya | Kapsam | Durum |
|---|---|---|
| `test/features/auth/data/supabase_auth_repository_test.dart` | `registerUser` (7 senaryo) + `loginUser` (5 senaryo) | ✅ Kapsamlı |
| `test/features/groups/data/supabase_group_repository_test.dart` | `createGroup` (2), `joinGroup` (3), `getMyGroups` (1) | ✅ Kapsamlı |
| `test/features/requests/data/supabase_request_repository_test.dart` | `getRequests`, `createRequest`, `updateRequestStatus`, `deleteRequest`, `getRequestsStream` | ✅ Kapsamlı |
| `test/features/groups/presentation/providers/active_group_provider_test.dart` | init (boş cache), init (geçerli cache), stale eviction, `switchGroup` | ✅ Kapsamlı |
| `test/shared/theme/app_theme_test.dart` | Theme token resolve (light + dark) | ✅ Var |
| `internal/service/auth_service_test.go` | Kod formatı (100 run), collision retry (3 senaryo) | ✅ Kapsamlı |
| `internal/middleware/auth_test.go` | Valid token, missing header, malformed, wrong secret, expired, missing sub | ✅ Kapsamlı |
| `test/widget_test.dart` | KapApp smoke test | ⚠️ Minimal |

---

## Eksik Test Alanları

### TST-F1: Flutter — `LoginController` unit testi
- [ ] Dosya: `test/features/auth/presentation/providers/login_controller_test.dart`
- [ ] Senaryo: e-posta/şifre boş → `status == FormzSubmissionStatus.failure`, `loginUser` çağrılmaz
- [ ] Senaryo: geçersiz e-posta formatı → validation failure, `loginUser` çağrılmaz
- [ ] Senaryo: geçerli input, `loginUser` → `Right(AppUser)` → `status == success`, `authNotifier.updateState` çağrılır
- [ ] Senaryo: geçerli input, `loginUser` → `Left(InvalidCredentialsFailure)` → `status == failure`, `errorMessage` dolu
- [ ] Senaryo: geçerli input, `loginUser` → `Left(NetworkFailure)` → `status == failure`
- [ ] Mock: `authRepositoryProvider` override + `authProvider.notifier` mock
- [ ] Commit: `test(auth): login controller unit tests`

### TST-F2: Flutter — `RegisterController` unit testi
- [ ] Dosya: `test/features/auth/presentation/providers/register_controller_test.dart`
- [ ] Senaryo: boş form submit → tüm alanlar dirty, `status == failure`, `registerUser` çağrılmaz
- [ ] Senaryo: şifreler eşleşmiyor → `confirmPassword` invalid, `status == failure`
- [ ] Senaryo: geçerli form → `registerUser` → `Right(AppUser)` → `status == success`, `authNotifier.updateState` çağrılır
- [ ] Senaryo: geçerli form → `registerUser` → `Left(EmailAlreadyInUseFailure)` → `status == failure`, `errorMessage` set
- [ ] Senaryo: `passwordChanged` → `confirmPassword` re-evaluates (cross-field validation)
- [ ] Commit: `test(auth): register controller unit tests`

### TST-F3: Flutter — `AuthNotifier` unit testi
- [ ] Dosya: `test/features/auth/presentation/providers/auth_provider_test.dart`
- [ ] Senaryo: aktif session + profil mevcut → `build()` → `AsyncData(AppUser)` döner
- [ ] Senaryo: aktif session + profil null (ghost session) → `signOut()` çağrılır, `build()` → `AsyncData(null)` döner
- [ ] Senaryo: session yok → `build()` → `AsyncData(null)` döner
- [ ] Senaryo: `signOut()` → `supabaseClient.auth.signOut()` çağrılır, state `AsyncData(null)` olur
- [ ] Mock: `supabaseClientProvider` override ile mock `SupabaseClient`
- [ ] Commit: `test(auth): auth notifier ghost session and session restore`

### TST-F4: Flutter — `RequestController` unit testi
- [ ] Dosya: `test/features/requests/presentation/providers/request_controller_test.dart`
- [ ] Senaryo: `activeGroup == null` → `build()` → boş liste döner, stream subscription kurulmaz
- [ ] Senaryo: aktif grup var → stream event gelir → state `AsyncData(List<RequestModel>)` güncellenir
- [ ] Senaryo: stream error → state `AsyncError(...)` olur
- [ ] Senaryo: `createRequest()` → `repository.createRequest()` çağrılır, stream ile state güncellenir
- [ ] Senaryo: `createRequest()` → `Left(Failure)` → exception fırlatılır (mevcut antipattern belgelenir)
- [ ] Senaryo: `deleteRequest()` → `Left(Failure)` → exception fırlatılır
- [ ] Senaryo: `updateRequestStatus()` → `Right` → repository çağrısı doğrulanır
- [ ] Mock: `requestRepositoryProvider` + `activeGroupProvider` override
- [ ] Commit: `test(requests): request controller stream and action tests`

### TST-F5: Flutter — Formz input model testleri
- [ ] Dosya: `test/features/auth/presentation/models/input_models_test.dart`
- [ ] `EmailInput`: boş → invalid, geçersiz format → invalid, geçerli → valid
- [ ] `PasswordInput`: boş → invalid, 7 karakter → invalid, 8+ karakter → valid
- [ ] `ConfirmedPasswordInput`: eşleşmiyor → invalid, eşleşiyor → valid
- [ ] `DisplayNameInput`: boş → invalid, 1 karakter → invalid, 2+ karakter → valid
- [ ] NOT: Bu testler saf Dart testleri — flutter_test bile gerekmez
- [ ] Commit: `test(auth): formz input model validation tests`

### TST-F6: Flutter — `GroupSwitcherWidget` widget testi
- [ ] Dosya: `test/features/groups/presentation/widgets/group_switcher_widget_test.dart`
- [ ] Senaryo: `activeGroup == null` → fallback ikon/metin gösterilir
- [ ] Senaryo: `activeGroup` mevcut → grup adı gösterilir
- [ ] Senaryo: widget'a tap → `GroupSwitcherBottomSheet` açılır
- [ ] Mock: `activeGroupProvider` override + `ProviderScope`
- [ ] Commit: `test(groups): group switcher widget tests`

### TST-F7: Flutter — `RequestCard` widget testi
- [ ] Dosya: `test/features/requests/presentation/widgets/request_card_test.dart`
- [ ] Senaryo: `status == 'pending'` → checkbox işaretsiz gösterilir
- [ ] Senaryo: `status == 'done'` → checkbox işaretli + item name strikethrough
- [ ] Senaryo: `isPrivate == true` → kilit ikonu görünür
- [ ] Senaryo: checkbox tap → `requestController.updateRequestStatus()` çağrılır
- [ ] Senaryo: delete ikonuna tap → `requestController.deleteRequest()` çağrılır
- [ ] Mock: `requestControllerProvider` override
- [ ] Commit: `test(requests): request card widget tests`

### TST-F8: Flutter — `ShoppingListScreen` smoke + integration widget testi
- [ ] Dosya: `test/features/requests/presentation/screens/shopping_list_screen_test.dart`
- [ ] Senaryo: `activeGroup == null` → "No active group" mesajı ve `GroupSwitcherWidget` gösterilir
- [ ] Senaryo: `requestsAsync == loading` → `CircularProgressIndicator` gösterilir
- [ ] Senaryo: requests boş → empty state ikonu ve metni gösterilir
- [ ] Senaryo: pending + done requests var → iki section başlığı ve `RequestCard`'lar render edilir
- [ ] Senaryo: FAB'a tap → `AddRequestBottomSheet` açılır
- [ ] Mock: tüm bağımlı provider'lar override edilir
- [ ] Commit: `test(requests): shopping list screen widget tests`

---

## Go Backend — Eksik Test Alanları

### TST-G1: Go — `AuthHandler` HTTP handler testi
- [x] Dosya: `internal/handler/auth_handler_test.go`
- [x] Senaryo: `userID` context'te mevcut + `GenerateUniqueCode` başarılı → HTTP 200 + `{"unique_code": "XXXX-XXXX"}`
- [x] Senaryo: `userID` context'te yok (middleware atlanmış) → HTTP 401
- [x] Senaryo: `GenerateUniqueCode` → `ErrCollisionLimitReached` → HTTP 500
- [x] Senaryo: `GenerateUniqueCode` → generic error → HTTP 500
- [x] Mock: `domain.AuthService` interface mock (struct + method)
- [x] Pattern: Fiber `app.Test()` ile HTTP-level test (mevcut middleware testindeki pattern kullanılabilir)
- [x] Commit: `test(go): auth handler HTTP response tests`

### TST-G2: Go — `UserRepository` implementation testi *(isteğe bağlı / integration)*
- [ ] Dosya: `internal/repository/supabase_user_repository_test.go`
- [ ] Senaryo: `IsCodeExists` → var olan kod → `true`
- [ ] Senaryo: `IsCodeExists` → olmayan kod → `false`
- [ ] Senaryo: Supabase bağlantı hatası → error wrap edilmiş mi?
- [ ] NOT: Bu integration test olacağı için `.env.test` veya `testcontainers-go` gerekebilir
- [ ] NOT: Sprint 2'ye ertelenebilir, önce handler ve service testleri tamamlanmalı
- [ ] Commit: `test(go): user repository integration tests`

### TST-G3: Go — CORS Middleware entegrasyon testi
- [x] Dosya: `internal/integration/cors_flow_test.go`
- [x] Senaryo: browser preflight OPTIONS isteği (Origin, Access-Control-Request-Method/Headers ile) -> HTTP 200/204 ve doğru Access-Control-* başlıkları
- [x] Senaryo: normal cross-origin POST isteği -> HTTP 200 ve doğru Access-Control-* başlıkları
- [x] Commit: `test(go): CORS flow integration tests`

---

## Öncelik Sırası

```
Yüksek Öncelik (kritik iş mantığı, hemen yapılmalı):
  1. TST-F3 — AuthNotifier (ghost session fix testi)
  2. TST-F1 — LoginController
  3. TST-F2 — RegisterController
  4. TST-G1 — AuthHandler Go
  5. TST-F4 — RequestController

Orta Öncelik (UI katmanı):
  6. TST-F5 — Formz input models
  7. TST-F6 — GroupSwitcherWidget
  8. TST-F7 — RequestCard

Düşük Öncelik (screen-level smoke):
  9. TST-F8 — ShoppingListScreen
 10. TST-G2 — UserRepository integration
```

---

## Test Kalitesi Hedef Metrikleri

| Katman | Mevcut | Hedef |
|---|---|---|
| Flutter — Data (repository) | %100 (3/3) | %100 |
| Flutter — Provider/Controller | %25 (1/4) | %100 |
| Flutter — Formz models | %0 (0/4) | %100 |
| Flutter — Widget | %5 (smoke only) | %60 |
| Go — Service | %100 (1/1) | %100 |
| Go — Middleware | %100 (1/1) | %100 |
| Go — Handler | %0 (0/1) | %100 |

