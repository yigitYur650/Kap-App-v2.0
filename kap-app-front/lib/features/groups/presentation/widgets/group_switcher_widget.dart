import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/active_group_provider.dart';
import 'group_switcher_bottom_sheet.dart';

/// A Material 3 widget that displays the active group name and triggers
/// the group switcher bottom sheet on tap.
class GroupSwitcherWidget extends ConsumerWidget {
  const GroupSwitcherWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGroup = ref.watch(activeGroupProvider);

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => const GroupSwitcherBottomSheet(),
        );
      },
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_outlined, size: 20),
            const SizedBox(width: 8.0),
            Text(
              activeGroup?.name ?? 'No Group Selected',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 4.0),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}
