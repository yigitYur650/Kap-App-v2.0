import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kap_app_front/features/groups/presentation/providers/active_group_provider.dart';
import 'package:kap_app_front/features/requests/presentation/providers/request_controller.dart';
import 'package:kap_app_front/features/requests/presentation/widgets/add_request_bottom_sheet.dart';
import 'package:kap_app_front/features/requests/presentation/widgets/ai_price_estimator_bar.dart';
import 'package:kap_app_front/features/requests/presentation/widgets/category_tabs_bar.dart';
import 'package:kap_app_front/features/requests/presentation/widgets/receipt_scanner_dialog.dart';
import 'package:kap_app_front/features/requests/presentation/widgets/request_card.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';
import 'package:kap_app_front/shared/theme/app_colors.dart';
import 'package:kap_app_front/shared/theme/app_typography.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  String _selectedCategory = 'Tümü';
  bool _isEstimatingPrices = false;
  double? _estimatedTotal;

  void _showAddRequestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddRequestBottomSheet(),
    );
  }

  void _showReceiptScanner(BuildContext context, List<String> items) {
    showDialog(
      context: context,
      builder: (context) => ReceiptScannerDialog(currentItems: items),
    );
  }

  Future<void> _calculateAIEstimatedPrices(List<Map<String, String>> itemSpecs) async {
    if (itemSpecs.isEmpty) return;

    setState(() {
      _isEstimatingPrices = true;
    });

    try {
      const backendUrl = String.fromEnvironment(
        'GO_BACKEND_URL',
        defaultValue: String.fromEnvironment(
          'BACKEND_URL',
          defaultValue: 'http://localhost:8080',
        ),
      );

      final jwtToken = Supabase.instance.client.auth.currentSession?.accessToken;

      final response = await http.post(
        Uri.parse('$backendUrl/api/v1/ai/estimate-prices'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'items': itemSpecs,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final total = (data['total_price'] as num?)?.toDouble();
        setState(() {
          _estimatedTotal = total;
        });

        if (mounted) {
          _showAIResultPopup(data);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI fiyat tahmini şu an alınamadı.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEstimatingPrices = false);
      }
    }
  }

  void _showAIResultPopup(Map<String, dynamic> data) {
    final items = (data['items'] as List<dynamic>?) ?? [];
    final total = data['total_price'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                        const Icon(Icons.auto_awesome, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('AI Tahmini Fiyat Raporu', style: AppTypography.headlineLg),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                        '~${total.toStringAsFixed(2)} TL',
                        style: AppTypography.headlineMd.copyWith(color: Colors.teal, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, idx) {
                      final item = items[idx];
                      final brand = item['brand'] as String?;
                      final sourceMarket = item['source_market'] as String?;
                      final unitSpec = item['unit_spec'] as String?;
                      final variantNote = item['variant_note'] as String?;
                      final variants = item['variants'] as List<dynamic>? ?? [];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['item_name'] ?? '',
                                    style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  '~${item['estimated_price']} TL',
                                  style: AppTypography.headlineMd.copyWith(
                                    color: Colors.teal,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if ((brand != null && brand.isNotEmpty) || (sourceMarket != null && sourceMarket.isNotEmpty)) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (brand != null && brand.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '🏷️ $brand',
                                        style: AppTypography.labelSm.copyWith(color: Colors.blue, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  if (sourceMarket != null && sourceMarket.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '🛒 $sourceMarket',
                                        style: AppTypography.labelSm.copyWith(color: Colors.orange, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              'Kategori: ${item['category'] ?? 'Genel'}',
                              style: AppTypography.labelSm.copyWith(color: AppColors.textMuted),
                            ),
                            if (unitSpec != null && unitSpec.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Paket: $unitSpec',
                                      style: AppTypography.labelSm.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (variantNote != null && variantNote.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.lightbulb_outline, size: 14, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      variantNote,
                                      style: AppTypography.labelSm.copyWith(
                                        color: Colors.amber,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (variants.isNotEmpty) ...[
                              const Divider(height: 14),
                              Text(
                                'Popüler Miktar & Fiyat Seçenekleri:',
                                style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              ...variants.map((v) {
                                final size = v['size'] ?? '';
                                final vPrice = v['price'] ?? 0;
                                final store = v['store'] ?? '';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text('• $size', style: AppTypography.bodyMd.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis),
                                      ),
                                      Text(
                                        '$vPrice TL ${store.toString().isNotEmpty ? "($store)" : ""}',
                                        style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.bold, color: Colors.tealAccent),
                                      ),
                                    ],
                                  ),
                                );
                              }),
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
      },
  );
}

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    final requestsAsync = ref.watch(requestControllerProvider);
    final localizations = AppLocalizations.of(context)!;
    final bottomNavHeight = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          activeGroup != null
              ? '${activeGroup.name} - ${localizations.nav_tab_list}'
              : localizations.shopping_list_title,
          style: AppTypography.headlineLg,
        ),
      ),
      body: activeGroup == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: AppColors.secondary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.shopping_list_no_active_group,
                      style: AppTypography.bodyLg.copyWith(
                        color: AppColors.secondary.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : requestsAsync.when(
              data: (items) {
                final categoryCounts = <String, int>{};
                for (var i in items) {
                  final cat = i.category ?? 'Genel';
                  categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
                }

                final filteredItems = _selectedCategory == 'Tümü'
                    ? items
                    : items.where((i) => (i.category ?? 'Genel') == _selectedCategory).toList();

                final pendingItems = filteredItems.where((i) => i.status == 'pending').toList();
                final completedItems = filteredItems.where((i) => i.status == 'done').toList();

                return Column(
                  children: [
                    // Category Tabs
                    CategoryTabsBar(
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
                      categoryCounts: categoryCounts,
                    ),

                    // AI Price Estimator Bar
                    AIPriceEstimatorBar(
                      isLoading: _isEstimatingPrices,
                      estimatedTotal: _estimatedTotal,
                      onEstimatePressed: () {
                        final itemSpecs = pendingItems.map((e) => {
                          'item_name': e.itemName,
                          'quantity': e.quantity ?? '',
                          'unit': e.unit ?? '',
                        }).toList();
                        _calculateAIEstimatedPrices(itemSpecs);
                      },
                      onScanReceiptPressed: () {
                        final pendingNames = pendingItems.map((e) => e.itemName).toList();
                        _showReceiptScanner(context, pendingNames);
                      },
                    ),

                    Expanded(
                      child: items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.playlist_add_check,
                                    size: 64,
                                    color: AppColors.secondary.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    localizations.shopping_list_no_items,
                                    style: AppTypography.bodyLg.copyWith(
                                      color: AppColors.secondary.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              children: [
                                // Pending list
                                if (pendingItems.isNotEmpty) ...[
                                  Text(
                                    localizations.shopping_list_active_section,
                                    style: AppTypography.labelLg.copyWith(
                                      color: AppColors.secondary,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...pendingItems.map((item) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: RequestCard(request: item),
                                      )),
                                  const SizedBox(height: 24),
                                ],

                                // Completed list
                                if (completedItems.isNotEmpty) ...[
                                  Text(
                                    localizations.shopping_list_completed_section,
                                    style: AppTypography.labelLg.copyWith(
                                      color: AppColors.secondary,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...completedItems.map((item) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: RequestCard(request: item),
                                      )),
                                ],

                                SizedBox(height: bottomNavHeight + 80),
                              ],
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Text('${localizations.errorGeneric}: $err'),
              ),
            ),
      floatingActionButton: activeGroup != null
          ? Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16.0),
              child: FloatingActionButton(
                onPressed: () => _showAddRequestSheet(context),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                elevation: 6,
                child: const Icon(Icons.add, size: 28),
              ),
            )
          : null,
    );
  }
}

