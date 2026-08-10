# TASK.md — Kap-App Sprint 1-5 Progress Log

> Sprint Status: **Active Development & Deployment**
> Version: **2.4.1+141**
> Core Goal: Shared Household Shopping, AI Receipt Scanner, Live Price Scraper, Personal Fitness & Nutrition Hub

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
