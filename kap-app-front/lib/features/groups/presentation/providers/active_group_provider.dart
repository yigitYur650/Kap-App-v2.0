import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/group_model.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import 'user_groups_provider.dart';

const String kActiveGroupIdKey = 'active_group_id';

/// Notifier managing the currently selected active group.
class ActiveGroup extends Notifier<GroupModel?> {
  @override
  GroupModel? build() {
    final groupsAsync = ref.watch(userGroupsProvider);
    final prefs = ref.watch(sharedPreferencesProvider);

    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return null;
        }

        final cachedId = prefs.getString(kActiveGroupIdKey);
        if (cachedId != null) {
          final containsGroup = groups.any((g) => g.id == cachedId);
          if (containsGroup) {
            return groups.firstWhere((g) => g.id == cachedId);
          } else {
            // Cache Invalidation Rule: Clear invalid cached ID asynchronously
            // to avoid state mutations during provider build execution.
            Future.microtask(() => prefs.remove(kActiveGroupIdKey));
          }
        }

        return groups.first;
      },
      loading: () => null,
      error: (err, stack) => null,
    );
  }

  /// Optimistically updates the active group state and schedules local storage persistence.
  void switchGroup(GroupModel group) {
    state = group;
    // Perform storage write in the background
    ref.read(sharedPreferencesProvider).setString(kActiveGroupIdKey, group.id);
  }
}

/// Provider that exposes the current active [GroupModel] (or null).
final activeGroupProvider = NotifierProvider<ActiveGroup, GroupModel?>(() {
  return ActiveGroup();
});
