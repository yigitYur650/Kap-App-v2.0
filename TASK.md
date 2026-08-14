# TASK.md — Kap-App Progress Log

> Sprint Status: **Active Development & Deployment**
> Version: **2.5.0**
> Core Goal: Shared Household Shopping, AI Receipt Scanner, Live Price Scraper, Personal Health & Fitness Hub (Nutrition Engine v2), Mandatory 2FA & Automated Notification Engine

---

## Status Legend

- `[x]` Done
- `[~]` In progress
- `[ ]` Planned

---

## 🚀 Completed Sprints & Features Summary

### Week 1 — Foundation + Auth
- [x] Project scaffold & dependency resolution (`pubspec.yaml`)
- [x] Registration & Supabase Auth integration
- [x] Login + Session restore + Route guard
- [x] UI polish & i18n support (`en`, `tr`)

### Week 2 — Groups + Shopping List
- [x] Create & Join Group via unique code
- [x] Multi-group switcher
- [x] Group member management
- [x] Realtime Shopping Requests list & WebSocket stream

### Week 3 — AI Receipt Scanner & Market Price Engine
- [x] Receipt Camera & Gallery Picker
- [x] Gemini 2.0 Flash / 3.6 Flash Vision OCR parsing
- [x] Market Price Scraper & 24h In-Memory Price Cache
- [x] AI Price Estimator Bar & Breakdown Modal

### Week 4 — Smart Categorization Engine (`CategoryHelper`)
- [x] 100+ Turkish product keyword categorization engine
- [x] Auto-tagging on Supabase DB inserts
- [x] Live Category badge on item creation
- [x] Extended Category Filter bar with "Et & Piliç" tab

### Week 5 — Personal Health & Fitness Hub (`FitnessCalculator`)
- [x] New "Kişisel" (`/health`) bottom navigation tab
- [x] Mifflin-St Jeor BMR, TDEE, Target Calories & Macro calculation engine
- [x] Personal health profile form (Weight, Height, Age, Gender, Activity Level, Goal)
- [x] Optional Privacy toggle ("Grup Arkadaşlarıyla Paylaş")
- [x] SharedPreferences local persistence & Supabase fallback
- [x] 100% Responsive UI layout (Energy Cards & Macro Badges)
- [x] Personal Profile-Aware AI Recommendation Engine (`UserHealthProfileDTO`)
- [x] Category Filter Chips inside AI Recommendations Dialog
- [x] "⚡ Tüm Önerilen Ürünleri Sepete Ekle" 1-click batch insertion

### Week 6 — Security, 2FA, Water/Fat Analysis & Notification Engine
- [x] Mandatory 2-Step Email Verification (2FA) via Supabase Auth + Resend SMTP
- [x] 2FA exemption for `halil@gmail.com` as system admin
- [x] Session cache invalidation on logout (`_invalidateAllUserProviders()`)
- [x] Restricted Admin Panel button visibility in Settings Screen
- [x] 6 to 8 digit OTP verification screen with rate-limit handling (`/verify-otp`)
- [x] Daily Water Intake (Liters) & Body Fat Percentage (%) calculation engine
- [x] Water & Body Fat analysis cards in Health Profile screen (`health_profile_screen.dart`)
- [x] Admin Notification Management tab in Admin Dashboard (`scheduled_notifications`)
- [x] Daily automated recurring notifications at 12:00 (Water), 17:00 (Market), 20:00 (Nutrition)
- [x] Instant live group event push notifications on request creation
- [x] 100% SUCCESS Release APK Build (`app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`)

