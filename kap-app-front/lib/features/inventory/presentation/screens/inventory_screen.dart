import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kap_app_front/features/groups/presentation/providers/active_group_provider.dart';
import 'package:kap_app_front/features/health/data/health_profile_repository.dart';
import 'package:kap_app_front/shared/utils/fitness_calculator.dart';
import 'package:kap_app_front/features/requests/presentation/providers/request_controller.dart';
import 'package:kap_app_front/shared/theme/app_colors.dart';
import 'package:kap_app_front/shared/theme/app_typography.dart';
import 'package:kap_app_front/shared/utils/category_helper.dart';
import '../../domain/models/inventory_item_model.dart';
import '../providers/inventory_provider.dart';
import '../widgets/add_inventory_item_sheet.dart';
import '../widgets/inventory_card.dart';
import '../widgets/inventory_recipe_dialog.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingRecipes = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAIRecipes(List<InventoryItem> items) async {
    final availableItems = items.where((i) => i.status == 'var' || i.status == 'azaldı').toList();
    if (availableItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evde stokta ürün bulunmuyor. Ürün ekledikten sonra tarif önerileri alabilirsiniz.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoadingRecipes = true);
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final jwtToken = session?.accessToken ?? '';
      const backendUrl = String.fromEnvironment('BACKEND_URL', defaultValue: 'https://kap-app-backend.onrender.com');

      final healthProfile = await ref.read(healthProfileRepositoryProvider).getHealthProfile();
      final macros = FitnessCalculator.calculateAll(healthProfile);

      final itemSpecs = availableItems.map((i) => {'item_name': i.itemName}).toList();

      final payload = {
        'items': itemSpecs,
        'user_profile': {
          'weight': healthProfile.weight,
          'height': healthProfile.height,
          'age': healthProfile.age,
          'gender': healthProfile.gender,
          'activity_level': healthProfile.activityLevel,
          'goal': healthProfile.goal,
          'bmr': macros.bmr,
          'tdee': macros.tdee,
          'target_calories': macros.targetCalories,
          'protein_grams': macros.proteinGrams,
          'carb_grams': macros.carbGrams,
          'fat_grams': macros.fatGrams,
        },
      };

      final resp = await http.post(
        Uri.parse('$backendUrl/api/v1/ai/recommendations'),
        headers: {
          'Content-Type': 'application/json',
          if (jwtToken.isNotEmpty) 'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(payload),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final recs = (data['recommendations'] as List<dynamic>?) ?? [];
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => InventoryRecipeDialog(
              recommendations: recs,
              onAddSuggestedItem: (suggestedName) {
                ref.read(requestControllerProvider.notifier).createRequest(
                      itemName: suggestedName,
                    );
              },
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yapay zeka servisinden yanıt alınamadı. Lütfen tekrar deneyin.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tarif önerileri alınırken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingRecipes = false);
      }
    }
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
    final activeGroup = ref.watch(activeGroupProvider);
    final state = ref.watch(inventoryNotifierProvider);
    final notifier = ref.read(inventoryNotifierProvider.notifier);

    // Calculate Summary Stats
    final totalCount = state.items.length;
    final inStockCount = state.items.where((InventoryItem i) => i.status == 'var').length;
    final lowStockCount = state.items.where((InventoryItem i) => i.status == 'azaldı').length;
    final outOfStockCount = state.items.where((InventoryItem i) => i.status == 'yok').length;

    final filteredList = state.filteredItems;

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactPhone = screenWidth < 380;
    final isTabletOrWeb = screenWidth >= 600;
    final bottomNavHeight = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar Header & Filters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.inventory_2,
                                  color: AppColors.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        activeGroup != null
                                            ? '${activeGroup.name} - Envanter'
                                            : 'Evde Ne Var?',
                                        style: AppTypography.headlineLg.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Evdeki stok durumunu takip edin',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodyMd.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppColors.primary),
                          onPressed: () => notifier.loadInventory(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stock Summary Stats Cards (Responsive 2x2 for small screens, 4-in-row for wider screens)
                    if (isCompactPhone)
                      Column(
                        children: [
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
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
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
                        ],
                      )
                    else
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

                    // AI Recipe Generator Banner Button
                    InkWell(
                      onTap: _isLoadingRecipes ? null : () => _fetchAIRecipes(state.items),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              Colors.purple.shade700,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('🍳', style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Ne Pişirsem? (AI Tarif Önerisi)',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Evdeki stok ürünleriyle lezzetli tarifler üret',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            _isLoadingRecipes
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.amberAccent,
                                    size: 22,
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

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

                    // Status Filter Chips Row
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
            ),

            // Main Content: No active group, Loading, Empty State, or Responsive Items Grid/List
            if (activeGroup == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 64,
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aktif ev grubu seçilmedi',
                          style: AppTypography.headlineMd,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Envanteri takip etmek ve ürün eklemek için lütfen bir ev grubuna katılın veya yeni grup oluşturun.',
                          style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (state.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredList.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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
                          textAlign: TextAlign.center,
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
                  ),
                ),
              )
            else if (isTabletOrWeb)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, bottomNavHeight + 80),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, idx) {
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
                    childCount: filteredList.length,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, bottomNavHeight + 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, idx) {
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
                    childCount: filteredList.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: activeGroup == null
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: bottomNavHeight + 12),
              child: FloatingActionButton.extended(
                heroTag: 'inventory_fab',
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: AppTypography.labelSm.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
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
