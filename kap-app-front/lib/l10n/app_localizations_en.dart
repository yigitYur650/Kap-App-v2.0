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
  String get add_request_private_recipient_required =>
      'A recipient must be selected for private requests.';

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

  @override
  String get inventoryTitle => 'Home Inventory';

  @override
  String get inventoryEmptyState => 'Nothing here yet.';

  @override
  String get inventoryStatusInStock => 'In Stock';

  @override
  String get inventoryStatusLow => 'Low Stock';

  @override
  String get inventoryStatusOutOfStock => 'Out of Stock';

  @override
  String get inventoryAddItemTitle => 'Add New Item';

  @override
  String get inventoryItemNameHint => 'Enter item name...';

  @override
  String get inventoryButtonAdd => 'Add';

  @override
  String get inventoryButtonCancel => 'Cancel';

  @override
  String get group_create_success => 'Home created successfully!';

  @override
  String get group_join_success => 'Joined home successfully!';

  @override
  String get group_create_title => 'Create New Home';

  @override
  String get group_create_name_hint => 'Home/Group Name';

  @override
  String get group_type_family => 'Family';

  @override
  String get group_type_community => 'Community';

  @override
  String get dialog_cancel => 'Cancel';

  @override
  String get dialog_create => 'Create';

  @override
  String get group_join_title => 'Join Home';

  @override
  String get group_join_code_hint => 'Join Code (e.g. XK7M2R9P)';

  @override
  String get dialog_join => 'Join';

  @override
  String get group_none_selected => 'No Home Selected';

  @override
  String get group_type_family_label => 'Family Group';

  @override
  String get group_type_community_label => 'Community Group';

  @override
  String get hub_active_list_summary => 'ACTIVE LIST SUMMARY';

  @override
  String get hub_no_pending_requests => 'No pending shopping requests.';

  @override
  String hub_more_items(Object count) {
    return '+$count More';
  }

  @override
  String get hub_members_header => 'HOME MEMBERS';

  @override
  String get group_role_admin => 'Admin';

  @override
  String get group_role_member => 'Member';

  @override
  String get hub_no_group_joined => 'You are not part of any home yet.';

  @override
  String get hub_create_group_button => 'Create Home';

  @override
  String get hub_join_group_button => 'Join Home';

  @override
  String shopping_list_items_count(Object count) {
    return '$count Items';
  }

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_active_group_info => 'ACTIVE GROUP INFO';

  @override
  String get settings_join_code => 'Join Code';

  @override
  String get settings_no_code => 'NO-CODE';

  @override
  String get settings_my_groups => 'MY HOME GROUPS';

  @override
  String get settings_no_groups_found => 'No groups found.';

  @override
  String get nav_tab_hub => 'Hub';

  @override
  String get nav_tab_list => 'List';

  @override
  String get nav_tab_settings => 'Settings';

  @override
  String get add_request_item_name_hint => 'What is needed? (e.g. Milk)';

  @override
  String get add_request_quantity_label => 'Quantity';

  @override
  String get add_request_quantity_hint => 'e.g. 2, 500';

  @override
  String get add_request_unit_label => 'Unit';

  @override
  String get add_request_unit_hint => 'e.g. pcs, kg, L';

  @override
  String get settings_delete_group_title => 'Delete Home?';

  @override
  String get settings_delete_group_confirm => 'Are you sure you want to delete';

  @override
  String get settings_delete_group_success => 'Home deleted successfully.';

  @override
  String get dialog_delete => 'Delete';
}
