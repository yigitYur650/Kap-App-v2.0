-- ============================================================
-- KAP-APP v2.0 — RLS & Security Diagnostic Snapshot Suite
-- ============================================================
-- 📌 KULLANIM NOTU:
-- Bu dosya, her veritabanı migration'ından sonra Supabase SQL Editor'de
-- RLS politikalarının ve yetki seviyelerinin durumunu hızlıca teşhis etmek
-- ve görsel olarak denetlemek için tasarlanmıştır.
--
-- Dosya içindeki 3 ayrı sorguyu Supabase SQL Editor'de sırayla çalıştırıp
-- çıktıları gözden geçirebilirsiniz (Henüz otomatik CI pipeline'ına bağlanmamıştır).
--
-- NOT: role_table_grants sorgusu anon rolünün tablo-seviyesi GRANT'lere sahip
-- olduğunu gösterir (bu Supabase'in varsayılan kurulumudur, normal). Gerçek
-- güvenlik RLS policy katmanındadır. 05.08.2026 tarihinde curl/fetch ile
-- anon key kullanılarak requests tablosunda PATCH denendi, RLS tarafından
-- etkisiz hale getirildiği (0 satır etkilendi) doğrulandı. Bu satırdaki
-- "⚠️ DIKKAT" bayrakları anomali değil, beklenen davranıştır — asıl kontrol
-- edilmesi gereken şey pg_policies çıktısında ilgili tabloda 'anon' rolünü
-- hedefleyen bir policy OLMAMASI gerektiğidir.
-- ============================================================


-- ============================================================
-- SORGU 1: Public Şemasındaki Tüm Tabloların RLS Durumu
-- (RLS'i KAPALI olan tablolar '❌ DISABLED' olarak belirginleşir)
-- ============================================================
SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN rowsecurity = true THEN '✅ ENABLED'
        ELSE '❌ DISABLED (DIKKAT: RLS KAPALI)'
    END AS rls_status,
    tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;


-- ============================================================
-- SORGU 2: Tüm RLS Politikalarının Detaylı Dökümü
-- (Tablo adına göre sıralı politika kuralları ve koşulları)
-- ============================================================
SELECT 
    tablename,
    policyname,
    cmd AS operation, -- SELECT, INSERT, UPDATE, DELETE, ALL
    roles,
    qual AS using_expression,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;


-- ============================================================
-- SORGU 3: 'authenticated' ve 'anon' Rol Yetkileri Tablosu
-- (Anon rolünün yazma yetkisi -INSERT/UPDATE/DELETE- olması durumunu belirginleştirir)
-- ============================================================
SELECT 
    grantee AS role_name,
    table_name,
    privilege_type,
    CASE 
        WHEN grantee = 'anon' AND privilege_type IN ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE') 
            THEN '⚠️ DIKKAT: Anon Yetkisiz Yazma Erişimi'
        ELSE 'OK'
    END AS anomaly_flag
FROM information_schema.role_table_grants
WHERE table_schema = 'public' 
  AND grantee IN ('authenticated', 'anon')
ORDER BY table_name, grantee, privilege_type;
