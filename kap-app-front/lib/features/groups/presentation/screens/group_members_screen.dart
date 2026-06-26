import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/active_group_provider.dart';
import '../providers/group_members_provider.dart';

/// A Material 3 screen that displays the members of the active group
/// and provides access to the user's unique joining code.
class GroupMembersScreen extends ConsumerWidget {
  const GroupMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final activeGroup = ref.watch(activeGroupProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.group_members_title),
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text(l10n.group_members_login_prompt));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.group_members_share_code_title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          l10n.group_members_share_code_subtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 10.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  user.uniqueCode,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            IconButton.filledTonal(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: user.uniqueCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.group_members_copied),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy),
                              tooltip: l10n.group_members_copy_tooltip,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),
                Text(
                  l10n.group_members_list_title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: activeGroup == null
                      ? Center(
                          child: Text(l10n.group_members_select_group_prompt),
                        )
                      : ref.watch(groupMembersProvider(activeGroup.id)).when(
                            data: (members) {
                              if (members.isEmpty) {
                                return Center(child: Text(l10n.group_members_empty));
                              }
                              return ListView.builder(
                                itemCount: members.length,
                                itemBuilder: (context, index) {
                                  final member = members[index];
                                  final isAdmin = member.role == 'admin';

                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        child: Text(member.user.displayName.isNotEmpty
                                            ? member.user.displayName[0].toUpperCase()
                                            : '?'),
                                      ),
                                      title: Text(member.user.displayName),
                                      subtitle: Text(member.user.email),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                          vertical: 4.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isAdmin
                                              ? Theme.of(context).colorScheme.primaryContainer
                                              : Theme.of(context).colorScheme.secondaryContainer,
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                        child: Text(
                                          member.role,
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: isAdmin
                                                    ? Theme.of(context).colorScheme.onPrimaryContainer
                                                    : Theme.of(context).colorScheme.onSecondaryContainer,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, _) => Center(child: Text('${l10n.group_members_load_failed}: $err')),
                          ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('${l10n.group_members_profile_load_failed}: $err')),
      ),
    );
  }
}

