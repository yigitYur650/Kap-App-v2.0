# TASK2.0.md — Kap-App Sprint 6 & Release Tracking

> **Current Version:** `2.4.1+151`
> **Release Build Status:** 🟢 100% SUCCESS (`app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`)

---

## 🛠️ Sprint 6 Completed Deliverables

1. **Mandatory 2FA OTP & Resend SMTP Integration**:
   - `25_add_2fa_enabled_to_users.sql` migration.
   - Resend Custom SMTP credentials active in Supabase.
   - `halil@gmail.com` protected as System Admin & exempted from 2FA.
   - Dynamic 6-8 digit OTP input screen with rate-limit status code 429 friendly handling.

2. **Security & Önbellek Temizliği**:
   - `isSystemAdminProvider` watching `authProvider`.
   - `_invalidateAllUserProviders()` invalidating all user-specific data on logout and session switches.

3. **Su Tüketimi & Vücut Yağ Oranı Analizi**:
   - `26_add_water_intake_and_body_fat_to_health_profiles.sql` migration.
   - `FitnessCalculator`: `calculateRecommendedWater` and `categorizeBodyFat`.
   - `HealthProfileScreen`: Water Intake (L) & Body Fat (%) form inputs & summary cards.

4. **Admin Bildirim Yönetimi & Otomatik Hatırlatıcılar**:
   - `27_create_scheduled_notifications.sql` migration.
   - Admin Dashboard Tab 3: **Otomatik Hatırlatıcılar**.
   - Daily recurring local notifications (12:00 Water, 17:00 Market, 20:00 Nutrition).
   - Live group item creation instant notifications.
