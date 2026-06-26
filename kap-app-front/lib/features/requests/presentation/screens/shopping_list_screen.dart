import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../groups/presentation/providers/group_members_provider.dart';
import '../providers/request_controller.dart';
import '../widgets/add_request_bottom_sheet.dart';
import '../widgets/request_card.dart';
import '../../../groups/presentation/widgets/group_switcher_widget.dart';

/// A Material 3 screen that displays the shopping requests list for the active group.
/// Reactively handles realtime stream subscriptions, user profile resolving, and status sorting.
class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeGroup = ref.watch(activeGroupProvider);

    if (activeGroup == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.shopping_list_title),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(authProvider.notifier).signOut();
              },
              tooltip: l10n.auth_sign_out,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_off_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16.0),
                Text(
                  l10n.shopping_list_no_active_group,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24.0),
                // Re-use group switcher directly to let them pick a group
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: GroupSwitcherWidget(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final requestsAsync = ref.watch(requestControllerProvider);
    final membersAsync = ref.watch(groupMembersProvider(activeGroup.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(activeGroup.name),
        actions: [
          const GroupSwitcherWidget(),
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => context.push('/members'),
            tooltip: l10n.group_members_title,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
            },
            tooltip: l10n.auth_sign_out,
          ),
        ],
      ),
      body: requestsAsync.when(
        data: (requests) {
          return membersAsync.when(
            data: (members) {
              if (requests.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          l10n.shopping_list_no_items,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Create lookup map for member names
              final memberMap = {
                for (final m in members) m.user.id: m.user.displayName
              };

              // Programmatic split and sorting to prevent list flickering on stream updates
              final pending = requests.where((r) => r.status == 'pending').toList();
              final completed = requests.where((r) => r.status == 'done').toList();

              // Sort by creation date descending to keep newest entries stable at the top
              pending.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              completed.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (pending.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                      child: Text(
                        l10n.shopping_list_active_section,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    ...pending.map((req) {
                      final requesterName = memberMap[req.requestedBy] ?? req.requestedBy;
                      return RequestCard(
                        key: ValueKey(req.id),
                        request: req,
                        requesterName: requesterName,
                      );
                    }),
                  ],
                  if (completed.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 8.0),
                      child: Text(
                        l10n.shopping_list_completed_section,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    ...completed.map((req) {
                      final requesterName = memberMap[req.requestedBy] ?? req.requestedBy;
                      return RequestCard(
                        key: ValueKey(req.id),
                        request: req,
                        requesterName: requesterName,
                      );
                    }),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text('${l10n.errorGeneric}: $err'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('${l10n.errorGeneric}: $err'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const AddRequestBottomSheet(),
          );
        },
        tooltip: l10n.shopping_list_add_item_tooltip,
        child: const Icon(Icons.add),
      ),
    );
  }
}
