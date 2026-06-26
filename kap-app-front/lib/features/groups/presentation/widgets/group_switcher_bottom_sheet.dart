import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/active_group_provider.dart';
import '../providers/user_groups_provider.dart';

/// A bottom sheet displaying the list of all groups the user belongs to,
/// enabling them to tap and switch the active group.
class GroupSwitcherBottomSheet extends ConsumerWidget {
  const GroupSwitcherBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(userGroupsProvider);
    final activeGroup = ref.watch(activeGroupProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Switch Group',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const Divider(height: 1),
          groupsAsync.when(
            data: (groups) {
              if (groups.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: Text('You are not in any groups.')),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final isSelected = activeGroup?.id == group.id;

                  return ListTile(
                    leading: const Icon(Icons.group),
                    title: Text(group.name),
                    subtitle: Text(group.type),
                    trailing: isSelected
                        ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      ref.read(activeGroupProvider.notifier).switchGroup(group);
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(child: Text('Failed to load groups: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
