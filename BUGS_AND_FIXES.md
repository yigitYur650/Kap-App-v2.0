# 🐛 Bug & Fix Log — Kap-App

> **Amacı:** Projede ortaya çıkan tüm teknik hatalar, semptomlar, kök nedenler ve uygulanan düzeltmelerin kronolojik günlüğüdür.

---

## 🛠️ Hata Günlüğü (Kronolojik Sırayla)

### HATA-01: `joinGroup` — `group_members` RLS Politikası Tıkanması
- **Semptom:** Kullanıcı katılım koduyla bir gruba katılmak istediğinde `42501 row-level security policy violated` hatası alıyordu.
- **Kök Neden:** RLS politikası kullanıcı grubun üyesi olmadan `group_members` tablosuna INSERT yapmasını engelliyordu.
- **Düzeltme:** `10_group_join_code.sql` migration'ında SECURITY DEFINER destekli veritabanı fonksiyonu yazıldı.

### HATA-02: `group_members` Admin Sayısı Yarış Durumu (Race Condition)
- **Semptom:** Son admin gruptan çıkarken admin kontrolü atlanabiliyordu.
- **Kök Neden:** İki istemci aynı anda gruptan çıkış yaptığında istemci tarafı kontrolde yarış durumu oluşuyordu.
- **Düzeltme:** `08_fix_admin_count_race.sql` ile veritabanı seviyesinde tetikleyici (trigger) eklendi.

### HATA-03: `requests` Realtime WebSocket `deleted_at` Filtre Uyumsuzluğu
- **Semptom:** Soft-deleted ürünler kanaldan silinmiyordu.
- **Kök Neden:** Supabase Realtime istemcisi `.isFilter('deleted_at', null)` sorgusunu socket katmanında desteklemiyordu.
- **Düzeltme:** `SupabaseRequestRepository` içerisinde istemci tarafı `.where((r) => r.deletedAt == null)` in-memory filtrelemesi uygulandı.

### HATA-04: Android Release Build — Multidex & Duplicate Library Hatası
- **Semptom:** `flutter build apk --release` komutu Gradle derleme hatası veriyordu.
- **Kök Neden:** `android/app/build.gradle` dosyasında minSdk ve multidex yapılandırması eksikti.
- **Düzeltme:** `multiDexEnabled true` yapıldı ve `minSdkVersion 21` olarak güncellendi.

### HATA-05: Fiş OCR Okuyucu — Türkçe Karakter & Bozuk JSON Ayrıştırma
- **Semptom:** Kameradan çekilen fiş fotoğraflarında tutar ve market adları bozuk okunuyordu.
- **Kök Neden:** Gemini Vision modeline verilen prompt serbest metin döndürüyor, JSON formatı garanti edilmiyordu.
- **Düzeltme:** Gemini 2.0 Flash ve 3.6 Flash modellerine strict JSON schema prompt entegre edildi, regex temizleyici yazıldı.

### HATA-06: Market Fiyat Tahmin Motoru — HTML Parsing Hataları
- **Semptom:** Playwright live scraper bazen bot korumasına (Cloudflare) takılıp fiyat verisi çekemiyordu.
- **Kök Neden:** Doğrudan sayfa indirme istekleri JS render olmasını beklemiyordu.
- **Düzeltme:** 24 saatlik in-memory fiyat önbelleği (Cache Engine) yazıldı. Başarılı çekilen fiyatlar RAM'e kaydedilip anında yanıt verilmeye başlandı.

### HATA-07: `shopping_list_screen.dart` — Duplicated named argument `isScrollControlled`
- **Semptom:** Flutter release derlemesinde `Duplicated named argument` derleme hatası oluşuyordu.
- **Kök Neden:** `showModalBottomSheet` çağrısında aynı argüman iki defa geçilmişti.
- **Düzeltme:** Yinelenen argümanlar temizlendi.

### HATA-08: AI Fiyat Tahmini — Market İsimleri ve Birim Boyut Uyumsuzluğu
- **Semptom:** Ürün fiyat tahminlerinde market isimleri ve gramaj/litre bilgisi görünmüyordu.
- **Kök Neden:** Backend verisinde `market_name` ve `unit_spec` alanları UI DTO'suna taşınmıyordu.
- **Düzeltme:** `ItemPriceEstimate` yapısına market ve birim alanları eklendi, UI arayüzü yenilendi.

