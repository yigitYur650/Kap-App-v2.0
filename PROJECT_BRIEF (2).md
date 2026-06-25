# Kap-App — Project Brief

> This file is injected at the start of every agentic session.
> Do not modify during active development. Changes are only allowed before a new sprint begins.

---

## 1. Project Overview

**Kap-App** is a shared household/community shopping and inventory management app.
Users join groups via a unique code, manage shared shopping requests, track home inventory
(in stock / low / out), and send private requests visible only to a specific member.

Platform: **Flutter (mobile, iOS + Android)**
Backend: **Supabase** (PostgreSQL + Auth + Realtime) + **Go API** (business logic layer)

---

## 2. Tech Stack (Locked)

| Layer | Technology |
|---|---|
| Mobile | Flutter 3.x (Dart) |
| Auth + DB + Realtime | Supabase (`supabase_flutter`) |
| Business logic API | Go (Fiber framework) |
| State management | Riverpod (`flutter_riverpod` + `riverpod_annotation`) |
| Navigation | go_router |
| Validation | formz |
| Local persistence | shared_preferences |
| i18n | flutter_localizations + intl |
| Testing (Flutter) | flutter_test + mocktail |
| Testing (Go) | stdlib `testing` + testify |

Do not introduce any library outside this list without explicit human approval.
Every session must begin by re-reading this stack. Never suggest alternatives mid-session.

---

## 3. Architecture

### Request routing rule
```
Flutter
  ├── → Supabase directly   : auth, raw CRUD, realtime subscriptions
  └── → Go API              : business logic, notifications, complex rules
```

Go is NOT a proxy for everything. It handles only what Supabase cannot do cleanly:
- `unique_code` generation
- Push notification dispatch
- Complex business rules (recipe ↔ inventory matching, future location logic)
- Rate limiting, third-party integrations

### Folder structure

```
kap-app/
├── .agent/
│   ├── PROJECT_BRIEF.md       ← this file
│   ├── TASK.md
│   └── bug-and-fix.md
├── kap-app-front/             ← Flutter
│   └── lib/
│       ├── main.dart
│       ├── core/
│       │   ├── repositories/  # Abstract interfaces only
│       │   ├── models/        # Shared domain models
│       │   └── errors/        # AppError types
│       ├── features/
│       │   ├── auth/
│       │   │   ├── data/
│       │   │   ├── providers/
│       │   │   └── screens/
│       │   ├── groups/
│       │   │   ├── data/
│       │   │   ├── providers/
│       │   │   └── screens/
│       │   └── requests/
│       │       ├── data/
│       │       ├── providers/
│       │       └── screens/
│       └── shared/
│           ├── widgets/
│           └── theme/
├── kap-app-backend/           ← Go API
│   ├── cmd/server/main.go
│   ├── internal/
│   │   ├── handler/           # HTTP handlers (one file per feature)
│   │   ├── service/           # Business logic (one file per feature)
│   │   ├── repository/        # DB access interfaces + Supabase impl
│   │   └── middleware/        # Auth, logging, rate limit
│   ├── pkg/
│   │   └── supabase/          # Supabase admin client wrapper
│   └── config/
└── supabase/
    ├── migrations/            # Ordered SQL migration files
    └── policies/              # One .sql file per RLS policy
```

Dependency direction (Flutter): `screens → providers → repositories ← data`
Dependency direction (Go): `handler → service → repository`
Never import a feature package into `core/` or `pkg/`.

---

## 4. Coding Rules

### General
- All prompts and code comments in **English**
- Every widget, provider, repository, handler, and service does **one thing only**
- No hardcoded strings in Flutter — all user-facing text via `.arb` i18n files
- Go handlers never contain business logic — delegate to service layer immediately

### Flutter naming
- Files: `snake_case.dart`
- Classes / Widgets: `PascalCase`
- Providers: `camelCaseProvider`
- Repositories: `FeatureRepository` (abstract) / `SupabaseFeatureRepository` (impl)
- Models: `PascalCase` (e.g. `AppUser`, `Group`, `ShoppingRequest`)
- i18n keys: `feature.action.label` dot notation in `.arb` files

