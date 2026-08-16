# 🛠️ KAP-APP v2.0 — Playwright Fiyat Tarama Mimarisi & Bug/Fix Raporu

Bu doküman, Kap-App v2.0 projesindeki canlı web fiyat tarama (Playwright Scraper) pipeline'ının geliştirilmesi, karşılaşılan tüm teknik hatalar, uygulanan çözümler ve gelecek mimari (AWS & Redis Price Pool) yol haritasını içermektedir.

---

## 1. 🏗️ Fiyat Tahmin Mimarisi (Multi-Stage Price Estimation Pipeline)

Sistem, kullanıcının alışveriş listesindeki ürünlerin fiyatlarını en doğru ve en hızlı şekilde getirmek için **4 Aşamalı bir Koruma ve Tahmin Hattı** kullanır:

```
[Kullanıcı İstek Gönderir]
         │
         ▼
 ┌──────────────────────────────────────────────────────────┐
 │ STAGE 1: Playwright Live Web Scraper + 24H Cache         │
 │ - Önce 24 Saatlik In-Memory Cache taranır (0.001 ms).    │
 │ - Yoksa Akakçe üzerinden canlı Playwright araması yapılır.│
 └───────────────────────────┬──────────────────────────────┘
                             │ (Başarısız veya Bulunamadı ise)
                             ▼
 ┌──────────────────────────────────────────────────────────┐
 │ STAGE 2: Groq AI (llama-3.3-70b-versatile)               │
 │ - Türkiye 2026 Migros/BİM/A101 raf fiyatı standartları. │
 └───────────────────────────┬──────────────────────────────┘
                             │ (API veya Kota Hatası ise)
                             ▼
 ┌──────────────────────────────────────────────────────────┐
 │ STAGE 3: Gemini AI (gemini-flash) [Yedek AI]              │
 └───────────────────────────┬──────────────────────────────┘
                             │ (Yedek AI da Yanıt Vermezse)
                             ▼
 ┌──────────────────────────────────────────────────────────┐
 │ STAGE 4: Safety Baseline Fallback                        │
 │ - Garantili temel gıda referans fiyat kataloğu.         │
 └──────────────────────────────────────────────────────────┘
```

---

## 2. 🐛 Karşılaşılan Tüm Hatalar ve Uygulanan Çözümler

### ❌ Hata 1: `502 Bad Gateway` & `CORS Policy Blocked`
- **Semptom:** İstemci tarafında `POST /api/v1/ai/estimate-prices` isteğinde aynı anda hem `502 Bad Gateway` hem de CORS engelleme hatası alınması.
- **Kök Neden:** GitHub'a `git push` yapıldığında Render bulut sunucusu Docker konteynırını yeniden derleyip başlatıyordu. Yeniden başlama esnasında Nginx proxy katmanı varsayılan `502 Bad Gateway` döndürüyor ve CORS başlıklarını (headers) eklemiyordu.
- **Çözüm:** 
  1. Sunucu başlatma süreci tamamlandığında 502 kendiliğinden çözüldü.
  2. `cmd/server/main.go` içerisine Fiber'ın resmi standart `cors.New(...)` middleware'i eklendi. Artık sunucu 400 veya 500 dönse dahi tarayıcıya her koşulda `Access-Control-Allow-Origin: *` başlığı eksiksiz gönderiliyor.

---

### ❌ Hata 2: Render Docker Derleme Hatası (`"/app/package.json": not found`)
- **Semptom:** Render üzerindeki Docker imajı derlenirken `#16 ERROR: "/app/package.json": not found` hatası verip duruyordu.
- **Kök Neden:** `.gitignore` dosyası içerisinde `package.json` engellendiği için Git deposuna aktarılamamıştı. Dockerfile `COPY --from=builder /app/package.json .` satırında dosyayı bulamıyordu.
- **Çözüm:** `package.json` git takibine alındı ve Dockerfile `RUN npm init -y && npm install --only=production playwright` olarak güncellendi.

---