### HATA-09: Gemini API 429 Quota Exceeded & API Key Fallback
- **Semptom:** Kullanıcılar AI tavsiye ve fiş okuma butonuna bastığında API kotası dolduğu için çökme yaşanıyordu.
- **Kök Neden:** Sadece tek bir Gemini API anahtarı deneniyor, hata durumunda yedek sağlayıcıya geçilmiyordu.
- **Düzeltme:** `queryGroqOrGeminiText` fallback mimarisi kuruldu. Groq Llama 3.3 70B birincil, Gemini model zinciri ikincil yedek olarak ayarlandı.

### HATA-10: `createRequest` Metod Çağrı Uyumsuzluğu
- **Semptom:** `Error: The named parameter 'groupId' isn't defined.`
- **Kök Neden:** `createRequest` metodu `groupId` parametresini dışarıdan almayıp Riverpod provider `activeGroupProvider` üzerinden otomatik alıyordu, UI tarafında `groupId: activeGroup.id` geçilmişti.
- **Düzeltme:** Metod imzası `createRequest(itemName: suggestedName)` olarak güncellendi.

### HATA-11: Alışveriş Ürünlerinde Kategori Ayrıştırma Eksikliği
- **Semptom:** Eklenen ürünler varsayılan olarak `Genel` kalıyor, sekmelerden süzülemiyordu. Sekmelerde "Et & Piliç" eksikti.
- **Kök Neden:** Türkçe ürün kelime haritası ve veritabanı seviyesinde etiketleme yoktu.
- **Düzeltme:** `CategoryHelper` motoru (100+ Türkçe kelime eşlemesi) yazıldı. `category_tabs_bar.dart` ve veritabanı kayıt repository'sine entegre edildi.

### HATA-12: `health_profile_screen.dart` — Tipografi Tanımsızlık Hataları
- **Semptom:** `Error: Member not found: 'titleLg'`, `buttonLg`, `headlineSm`.
- **Kök Neden:** Tipografi sınıfında bu isimler `headlineMd`, `bodyLg`, `labelLg` olarak tanımlıydı.
- **Düzeltme:** Tüm tipografi çağrıları standart `AppTypography` getter'ları ile düzeltildi.

### HATA-13: `PostgrestException: Could not find table public.health_profiles`
- **Semptom:** Supabase veritabanında `health_profiles` SQL migration'ı henüz tetiklenmediği için profil kaydedilirken kırmızı hata barı çıkıyordu.
- **Kök Neden:** Doğrudan Supabase upsert atılıyor ve hata yakalanmıyordu.
- **Düzeltme:** `health_profile_repository.dart` dosyasına SharedPreferences yerel depolama ve Supabase try-catch fallback mekanizması eklendi.

### HATA-14: Kişisel Fitness Ekranında Metin Kesilmesi & Responsive Taşma
- **Semptom:** BMR, TDEE, Makro değerleri tek satıra sıkıştığı için metinler üst üste biniyordu. ChoiceChip'lerde "Form Korun..." metni kesiliyordu.
- **Kök Neden:** Sabit `Row` ve `Expanded` kullanımı dar ekran genişliklerine sığmıyordu.
- **Düzeltme:** BMR/TDEE 2 sütunlu enerji kartına, Makrolar 3 sütunlu rozet alanına bölündü. ChoiceChip'ler `Wrap` yapısına geçirilerek metin kırpılması tamamen engellendi.

### HATA-15: AI Tavsiye Sisteminde Genel Öneriler & Kategori Filtresi Eksikliği
- **Semptom:** AI önerileri kullanıcının kişisel kilosunu, yaşını, hedefini ve makrolarını dikkate almayıp genel veriler üretiyordu. Tavsiye penceresinde süzme sekmeleri yoktu.
- **Kök Neden:** Backend API isteğine kullanıcı profil verileri gönderilmiyordu ve UI diyaloğunda filtre sekmeleri tanımlanmamıştı.
- **Düzeltme:** `UserHealthProfileDTO` backend promptuna entegre edildi. `AIRecommendationsDialog` sekmeli (Tümü, Sağlık, Tasarruf, Tarifler, Unutulanlar, Tazelik) ve "⚡ Tüm Önerilenleri Sepete Ekle" butonlu hale getirildi.

