import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/request_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/group_members_provider.dart';
import '../providers/request_controller.dart';

/// A Material 3 card representing a shopping request, allowing status updates
/// via checkbox for owners and admins, showing privacy locks, and letting the creator delete it.
class RequestCard extends ConsumerWidget {
  final RequestModel request;
  final String requesterName;

  const RequestCard({
    super.key,
    required this.request,
    required this.requesterName,
  });

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authProvider).value;
    final isOwner = authUser != null && authUser.id == request.requestedBy;
    final isDone = request.status == 'done';

    // Watch group members to resolve if the current user is an admin of this group
    final membersAsync = ref.watch(groupMembersProvider(request.groupId));
    final isAdmin = membersAsync.maybeWhen(
      data: (members) => members.any((m) => m.user.id == authUser?.id && m.role == 'admin'),
      orElse: () => false,
    );

    // Hardened activation boundary condition
    final canToggle = isOwner || isAdmin;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: ListTile(
        leading: Checkbox(
          value: isDone,
          onChanged: canToggle
              ? (value) {
                  if (value != null) {
                    final newStatus = value ? 'done' : 'pending';
                    ref.read(requestControllerProvider.notifier).updateRequestStatus(
                          requestId: request.id,
                          status: newStatus,
                        );
                  }
                }
              : null, // Disabled if user lacks permissions
        ),
        title: Text(
          _capitalize(request.itemName),
          style: TextStyle(
            decoration: isDone ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
            color: isDone ? Theme.of(context).colorScheme.outline : null,
          ),
        ),
        subtitle: Text(
          requesterName,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (request.isPrivate) ...[
              Icon(
                Icons.lock_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8.0),
            ],
            if (isOwner)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () {
                  ref.read(requestControllerProvider.notifier).deleteRequest(
                        requestId: request.id,
                      );
                },
                tooltip: 'Delete Request',
              ),
          ],
        ),
      ),
    );
  }
}

