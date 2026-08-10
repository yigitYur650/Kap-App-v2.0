# 🗺️ Kap-App — Complete Project Map for LLM Agents (v4)

> **Purpose:** This file is designed to be read by an LLM agent at the start of every session.
> It contains the full structural fingerprint of the project, all architectural decisions,
> known technical debt, error handling patterns, and database schema — so the LLM can
> operate without reading every single file first.
>
> **Last updated:** 2026-08-11 (v4 - Version 2.4.1+128: Playwright Live Scraper, 24h In-Memory Price Cache & Gemini 3.6 Vision)
> **Status:** Sprint 1-4, AI Receipt OCR, Playwright Scraper, 24h In-Memory Cache & Version 2.4.1+128 complete. Go Backend tests 100% PASSING. Flutter analyze clean.
>
> **⚠️ NOTE:** This is v4. `PROJECT_MAP_FOR_LLM.md` (v1), `PROJECT_MAP_FOR_LLM_v2.md` (v2), and `PROJECT_MAP_FOR_LLM_v3.md` (v3) 
> exist alongside this file. This v4 file is the AUTHORITATIVE version.

---

## 1. 🏗️ PROJECT OVERVIEW

**Kap-App** is a shared household/community shopping and inventory management app.
Users join groups via a unique code, manage shared shopping requests, track home inventory
(in stock / low / out), and send private requests visible only to a specific member.

| Layer | Technology |
|---|---|
| Mobile | **Flutter 3.x** (Dart) — Web, iOS + Android target |
| State management | **Riverpod 3** (`flutter_riverpod` — `AsyncNotifier`, `Notifier`, `FutureProvider.family`) |
| Auth + DB + Realtime | **Supabase** (`supabase_flutter` — Auth, PostgreSQL, Realtime streams) |
| Business logic API | **Go** (Fiber v2 framework) — runs separately on port 8080 |
| Navigation | **go_router** |
| Validation | **formz** |
| Local persistence | **shared_preferences** |
| i18n | **flutter_localizations** + **intl** (`.arb` files for `en` and `tr`) |
| Testing (Flutter) | **flutter_test** + **mocktail** — Unit tests & widget tests |
| Testing (Go) | **stdlib testing** + **testify** — In-memory DB E2E isolation tests (100% PASSING) |
| Testing (E2E) | **Playwright** — Tests Supabase REST API & Backend endpoints |
| Functional error handling | **fpdart** (`Either<Failure, T>`) — no exceptions thrown to UI |

---

## 2. 📁 FOLDER STRUCTURE