### Week 7 — Nutrition Engine v2 & Safety Guardrails
- [x] Mifflin-St Jeor BMR & TDEE calculation engine refactor
- [x] **Guardrail 1 (Gender Calorie Floor):** Mandatory minimum 1200 kcal (F) / 1500 kcal (M) with critical warning banner
- [x] **Guardrail 2 (Kidney Disease Limit):** Max 0.8g/kg protein limit when active; ISSN 0.8–2.4g/kg ranges for healthy users
- [x] **Guardrail 3 (Allergen Exclusion):** `FoodDatabase` with `filterByAllergens` excluding user allergens (`peanut`, `gluten`, `lactose`, etc.) from UI recommendations
- [x] Goal-specific macro portioning (Kas Yapımı: 40/40/20, Keto: 22/8/70, Dengeli: 30/40/30)
- [x] Health profile UI expansion (Kidney switch, Allergen FilterChips, Nutrition Model selector, Food Recommendation cards)
- [x] Zero hardcoded strings (`app_tr.arb` and `app_en.arb` localization)
- [x] Self-contained SQL Migration `28_add_nutrition_rules_fields_to_health_profiles.sql`
- [x] 100% CLEAN `flutter analyze` & `flutter gen-l10n` build

---

## 🚀 Sprint 8 — AI Kota, Monetizasyon & Abonelik Altyapısı (SSOT)

> **Proje:** Kap-App v2.0  
> **Modül:** AI Kota, Monetizasyon, Referral & Subscription Altyapısı  
> **Tarih:** 2026-08-15  

### 🗄️ Aşama 1: Veritabanı & RLS Katmanı (Supabase / PostgreSQL)
- [x] **Task 1.1:** `29_add_ai_usage_and_subscriptions.sql` migrasyonu (`user_ai_usage`, `user_subscriptions`, `referral_codes`, `referral_logs`, `processed_webhook_events`).
- [x] **Task 1.2:** `consume_ai_credit(p_user_id UUID)` atomic stored procedure (FOR UPDATE kilidi ve günlük otomatik reset).
- [x] **Task 1.3:** `claim_referral_reward(p_referrer_code TEXT, p_new_user_id UUID, p_device_hash TEXT)` fonksiyonu (Post-2FA & Device Fingerprinting).
- [x] **Task 1.4:** Row Level Security (RLS) politikaları ve performans indeksleri.

### ⚙️ Aşama 2: Backend Katmanı (Go / Fiber)
- [x] **Task 2.1:** Domain modellerinin eklenmesi (`internal/domain/subscription.go`, `internal/domain/ai_usage.go`).
- [x] **Task 2.2:** Repository katmanında kredi tüketim ve abonelik sorguları (`internal/repository/subscription_repository.go`).
- [x] **Task 2.3:** `AIService` ve `AIHandler` refaktörü (Kredi kontrolü & `402 Payment Required` hatası).
- [x] **Task 2.4:** RevenueCat Webhook Handler (`POST /api/v1/subscriptions/webhook`) & Idempotency kontrolü.
- [x] **Task 2.5:** Referral doğrulama endpoint'i (`POST /api/v1/referral/claim`).

### 📱 Aşama 3: Frontend Katmanı (Flutter & Riverpod)
- [x] **Task 3.1:** `purchases_flutter` & `google_mobile_ads` bağımlılıklarının eklenmesi ve `pubspec.yaml` versiyon güncellemesi.
- [x] **Task 3.2:** `subscription_provider.dart` ve `ai_quota_provider.dart` state notifier'ları.
- [x] **Task 3.3:** **Paywall / Limit Dialog (shadcn/ui standartlarında):** Pro Yükseltme, Ödüllü Reklam İzleme (+1), Arkadaş Daveti (+7 Gün Pro).
- [x] **Task 3.4:** i18n `.arb` dosyalarına yeni anahtarların eklenmesi (`app_tr.arb`, `app_en.arb`).

### 🧪 Aşama 4: Test & Edge Cases
- [x] **Task 4.1:** Eşzamanlı istek (concurrency) ve atomic RPC testleri.
- [x] **Task 4.2:** Referral anti-fraud ve device fingerprinting testleri.
- [x] **Task 4.3:** Webhook idempotency testleri.


