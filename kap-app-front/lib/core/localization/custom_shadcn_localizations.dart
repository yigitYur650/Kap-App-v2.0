import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shadcn_flutter/src/components/locale/shadcn_localizations_en.dart';

/// Custom Localizations Delegate for ShadcnUI to handle Turkish locale and fallback to English.
class CustomShadcnLocalizationsDelegate extends LocalizationsDelegate<ShadcnLocalizations> {
  const CustomShadcnLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'tr'].contains(locale.languageCode);
  }

  @override
  Future<ShadcnLocalizations> load(Locale locale) {
    if (locale.languageCode == 'tr') {
      return SynchronousFuture<ShadcnLocalizations>(ShadcnLocalizationsTr());
    }
    return SynchronousFuture<ShadcnLocalizations>(ShadcnLocalizationsEn());
  }

  @override
  bool shouldReload(CustomShadcnLocalizationsDelegate old) => false;
}

/// Turkish localization mappings for ShadcnUI components, inheriting En fallback strings.
class ShadcnLocalizationsTr extends ShadcnLocalizationsEn {
  ShadcnLocalizationsTr() : super('tr');

  @override
  String get datePickerSelectYear => 'Yıl Seçin';

  @override
  String get placeholderDatePicker => 'Tarih seçin';

  @override
  String get placeholderTimePicker => 'Saat seçin';

  @override
  String get buttonPrevious => 'Geri';

  @override
  String get buttonNext => 'İleri';

  @override
  String get commandSearch => 'Arama yapın...';

  @override
  String get commandEmpty => 'Sonuç bulunamadı.';

  @override
  String get refreshTriggerPull => 'Yenilemek için çekin';

  @override
  String get refreshTriggerRelease => 'Yenilemek için bırakın';

  @override
  String get refreshTriggerRefreshing => 'Yenileniyor...';

  @override
  String get refreshTriggerComplete => 'Yenileme tamamlandı';
}
