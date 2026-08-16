# Kap-App Release Notes

## [2.4.1+175] - 2026-08-16
- **Yapılan Değişiklikler:**
  - Fiyat tahmin pipeline akışı güncellendi: Playwright Canlı Web Scraper -> Groq AI (`llama-3.3-70b-versatile`) -> Gemini AI Backup -> Standart Referans Fiyatlar.
  - `MarketPriceService` ve `AIService.EstimatePrices` servislerinde Playwright birincil canlı fiyat kaynağı olarak konumlandırıldı.
  - `price_scraper.js` script'indeki yönlendirme çakışmaları ve modül require fallback zinciri düzeltildi.
  - Production Dockerfile güncellendi (Alpine Linux imajına Node.js, Playwright ve Chromium bağımlılıkları eklendi).
  - Go backend CORS middleware'i dinamik portları destekleyecek şekilde güçlendirildi.
  - `auth_provider.dart` içerisindeki `isSystemAdminProvider` dairesel bağımlılık (CircularDependencyError) uyarısı giderildi.
- **Değişen Dosyalar:**
  - `kap-app-backend/internal/service/ai_service.go`
  - `kap-app-backend/internal/service/market_price_service.go`
  - `kap-app-backend/internal/service/ai_test.go`
  - `kap-app-backend/scripts/price_scraper.js`
  - `kap-app-backend/Dockerfile`
  - `kap-app-backend/cmd/server/main.go`
  - `kap-app-front/lib/features/auth/presentation/providers/auth_provider.dart`
  - `kap-app-front/pubspec.yaml`
  - `render.yaml`
  - `RELEASE_NOTES.md`
- **Gereken Env Değişkenleri:**
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE_KEY`
  - `SUPABASE_JWT_SECRET`
  - `GROQ_API_KEY`
  - `GEMINI_API_KEY`
  - `CORS_ALLOWED_ORIGINS`
  - `GO_BACKEND_URL`

## [2.4.1+174] - 2026-08-15
- **Yapılan Değişiklikler:**
  - Flutter tarafında `CategoryHelper`, `FitnessCalculator` (Guardrail 1 Kalori Tabanı, Guardrail 2 Böbrek Sınırı) ve `FoodDatabase` (Guardrail 3 Alerjen Filtresi) için birim testleri (`kap-app-front/test/unit_test.dart`) yazıldı ve testler başarıyla çalıştırıldı.
  - GitHub Actions CI/CD boru hattı (`.github/workflows/ci.yml`) Go backend testleri, Flutter kod analizi & birim testleri ve Playwright E2E testlerini kapsayacak şekilde yapılandırıldı.
  - Kapsamlı Türkçe Proje Haritası dokümanı hazırlandı.
- **Değişen Dosyalar:**
  - `kap-app-front/test/unit_test.dart`
  - `.github/workflows/ci.yml`
  - `RELEASE_NOTES.md`
- **Gereken Env Değişkenleri:**
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `GROQ_API_KEY`
  - `GEMINI_API_KEY`
