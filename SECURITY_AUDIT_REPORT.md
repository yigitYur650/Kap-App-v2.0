# 🔒 KAP-APP v2.0 — Kapsamlı Güvenlik Denetim Raporu

> **Rapor Tarihi:** 2026-08-12
> **İncelenen Sürüm:** v2.4.1+128
> **Yöntem:** Statik kaynak kod analizi — hiçbir kod değişikliği yapılmadı.
> **Kapsam:** Go Backend, Flutter Frontend, Supabase Migrations (RLS & Triggers), .env, Dockerfile, Deployment, Git History

---

## 📊 ÖZET TABLO

| Seviye | Açık Sayısı |
|--------|-------------|
| 🔴 KRİTİK (P0) | 5 |
| 🟠 YÜKSEK (P1) | 7 |
| 🟡 ORTA (P2) | 8 |
| 🔵 DÜŞÜK (P3) | 5 |
| **TOPLAM** | **25** |

---

## 🔴 KRİTİK SEVİYE (P0) — Acil Müdahale Gerekli

### SEC-001: `.env` Dosyası Git Reposunda — Tüm Gizli Anahtarlar Açıkta
- **Dosya:** `.env` (proje kökü)
- **Açıklama:** `.env` dosyası repo kökünde mevcut. İçinde şu gerçek (production) anahtarlar açık metin olarak yer alıyor:
  - `SUPABASE_URL` (gerçek proje URL'si)
  - `SUPABASE_ANON_KEY` (JWT — tam anon key)
  - `SUPABASE_SERVICE_ROLE_KEY` (**SÜPER YETKİLİ** — RLS bypass eder, tüm veriye erişir)
  - `SUPABASE_JWT_SECRET` (HMAC imzalama anahtarı — bu ile sahte JWT üretilebilir)
  - `GEMINI_API_KEY` (Google AI API anahtarı)
  - `GROQ_API_KEY` (Groq LLM API anahtarı)
- **Risk:** Bu anahtarları ele geçiren herhangi biri; tüm kullanıcı verilerine, auth sistemine, AI endpoint'lerine sınırsız erişim sağlayabilir. Service Role Key ile RLS tamamen devre dışı kalır.
- **Etki:** Tam veritabanı erişimi, sahte JWT üretimi, kullanıcı verisi sızması, hesap ele geçirme.
- **Not:** `.gitignore` dosyasında `*.env` ve `.env` pattern'leri mevcut ama dosya daha önce commit edilmiş olabilir veya `.gitignore` sonradan eklenmiş olabilir.

---

### SEC-002: Firebase Service Account JSON Repo'da Açıkta
- **Dosya:** `kap-app-backend/kap-app-119cb-firebase-adminsdk-fbsvc-8f763a91b4.json` (2,379 bytes)
- **Dosya:** `kap-app-backend/service-account.json` (2,379 bytes)
- **Açıklama:** Firebase Admin SDK service account JSON dosyaları backend dizininde açıkta bulunuyor. Bu dosyalar Firebase Cloud Messaging (FCM) ve diğer Firebase servislerine tam admin erişim sağlar.
- **Risk:** Bu dosyalar ile saldırgan; tüm kullanıcılara push notification gönderebilir, Firebase projesi üzerinde admin işlem yapabilir.
- **Not:** `kap-app-backend/.gitignore`'da `*.json` pattern'i var ama `.gitignore` eklenmeden önce commit edilmiş olabilir. Dosyaların aynı boyutta olması (2,379 bytes) aynı dosyanın kopyası olduğuna işaret eder.

---

### SEC-003: CORS Politikası `Access-Control-Allow-Origin: *` — Tam Wildcard
- **Dosya:** `kap-app-backend/cmd/server/main.go` (satır 33-41)
- **Açıklama:** Production sunucusunda CORS header'ı `"*"` olarak ayarlanmış:
  ```go
  c.Set("Access-Control-Allow-Origin", "*")
  ```
  Kodda bir `WARNING` yorumu var ("In production, replace `*` with explicit origins") ama bu değişiklik hiçbir zaman yapılmamış.
- **Risk:** Herhangi bir web sitesinden (kötü niyetli dahil) backend API'ye cross-origin istek atılabilir. Bu; CSRF benzeri saldırılar, token çalma ve yetkisiz API erişimine kapı açar.
- **Karşılaştırma:** CORS test dosyası (`cors_flow_test.go`) kısıtlı origin listesi ile test yapıyor ama production'daki `main.go` wildcard kullanıyor — tutarsızlık mevcut.

---

### SEC-004: Supabase Anon Key ile Konsola Log Basılıyor (Frontend)
- **Dosya:** `kap-app-front/lib/main.dart` (satır 40-46)
- **Açıklama:** Uygulama başlatılırken Supabase URL ve Anon Key prefix'i konsola yazılıyor:
  ```dart
  print('SUPABASE_URL: $supabaseUrl');
  print('SUPABASE_ANON_KEY length: ${supabaseAnonKey.length}');
  print('SUPABASE_ANON_KEY prefix: ${supabaseAnonKey.substring(0, 10)}...');
  ```
- **Risk:** Production build'lerde bu bilgiler cihaz loglarında kalır. Android logcat veya iOS Console ile görüntülenebilir. Web build'de ise browser console'da görünür.

---

### SEC-005: 2FA Bypass — Hardcoded Email İstisnası
- **Dosya:** `kap-app-front/lib/features/auth/data/supabase_auth_repository.dart` (satır 195)
- **Dosya:** `supabase/migrations/25_add_2fa_enabled_to_users.sql` (satır 17)
- **Açıklama:** `halil@gmail.com` adresi hem Flutter kodunda hem de veritabanı migration'ında 2FA'dan muaf tutulmuş:
  ```dart
  if (appUser.is2FAEnabled && appUser.email.trim().toLowerCase() != 'halil@gmail.com') {
  ```
  ```sql
  UPDATE public.users SET is_2fa_enabled = false WHERE email = 'halil@gmail.com';
  ```
- **Risk:** Belirli bir hesabın güvenlik kontrollerinden muaf tutulması, kaynak kodunu gören herkes tarafından bilinir ve hedef haline gelebilir. Bu hesap ele geçirildiğinde 2FA koruması olmaz.

---

## 🟠 YÜKSEK SEVİYE (P1)

### SEC-006: AI Prompt Injection Güvenlik Açığı (Indirect Prompt Injection)
- **Dosya:** `kap-app-backend/internal/service/ai_service.go` (satır 121-216)
- **Açıklama:** `EstimatePrices` ve `GetShoppingRecommendations` fonksiyonlarında kullanıcı girdileri (`item_name`, `quantity`, `unit`) doğrudan LLM prompt'una enjekte ediliyor:
  ```go
  prompt := fmt.Sprintf(`...Ürünler: %s...`, strings.Join(formattedItems, ", "))
  ```
  `sanitizeInput` fonksiyonu sadece `\n`, `\r` karakterlerini temizliyor ve uzunluk sınırı koyuyor. Ancak prompt injection payload'ları bu sanitizasyondan geçer.
- **Risk:** Saldırgan, kötü niyetli ürün adları göndererek AI yanıtlarını manipüle edebilir, yanıltıcı fiyatlar ürettirip kullanıcıları kandırabilir.

---

### SEC-007: Hata Mesajlarında İç Detay Sızıntısı
- **Dosya:** `kap-app-backend/internal/handler/ai_handler.go` (satır 53-55, 89-96)
- **Açıklama:** AI handler'ları hata durumunda `err.Error()` değerini doğrudan istemciye dönüyor:
  ```go
  return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
      "error": err.Error(),
  })
  ```
  Bu hata mesajları; API key parçaları, sunucu iç yolları, Groq/Gemini hata detayları gibi hassas bilgileri içerebilir.
- **Risk:** Saldırgan, sunucu iç yapısı hakkında bilgi toplayabilir (information disclosure).

---

### SEC-008: OS Command Injection Riski — Playwright Scraper
- **Dosya:** `kap-app-backend/internal/service/playwright_price_service.go` (satır 27)
- **Açıklama:** Kullanıcı tarafından sağlanan `query` parametresi shell komutuna aktarılıyor:
  ```go
  cmd := exec.CommandContext(ctx, "node", s.scriptPath, fmt.Sprintf("--query=%s", query))
  ```
- **Risk:** Go'nun `exec.CommandContext` kullanımı shell interpolation yapmaz, doğrudan OS command injection riski düşüktür. Ancak `node` scriptine geçirilen argüman içinde özel karakterler script tarafında sorun yaratabilir.

---

### SEC-009: JWT Token Doğrulama — `iss` ve `aud` Claim Kontrolü Eksik
- **Dosya:** `kap-app-backend/internal/middleware/auth.go` (satır 220-252)
- **Açıklama:** JWT parse işleminde `iss` (issuer) ve `aud` (audience) claim'leri kontrol edilmiyor.
- **Risk:** Başka bir Supabase projesinden veya farklı bir JWT sağlayıcıdan alınmış, aynı signing key ile imzalanmış geçerli bir token kabul edilebilir.

---

### SEC-010: `product_price_pool` Tablosunda Aşırı İzin Veren RLS
- **Dosya:** `supabase/migrations/22_add_product_price_pool_and_request_history.sql` (satır 34-39)
- **Açıklama:** `product_price_pool` tablosunda `FOR ALL` politikası `USING (true) WITH CHECK (true)` ile tanımlanmış:
  ```sql
  CREATE POLICY "Allow authenticated write price pool"
  ON public.product_price_pool FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);
  ```
- **Risk:** Herhangi bir kimliği doğrulanmış kullanıcı; fiyat verilerini silme, güncelleme ve istediği veriyi ekleme yetkisine sahip. Fiyat manipülasyonuna yol açar.

---

### SEC-011: `health_profiles` — Hassas Sağlık Verisi Varsayılan Olarak Public
- **Dosya:** `supabase/migrations/23_health_profiles_and_sharing.sql` (satır 11)
- **Açıklama:** `is_public` sütunu `DEFAULT true` ile tanımlanmış. Kullanıcıların kilo, boy, yaş, cinsiyet ve beslenme hedefleri gibi hassas sağlık verileri varsayılan olarak tüm kimliği doğrulanmış kullanıcılara açık.
- **Risk:** KVKK/GDPR açısından kişisel sağlık verisi "özel nitelikli veri" kategorisindedir. Varsayılan olarak herkese açık olması ciddi gizlilik ihlalidir.

---

### SEC-012: Admin Dashboard Rota Koruması Eksik (Client-Side Only)
- **Dosya:** `kap-app-front/lib/core/navigation/router.dart` (satır 62-65)
- **Açıklama:** `/admin` rotası `GoRouter`'da herhangi bir guard olmadan tanımlanmış. Admin kontrolü yalnızca widget içinde client-side olarak yapılıyor.
- **Risk:** Admin paneli UI'ı herhangi bir kullanıcıya gösterilebilir. Backend API katmanı admin kontrolü yapsa da, bilgi sızıntısı ve social engineering riski mevcuttur.

---

## 🟡 ORTA SEVİYE (P2)

### SEC-013: Rate Limiter In-Memory — Sunucu Restart ile Sıfırlanır
- **Dosya:** `kap-app-backend/internal/middleware/rate_limiter.go`
- **Açıklama:** AI rate limiter tamamen RAM'de tutuluyor. Sunucu yeniden başlatıldığında tüm limit sayaçları sıfırlanır.
- **Risk:** Saldırgan, sunucuyu yeniden başlatmaya zorlayarak rate limit'i bypass edebilir. Render free tier'de idle timeout sonrası sunucu restart olur.

---

### SEC-014: Base64 Image Payload DoS Riski
- **Dosya:** `kap-app-backend/internal/handler/ai_handler.go` (satır 80-85)
- **Açıklama:** Receipt scanner 10MB base64 limiti koyuyor, ancak Fiber'ın body limit konfigürasyonu açıkça ayarlanmamış.
- **Risk:** Büyük payload'lar ile memory pressure oluşturulabilir. Rate limiter başına 20 istek x 10MB = 200MB/saat/kullanıcı.

---

### SEC-015: Fiber Konfigürasyonunda Güvenlik Headerları Eksik
- **Dosya:** `kap-app-backend/cmd/server/main.go` (satır 27-29)
- **Açıklama:** Fiber uygulaması şu güvenlik headerları olmadan çalışıyor:
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`
  - `Strict-Transport-Security` (HSTS)
  - `Content-Security-Policy`
  - `X-XSS-Protection`
- **Risk:** MIME sniffing, clickjacking ve downgrade attack'lerine karşı korumasız.

---

### SEC-016: Gemini API Key URL Query String'de Taşınıyor
- **Dosya:** `kap-app-backend/internal/service/ai_service.go` (satır 279, 425)
- **Açıklama:** Gemini API çağrılarında API key URL query parametresi olarak gönderiliyor:
  ```go
  url := fmt.Sprintf("...?key=%s", s.geminiKey)
  ```
- **Risk:** API key'ler URL'de taşındığında; sunucu logları, reverse proxy logları ve CDN loglarında kalıcı olarak kaydedilir.

---

### SEC-017: Graceful Shutdown Timeout — AI İstekleri İle Uyumsuz
- **Dosya:** `kap-app-backend/cmd/server/main.go` (satır 139)
- **Açıklama:** AI servis çağrıları 20 saniyelik timeout'a sahip. Ancak graceful shutdown window'u yalnızca 10 saniye.
- **Risk:** Uzun süren AI isteği shutdown sırasında kesilecektir.

---

### SEC-018: Dockerfile — Root Kullanıcı ile Çalıştırma
- **Dosya:** `kap-app-backend/Dockerfile` (satır 29)
- **Açıklama:** Container `WORKDIR /root/` ile root kullanıcı olarak çalışıyor. Non-root kullanıcı oluşturulmuyor.
- **Risk:** Container escape durumunda saldırgan host üzerinde root yetkileri elde edebilir.

---

### SEC-019: `sanitizeInput` — Yetersiz Sanitizasyon
- **Dosya:** `kap-app-backend/internal/handler/ai_handler.go` (satır 130-138)
- **Açıklama:** `sanitizeInput` fonksiyonu sadece `\n` ve `\r` karakterlerini temizliyor. Unicode kontrol karakterleri, zero-width karakterler ve HTML/Script injection karakterleri temizlenmiyor.
- **Risk:** AI prompt injection ve potansiyel XSS riski.

---

### SEC-020: Rune vs Byte Uzunluk Kontrolü (Türkçe Karakter Sorunu)
- **Dosya:** `kap-app-backend/internal/handler/ai_handler.go` (satır 134)
- **Açıklama:** `sanitizeInput` fonksiyonu `len(cleaned)` ile byte uzunluğu kontrol ediyor, `utf8.RuneCountInString()` ile değil. Türkçe karakterler UTF-8'de 2 byte yer kaplar. `cleaned[:maxLen]` ile multi-byte karakter ortasından kesilebilir.
- **Risk:** Geçersiz UTF-8 string'lerin downstream sistemlerde beklenmedik davranışlara yol açması.

---

## 🔵 DÜŞÜK SEVİYE (P3)

### SEC-021: `render.yaml` — Eksik Environment Variables
- **Dosya:** `render.yaml`
- **Açıklama:** Render deployment konfigürasyonunda `SUPABASE_JWT_SECRET`, `GROQ_API_KEY`, `GEMINI_API_KEY`, `CORS_ALLOWED_ORIGINS` gibi önemli env var'lar eksik.
- **Risk:** Deployment tutarsızlıkları.

---

### SEC-022: `CheckUpdateHandler` — Unauthenticated Public Endpoint
- **Dosya:** `kap-app-backend/cmd/server/main.go` (satır 66)
- **Açıklama:** `/api/v1/app/check-update` endpoint'i herhangi bir authentication olmadan public erişime açık.
- **Risk:** Düşük — sadece versiyon bilgisi döner ama saldırganlar güncelleme döngüsünü takip edebilir.

---

### SEC-023: Version ID Doğrulaması Eksik — IDOR Riski
- **Dosya:** `kap-app-backend/internal/handler/app_version_handler.go` (satır 92-109)
- **Açıklama:** `DeleteVersionHandler` gelen `id` parametresinin UUID formatında olup olmadığını kontrol etmiyor.
- **Risk:** Düşük — Supabase REST API geçersiz UUID için hata dönecektir.

---

### SEC-024: FCM Push Notification — Yanıt Gövdesi İstemciye Döndürülüyor
- **Dosya:** `kap-app-backend/internal/handler/app_version_handler.go` (satır 188-192)
- **Açıklama:** FCM API yanıtı doğrudan istemciye döndürülüyor. FCM yanıtı içinde proje detayları bulunabilir.
- **Risk:** Düşük seviye bilgi sızıntısı.

---

### SEC-025: `health_profiles` — DELETE Politikası Tanımlı Değil
- **Dosya:** `supabase/migrations/23_health_profiles_and_sharing.sql`
- **Açıklama:** `health_profiles` tablosunda DELETE politikası tanımlanmamış. Kullanıcılar kendi sağlık profillerini silemez.
- **Risk:** GDPR "hakkımın silinmesini talep etme" (right to erasure) prensibiyle çelişir.

---

## ✅ GÜVENLİK MİMARİSİ — OLUMLU BULGULAR

| Alan | Durum |
|------|-------|
| RLS (Row Level Security) | ✅ Tüm tablolarda aktif, çoğu politika doğru tasarlanmış |
| JWT Doğrulama | ✅ ES256 (JWKS) + HS256 dual-mode desteği mevcut |
| JWKS Cache | ✅ Thread-safe, TTL tabanlı, stale fallback ile sağlam |
| Soft Delete | ✅ `requests` tablosunda fiziksel silme trigger ile engellenmiş |
| Admin Middleware | ✅ `system_admins` tablosu ile backend seviyesinde doğrulama |
| AI Rate Limiting | ✅ Per-user, 20 istek/saat limiti |
| Receipt Privacy | ✅ Base64 image RAM'de işlenip atılıyor, diske yazılmıyor |
| Input Sanitization | ✅ Temel seviyede mevcut (uzunluk sınırı + newline temizleme) |
| Password Hashing | ✅ Supabase Auth tarafından bcrypt ile yönetiliyor |
| Unique Code Collision | ✅ Retry mekanizması ve PostgreSQL unique constraint koruması |

---

## 🗺️ ÖNERİLEN AKSİYON PLANI (Öncelik Sırasına Göre)

1. **[P0] Tüm gizli anahtarları rotate edin** — Supabase, Gemini, Groq API anahtarlarını yeniden oluşturun.
2. **[P0] `.env` dosyasını git geçmişinden tamamen temizleyin** — `git filter-branch` veya `BFG Repo Cleaner` kullanın.
3. **[P0] Firebase service account JSON dosyalarını repo'dan kaldırın** — Render environment variable olarak taşıyın.
4. **[P0] CORS wildcard'ı kısıtlayın** — `cfg.CORSAllowedOrigins` değerini aktif kullanın.
5. **[P0] Production build'lerde console log'ları devre dışı bırakın.**
6. **[P0] Hardcoded 2FA bypass'ını kaldırın** — Admin kullanıcıyı veritabanı seviyesinde yönetin.
7. **[P1] AI prompt injection koruması ekleyin** — Input validation güçlendirin.
8. **[P1] Hata mesajlarını jenerik hale getirin** — İç detayları loglamaya, istemciye genel mesaj döndürmeye geçin.
9. **[P1] `product_price_pool` RLS'yi kısıtlayın** — Yazma yetkisini admin veya service role ile sınırlayın.
10. **[P1] Sağlık verisi gizliliğini `is_public = false` yapın.**
11. **[P2] Güvenlik headerlarını ekleyin** (Helmet benzeri middleware).
12. **[P2] Dockerfile'da non-root kullanıcıya geçin.**
13. **[P2] UTF-8 safe string truncation'a geçin.**

---

*Bu rapor yalnızca statik kod analizi ile hazırlanmıştır. Penetrasyon testi veya dinamik analiz yapılmamıştır.*
*Hiçbir kaynak kod dosyası değiştirilmemiştir.*
