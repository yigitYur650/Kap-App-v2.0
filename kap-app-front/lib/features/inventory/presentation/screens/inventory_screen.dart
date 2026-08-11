import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kap_app_front/features/requests/presentation/providers/request_controller.dart';
import 'package:kap_app_front/shared/theme/app_colors.dart';
import 'package:kap_app_front/shared/theme/app_typography.dart';
import 'package:kap_app_front/shared/utils/category_helper.dart';
import '../../domain/models/inventory_item_model.dart';
import '../providers/inventory_provider.dart';
import '../widgets/add_inventory_item_sheet.dart';
import '../widgets/inventory_card.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddInventoryItemSheet(
        onAddItem: ({required itemName, required status, required category}) {
          ref.read(inventoryNotifierProvider.notifier).addItem(
                itemName: itemName,
                status: status,
                category: category,
              );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$itemName" envantere eklendi!'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryNotifierProvider);
    final notifier = ref.read(inventoryNotifierProvider.notifier);

    // Calculate Summary Stats
    final totalCount = state.items.length;
    final inStockCount = state.items.where((InventoryItem i) => i.status == 'var').length;
    final lowStockCount = state.items.where((InventoryItem i) => i.status == 'azaldı').length;
    final outOfStockCount = state.items.where((InventoryItem i) => i.status == 'yok').length;

    final filteredList = state.filteredItems;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.inventory_2,
                              color: AppColors.primary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Evde Ne Var?',
                                style: AppTypography.headlineLg.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Evdeki stokları ve malzeme durumunu takip edin',
                                style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.primary),
                        onPressed: () => notifier.loadInventory(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stock Summary Stats Cards (Total, In Stock, Low Stock, Out)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          label: 'Toplam',
                          count: totalCount,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          label: '🟢 Var',
                          count: inStockCount,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          label: '🟡 Azaldı',
                          count: lowStockCount,
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          label: '🔴 Yok',
                          count: outOfStockCount,
                          color: const Color(0xFFF44336),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => notifier.setSearchQuery(val),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Envanterde ara...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                notifier.setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status Filter Chips Row (Tümü, Var, Azaldı, Yok)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Tümü ($totalCount)',
                          statusKey: 'Tümü',
                          current: state.statusFilter,
                          onTap: () => notifier.setStatusFilter('Tümü'),
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: '🟢 Var ($inStockCount)',
                          statusKey: 'var',
                          current: state.statusFilter,
                          onTap: () => notifier.setStatusFilter('var'),
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: '🟡 Azaldı ($lowStockCount)',
                          statusKey: 'azaldı',
                          current: state.statusFilter,
                          onTap: () => notifier.setStatusFilter('azaldı'),
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: '🔴 Yok ($outOfStockCount)',
                          statusKey: 'yok',
                          current: state.statusFilter,
                          onTap: () => notifier.setStatusFilter('yok'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('Tümü', state.categoryFilter, notifier),
                        ...CategoryHelper.categories.map(
                          (cat) => _buildCategoryChip(cat, state.categoryFilter, notifier),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Inventory Items List
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 56,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                state.searchQuery.isNotEmpty
                                    ? 'Aramanıza uygun ürün bulunamadı.'
                                    : 'Evde henüz kayıtlı ürün bulunmuyor.',
                                style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _openAddItemSheet,
                                icon: const Icon(Icons.add),
                                label: const Text('İlk Ürünü Ekle'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                          itemCount: filteredList.length,
                          itemBuilder: (context, idx) {
                            final item = filteredList[idx];

                            return InventoryCard(
                              item: item,
                              onStatusChanged: (newStatus) {
                                notifier.updateStatus(item.id, newStatus);
                              },
                              onAddToList: () {
                                ref
                                    .read(requestControllerProvider.notifier)
                                    .createRequest(itemName: item.itemName);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('"${item.itemName}" alışveriş listesine eklendi!'),
                                    backgroundColor: AppColors.primary,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              onDelete: () {
                                notifier.removeItem(item.id);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.extended(
          onPressed: _openAddItemSheet,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Ürün Ekle',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String statusKey,
    required String current,
    required VoidCallback onTap,
  }) {
    final isSelected = current == statusKey;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textMuted,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildCategoryChip(
      String category, String currentCategory, InventoryNotifier notifier) {
    final isSelected = currentCategory == category;
    final icon = CategoryHelper.getCategoryIcon(category);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          '$icon $category',
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.surfaceVariant,
        backgroundColor: const Color(0xFF1E1E1E),
        onSelected: (_) => notifier.setCategoryFilter(category),
      ),
    );
  }
}