### ❌ Hata 3: Sub-Package Script Path Hatası (`MODULE_NOT_FOUND`)
- **Semptom:** Playwright servisi unit testlerden veya alt paketlerden (`internal/service`) çağrıldığında `scripts/price_scraper.js` dosyasını bulamayıp Node.js `MODULE_NOT_FOUND` hatası veriyordu.
- **Kök Neden:** Göreceli dosya yolu (relative path) çalıştırılan dizine göre değişiyordu.
- **Çözüm:** `PlaywrightPriceService` başlatılırken `os.Stat` kullanan dinamik bir aday yol kontrol döngüsü eklendi (`scripts/`, `../scripts/`, `../../scripts/`).

---

### ❌ Hata 4: `signal: killed` (12. Saniyede İşlemin Öldürülmesi)
- **Semptom:** Konsolda `FAILED for 'kıvırcık' after 12.196s: signal: killed` şeklinde log düşmesi.
- **Kök Neden:** Go tarafında `context.WithTimeout(context.Background(), 12*time.Second)` tanımlıydı. Render'ın ücretsiz sunucusunda (0.1 CPU core) aynı anda 3 ağır Chromium açılması 12 saniyeyi aşıyordu. Go 12. saniyede Node.js sürecini `SIGKILL` sinyaliyle zorla öldürüyordu.
- **Çözüm:**
  1. Go zaman aşımı `25*time.Second` yapıldı.
  2. CPU ve RAM yükünü hafifletmek için eşzamanlı Playwright iş parçacığı sayısı (Concurrency Pool) 3'ten **2'ye düşürüldü**.
  3. Chromium sayfa navigasyon zaman aşımı 7 saniyeden **4.5 saniyeye** indirildi.

---

### ❌ Hata 5: `Target page, context or browser has been closed`
- **Semptom:** Playwright çalışırken `page.waitForTimeout` fırlatarak script'in çökmesine neden oluyordu.
- **Kök Neden:** Sayfa yüklenirken veya dinamik yönlendirme yapıldığında Playwright'ın dahili `page.waitForTimeout()` metodu sayfa bağlamını kaybettiği için istisna atıyordu.
- **Çözüm:** Kırılgan `page.waitForTimeout` tamamen kaldırıldı. Yerine Node.js'in çökmesi imkansız yerel zamanlayıcısı eklendi:
  ```javascript
  const sleep = ms => new Promise(res => setTimeout(res, ms));
  ```

---

### ❌ Hata 6: Akakçe Cloudflare Anti-Bot / 429 Engeli ("Just a moment...")
- **Semptom:** Bazı ürün aramalarında Playwright'ın hiç fiyat bulamayıp *"No prices found for query"* çıktısı vermesi.
- **Kök Neden:** Akakçe arama URL'sine (`/arama/?q=...`) doğrudan girildiğinde Cloudflare anti-bot mekanizması devreye girip `"Just a moment..."` doğrulama ekranı fırlatıyordu.
- **Çözüm:** `price_scraper.js` dosyasına Cloudflare Evasion başlıkları eklendi:
  1. `addInitScript` ile `navigator.webdriver = undefined` yapıldı.
  2. `Referer: https://www.akakce.com/` başlığı eklendi.
  3. Masaüstü Chrome 123 `Sec-Ch-Ua` başlıkları eklendi.

---

### ❌ Hata 7: `main.go:9:2: "strings" imported and not used`
- **Semptom:** Render Docker derlemesinde `go build` adımının 1 exit code ile kalması.
- **Kök Neden:** CORS middleware refaktörü sonrası `main.go` içinde atıl kalan `strings` importu.
- **Çözüm:** Atıl import temizlendi, `go vet ./...` ile sıfır hatayla doğrulandı.

---

