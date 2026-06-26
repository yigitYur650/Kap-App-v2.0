import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/network/supabase_client.dart';

/// Represents a group member coupled with their database profile and group role.
class GroupMemberWithProfile {
  final AppUser user;
  final String role;
  const GroupMemberWithProfile({required this.user, required this.role});
}

/// Provider that fetches all user profiles belonging to a specific group.
final groupMembersProvider = FutureProvider.family<List<GroupMemberWithProfile>, String>((ref, groupId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final response = await supabase
      .from('group_members')
      .select('role, users (id, display_name, email, unique_code)')
      .eq('group_id', groupId);

  final list = (response as List).map((item) {
    final userJson = item['users'] as Map<String, dynamic>;
    final role = item['role'] as String;
    return GroupMemberWithProfile(
      user: AppUser.fromJson(userJson),
      role: role,
    );
  }).toList();

  return list;
});
