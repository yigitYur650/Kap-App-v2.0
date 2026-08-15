import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

import '../../../../shared/utils/category_helper.dart';

class CategoryTabsBar extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final Map<String, int> categoryCounts;

  List<String> get categories => CategoryHelper.categories;

  const CategoryTabsBar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.categoryCounts = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          final count = categoryCounts[category] ?? 0;

          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category,
                  style: AppTypography.bodyMd.copyWith(
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (count > 0 && category != 'Tümü') ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            selected: isSelected,
            onSelected: (_) => onCategorySelected(category),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border.withValues(alpha: 0.3),
              ),
            ),
          );
        },
      ),
    );
  }
}