### Go naming
- Files: `snake_case.go`
- Exported types: `PascalCase`
- Interfaces: `FeatureService`, `FeatureRepository`
- Handlers: `FeatureHandler` struct with method per route
- Unexported helpers: `camelCase`

### Error handling
- Flutter: every repository method returns `({T? data, AppError? error})` — never throws to UI
- Go: every service method returns `(T, error)` — handlers convert to HTTP response, never panic
- `AppError` defined in `core/errors/app_error.dart`
- Go errors wrapped with `fmt.Errorf("context: %w", err)` — never swallowed silently
- On debug: explain root cause first, then propose a fix that does not break other parts

### RLS rules
- Each policy is its own file under `supabase/policies/`
- Never patch a broken RLS rule in production — reproduce locally, inspect fully, then apply
- Use helper functions `is_group_member()` and `is_group_admin()` — never inline the logic

---

## 5. Database Schema (Summary)

| Table | Key Fields |
|---|---|
| `users` | id (PK), display_name, unique_code, email, email_verified |
| `groups` | id (PK), name, type (family/community), created_by (FK) |
| `group_members` | user_id + group_id (composite PK), role (admin/member) |
| `requests` | id, group_id, requested_by, item_name, is_private, private_to, status |
| `inventory` | id, group_id, added_by, item_name, stock_status (var/azaldı/yok) |
| `recipes` *(future)* | id, group_id, created_by, title, is_public |
| `recipe_items` *(future)* | id, recipe_id, ingredient, needed_qty |

**Critical:** `is_private = true` rows in `requests` are visible only to `private_to` or
`requested_by`. Enforced at RLS layer — never filter this in application or Go code.

---

## 6. Go API Endpoints (Sprint 1 scope)

| Method | Path | Handler | Description |
|---|---|---|---|
| POST | `/api/v1/auth/generate-code` | `AuthHandler` | Generate unique_code on registration |
| POST | `/api/v1/notifications/send` | `NotificationHandler` | Send push notification |

All routes require Supabase JWT validation via middleware. Go never manages sessions —
it validates the token Supabase issued, nothing more.

---

## 7. Task & Progress Rules

- Active task list lives in `TASK.md` — updated every end of day
- New features or scope changes only added **before a sprint starts** — never mid-sprint
- Each task is atomic: one task = one micro unit = one testable piece
- Every micro unit is tested immediately after being written

---

## 8. Bug & Fix Log

All bugs recorded in `bug-and-fix.md`:
```
## [date] Short title
Symptom / Root cause / Fix / Risk / Status
```

---

## 9. Session Startup Checklist

Before writing any code:
1. [ ] PROJECT_BRIEF.md read in full
2. [ ] TASK.md current sprint loaded
3. [ ] bug-and-fix.md last 3 entries reviewed
4. [ ] Single task for this session clearly stated
5. [ ] Task is atomic — if not, break it down first
6. [ ] Affected files identified before touching anything

---

## 10. Output Format per Session

```
### Session Summary
- Task completed: [name]
- Files changed: [list]
- Decisions made: [architectural or naming choices]
- Assumptions: [what was assumed]
- Edge cases not covered: [known gaps]
- Suggested next task: [one atomic next step]
```

---

## 11. What the Agent Must Never Do

- Never modify `core/errors/`, `core/repositories/`, or `pkg/supabase/` without explicit instruction
- Never install a library not in the approved stack
- Never add a task to TASK.md mid-sprint
- Never patch an RLS rule — fix at root
- Never leave a hardcoded string in any Flutter widget
- Never put business logic in a Go handler — delegate to service immediately
- Never use `dynamic` in Dart or `interface{}` in Go without an explanatory comment
- Never produce more than one micro unit per session unless explicitly asked
- Never proceed if the task is ambiguous — ask first
