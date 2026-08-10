import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class PriceBreakdownDialog extends StatelessWidget {
  final Map<String, dynamic> priceData;

  const PriceBreakdownDialog({
    super.key,
    required this.priceData,
  });

  @override
  Widget build(BuildContext context) {
    final items = priceData['items'] as List<dynamic>? ?? [];
    final totalPrice = priceData['total_price'] ?? 0.0;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Fiyat & Boyut Detayları',
              style: AppTypography.headlineLg,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tahmini Toplam:', style: AppTypography.labelLg),
                    Text(
                      '~${totalPrice.toStringAsFixed(2)} TL',
                      style: AppTypography.headlineMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...items.map((item) {
                final name = item['item_name'] ?? 'Ürün';
                final brand = item['brand'] ?? '';
                final price = item['estimated_price'] ?? 0;
                final minP = item['min_price'] ?? price;
                final maxP = item['max_price'] ?? price;
                final category = item['category'] ?? '';
                final sourceMarket = item['source_market'] ?? '';
                final variants = item['variants'] as List<dynamic>? ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '~$price TL',
                              style: AppTypography.labelLg.copyWith(color: Colors.teal, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (brand.toString().isNotEmpty || sourceMarket.toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (brand.toString().isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '🏷️ $brand',
                                    style: AppTypography.labelSm.copyWith(color: Colors.blue.shade800),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (sourceMarket.toString().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '🛒 $sourceMarket',
                                    style: AppTypography.labelSm.copyWith(color: Colors.orange.shade800),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          'Aralık: $minP TL - $maxP TL ${category.isNotEmpty ? '• $category' : ''}',
                          style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted, fontSize: 11),
                        ),
                        if (variants.isNotEmpty) ...[
                          const Divider(height: 16),
                          Text(
                            'Popüler Miktar & Fiyat Seçenekleri:',
                            style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          ...variants.map((v) {
                            final size = v['size'] ?? '';
                            final vPrice = v['price'] ?? 0;
                            final store = v['store'] ?? '';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('• $size', style: AppTypography.bodyMd.copyWith(fontSize: 12)),
                                  Text(
                                    '$vPrice TL ${store.isNotEmpty ? "($store)" : ""}',
                                    style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}