### ❌ Hata 8: 'bulgur' Gibi Ürünlerde DOM Kart Seçici Uyumsuzluğu
- **Semptom:** `bulgur` aramasında sayfada 57 adet fiyat bulunmasına rağmen script'in *"No prices found for query: bulgur"* hatası fırlatması.
- **Kök Neden:** `document.querySelectorAll` içerisinde iç içe etiketler (`span.pb_v8`) kart olarak seçildiği için ürün başlığı `titleEl` boş dönüyor ve dizi filtreleniyordu. Ayrıca `page.goto` tamamlandığı an DOM kartları henüz işlenmemiş olabiliyordu.
- **Çözüm:**
  1. Script'e `await page.waitForSelector('ul#b > li, span.pt_v8, span.pb_v8, b.p_v8', { timeout: 4000 })` eklendi.
  2. 2 Aşamalı DOM Ayrıştırma Stratejisi (Strategy 1: Product Cards -> Strategy 2: Direct Price Elements Fallback) eklendi. `bulgur` araması için **110.06 TL** (min 34 TL, max 349.17 TL) canlı verisi %100 doğrulukla çekildi.

---

## 3. 🧠 Mimarisi ve Ölçeklendirme Analizi

### Soru 1: Neden Tek Bir Render Sunucusundan Yatay Ölçeklendirme Yapılamaz?
- **Render Free Tier Sınırları:** Render'ın ücretsiz planı tek bir konteynır (0.1 CPU core, 512 MB RAM) sunar. Aynı sunucuda hem Go web API'sini çalıştırmak hem de aynı anda 3-4 adet bellek canavarı olan Chromium tarayıcısı açmak CPU boğulmasına neden olur.
- **Neden Sunucu Telefona/İstemciye Kopyalanamaz?**
  1. **İstemci Güvenliği (Security & CORS):** İstemci (Flutter Web veya Mobil) üzerinden doğrudan tarama yapmak CORS engellerine takılır ve API anahtarlarının/scraplerın açığa çıkmasına neden olur.
  2. **Mobil Sınırlamalar:** Mobil cihazlar (iOS/Android) üzerinde headless Chromium süreci çalıştırılamaz.

---

### Soru 2: İkinci Veritabanı ve Ayrı Scraper Servisi (Uzun Vadeli AWS & Redis Mimarisi)

Gelecekte kullanıcı sayısı arttığında uygulanacak **Faz 2 Veritabanı ve Microservice Mimarisi**:

```
[İstemci (Flutter App)]
         │
         ▼
┌────────────────────────────────────────────────────────┐
│ Ana Go API Sunucusu (Hafif ve Hızlı)                   │
└────────┬───────────────────────────────────────────────┘
         │
         ├──────────────────────────┐
         ▼ (1. Öncelikli Sorgu)     ▼ (Havuzda Yoksa / Eskiyse)
┌────────────────────────┐  ┌────────────────────────────────────┐
│ Redis & PostgreSQL     │  │ Ayrı Scraper Worker Servisi        │
│ Fiyat Havuzu (Cache)   │  │ (AWS EC2 / Lambda + Playwright)    │
│ - 0.001 ms Yanıt       │  └─────────────────┬──────────────────┘
│ - 24-48 Saat Kalıcılık │                    │ (Canlı Fiyatı Çeker)
└────────────────────────┘                    ▼
                                    ┌──────────────────┐
                                    │ Fiyat Havuzunu   │
                                    │ Günceller        │
                                    └──────────────────┘
```

#### Bu Mimarinin Avantajları:
1. **Sıfır Bekleme Süresi (Instant Response):** Kullanıcıların arattığı her ürün merkezi Fiyat Havuzuna kaydedilir. 2. kullanıcı aynı ürünü arattığında Playwright çalıştırmadan **0.001 saniyede** yanıt verilir.
2. **Kullanıcı Sayısı Arttıkça Sistem Hızlanır:** Ne kadar çok kullanıcı arama yaparsa, veritabanı fiyat havuzu o kadar zenginleşir ve Playwright'a olan ihtiyaç minimuma iner.
3. **Ban ve Kota Riski Ortadan Kalkar:** Akakçe veya hedef sitelere sürekli aynı istekler atılmayacağı için IP ban yeme riski sıfırlanır.
4. **Sunucu Yükü Ayrışır:** Ana Go API sunucusu sadece JSON yanıtı verir, ağır Playwright iş yükü AWS üzerindeki Scraper Worker servisine devredilir.
