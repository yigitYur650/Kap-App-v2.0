import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kap_app_front/core/models/request_model.dart';
import 'package:kap_app_front/features/requests/presentation/providers/request_controller.dart';
import 'package:kap_app_front/shared/theme/app_colors.dart';
import 'package:kap_app_front/shared/theme/app_typography.dart';

class RequestCard extends ConsumerWidget {
  final RequestModel request;

  const RequestCard({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = request.status == 'done';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFF0F1011) : const Color(0xFF141414),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDone
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          // Animated Checkbox status toggle
          GestureDetector(
            onTap: () async {
              final result = await ref.read(requestControllerProvider.notifier).updateRequestStatus(
                    requestId: request.id,
                    status: isDone ? 'pending' : 'done',
                  );
              result.fold(
                (failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(failure.message),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                (_) {},
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDone ? AppColors.primary : const Color(0xFF333333),
                  width: 2,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: isDone
                    ? const Icon(
                        Icons.check_rounded,
                        key: ValueKey('check_icon'),
                        color: Colors.white,
                        size: 16,
                      )
                    : const SizedBox(key: ValueKey('empty_icon')),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Item name, quantity/unit badge & private tag
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Item name row
                Row(
                  children: [
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutCubic,
                        style: AppTypography.bodyLg.copyWith(
                          decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                          decorationColor: AppColors.secondary.withValues(alpha: 0.5),
                          color: isDone
                              ? AppColors.secondary.withValues(alpha: 0.4)
                              : AppColors.text,
                        ),
                        child: Text(request.itemName),
                      ),
                    ),
                    if (request.isPrivate) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: AppColors.secondary.withValues(alpha: 0.5),
                      ),
                    ],
                  ],
                ),
                // Quantity/unit badge (shown beneath item name)
                if (request.quantity != null || request.unit != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: AppTypography.labelSm.copyWith(
                        color: isDone
                            ? AppColors.secondary.withValues(alpha: 0.3)
                            : AppColors.secondary.withValues(alpha: 0.5),
                      ),
                      child: Text(
                        '${request.quantity ?? ''}${request.quantity != null && request.unit != null ? ' ' : ''}${request.unit ?? ''}',
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Delete button (accessible to any group member)
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
            onPressed: () async {
              final result = await ref.read(requestControllerProvider.notifier).deleteRequest(
                    requestId: request.id,
                  );
              result.fold(
                (failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(failure.message),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                (_) {},
              );
            },
          ),
        ],
      ),
    );
  }
}
