import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class InventoryRecipeDialog extends StatefulWidget {
  final List<dynamic> recommendations;
  final Function(String itemName)? onAddSuggestedItem;

  const InventoryRecipeDialog({
    super.key,
    required this.recommendations,
    this.onAddSuggestedItem,
  });

  @override
  State<InventoryRecipeDialog> createState() => _InventoryRecipeDialogState();
}

class _InventoryRecipeDialogState extends State<InventoryRecipeDialog> {
  String _selectedFilter = 'recipe';

  static const List<Map<String, String>> _categories = [
    {'key': 'Tümü', 'label': 'Tümü', 'icon': '✨'},
    {'key': 'recipe', 'label': 'Tarifler', 'icon': '🍳'},
    {'key': 'health', 'label': 'Beslenme', 'icon': '🥗'},
    {'key': 'missing', 'label': 'Eksik Malzeme', 'icon': '⚠️'},
    {'key': 'savings', 'label': 'Tasarruf', 'icon': '💰'},
  ];

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'recipe':
        return Colors.orange;
      case 'health':
        return Colors.green;
      case 'missing':
        return Colors.redAccent;
      case 'savings':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'recipe':
        return 'Yemek Tarifi Önerisi';
      case 'health':
        return 'Sağlıklı Öğün İpucu';
      case 'missing':
        return 'Eksik Tamamlayıcı Malzeme';
      case 'savings':
        return 'Tasarruf & İsraf Önleme';
      default:
        return 'Envanter Tavsiyesi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    final filteredRecs = _selectedFilter == 'Tümü'
        ? widget.recommendations
        : widget.recommendations
            .where((r) => (r['category']?.toString().toLowerCase()) == _selectedFilter.toLowerCase())
            .toList();

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isWeb ? 580 : screenWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
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
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '🍳',
                          style: TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ne Pişirsem? (AI Tarifler)',
                              style: AppTypography.headlineLg.copyWith(fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Evdeki stokta olan malzemelerinize özel tarifler:',
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Category Filters
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final isSelected = cat['key'] == _selectedFilter;
                  final catColor = _getCategoryColor(cat['key']!);

                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat['icon']!),
                        const SizedBox(width: 4),
                        Text(
                          cat['label']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textMuted,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: catColor.withValues(alpha: 0.3),
                    backgroundColor: const Color(0xFF1E1E1E),
                    onSelected: (_) => setState(() => _selectedFilter = cat['key']!),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Recipe & Recommendations List
            Expanded(
              child: filteredRecs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('👨‍🍳', style: TextStyle(fontSize: 42)),
                          const SizedBox(height: 10),
                          Text(
                            'Bu kategoride henüz tarif önerisi yok.',
                            style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredRecs.length,
                      itemBuilder: (context, idx) {
                        final rec = filteredRecs[idx];
                        final category = rec['category'] ?? 'recipe';
                        final title = rec['title'] ?? 'Nefis Yemek Tarifi';
                        final desc = rec['description'] ?? '';
                        final icon = rec['icon'] ?? '🍳';
                        final suggestedItem = rec['suggested_item']?.toString().trim() ?? '';
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
                              // Header
                              Row(
                                children: [
                                  Text(icon, style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: AppTypography.headlineMd.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getCategoryLabel(category),
                                      style: AppTypography.labelSm.copyWith(
                                        color: catColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Description
                              Text(
                                desc,
                                style: AppTypography.bodyMd.copyWith(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),

                              // Add missing item button if suggested_item exists
                              if (suggestedItem.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 36,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (widget.onAddSuggestedItem != null) {
                                        widget.onAddSuggestedItem!(suggestedItem);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '"$suggestedItem" alışveriş listenize eklendi!',
                                            ),
                                            backgroundColor: AppColors.primary,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '🛒 "$suggestedItem" Alışveriş Listesine Ekle',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: catColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
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