```
kap-app-full/                      ← Monorepo root
├── .agent/                        ← LLM context files
│   ├── PROJECT_BRIEF.md           ← Master brief (injected at session start)
│   ├── TASK.md                    ← Sprint tasks + daily progress
│   ├── bug-and-fix.md             ← All bugs logged with root cause + fix
│   ├── PROJECT_MAP_FOR_LLM_v3.md  ← OLD v3 (kept for reference)
│   └── PROJECT_MAP_FOR_LLM_v4.md ← THIS FILE (authoritative)
├── kap-app-front/                 ← Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── l10n/                  ← Generated localization files (.arb)
│   │   ├── core/
│   │   │   ├── errors/
│   │   │   │   ├── failure.dart   ← Failure hierarchy
│   │   │   │   └── app_error.dart ← AppError wrapper
│   │   │   ├── models/
│   │   │   │   ├── app_user.dart
│   │   │   │   ├── group_model.dart (flat permissions, no type)
│   │   │   │   └── request_model.dart
│   │   │   ├── navigation/
│   │   │   │   ├── router.dart    ← GoRouter + auth redirect guard
│   │   │   │   └── shell_screen.dart
│   │   │   ├── network/
│   │   │   │   └── supabase_client.dart
│   │   │   ├── providers/
│   │   │   │   └── shared_preferences_provider.dart
│   │   │   └── repositories/      ← Abstract interfaces
│   │   │       ├── auth_repository.dart
│   │   │       ├── group_repository.dart
│   │   │       └── request_repository.dart
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   │   ├── data/
│   │   │   │   │   └── supabase_auth_repository.dart
│   │   │   │   ├── presentation/
│   │   │   │   │   ├── models/    ← Formz inputs
│   │   │   │   │   ├── providers/
│   │   │   │   │   │   ├── auth_provider.dart
│   │   │   │   │   │   ├── login_controller.dart
│   │   │   │   │   │   └── register_controller.dart
│   │   │   │   │   └── screens/
│   │   │   │   │       ├── login_screen.dart
│   │   │   │   │       └── register_screen.dart
│   │   │   │   └── data/
│   │   │   │       └── auth_repository_provider.dart
│   │   │   ├── groups/
│   │   │   │   ├── data/
│   │   │   │   │   ├── supabase_group_repository.dart
│   │   │   │   │   └── group_repository_provider.dart
│   │   │   │   └── presentation/
│   │   │   │       ├── providers/
│   │   │   │       │   ├── active_group_provider.dart
│   │   │   │       │   ├── user_groups_provider.dart
│   │   │   │       │   └── group_members_provider.dart
│   │   │   │       ├── screens/
│   │   │   │       │   ├── hub_screen.dart
│   │   │   │       │   └── settings_screen.dart
│   │   │   │       └── widgets/
│   │   │   │           ├── active_list_summary_card.dart
│   │   │   │           ├── create_group_dialog.dart
│   │   │   │           ├── join_group_dialog.dart
│   │   │   │           └── group_member_tile.dart
│   │   │   └── requests/
│   │   │       ├── data/
│   │   │       │   └── supabase_request_repository.dart
│   │   │       ├── presentation/
│   │   │       │   ├── providers/
│   │   │       │   │   └── request_controller.dart
│   │   │       │   ├── screens/
│   │   │       │   │   └── shopping_list_screen.dart
│   │   │       │   └── widgets/
│   │   │       │       ├── add_request_bottom_sheet.dart
│   │   │       │       └── request_card.dart
│   │   │       └── data/
│   │   │           └── request_repository_provider.dart
│   │   └── shared/
│   │       └── theme/
│   │           ├── app_colors.dart
│   │           ├── app_typography.dart
│   │           └── app_shapes.dart
│   └── e2e/
│       └── shopping_isolation_backend.spec.ts  ← Playwright E2E test
├── kap-app-backend/               ← Go API server
│   ├── cmd/server/main.go
│   ├── config/config.go
│   ├── internal/
│   │   ├── domain/
│   │   │   └── auth.go
│   │   ├── handler/
│   │   │   ├── auth_handler.go
│   │   │   ├── auth_handler_test.go
│   │   │   └── e2e_isolation_test.go ← In-memory E2E tests for flat model
│   │   ├── service/
│   │   │   ├── auth_service.go
│   │   │   └── auth_service_test.go
│   │   ├── repository/
│   │   │   └── supabase_user_repository.go
│   │   └── middleware/
│   │       ├── auth.go
│   │       └── auth_test.go
│   └── pkg/supabase/
│       └── client.go              ← Uses url.QueryEscape for REST params
└── supabase/
    ├── checks/
    │   └── rls_snapshot.sql       ← RLS & Security Diagnostic Snapshot Suite
    └── migrations/
        ├── 01_base_infrastructure.sql
        ├── 02_groups_and_membership.sql
        ├── 03_shopping_requests.sql
        ├── 04_inventory_management.sql
        ├── 05_recipes_and_lookup.sql
        ├── 06_cleanup_orphaned_policies.sql
        ├── 07_user_device_tokens.sql
        ├── 08_fix_admin_count_race.sql
        ├── 09_requests_expansion_and_casing_fix.sql
        ├── 10_group_join_code.sql
        ├── 11_fix_request_status_update_for_family.sql
        ├── 12_fix_requests_select_rls_group_deleted_at.sql
        ├── 13_enable_realtime_requests.sql
        ├── 14_fix_requests_update_rls_and_trigger.sql
        ├── 15_remove_admin_role_and_group_type.sql  ← Flat permission model
        └── 16_add_text_length_constraints.sql       ← Text length bounds
```

---

## 3. 🔄 RIVERPOD STATE LAYOUT

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
  └── param: groupId → queries group_members + users join (flat model, no role)

requestControllerProvider (AsyncNotifier<List<RequestModel>>)
  ├── watches: activeGroupProvider (only — NOT userGroupsProvider)
  ├── builds: subscribes to repository.getRequestsStream(groupId)
  ├── auto-disposes stream via ref.onDispose()
  └── methods: createRequest, updateRequestStatus, deleteRequest
