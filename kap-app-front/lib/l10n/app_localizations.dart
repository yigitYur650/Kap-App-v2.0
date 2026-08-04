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

  /// No description provided for @add_request_private_recipient_required.
  ///
  /// In en, this message translates to:
  /// **'A recipient must be selected for private requests.'**
  String get add_request_private_recipient_required;

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

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Home Inventory'**
  String get inventoryTitle;

  /// No description provided for @inventoryEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get inventoryEmptyState;

  /// No description provided for @inventoryStatusInStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inventoryStatusInStock;

  /// No description provided for @inventoryStatusLow.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get inventoryStatusLow;

  /// No description provided for @inventoryStatusOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get inventoryStatusOutOfStock;

  /// No description provided for @inventoryAddItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Item'**
  String get inventoryAddItemTitle;

  /// No description provided for @inventoryItemNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter item name...'**
  String get inventoryItemNameHint;

  /// No description provided for @inventoryButtonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get inventoryButtonAdd;

  /// No description provided for @inventoryButtonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get inventoryButtonCancel;

  /// No description provided for @group_create_success.
  ///
  /// In en, this message translates to:
  /// **'Home created successfully!'**
  String get group_create_success;

  /// No description provided for @group_join_success.
  ///
  /// In en, this message translates to:
  /// **'Joined home successfully!'**
  String get group_join_success;

  /// No description provided for @group_create_title.
  ///
  /// In en, this message translates to:
  /// **'Create New Home'**
  String get group_create_title;

  /// No description provided for @group_create_name_hint.
  ///
  /// In en, this message translates to:
  /// **'Home/Group Name'**
  String get group_create_name_hint;

  /// No description provided for @group_type_family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get group_type_family;

  /// No description provided for @group_type_community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get group_type_community;

  /// No description provided for @dialog_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialog_cancel;

  /// No description provided for @dialog_create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get dialog_create;

  /// No description provided for @group_join_title.
  ///
  /// In en, this message translates to:
  /// **'Join Home'**
  String get group_join_title;

  /// No description provided for @group_join_code_hint.
  ///
  /// In en, this message translates to:
  /// **'Join Code (e.g. XK7M2R9P)'**
  String get group_join_code_hint;

  /// No description provided for @dialog_join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get dialog_join;

  /// No description provided for @group_none_selected.
  ///
  /// In en, this message translates to:
  /// **'No Home Selected'**
  String get group_none_selected;

  /// No description provided for @group_type_family_label.
  ///
  /// In en, this message translates to:
  /// **'Family Group'**
  String get group_type_family_label;

  /// No description provided for @group_type_community_label.
  ///
  /// In en, this message translates to:
  /// **'Community Group'**
  String get group_type_community_label;

  /// No description provided for @hub_active_list_summary.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE LIST SUMMARY'**
  String get hub_active_list_summary;

  /// No description provided for @hub_no_pending_requests.
  ///
  /// In en, this message translates to:
  /// **'No pending shopping requests.'**
  String get hub_no_pending_requests;

  /// No description provided for @hub_more_items.
  ///
  /// In en, this message translates to:
  /// **'+{count} More'**
  String hub_more_items(Object count);

  /// No description provided for @hub_members_header.
  ///
  /// In en, this message translates to:
  /// **'HOME MEMBERS'**
  String get hub_members_header;

  /// No description provided for @group_role_admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get group_role_admin;

  /// No description provided for @group_role_member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get group_role_member;

  /// No description provided for @hub_no_group_joined.
  ///
  /// In en, this message translates to:
  /// **'You are not part of any home yet.'**
  String get hub_no_group_joined;

  /// No description provided for @hub_create_group_button.
  ///
  /// In en, this message translates to:
  /// **'Create Home'**
  String get hub_create_group_button;

  /// No description provided for @hub_join_group_button.
  ///
  /// In en, this message translates to:
  /// **'Join Home'**
  String get hub_join_group_button;

  /// No description provided for @shopping_list_items_count.
  ///
  /// In en, this message translates to:
  /// **'{count} Items'**
  String shopping_list_items_count(Object count);

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_active_group_info.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE GROUP INFO'**
  String get settings_active_group_info;

  /// No description provided for @settings_join_code.
  ///
  /// In en, this message translates to:
  /// **'Join Code'**
  String get settings_join_code;

  /// No description provided for @settings_no_code.
  ///
  /// In en, this message translates to:
  /// **'NO-CODE'**
  String get settings_no_code;

  /// No description provided for @settings_my_groups.
  ///
  /// In en, this message translates to:
  /// **'MY HOME GROUPS'**
  String get settings_my_groups;

  /// No description provided for @settings_no_groups_found.
  ///
  /// In en, this message translates to:
  /// **'No groups found.'**
  String get settings_no_groups_found;

  /// No description provided for @nav_tab_hub.
  ///
  /// In en, this message translates to:
  /// **'Hub'**
  String get nav_tab_hub;

  /// No description provided for @nav_tab_list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get nav_tab_list;

  /// No description provided for @nav_tab_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nav_tab_settings;

  /// No description provided for @add_request_item_name_hint.
  ///
  /// In en, this message translates to:
  /// **'What is needed? (e.g. Milk)'**
  String get add_request_item_name_hint;

  /// No description provided for @add_request_quantity_label.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get add_request_quantity_label;

  /// No description provided for @add_request_quantity_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2, 500'**
  String get add_request_quantity_hint;

  /// No description provided for @add_request_unit_label.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get add_request_unit_label;

  /// No description provided for @add_request_unit_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. pcs, kg, L'**
  String get add_request_unit_hint;

  /// No description provided for @settings_delete_group_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Home?'**
  String get settings_delete_group_title;

  /// No description provided for @settings_delete_group_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get settings_delete_group_confirm;

  /// No description provided for @settings_delete_group_success.
  ///
  /// In en, this message translates to:
  /// **'Home deleted successfully.'**
  String get settings_delete_group_success;

  /// No description provided for @dialog_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dialog_delete;
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
