import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kap_app_front/features/requests/presentation/providers/request_controller.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';
import 'package:kap_app_front/shared/theme/app_colors.dart';
import 'package:kap_app_front/shared/theme/app_typography.dart';

class ActiveListSummaryCard extends ConsumerWidget {
  const ActiveListSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(requestControllerProvider);
    final localizations = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => context.go('/list'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF141414).withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            left: BorderSide(color: AppColors.primary, width: 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.hub_active_list_summary,
                  style: AppTypography.labelLg.copyWith(
                    color: AppColors.secondary,
                    letterSpacing: 1.5,
                  ),
                ),
                requestsAsync.when(
                  data: (items) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      localizations.shopping_list_items_count(
                        items.where((i) => i.status == 'pending').length,
                      ),
                      style: AppTypography.labelSm.copyWith(color: AppColors.primary),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            requestsAsync.when(
              data: (items) {
                final pending = items.where((i) => i.status == 'pending').toList();
                if (pending.isEmpty) {
                  return Text(
                    localizations.hub_no_pending_requests,
                    style: AppTypography.bodyMd.copyWith(color: Colors.white70),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...pending.take(3).map((item) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2020),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF242424)),
                          ),
                          child: Text(
                            item.itemName,
                            style: AppTypography.labelLg,
                          ),
                        )),
                    if (pending.length > 3)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          localizations.hub_more_items(pending.length - 3),
                          style: AppTypography.labelLg.copyWith(color: Colors.white),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Text('${localizations.errorGeneric}: $err'),
            ),
          ],
        ),
      ),
    );
  }
}
