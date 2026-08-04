import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kap_app_front/features/groups/presentation/providers/active_group_provider.dart';
import 'package:kap_app_front/features/requests/presentation/providers/request_controller.dart';
import 'package:kap_app_front/features/requests/presentation/widgets/add_request_bottom_sheet.dart';
import 'package:kap_app_front/features/requests/presentation/widgets/request_card.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';
import 'package:kap_app_front/shared/theme/app_colors.dart';
import 'package:kap_app_front/shared/theme/app_typography.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  void _showAddRequestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddRequestBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGroup = ref.watch(activeGroupProvider);
    final requestsAsync = ref.watch(requestControllerProvider);
    final localizations = AppLocalizations.of(context)!;
    final bottomNavHeight = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          activeGroup != null
              ? '${activeGroup.name} - ${localizations.nav_tab_list}'
              : localizations.shopping_list_title,
          style: AppTypography.headlineLg,
        ),
      ),
      body: activeGroup == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: AppColors.secondary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.shopping_list_no_active_group,
                      style: AppTypography.bodyLg.copyWith(
                        color: AppColors.secondary.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : requestsAsync.when(
              data: (items) {
                final pendingItems = items.where((i) => i.status == 'pending').toList();
                final completedItems = items.where((i) => i.status == 'done').toList();

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.playlist_add_check,
                          size: 64,
                          color: AppColors.secondary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations.shopping_list_no_items,
                          style: AppTypography.bodyLg.copyWith(
                            color: AppColors.secondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    // Pending list
                    if (pendingItems.isNotEmpty) ...[
                      Text(
                        localizations.shopping_list_active_section,
                        style: AppTypography.labelLg.copyWith(
                          color: AppColors.secondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...pendingItems.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: RequestCard(request: item),
                          )),
                      const SizedBox(height: 24),
                    ],

                    // Completed list
                    if (completedItems.isNotEmpty) ...[
                      Text(
                        localizations.shopping_list_completed_section,
                        style: AppTypography.labelLg.copyWith(
                          color: AppColors.secondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...completedItems.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: RequestCard(request: item),
                          )),
                    ],

                    // Dynamic bottom padding to prevent last item from hiding under nav bar
                    SizedBox(height: bottomNavHeight + 80),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Text('${localizations.errorGeneric}: $err'),
              ),
            ),
      floatingActionButton: activeGroup != null
          ? Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16.0),
              child: FloatingActionButton(
                onPressed: () => _showAddRequestSheet(context),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                elevation: 6,
                child: const Icon(Icons.add, size: 28),
              ),
            )
          : null,
    );
  }
}
