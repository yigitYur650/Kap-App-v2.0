import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class AIRecommendationsDialog extends StatelessWidget {
  final List<dynamic> recommendations;
  final Function(String itemName)? onAddSuggestedItem;

  const AIRecommendationsDialog({
    super.key,
    required this.recommendations,
    this.onAddSuggestedItem,
  });

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return Colors.green;
      case 'savings':
        return Colors.orange;
      case 'recipe':
        return Colors.purple;
      case 'missing':
        return Colors.amber;
      case 'storage':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return 'Dengeli Beslenme';
      case 'savings':
        return 'Bütçe & Tasarruf';
      case 'recipe':
        return 'Yemek Tarifi Fikri';
      case 'missing':
        return 'Unutulanlar Uyarısı';
      case 'storage':
        return 'Tazelik & İsraf Önleme';
      default:
        return 'Akıllı Tavsiye';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isWeb ? 560 : screenWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        margin: EdgeInsets.all(isWeb ? 16 : 0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(24),
            bottom: Radius.circular(isWeb ? 24 : 0),
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 28),
                    const SizedBox(width: 8),
                    Text('AI Akıllı Tavsiyeler', style: AppTypography.headlineLg),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Alışveriş listenize göre kişiselleştirilmiş beslenme, bütçe ve tarif ipuçları:',
              style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: recommendations.length,
                itemBuilder: (context, idx) {
                  final rec = recommendations[idx];
                  final category = rec['category'] ?? 'health';
                  final title = rec['title'] ?? 'Tavsiye';
                  final desc = rec['description'] ?? '';
                  final icon = rec['icon'] ?? '💡';
                  final suggestedItem = rec['suggested_item'] ?? '';
                  final catColor = _getCategoryColor(category);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: catColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(icon, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getCategoryLabel(category),
                                style: AppTypography.labelSm.copyWith(color: catColor, fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          desc,
                          style: AppTypography.bodyMd.copyWith(fontSize: 13, height: 1.4),
                        ),
                        if (suggestedItem.toString().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (onAddSuggestedItem != null) {
                                  onAddSuggestedItem!(suggestedItem);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('"$suggestedItem" alışveriş listesine eklendi!'),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add_shopping_cart, size: 16),
                              label: Text('"$suggestedItem" Listeye Ekle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: catColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                textStyle: AppTypography.labelSm.copyWith(fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
