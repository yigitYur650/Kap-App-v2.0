import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Kap App'**
  String get appTitle;

  /// Generic fallback error message
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get errorGeneric;

  /// No description provided for @auth_email_invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get auth_email_invalid;

  /// No description provided for @auth_email_empty.
  ///
  /// In en, this message translates to:
  /// **'Email address cannot be empty.'**
  String get auth_email_empty;

  /// No description provided for @auth_password_too_short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get auth_password_too_short;

  /// No description provided for @auth_password_empty.
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty.'**
  String get auth_password_empty;

  /// No description provided for @auth_password_mismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get auth_password_mismatch;

  /// No description provided for @auth_display_name_empty.
  ///
  /// In en, this message translates to:
  /// **'Display name cannot be empty.'**
  String get auth_display_name_empty;

  /// No description provided for @auth_login_title.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get auth_login_title;

  /// No description provided for @auth_login_button.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get auth_login_button;

  /// No description provided for @auth_login_email_label.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get auth_login_email_label;

  /// No description provided for @auth_login_password_label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_login_password_label;

  /// No description provided for @auth_login_forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get auth_login_forgot_password;

  /// No description provided for @auth_login_register_prompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get auth_login_register_prompt;

  /// No description provided for @auth_login_register_link.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get auth_login_register_link;

  /// No description provided for @auth_register_title.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get auth_register_title;

  /// No description provided for @auth_register_button.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get auth_register_button;

  /// No description provided for @auth_register_display_name_label.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get auth_register_display_name_label;

  /// No description provided for @auth_register_email_label.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get auth_register_email_label;

  /// No description provided for @auth_register_password_label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_register_password_label;

  /// No description provided for @auth_register_confirm_password_label.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get auth_register_confirm_password_label;

  /// No description provided for @auth_register_login_prompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get auth_register_login_prompt;

  /// No description provided for @auth_register_login_link.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get auth_register_login_link;

  /// No description provided for @shopping_list_title.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get shopping_list_title;

  /// No description provided for @shopping_list_no_active_group.
  ///
  /// In en, this message translates to:
  /// **'Select or join a group first to view the shopping list.'**
  String get shopping_list_no_active_group;

  /// No description provided for @shopping_list_active_section.
  ///
  /// In en, this message translates to:
  /// **'Active Items'**
  String get shopping_list_active_section;

  /// No description provided for @shopping_list_completed_section.
  ///
  /// In en, this message translates to:
  /// **'Completed Items'**
  String get shopping_list_completed_section;

  /// No description provided for @shopping_list_no_items.
  ///
  /// In en, this message translates to:
  /// **'No items in this list.'**
  String get shopping_list_no_items;

  /// No description provided for @shopping_list_add_item_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get shopping_list_add_item_tooltip;

  /// No description provided for @request_card_private_label.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get request_card_private_label;

  /// No description provided for @add_request_title.
  ///
  /// In en, this message translates to:
  /// **'Add Shopping Item'**
  String get add_request_title;

  /// No description provided for @add_request_item_name_label.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get add_request_item_name_label;

  /// No description provided for @add_request_item_name_empty.
  ///
  /// In en, this message translates to:
  /// **'Item name cannot be empty.'**
  String get add_request_item_name_empty;

  /// No description provided for @add_request_private_label.
  ///
  /// In en, this message translates to:
  /// **'Private Request (only visible to specified member)'**
  String get add_request_private_label;

  /// No description provided for @add_request_private_to_label.
  ///
  /// In en, this message translates to:
  /// **'Private To'**
  String get add_request_private_to_label;

  /// No description provided for @add_request_submit_button.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add_request_submit_button;

  /// No description provided for @add_request_cancel_button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get add_request_cancel_button;

  /// No description provided for @group_members_title.
  ///
  /// In en, this message translates to:
  /// **'Group Members'**
  String get group_members_title;

  /// No description provided for @auth_sign_out.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get auth_sign_out;

  /// No description provided for @group_members_login_prompt.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view members.'**
  String get group_members_login_prompt;

  /// No description provided for @group_members_share_code_title.
  ///
  /// In en, this message translates to:
  /// **'Your Share Code'**
  String get group_members_share_code_title;

  /// No description provided for @group_members_share_code_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Share this code with family members to let them join your family group:'**
  String get group_members_share_code_subtitle;

  /// No description provided for @group_members_copied.
  ///
  /// In en, this message translates to:
  /// **'Share code copied to clipboard'**
  String get group_members_copied;

  /// No description provided for @group_members_copy_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get group_members_copy_tooltip;

  /// No description provided for @group_members_list_title.
  ///
  /// In en, this message translates to:
  /// **'Members List'**
  String get group_members_list_title;

  /// No description provided for @group_members_select_group_prompt.
  ///
  /// In en, this message translates to:
  /// **'Select or join a group first to view members.'**
  String get group_members_select_group_prompt;

  /// No description provided for @group_members_empty.
  ///
  /// In en, this message translates to:
  /// **'No members in this group.'**
  String get group_members_empty;

  /// No description provided for @group_members_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load members'**
  String get group_members_load_failed;

  /// No description provided for @group_members_profile_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get group_members_profile_load_failed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