```

---

## 4. ⚡ PERMISSION & DATA FLOW PATTERNS

### 4.1 Flat Permission Architecture (Migration 15)

In Kap-App v2.0, **all active group members have equal rights**:
- Any member can create shopping requests
- Any member can change request status (`pending` ↔ `done`)
- Any member can update or soft-delete requests
- Any member can edit group settings or delete/leave the group
- **No admin roles** (`group_members.role` column removed)
- **No group types** (`groups.type` column removed; family vs community distinction eliminated)

---

## 5. 🗄️ DATABASE SCHEMA (Supabase PostgreSQL)

### 5.1 Core Tables (as of Migration 16)

#### `users` (01_base_infrastructure.sql + 16_add_text_length_constraints.sql)
| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK → auth.users(id) ON DELETE CASCADE |
| display_name | text | NOT NULL, CHECK (char_length(display_name) BETWEEN 1 AND 100) |
| unique_code | text | UNIQUE NOT NULL |
| email | text | UNIQUE NOT NULL |
| email_verified | boolean | DEFAULT false |
| is_invitable | boolean | DEFAULT true |
| account_status | text | CHECK ('active','suspended','deleted') |
| created_at | timestamptz | DEFAULT now() |
| deleted_at | timestamptz | nullable |

#### `groups` (02_groups_and_membership.sql + 15_remove_admin_role_and_group_type.sql + 16)
| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK DEFAULT gen_random_uuid() |
| name | text | NOT NULL, CHECK (char_length(name) BETWEEN 1 AND 100) |
| join_code | text | UNIQUE (nullable, unique index WHERE deleted_at IS NULL) |
| created_by | uuid | → users(id) |
| created_at | timestamptz | DEFAULT now() |
| deleted_at | timestamptz | nullable |

*(Note: `type` column was DROPPED in migration 15).*

#### `group_members` (02_groups_and_membership.sql + 15_remove_admin_role_and_group_type.sql)
| Column | Type | Constraints |
|---|---|---|
| user_id | uuid | PK → users(id) ON DELETE CASCADE |
| group_id | uuid | PK → groups(id) ON DELETE CASCADE |
| joined_at | timestamptz | DEFAULT now() |

*(Note: `role` column was DROPPED in migration 15).*

#### `requests` (03_shopping_requests.sql + 14 + 15 + 16)
| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| group_id | uuid | NOT NULL → groups(id) ON DELETE CASCADE |
| requested_by | uuid | NOT NULL → users(id) |
| item_name | text | NOT NULL, CHECK (char_length(item_name) BETWEEN 1 AND 200) |
| is_private | boolean | DEFAULT false |
| private_to | uuid | → users(id) |
| status | text | DEFAULT 'pending', CHECK ('pending','done') |
| created_at | timestamptz | DEFAULT now() |
| deleted_at | timestamptz | nullable |

#### `product_price_pool` (22_add_product_price_pool_and_request_history.sql)
| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK DEFAULT gen_random_uuid() |
| product_name | text | NOT NULL UNIQUE |
| category | text | NOT NULL DEFAULT 'Genel' |
| estimated_price | numeric(10,2) | NOT NULL DEFAULT 0.00 |
| min_price | numeric(10,2) | NOT NULL DEFAULT 0.00 |
| max_price | numeric(10,2) | NOT NULL DEFAULT 0.00 |
| sample_count | integer | NOT NULL DEFAULT 1 |
| updated_at | timestamptz | DEFAULT now() |

*(Note: `requests` table was also expanded in Migration 22 with `category`, `bought_by`, `bought_at`, `bought_price`).*

---

## 6. 🧪 TEST INVENTORY & VERIFICATION

1. **Go Backend Tests:** `go test ./...` passes 100% cleanly (including AIService, MarketPriceService & FCM OAuth2 PEM tests).
2. **Flutter Codebase:** `flutter analyze` reports 0 errors and 0 warnings.
3. **Database Security:** Diagnostic script `supabase/checks/rls_snapshot.sql` available for verifying RLS policy health.

---

## 7. 🤖 AI INTEGRATION & SMART FEATURES (NEW IN BUILD 122-126)

### 7.1 Architecture & Models (0 TL Cost Infrastructure)
- **Groq API (`llama-3.3-70b-versatile`):** Ultra-fast text completion, categorization, and 2026 Turkish market price anchoring (Free Developer Tier).
- **Google Gemini 2.0 Flash Vision:** Receipt scanning and OCR price extraction (Free 1,500 requests/day).

### 7.2 Core Capabilities & Endpoints
1. **Live Turkish Market Price Engine (`MarketPriceService`):**
   - Queries live public market search APIs (Akakçe / Migros) using normalized queries (`sut fiyati`, `tavuk fiyati`).
   - Caches prices in Supabase `product_price_pool` table for 24 hours.
   - Falls back to 2026 inflation anchored AI prompts when live market scrapers are rate-limited.
2. **Smart Quantity & Variant Sensitivity (`ItemSpecDTO`):**
   - Sends product name + quantity + unit payload (`item_name: "üçgen peynir", quantity: "8'li"`).
   - Generates exact package pricing, unit specifications (`unit_spec: "8'li Standart Kutu (100g)"`), and variant hints (`variant_note: "24'lü Aile Boyu ise ~95 TL"`).
3. **RAM-Only Receipt Scanner (`ScanReceipt`):**
   - Accepts base64 encoded receipt photos.
   - Extracts store name, date, total, and line-item prices.
   - **Zero Retention Privacy:** Images processed in-memory (RAM) and immediately discarded. Never written to disk or storage buckets.
4. **Category Tabs Filtering (`CategoryTabsBar`):**
   - Dynamic tabbed filtering (*Tümü, Süt & Kahvaltılık, Meyve & Sebze, Temel Gıda, Atıştırmalık, İçecek, Temizlik, Genel*).
5. **Security & Rate Limiting (`AIRateLimiter`):**
   - JWT-authenticated rate limiter middleware in Go backend (max 20 AI requests / hour per user).
   - Sanitizes and truncates string inputs to max 30-100 characters.

---

*End of PROJECT_MAP_FOR_LLM_v4.md — This is the authoritative project map.*
