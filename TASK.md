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
- [ ] Implement `SupabaseAuthRepository` in `features/auth/data/`
- [ ] `registerUser(email, password, displayName)` — calls Supabase Auth
- [x] On register: generate `unique_code` (random readable string, server-side function)
- [ ] Insert row into `users` table after Supabase auth signup
- [ ] Unit test: `SupabaseAuthRepository` with mocktail
- [ ] Commit: `feat(auth): registration service`

### W1-3: Auth — Email verification
- [ ] Resend integration: Supabase sends verification email on signup (configure in Supabase dashboard — no custom code needed unless custom template)
- [ ] `VerifyEmailScreen` — shows "check your inbox" with resend button
- [ ] `resendVerificationEmail()` in `AuthRepository`
- [ ] Block app entry if `email_verified = false`
- [ ] Unit test: resend cooldown logic
- [ ] Commit: `feat(auth): email verification screen`

### W1-4: Auth — Login + session
- [ ] `loginUser(email, password)` in `AuthRepository`
- [ ] Riverpod `authProvider` — holds current user state (`AsyncValue<AppUser?>`)
- [ ] Auto-restore session on app launch (`supabase.auth.currentSession`)
- [ ] `LoginScreen` — email + password fields, formz validation
- [ ] Route guard: unauthenticated → `/login`, unverified → `/verify-email`, verified → `/home`
- [ ] Unit test: route guard logic
- [ ] Commit: `feat(auth): login and session restore`

### W1-5: Auth — UI polish
- [ ] `RegisterScreen` — display name, email, password, confirm password
- [ ] `LoginScreen` — email, password, "forgot password" placeholder
- [ ] All strings via i18n keys — zero hardcoded text
- [ ] Commit: `feat(auth): registration and login screens`

---

## Week 2 — Groups + Shopping List

### W2-1: Group — Create and join
- [ ] `GroupRepository` interface in `core/`
- [ ] `createGroup(name, type)` — inserts into `groups`, adds creator as admin in `group_members`
- [ ] `joinGroup(uniqueCode)` — looks up user by `unique_code`, adds to `group_members`
- [ ] `getMyGroups()` — returns all groups for current user
- [ ] Unit test: `createGroup` and `joinGroup`
- [ ] Commit: `feat(groups): create and join group service`

### W2-2: Group — Multi-group switcher
- [ ] Riverpod `activeGroupProvider` — holds currently selected group
- [ ] Top-left group switcher widget (`GroupSwitcherWidget`) — shows group name, tap to change
- [ ] `GroupSwitcherBottomSheet` — lists all user groups, tap to switch
- [ ] Active group persisted across sessions (shared_preferences)
- [ ] Unit test: active group switch
- [ ] Commit: `feat(groups): multi-group switcher`

### W2-3: Group — Member management screen
- [ ] `GroupMembersScreen` — lists members with display name and role badge
- [ ] Show current user's `unique_code` in settings screen (for sharing)
- [ ] Commit: `feat(groups): members screen and unique code display`

### W2-4: Shopping list — Core
- [ ] `RequestRepository` interface in `core/`
- [ ] `getRequests(groupId)` — fetches non-private + own private requests
- [ ] `createRequest(groupId, itemName, {isPrivate, privateTo})` 
- [ ] `updateRequestStatus(requestId, status)` — pending → done
- [ ] `deleteRequest(requestId)`
- [ ] Unit test: private request visibility logic
- [ ] Commit: `feat(requests): shopping list service`

### W2-5: Shopping list — UI
- [ ] `ShoppingListScreen` — grouped by status (pending on top)
- [ ] `RequestCard` micro component — item name, requester, status toggle, delete (own only)
- [ ] `AddRequestBottomSheet` — item name input, private toggle, member picker (if private)
- [ ] Private requests show lock icon — not visible to other members
- [ ] All strings via i18n
- [ ] Commit: `feat(requests): shopping list screen`

### W2-6: Integration + manual QA
- [ ] End-to-end flow test: register → verify → create group → add request → mark done
- [ ] End-to-end flow test: join group via unique code → see shared list → add private request
- [ ] Fix any blockers found — log each in `bug-and-fix.md`
- [ ] Commit: `test: sprint 1 integration qa`

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




