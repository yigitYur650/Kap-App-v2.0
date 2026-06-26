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
}
