// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kap App';

  @override
  String get errorGeneric => 'An unexpected error occurred. Please try again.';

  @override
  String get auth_email_invalid => 'Please enter a valid email address.';

  @override
  String get auth_email_empty => 'Email address cannot be empty.';

  @override
  String get auth_password_too_short =>
      'Password must be at least 6 characters.';

  @override
  String get auth_password_empty => 'Password cannot be empty.';

  @override
  String get auth_password_mismatch => 'Passwords do not match.';

  @override
  String get auth_display_name_empty => 'Display name cannot be empty.';

  @override
  String get auth_login_title => 'Sign In';

  @override
  String get auth_login_button => 'Sign In';

  @override
  String get auth_login_email_label => 'Email Address';

  @override
  String get auth_login_password_label => 'Password';

  @override
  String get auth_login_forgot_password => 'Forgot Password?';

  @override
  String get auth_login_register_prompt => 'Don\'t have an account?';

  @override
  String get auth_login_register_link => 'Register';

  @override
  String get auth_register_title => 'Sign Up';

  @override
  String get auth_register_button => 'Sign Up';

  @override
  String get auth_register_display_name_label => 'Display Name';

  @override
  String get auth_register_email_label => 'Email Address';

  @override
  String get auth_register_password_label => 'Password';

  @override
  String get auth_register_confirm_password_label => 'Confirm Password';

  @override
  String get auth_register_login_prompt => 'Already have an account?';

  @override
  String get auth_register_login_link => 'Sign In';

  @override
  String get shopping_list_title => 'Shopping List';

  @override
  String get shopping_list_no_active_group =>
      'Select or join a group first to view the shopping list.';

  @override
  String get shopping_list_active_section => 'Active Items';

  @override
  String get shopping_list_completed_section => 'Completed Items';

  @override
  String get shopping_list_no_items => 'No items in this list.';

  @override
  String get shopping_list_add_item_tooltip => 'Add Item';

  @override
  String get request_card_private_label => 'Private';

  @override
  String get add_request_title => 'Add Shopping Item';

  @override
  String get add_request_item_name_label => 'Item Name';

  @override
  String get add_request_item_name_empty => 'Item name cannot be empty.';

  @override
  String get add_request_private_label =>
      'Private Request (only visible to specified member)';

  @override
  String get add_request_private_to_label => 'Private To';

  @override
  String get add_request_submit_button => 'Add';

  @override
  String get add_request_cancel_button => 'Cancel';

  @override
  String get group_members_title => 'Group Members';

  @override
  String get auth_sign_out => 'Sign Out';

  @override
  String get group_members_login_prompt => 'Please log in to view members.';

  @override
  String get group_members_share_code_title => 'Your Share Code';

  @override
  String get group_members_share_code_subtitle =>
      'Share this code with family members to let them join your family group:';

  @override
  String get group_members_copied => 'Share code copied to clipboard';

  @override
  String get group_members_copy_tooltip => 'Copy Code';

  @override
  String get group_members_list_title => 'Members List';

  @override
  String get group_members_select_group_prompt =>
      'Select or join a group first to view members.';

  @override
  String get group_members_empty => 'No members in this group.';

  @override
  String get group_members_load_failed => 'Failed to load members';

  @override
  String get group_members_profile_load_failed => 'Error loading profile';
}
