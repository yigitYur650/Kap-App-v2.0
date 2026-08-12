// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Kap App';

  @override
  String get errorGeneric =>
      'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get auth_email_invalid => 'Lütfen geçerli bir e-posta adresi girin.';

  @override
  String get auth_email_empty => 'E-posta adresi boş bırakılamaz.';

  @override
  String get auth_password_too_short => 'Şifre en az 6 karakter olmalıdır.';

  @override
  String get auth_password_empty => 'Şifre boş bırakılamaz.';

  @override
  String get auth_password_mismatch => 'Şifreler eşleşmiyor.';

  @override
  String get auth_display_name_empty => 'Kullanıcı adı boş bırakılamaz.';

  @override
  String get auth_login_title => 'Giriş Yap';

  @override
  String get auth_login_button => 'Giriş Yap';

  @override
  String get auth_login_email_label => 'E-posta Adresi';

  @override
  String get auth_login_password_label => 'Şifre';

  @override
  String get auth_login_forgot_password => 'Şifremi Unuttum?';

  @override
  String get auth_login_register_prompt => 'Hesabınız yok mu?';

  @override
  String get auth_login_register_link => 'Kayıt Ol';

  @override
  String get auth_register_title => 'Kayıt Ol';

  @override
  String get auth_register_button => 'Kayıt Ol';

  @override
  String get auth_register_display_name_label => 'Kullanıcı Adı';

  @override
  String get auth_register_email_label => 'E-posta Adresi';

  @override
  String get auth_register_password_label => 'Şifre';

  @override
  String get auth_register_confirm_password_label => 'Şifreyi Onayla';

  @override
  String get auth_register_login_prompt => 'Zaten bir hesabınız var mı?';

  @override
  String get auth_register_login_link => 'Giriş Yap';

  @override
  String get shopping_list_title => 'Alışveriş Listesi';

  @override
  String get shopping_list_no_active_group =>
      'Alışveriş listesini görüntülemek için önce bir gruba katılın veya seçin.';

  @override
  String get shopping_list_active_section => 'Aktif Ürünler';

  @override
  String get shopping_list_completed_section => 'Tamamlanan Ürünler';

  @override
  String get shopping_list_no_items => 'Bu listede ürün yok.';

  @override
  String get shopping_list_add_item_tooltip => 'Ürün Ekle';

  @override
  String get request_card_private_label => 'Gizli';

  @override
  String get add_request_title => 'Alışveriş Ürünü Ekle';

  @override
  String get add_request_item_name_label => 'Ürün Adı';

  @override
  String get add_request_item_name_empty => 'Ürün adı boş olamaz.';

  @override
  String get add_request_private_label =>
      'Gizli İstek (yalnızca belirtilen üyeye görünür)';

  @override
  String get add_request_private_to_label => 'Şu Üyeye Gizle';

  @override
  String get add_request_submit_button => 'Ekle';

  @override
  String get add_request_cancel_button => 'İptal';

  @override
  String get add_request_private_recipient_required =>
      'Gizli istekler için bir alıcı seçilmelidir.';

  @override
  String get group_members_title => 'Grup Üyeleri';

  @override
  String get auth_sign_out => 'Çıkış Yap';

  @override
  String get group_members_login_prompt =>
      'Üyeleri görüntülemek için lütfen giriş yapın.';

  @override
  String get group_members_share_code_title => 'Paylaşım Kodunuz';

  @override
  String get group_members_share_code_subtitle =>
      'Aile üyelerinizin aile grubunuza katılması için bu kodu onlarla paylaşın:';

  @override
  String get group_members_copied => 'Paylaşım kodu panoya kopyalandı';

  @override
  String get group_members_copy_tooltip => 'Kodu Kopyala';

  @override
  String get group_members_list_title => 'Üye Listesi';

  @override
  String get group_members_select_group_prompt =>
      'Üyeleri görüntülemek için önce bir gruba katılın veya seçin.';

  @override
  String get group_members_empty => 'Bu grupta üye yok.';

  @override
  String get group_members_load_failed => 'Üyeler yüklenemedi';

  @override
  String get group_members_profile_load_failed =>
      'Profil yüklenirken hata oluştu';

  @override
  String get inventoryTitle => 'Evde Ne Var?';

  @override
  String get inventoryEmptyState => 'Burada henüz hiçbir şey yok.';

  @override
  String get inventoryStatusInStock => 'Var';

  @override
  String get inventoryStatusLow => 'Azaldı';

  @override
  String get inventoryStatusOutOfStock => 'Yok';

  @override
  String get inventoryAddItemTitle => 'Yeni Ürün Ekle';

  @override
  String get inventoryItemNameHint => 'Ürün adı girin...';

  @override
  String get inventoryButtonAdd => 'Ekle';

  @override
  String get inventoryButtonCancel => 'İptal';

  @override
  String get group_create_success => 'Ev başarıyla oluşturuldu!';

  @override
  String get group_join_success => 'Eve başarıyla katıldınız!';

  @override
  String get group_create_title => 'Yeni Ev Oluştur';

  @override
  String get group_create_name_hint => 'Ev/Grup İsmi';

  @override
  String get group_type_family => 'Aile';

  @override
  String get group_type_community => 'Topluluk';

  @override
  String get dialog_cancel => 'İptal';

  @override
  String get dialog_create => 'Oluştur';

  @override
  String get group_join_title => 'Eve Katıl';

  @override
  String get group_join_code_hint => 'Katılım Kodu (Örn: XK7M2R9P)';

  @override
  String get dialog_join => 'Katıl';

  @override
  String get group_none_selected => 'Ev Seçilmedi';

  @override
  String get group_type_family_label => 'Aile Grubu';

  @override
  String get group_type_community_label => 'Topluluk Grubu';

  @override
  String get hub_active_list_summary => 'AKTİF LİSTE ÖZETİ';

  @override
  String get hub_no_pending_requests => 'Bekleyen alışveriş talebi yok.';

  @override
  String hub_more_items(Object count) {
    return '+$count Daha';
  }

  @override
  String get hub_members_header => 'EV ÜYELERİ';

  @override
  String get group_role_admin => 'Yönetici';

  @override
  String get group_role_member => 'Üye';

  @override
  String get hub_no_group_joined => 'Henüz bir eve dahil değilsiniz.';

  @override
  String get hub_create_group_button => 'Ev Oluştur';

  @override
  String get hub_join_group_button => 'Eve Katıl';

  @override
  String shopping_list_items_count(Object count) {
    return '$count Ürün';
  }

  @override
  String get settings_title => 'Ayarlar';

  @override
  String get settings_active_group_info => 'AKTİF GRUP BİLGİSİ';

  @override
  String get settings_join_code => 'Katılım Kodu';

  @override
  String get settings_no_code => 'KOD-YOK';

  @override
  String get settings_my_groups => 'EV GRUPLARIM';

  @override
  String get settings_no_groups_found => 'Kayıtlı grup bulunmuyor.';

  @override
  String get nav_tab_hub => 'Hub';

  @override
  String get nav_tab_list => 'Liste';

  @override
  String get nav_tab_settings => 'Ayarlar';

  @override
  String get add_request_item_name_hint => 'Ne lazım? (Örn: Süt)';

  @override
  String get add_request_quantity_label => 'Miktar';

  @override
  String get add_request_quantity_hint => 'Örn: 2, 500';

  @override
  String get add_request_unit_label => 'Birim';

  @override
  String get add_request_unit_hint => 'Örn: adet, kg, L';

  @override
  String get settings_delete_group_title => 'Ev Silinsin mi?';

  @override
  String get settings_delete_group_confirm =>
      'Bu evi silmek istediğinize emin misiniz:';

  @override
  String get settings_delete_group_success => 'Ev başarıyla silindi.';

  @override
  String get dialog_delete => 'Sil';

  @override
  String get health_title => 'Kişisel Beslenme & Fitness';

  @override
  String get health_daily_target_calories => 'Günlük Hedef Kalori';

  @override
  String get health_goal_lose => '🏃‍♂️ Kilo Verme';

  @override
  String get health_goal_maintain => '🧘‍♀️ Form Koruma';

  @override
  String get health_goal_gain => '🏋️‍♂️ Kilo Alma';

  @override
  String get health_bmr_label => 'BMR (Metabolizma)';

  @override
  String get health_tdee_label => 'TDEE (Harcanan)';

  @override
  String get health_protein_label => 'Protein';

  @override
  String get health_carbs_label => 'Karbonhidrat';

  @override
  String get health_fat_label => 'Yağ';

  @override
  String get health_water_target_label => 'Su Tüketimi (Hedef)';

  @override
  String get health_body_fat_label => 'Vücut Yağ Durumu';

  @override
  String get health_body_measurements_title => 'Vücut Ölçülerim & Hedeflerim';

  @override
  String get health_weight_label => 'Kilo (kg)';

  @override
  String get health_height_label => 'Boy (cm)';

  @override
  String get health_age_label => 'Yaş';

  @override
  String get health_daily_water_label => 'Günlük Su (Litre)';

  @override
  String get health_body_fat_pct_label => 'Yağ Oranı (%)';

  @override
  String get health_gender_label => 'Cinsiyet';

  @override
  String get health_gender_male => 'Erkek 👨';

  @override
  String get health_gender_female => 'Kadın 👩';

  @override
  String get health_activity_level_label => 'Günlük Hareket Seviyesi';

  @override
  String get health_activity_sedentary => 'Hareketsiz (Masa başı iş)';

  @override
  String get health_activity_light => 'Hafif Aktif (Haftada 1-3 gün egzersiz)';

  @override
  String get health_activity_moderate =>
      'Orta Aktif (Haftada 3-5 gün egzersiz)';

  @override
  String get health_activity_active => 'Çok Aktif (Haftada 6-7 gün egzersiz)';

  @override
  String get health_activity_very_active => 'Fiziksel İş / Ağır Antrenman';

  @override
  String get health_main_goal_label => 'Ana Hedef';

  @override
  String get health_fitness_goal_label => 'Beslenme Modeli';

  @override
  String get health_fitness_muscle => '🏋️‍♂️ Kas Yapımı (Yüksek Protein)';

  @override
  String get health_fitness_keto => '🔥 Yağ Yakımı (Keto / Düşük Karbonhidrat)';

  @override
  String get health_fitness_balanced => '⚖️ Dengeli & Sürdürülebilir';

  @override
  String get health_kidney_disease_title => 'Böbrek Rahatsızlığı';

  @override
  String get health_kidney_disease_subtitle =>
      'Aktifse, güvenlik için protein alımı maksimum 0.8g/kg ile sınırlandırılır.';

  @override
  String get health_allergen_title => 'Alerjenler';

  @override
  String get health_allergen_subtitle =>
      'Alerjenlerinizi seçin. Bu gıdalar önerilerden çıkarılır.';

  @override
  String get health_share_with_group_title => 'Grup Arkadaşlarıyla Paylaş';

  @override
  String get health_share_with_group_subtitle =>
      'Seçeneği açarsanız gruptaki üyeler beslenme ilerlemenizi görebilir.';

  @override
  String get health_save_button => 'Kişisel Bilgileri Kaydet';

  @override
  String get health_save_success =>
      'Kişisel sağlık profiliniz başarıyla güncellendi!';

  @override
  String health_save_error(String error) {
    return 'Hata oluştu: $error';
  }

  @override
  String health_calorie_floor_warning(int floor) {
    return '⚠️ KRİTİK: Hesaplanan kalori hedefiniz güvenli minimum ($floor kcal) altındaydı. Otomatik olarak güvenli tabana ayarlandı.';
  }

  @override
  String get health_protein_per_kg_label => 'Protein Oranı';

  @override
  String health_protein_per_kg_value(String value) {
    return '$value g/kg';
  }

  @override
  String get health_macro_model_label => 'Makro Model';

  @override
  String get health_recommended_foods_title => 'Önerilen Gıdalar';

  @override
  String get health_kcal_unit => 'kcal';
}
