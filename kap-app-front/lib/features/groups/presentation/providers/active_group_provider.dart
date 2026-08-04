import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/group_model.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import 'user_groups_provider.dart';

const String kActiveGroupIdKey = 'active_group_id';

/// Notifier managing the currently selected active group.
///
/// **Flicker Prevention (FL-D-C7):**
/// During `userGroupsProvider` invalidation (e.g., after createGroup/joinGroup),
/// the provider goes through loading→data cycle. Previously, this caused
/// `activeGroupProvider` to return null during loading, which triggered stream
/// subscription disposal and re-creation in `requestControllerProvider`.
///
/// Fix: Cache the last known group list in a StateProvider and use it
/// during the loading phase instead of accessing our own `state` (which would
/// cause a circular dependency).
///
/// **Initialization Fix (FL-D-C7-v2):**
/// Previously the loading/error callbacks accessed `state` directly, which triggered
/// `ref.readSelf()` on an uninitialized provider, causing:
///   "Bad state: Tried to read the state of an uninitialized provider."
/// Now we use [userGroupsProvider]'s `.hasValue` / `.value` via a separate
/// non-circular path to preserve the last known data.
class ActiveGroup extends Notifier<GroupModel?> {
  // Stores the last successfully loaded group list outside of Riverpod state
  // to avoid circular dependency during the loading phase.
  List<GroupModel>? _lastKnownGroups;

  @override
  GroupModel? build() {
    final groupsAsync = ref.watch(userGroupsProvider);
    final prefs = ref.watch(sharedPreferencesProvider);

    return groupsAsync.when(
      data: (groups) {
        // Cache the latest group list for use during future loading cycles
        _lastKnownGroups = groups;

        if (groups.isEmpty) {
          // No groups available — clear cached ID and return null
          Future.microtask(() => prefs.remove(kActiveGroupIdKey));
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
      loading: () {
        // Flicker Prevention: Return the last known active group using the
        // cached group list, WITHOUT accessing our own `state` (which would
        // trigger a circular dependency since build() hasn't completed yet).
        final lastGroups = _lastKnownGroups;
        if (lastGroups == null || lastGroups.isEmpty) {
          return null;
        }

        // Try to recover the previously selected group from the cached list
        final cachedId = prefs.getString(kActiveGroupIdKey);
        if (cachedId != null) {
          final match = lastGroups.where((g) => g.id == cachedId);
          if (match.isNotEmpty) {
            return match.first;
          }
        }

        // Fall back to the cached list's first group
        return lastGroups.first;
      },
      error: (err, stack) {
        // On error, return the last known group from the cache.
        // This prevents the UI from collapsing when a transient error occurs.
        final lastGroups = _lastKnownGroups;
        if (lastGroups == null || lastGroups.isEmpty) {
          return null;
        }

        final cachedId = prefs.getString(kActiveGroupIdKey);
        if (cachedId != null) {
          final match = lastGroups.where((g) => g.id == cachedId);
          if (match.isNotEmpty) {
            return match.first;
          }
        }

        return lastGroups.first;
      },
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
