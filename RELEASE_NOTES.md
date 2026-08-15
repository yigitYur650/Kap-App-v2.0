# Kap-App Release Notes

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
