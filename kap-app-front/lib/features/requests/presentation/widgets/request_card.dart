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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          // Checkbox status toggle
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
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDone ? AppColors.primary : const Color(0xFF2A2A2A),
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
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
                      child: Text(
                        request.itemName,
                        style: AppTypography.bodyLg.copyWith(
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone
                              ? AppColors.secondary.withOpacity(0.4)
                              : AppColors.text,
                        ),
                      ),
                    ),
                    if (request.isPrivate) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: AppColors.secondary.withOpacity(0.5),
                      ),
                    ],
                  ],
                ),
                // Quantity/unit badge (shown beneath item name)
                if (request.quantity != null || request.unit != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${request.quantity ?? ''}${request.quantity != null && request.unit != null ? ' ' : ''}${request.unit ?? ''}',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.secondary.withOpacity(0.5),
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
              Icons.delete_outline,
              size: 20,
              color: AppColors.primary.withOpacity(0.8),
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
