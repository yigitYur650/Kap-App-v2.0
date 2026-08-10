# 🗺️ Kap-App — Complete Project Map for LLM Agents (v5)

> **Purpose:** This file is designed to be read by an LLM agent at the start of every session.
> It contains the full structural fingerprint of the project, all architectural decisions,
> known technical debt, error handling patterns, database schema, and AI pipelines.
>
> **Last updated:** 2026-08-11 (v5 - Version 2.4.1+141: Personal Fitness & Nutrition Hub, CategoryHelper, Profile-Aware AI Engine & Category Filter Chips)
> **Status:** Sprints 1-5 complete. Go Backend & Flutter analyze 100% CLEAN (0 Errors).
>
> **⚠️ NOTE:** This v5 file is the AUTHORITATIVE version.

---

## 1. 🏗️ PROJECT OVERVIEW

**Kap-App** is a shared household/community shopping, inventory management, AI-powered price estimation, and personal health/fitness app.

| Layer | Technology |
|---|---|
| Mobile | **Flutter 3.x** (Dart) — Target: Web, Android, iOS |
| State management | **Riverpod 3** (`flutter_riverpod` — `AsyncNotifier`, `Notifier`, `FutureProvider`) |
| Auth + DB + Realtime | **Supabase** (`supabase_flutter` — Auth, PostgreSQL, Realtime streams) |
| Local persistence | **shared_preferences** + local fallback cache |
| Business logic API | **Go** (Fiber v2 framework) — runs on port 8080 |
| AI Engines | **Groq** (Llama 3.3 70B primary) + **Gemini** (2.0 Flash / 3.6 Flash fallback) |
| Navigation | **go_router** + `StatefulShellRoute` (4 bottom tabs: Hub, Liste, Kişisel, Ayarlar) |
| i18n | **flutter_localizations** + **intl** (`.arb` files for `en` and `tr`) |
| Functional Error Handling | **fpdart** (`Either<Failure, T>`) — zero uncaught UI crashes |

---

## 2. 📱 BOTTOM NAVIGATION TABS

1. **Tab 0 (`/`):** Hub Dashboard (Active group overview & quick stats).
2. **Tab 1 (`/list`):** Shopping List (Realtime requests, receipt OCR scanner, price estimator, AI recommendations, category filters).
3. **Tab 2 (`/health`):** Kişisel Fitness & Beslenme (Mifflin-St Jeor BMR, TDEE, Target Calories, Macros, Form inputs, Privacy toggle).
4. **Tab 3 (`/settings`):** Settings & Admin tools.

---

## 3. 🧠 KEY UTILITIES & ALGORITHMS

### A. `CategoryHelper` (`lib/shared/utils/category_helper.dart`)
- Analyzes product item names with 100+ Turkish supermarket keywords.
- Categories: `Süt & Kahvaltılık`, `Meyve & Sebze`, `Et & Piliç`, `Temel Gıda`, `Atıştırmalık`, `İçecek`, `Temizlik`, `Genel`.

### B. `FitnessCalculator` (`lib/shared/utils/fitness_calculator.dart`)
- **BMR:** $10 \times \text{weight} + 6.25 \times \text{height} - 5 \times \text{age} + (gender == 'male' ? 5 : -161)$
- **TDEE:** BMR $\times$ Activity Multiplier ($1.2$ - $1.9$)
- **Goal Adjustments:** Kilo Verme ($-500$), Kilo Alma ($+500$), Form Koruma ($0$)
- **Macros:** Protein ($2\text{g/kg}$), Fat ($0.8\text{g/kg}$), Carbs (Remaining / 4).

### C. Profile-Aware AI Recommendation Engine (`ai_service.go`)
- Receives user's personal health profile (weight, height, age, goal, BMR, TDEE, target calories, macros).
- Generates 5 categories of Turkish tips: `health`, `savings`, `recipe`, `missing`, `storage`.
- Dialog features category filter chips (`Tümü`, `Sağlık`, `Tasarruf`, `Tarifler`, `Unutulanlar`, `Tazelik`) & 1-click **"⚡ Tüm Önerilenleri Sepete Ekle"** batch action.

---

## 4. 🗄️ DATABASE MIGRATIONS SUMMARY

- `01` - `21`: Auth, Groups, Requests, Realtime Streams, RLS, Push Notifications.
- `22_add_product_price_pool_and_request_history.sql`: Price pool & purchase history.
- `23_health_profiles_and_sharing.sql`: `health_profiles` table, RLS policies, updated_at trigger.

---

## 5. 🐛 KNOWN BUGS & FIXES REFERENCE

For the full detailed log of all 15 resolved technical issues, refer to [BUGS_AND_FIXES.md](file:///c:/Users/yigit/OneDrive/Desktop/kap-app-full/BUGS_AND_FIXES.md).
