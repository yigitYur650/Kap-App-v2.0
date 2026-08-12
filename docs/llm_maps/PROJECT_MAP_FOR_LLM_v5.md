# 🗺️ Kap-App — Complete Project Map for LLM Agents (v5)

> **Purpose:** This file is designed to be read by an LLM agent at the start of every session.
> It contains the full structural fingerprint of the project, all architectural decisions,
> known technical debt, error handling patterns, database schema, and AI pipelines.
>
> **Last updated:** 2026-08-12 (v5 - Version 2.4.1+151: Mandatory 2FA via Resend, Water & Body Fat Analysis, Admin Scheduled Notification System & Release APK)
> **Status:** Sprints 1-6 complete. Release APK Built (100% Success). Go Backend & Flutter analyze 100% CLEAN (0 Errors).
>
> **⚠️ NOTE:** This v5 file is the AUTHORITATIVE version.

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
| i18n | **flutter_localizations** + **intl** (`.arb` files for `en` and `tr`) |
| Functional Error Handling | **fpdart** (`Either<Failure, T>`) — zero uncaught UI crashes |

---

## 2. 📱 NAVIGATION & TABS

1. **Hub Screen (`/hub`):** Active group overview, quick stats, active members.
2. **Shopping List (`/list`):** Realtime requests, receipt OCR scanner, price estimator, AI recommendations, category filters.
3. **Kişisel Fitness (`/health`):** BMR, TDEE, Target Calories, Macros, Daily Water Intake (L), Body Fat (%), Privacy toggle.
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
- **Goal Adjustments:** Kilo Verme ($-500$), Kilo Alma ($+500$), Form Koruma ($0$)
- **Macros:** Protein ($2\text{g/kg}$), Fat ($0.8\text{g/kg}$), Carbs (Remaining / 4).
- **Water Intake:** $\text{weight} \times 0.035 + \text{activityBonus}$ ($0.0 - 1.0\text{L}$).
- **Body Fat Classification:** `Temel Yağ`, `Sporcu`, `Fit / İdeal`, `Ortalama`, `Yüksek`.

### C. `NotificationService` (`lib/core/services/notification_service.dart`)
- Handles local daily recurring scheduled notifications (`12:00` Water, `17:00` Market, `20:00` Nutrition).
- Handles instant group activity push notifications (e.g. when a user adds a shopping request).

---

## 4. 🗄️ DATABASE MIGRATIONS SUMMARY

- `01` - `24`: Auth, Groups, Requests, Inventory, RLS, Price Pool.
- `25_add_2fa_enabled_to_users.sql`: `is_2fa_enabled` column (`DEFAULT true`), `halil@gmail.com` registered as System Admin.
- `26_add_water_intake_and_body_fat_to_health_profiles.sql`: `daily_water_intake_liters` and `body_fat_percentage` columns.
- `27_create_scheduled_notifications.sql`: `scheduled_notifications` table for automated daily admin push reminders.

---

## 5. 🐛 KNOWN BUGS & FIXES REFERENCE

For the full detailed log of all 20 resolved technical issues, refer to [BUGS_AND_FIXES.md](file:///c:/Users/yigit/OneDrive/Desktop/kap-app-full/BUGS_AND_FIXES.md).
