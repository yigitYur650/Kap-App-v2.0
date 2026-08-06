import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class AIPriceEstimatorBar extends StatelessWidget {
  final bool isLoading;
  final double? estimatedTotal;
  final VoidCallback onEstimatePressed;
  final VoidCallback? onScanReceiptPressed;

  const AIPriceEstimatorBar({
    super.key,
    required this.isLoading,
    this.estimatedTotal,
    required this.onEstimatePressed,
    this.onScanReceiptPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Akıllı Asistan',
                          style: AppTypography.labelLg.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          estimatedTotal != null
                              ? 'Tahmini Toplam: ~${estimatedTotal!.toStringAsFixed(2)} TL'
                              : 'Listenin tahmini fiyatını çıkarın veya fiş taratın',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onScanReceiptPressed != null)
                      TextButton.icon(
                        onPressed: onScanReceiptPressed,
                        icon: const Icon(Icons.receipt_long, size: 18, color: AppColors.primary),
                        label: Text(
                          isNarrow ? 'Fiş' : 'Fiş Tara',
                          style: AppTypography.labelSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      onPressed: onEstimatePressed,
                      icon: const Icon(Icons.calculate_outlined, size: 16),
                      label: Text(
                        isNarrow ? 'Hesapla' : 'Fiyat Hesapla',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isNarrow ? 10 : 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
