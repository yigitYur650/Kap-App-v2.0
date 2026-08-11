import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/utils/category_helper.dart';

class AddInventoryItemSheet extends StatefulWidget {
  final Function({
    required String itemName,
    required String status,
    required String category,
  }) onAddItem;

  const AddInventoryItemSheet({
    super.key,
    required this.onAddItem,
  });

  @override
  State<AddInventoryItemSheet> createState() => _AddInventoryItemSheetState();
}

class _AddInventoryItemSheetState extends State<AddInventoryItemSheet> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedStatus = 'var';
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = CategoryHelper.categories.first;
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final text = _nameController.text.trim();
    if (text.isNotEmpty) {
      final detected = CategoryHelper.detectCategory(text);
      if (detected != _selectedCategory) {
        setState(() {
          _selectedCategory = detected;
        });
      }
    }
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    widget.onAddItem(
      itemName: name,
      status: _selectedStatus,
      category: _selectedCategory,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isWeb ? 560 : screenWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        margin: EdgeInsets.all(isWeb ? 16 : 0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(24),
            bottom: Radius.circular(isWeb ? 24 : 0),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Ev Envanterine Ürün Ekle',
                      style: AppTypography.headlineLg.copyWith(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Item Name TextField
              TextField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ürün adı (Örn: Süt, Yumurta, Deterjan)...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  prefixIcon: const Icon(Icons.inventory, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 14),

              // Status Selector ChoiceChips
              Text(
                'Başlangıç Stok Durumu:',
                style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('🟢 Var'),
                      ),
                      selected: _selectedStatus == 'var',
                      selectedColor: Colors.green.withValues(alpha: 0.3),
                      onSelected: (_) => setState(() => _selectedStatus = 'var'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ChoiceChip(
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('🟡 Azaldı'),
                      ),
                      selected: _selectedStatus == 'azaldı',
                      selectedColor: Colors.orange.withValues(alpha: 0.3),
                      onSelected: (_) => setState(() => _selectedStatus = 'azaldı'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ChoiceChip(
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('🔴 Yok'),
                      ),
                      selected: _selectedStatus == 'yok',
                      selectedColor: Colors.red.withValues(alpha: 0.3),
                      onSelected: (_) => setState(() => _selectedStatus = 'yok'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Category Dropdown
              Text(
                'Kategori:',
                style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceVariant,
                    items: CategoryHelper.categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(
                          '${CategoryHelper.getCategoryIcon(cat)} $cat',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Envantere Ekle',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
