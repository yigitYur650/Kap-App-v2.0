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

  @override
  String get health_title => 'Personal Nutrition & Fitness';

  @override
  String get health_daily_target_calories => 'Daily Target Calories';

  @override
  String get health_goal_lose => '🏃‍♂️ Weight Loss';

  @override
  String get health_goal_maintain => '🧘‍♀️ Maintain';

  @override
  String get health_goal_gain => '🏋️‍♂️ Weight Gain';

  @override
  String get health_bmr_label => 'BMR (Metabolism)';

  @override
  String get health_tdee_label => 'TDEE (Expenditure)';

  @override
  String get health_protein_label => 'Protein';

  @override
  String get health_carbs_label => 'Carbohydrate';

  @override
  String get health_fat_label => 'Fat';

  @override
  String get health_water_target_label => 'Water Intake (Target)';

  @override
  String get health_body_fat_label => 'Body Fat Status';

  @override
  String get health_body_measurements_title => 'My Body Measurements & Goals';

  @override
  String get health_weight_label => 'Weight (kg)';

  @override
  String get health_height_label => 'Height (cm)';

  @override
  String get health_age_label => 'Age';

  @override
  String get health_daily_water_label => 'Daily Water (L)';

  @override
  String get health_body_fat_pct_label => 'Fat Ratio (%)';

  @override
  String get health_gender_label => 'Gender';

  @override
  String get health_gender_male => 'Male 👨';

  @override
  String get health_gender_female => 'Female 👩';

  @override
  String get health_activity_level_label => 'Daily Activity Level';

  @override
  String get health_activity_sedentary => 'Sedentary (Desk job)';

  @override
  String get health_activity_light => 'Lightly Active (1-3 days/week)';

  @override
  String get health_activity_moderate => 'Moderately Active (3-5 days/week)';

  @override
  String get health_activity_active => 'Very Active (6-7 days/week)';

  @override
  String get health_activity_very_active => 'Physical Job / Heavy Training';

  @override
  String get health_main_goal_label => 'Main Goal';

  @override
  String get health_fitness_goal_label => 'Nutrition Model';

  @override
  String get health_fitness_muscle => '🏋️‍♂️ Muscle Building (High Protein)';

  @override
  String get health_fitness_keto => '🔥 Fat Loss (Keto / Low Carb)';

  @override
  String get health_fitness_balanced => '⚖️ Balanced & Sustainable';

  @override
  String get health_kidney_disease_title => 'Kidney Disease';

  @override
  String get health_kidney_disease_subtitle =>
      'If active, protein intake is limited to max 0.8g/kg for safety.';

  @override
  String get health_allergen_title => 'Allergens';

  @override
  String get health_allergen_subtitle =>
      'Select your allergens. These foods will be excluded from recommendations.';

  @override
  String get health_share_with_group_title => 'Share with Group Members';

  @override
  String get health_share_with_group_subtitle =>
      'If enabled, group members can see your nutrition progress.';

  @override
  String get health_save_button => 'Save Personal Info';

  @override
  String get health_save_success =>
      'Your personal health profile has been updated successfully!';

  @override
  String health_save_error(String error) {
    return 'An error occurred: $error';
  }

  @override
  String health_calorie_floor_warning(int floor) {
    return '⚠️ CRITICAL: Your calculated calorie target was below the safe minimum ($floor kcal). It has been automatically set to the safe floor.';
  }

  @override
  String get health_protein_per_kg_label => 'Protein Ratio';

  @override
  String health_protein_per_kg_value(String value) {
    return '$value g/kg';
  }

  @override
  String get health_macro_model_label => 'Macro Model';

  @override
  String get health_recommended_foods_title => 'Recommended Foods';

  @override
  String get health_kcal_unit => 'kcal';
}
