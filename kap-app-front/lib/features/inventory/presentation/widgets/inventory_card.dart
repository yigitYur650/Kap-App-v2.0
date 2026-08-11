import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../domain/models/inventory_item_model.dart';

class InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final Function(String newStatus) onStatusChanged;
  final VoidCallback onAddToList;
  final VoidCallback onDelete;

  const InventoryCard({
    super.key,
    required this.item,
    required this.onStatusChanged,
    required this.onAddToList,
    required this.onDelete,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'var':
        return const Color(0xFF4CAF50); // Green
      case 'azaldı':
        return const Color(0xFFFF9800); // Amber/Orange
      case 'yok':
        return const Color(0xFFF44336); // Red
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Item Name, Category Badge, Delete Action
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: AppTypography.headlineMd.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Segmented Status Selector Buttons: [Var] [Azaldı] [Yok]
          Row(
            children: [
              Expanded(
                child: _buildStatusBtn(
                  statusKey: 'var',
                  label: '🟢 Var',
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatusBtn(
                  statusKey: 'azaldı',
                  label: '🟡 Azaldı',
                  color: const Color(0xFFFF9800),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatusBtn(
                  statusKey: 'yok',
                  label: '🔴 Yok',
                  color: const Color(0xFFF44336),
                ),
              ),
            ],
          ),

          // Add to Shopping List Action (Visible when 'azaldı' or 'yok')
          if (item.status == 'azaldı' || item.status == 'yok') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: onAddToList,
                icon: const Icon(Icons.add_shopping_cart, size: 16),
                label: Text(
                  '🛒 "${item.itemName}" Listeye Ekle',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
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
  }

  Widget _buildStatusBtn({
    required String statusKey,
    required String label,
    required Color color,
  }) {
    final isSelected = item.status == statusKey;

    return InkWell(
      onTap: () => onStatusChanged(statusKey),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF333333),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