### HATA-16: Yeni Hesap Kaydında 2FA Doğrulamasının Atlanması
- **Semptom:** Yeni kullanıcı kayıt olduğu an 2FA OTP kod ekranına yönlendirilmeden doğrudan ana sayfaya giriş yapabiliyordu.
- **Kök Neden:** `register_controller.dart` içerisinde kayıt başarılı olduğunda `authNotifier.updateState(user)` çağrılarak 2FA adımı tetiklenmiyordu.
- **Düzeltme:** `register_controller.dart` güncellenerek kayıt sonrası `signInWithOtp` tetiklendi ve kullanıcı 6-8 haneli `/verify-otp` doğrulama ekranına yönlendirildi.

### HATA-17: Admin Olmayan Hesaplarda Admin Paneli Butonunun Görünmesi
- **Semptom:** Sistem admini olmayan kullanıcıların Ayarlar sayfasında "Admin Paneline Git" butonu görünüyordu.
- **Kök Neden:** `isSystemAdminProvider` Riverpod sağlayıcısı `authProvider` kullanıcısını anlık izlemediği için önceki admin oturumunun durumunu hafızada tutuyordu.
- **Düzeltme:** `isSystemAdminProvider` içerisine `ref.watch(authProvider)` eklendi, aktif kullanıcının `system_admins` tablosunda olup olmadığı dinamik kontrol edildi.

### HATA-18: Çıkış Yapıldığında Önbellekteki Kişisel Verilerin Yeni Hesaba Sızması
- **Semptom:** Bir hesaptan çıkıp farklı bir hesap açıldığında önceki kullanıcının sağlık profili ve aktif grup bilgileri yeni hesapta görünüyordu.
- **Kök Neden:** `AuthNotifier.signOut()` ve `updateState()` metotlarında `healthProfileProvider` ve `isSystemAdminProvider` sıfırlanmıyordu.
- **Düzeltme:** `_invalidateAllUserProviders()` metodu yazılarak çıkış ve oturum değişim anında tüm kişisel sağlık, grup ve admin önbellekleri tamamen temizlendi.

### HATA-19: 8 Haneli Supabase OTP Kodlarının 6 Hanede Kesilmesi
- **Semptom:** Supabase 8 haneli OTP kodu gönderdiğinde giriş ekranı 6 hane ile sınırlandığı için doğrulama başarısız oluyordu.
- **Kök Neden:** `OTPVerificationScreen` içerisindeki `maxLength` değeri 6 olarak sabitlenmişti.
- **Düzeltme:** `maxLength: 8` ve `letterSpacing: 6` olarak güncellendi. Arayüz hem 6 hem de 8 haneli kodları destekler hale getirildi.

### HATA-20: Admin Sağlayıcılarında Göreceli Import (`../../`) Yolu Hatası
- **Semptom:** `flutter build apk` release derlemesinde `Error when reading lib/features/admin/presentation/data/...` derleme hatası veriyordu.
- **Kök Neden:** `admin_dashboard_screen.dart` ve `admin_provider.dart` dosyalarında göreceli yollar (`../../`) yanlış dizini hedefliyordu.
- **Düzeltme:** Tüm importlar `package:kap_app_front/features/admin/...` paket standartına çevrildi.

### HATA-21: Playwright Live Scraper — Hibrit Event-Driven Bekleme & Cloudflare Aşımı
- **Semptom:** Fiyat taramalarında sabit bekleme süreleri yavaşlığa ve Cloudflare anti-bot doğrulama ekranına ("Just a moment...") neden oluyordu.
- **Kök Neden:** Sabit zaman aşımları ve varsayılan headless tarayıcı kimliği Cloudflare tarafından bot olarak algılanıyordu.
- **Düzeltme:** `addInitScript` ile `navigator.webdriver` gizlendi, `Referer` başlığı eklendi. Sabit sleep süreleri yerine `state: 'attached'` event-driven DOM beklemesi ve 200ms mikro duraksamadan oluşan hibrit mimariye geçildi. Tarama hızları %50 artırıldı.


