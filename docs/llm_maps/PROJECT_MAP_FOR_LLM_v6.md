# 🗺️ Kap-App — Complete Project Map for LLM Agents (v6)

> **Purpose:** This file is designed to be read by an LLM agent at the start of every session.
> It contains the full structural fingerprint of the project, all architectural decisions,
> known technical debt, error handling patterns, database schema, and AI pipelines.
>
> **Last updated:** 2026-08-12 (v6 - Version 2.5.0: Nutrition Engine v2 Refactor: ISSN Protein Ranges, 3 Safety Guardrails, Food Classification Database & Allergen Exclusion Filter)
> **Status:** Sprints 1-7 complete. Release APK Built (100% Success). Go Backend & Flutter analyze 100% CLEAN (0 Errors).
>
> **⚠️ NOTE:** This v6 file is the AUTHORITATIVE version.

---

## 1. 🏗️ PROJECT OVERVIEW

**Kap-App** is a shared household/community shopping, inventory management, AI-powered price estimation, personal health/fitness, and automated notification management app.

| Layer | Technology |
|---|---|
| Mobile | **Flutter 3.x** (Dart) — Target: Web, Android (Release APK), iOS |
| State management | **Riverpod 3** (`flutter_riverpod` — `AsyncNotifier`, `Notifier`, `FutureProvider`) |
| Auth + 2FA | **Supabase Auth** + **Resend SMTP** (Mandatory 2FA OTP Email Verification, `halil@gmail.com` exempted) |
| Database & Realtime | **Supabase PostgreSQL** + Realtime WebSockets |
| Local persistence | **shared_preferences** + `flutter_local_notifications` |
| Business logic API | **Go** (Fiber v2 framework) — runs on port 8080 |
| AI Engines | **Groq** (Llama 3.3 70B primary) + **Gemini** (2.0 Flash / 3.6 Flash fallback) |
| Navigation | **go_router** (`/hub`, `/list`, `/health`, `/settings`, `/verify-otp`, `/admin`) |
| i18n | **flutter_localizations** + **intl** (`.arb` files for `en` and `tr`) — Zero hardcoded text |
| Functional Error Handling | **fpdart** (`Either<Failure, T>`) — zero uncaught UI crashes |

---

## 2. 📱 NAVIGATION & TABS

1. **Hub Screen (`/hub`):** Active group overview, quick stats, active members.
2. **Shopping List (`/list`):** Realtime requests, receipt OCR scanner, price estimator, AI recommendations, category filters.
3. **Kişisel Fitness (`/health`):** Nutrition Engine v2 (BMR, TDEE, Calorie Floor Guardrail 1, Kidney Disease Limit Guardrail 2, Allergen FilterChips & Recommendation Exclusions Guardrail 3, Water & Body Fat analysis, Privacy toggle).
4. **Settings (`/settings`):** 2FA toggle switch, System Admin Panel navigation button (restricted to `isSystemAdminProvider`).
5. **Admin Dashboard (`/admin`):**
   - Tab 1: OTA App Version Release.
   - Tab 2: Instant Broadcast Push Notifications.
   - Tab 3: Otomatik Hatırlatıcılar (Scheduled automated daily notifications at 12:00, 17:00, 20:00).
6. **2FA Verification (`/verify-otp`):** 6 to 8 digit OTP verification screen with countdown timer and rate-limit handling.

---

## 3. 🧠 KEY UTILITIES & SERVICES

### A. `CategoryHelper` (`lib/shared/utils/category_helper.dart`)
- Analyzes product item names with 100+ Turkish supermarket keywords.
- Categories: `Süt & Kahvaltılık`, `Meyve & Sebze`, `Et & Piliç`, `Temel Gıda`, `Atıştırmalık`, `İçecek`, `Temizlik`, `Genel`.

### B. `FitnessCalculator` (`lib/shared/utils/fitness_calculator.dart`)
- **BMR:** $10 \times \text{weight} + 6.25 \times \text{height} - 5 \times \text{age} + (gender == 'male' ? 5 : -161)$
- **TDEE:** BMR $\times$ Activity Multiplier ($1.2$ - $1.9$)
- **Calorie Floor Guardrail 1:** Minimum 1200 kcal (female) / 1500 kcal (male) with critical warning banner.
- **Protein Guardrail 2:** ISSN ranges (0.8 - 2.4 g/kg) based on fitness goal (`muscle_building`, `fat_loss_keto`, `balanced`). Capped at 0.8 g/kg if `hasKidneyDisease` is active.
- **Goal Portioning:**
  - `muscle_building`: 40% Protein, 40% Carbs, 20% Fat
  - `fat_loss_keto`: 22% Protein, 8% Carbs, 70% Fat
  - `balanced`: 30% Protein, 40% Carbs, 30% Fat

### C. `FoodDatabase` (`lib/shared/utils/food_database.dart`)
- Classified food lists: Protein-dense (animal/plant), Healthy fats (unsaturated/omega3/keto), Complex carbs (low GI/fiber).
- **Allergen Exclusion Guardrail 3:** `filterByAllergens` filters out user allergens (`peanut`, `gluten`, `lactose`, etc.) from UI recommendations.

### D. `NotificationService` (`lib/core/services/notification_service.dart`)
- Local daily recurring scheduled notifications (`12:00` Water, `17:00` Market, `20:00` Nutrition).
- Instant group activity push notifications.

---

## 4. 🗄️ DATABASE MIGRATIONS SUMMARY

- `01` - `24`: Auth, Groups, Requests, Inventory, RLS, Price Pool.
- `25_add_2fa_enabled_to_users.sql`: `is_2fa_enabled` column (`DEFAULT true`), `halil@gmail.com` registered as System Admin.
- `26_add_water_intake_and_body_fat_to_health_profiles.sql`: `daily_water_intake_liters` and `body_fat_percentage` columns.
- `27_create_scheduled_notifications.sql`: `scheduled_notifications` table for automated daily admin push reminders.
- `28_add_nutrition_rules_fields_to_health_profiles.sql`: Self-contained table creation and columns `fitness_goal`, `has_kidney_disease`, `allergens`.

---

## 5. 🐛 KNOWN BUGS & FIXES REFERENCE

For the full detailed log of all 20 resolved technical issues, refer to [BUGS_AND_FIXES.md](file:///c:/Users/yigit/OneDrive/Desktop/kap-app-full/BUGS_AND_FIXES.md).
