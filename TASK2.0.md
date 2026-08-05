# 📋 Kap-App v2.0 — Admin Paneli, Bildirim Yönetimi & OTA Otomatik Güncelleme Görev Listesi

> **Sürüm:** v2.0 - Sürüm Yönetimi & Admin Ekosistemi  
> **Tarih:** 2026-08-05  
> **Amaç:** Web tabanlı Admin Paneli, Push Bildirim Yönetimi ve Mobil Uygulama İçi Otomatik Güncelleme (In-App OTA Updater) altyapısının kurulması.

---

## 🎯 Faz 1: Veritabanı ve Güvenlik Altyapısı (Supabase Migration 19)

- [x] **1.1 `public.system_admins` Tablosunun Oluşturulması**
  - Sistem yöneticilerini tanımlayan özel yetki tablosu ve RLS politikaları.
- [x] **1.2 `public.app_versions` Tablosunun Oluşturulması**
  - `version_code`, `version_name`, `apk_url`, `changelog`, `is_mandatory` alanları.
- [x] **1.3 `public.push_notifications` Tablosunun Oluşturulması**
  - `title`, `body`, `scheduled_at`, `sent_at`, `status` alanları.
- [x] **1.4 Supabase Storage `app-releases` Public Bucket Yapılandırması**
  - APK dosyalarının doğrudan yüklenebileceği halka açık güvenli depolama alanı.

---

## ⚙️ Faz 2: Go Backend API Mikroservis Geliştirmeleri

- [x] **2.1 Sürüm Kontrol API Ucu (`GET /api/v1/app/check-update`)**
  - Mobil uygulamanın açılışta en son yayınlanan sürümü sorguladığı halka açık uç.
- [x] **2.2 Admin Yetki Middleware'i (`middleware.AdminRequired`)**
  - Admin isteklerini doğrulanmış JWT ve `system_admins` tablosu ile koruma.
- [x] **2.3 Admin Sürüm Yayınlama API Ucu (`POST /api/v1/admin/app-version`)**
  - Yeni APK sürümü ve yenilik notlarının veritabanına kaydedilmesi.
- [x] **2.4 Admin Bildirim Gönderme ve Zamanlama API Ucu (`POST /api/v1/admin/notifications`)**
  - Tüm kullanıcılara anlık veya zamanlanmış bildirim tetikleme.

---

## 📱 Faz 3: Flutter Mobil Uygulama İçi Otomatik Güncelleme (OTA)

- [x] **3.1 `package_info_plus` veya Yerel Sürüm Tanımı Entegrasyonu**
  - Uygulama mevcut sürümünün (ör. `v2.0.0` / Code `100`) okunması.
- [x] **3.2 Uygulama Açılışında Güncelleme Kontrolcüsü (`AppUpdateChecker`)**
  - Uygulama başlatıldığında Go backend'den son sürümü sorgulama.
- [x] **3.3 Şık Güncelleme Diyalog Penceresi (`AppUpdateDialog`)**
  - Yeni sürüm adı, yenilikler (Changelog) ve "Şimdi İndir ve Yükle" butonu.
  - Zorunlu güncellemelerde kapatılamayan diyalog (Mandatory Update).
- [x] **3.4 Otomatik APK İndirme ve Yükleme Tetikleyici**
  - APK dosyasını indirip Android Paket Yükleyicisini (Package Installer) başlatma.

---

## 💻 Faz 4: Web Admin Paneli Arayüzü (`/admin`)

- [x] **4.1 Giriş ve Admin Doğrulama Ekranı (`/admin/login`)**
  - Yalnızca `system_admins` yetkisine sahip kullanıcıların giriş yapabilmesi.
- [x] **4.2 Uygulama Sürüm Yönetimi Sekmesi (APK Upload & Release)**
  - Bilgisayardan `.apk` dosyası seçip Supabase Storage'a yükleme.
  - Sürüm numarası, değişiklik notları girip canlıya alma.
- [x] **4.3 Bildirim Yayınlama ve Zamanlama Sekmesi (Push Broadcast)**
  - Bildirim başlığı, metni, zaman seçici (Timepicker) ve "Gönder" butonu.
  - Geçmiş gönderilen bildirimlerin durumu ve log ekranı.

---

## 🧪 Faz 5: Doğrulama ve E2E Testler

- [x] **5.1 Go Backend E2E Testleri**
  - Sürüm kontrol ve Admin yetki uçlarının testi.
- [x] **5.2 Flutter Analiz ve Derleme Kontrolü**
  - Mobil ve Web derlemelerinin hatasız doğrulanması.
