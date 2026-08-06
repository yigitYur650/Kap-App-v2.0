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

  Future<void> _calculateAIEstimatedPrices(List<String> itemNames) async {
    if (itemNames.isEmpty) return;

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
          'items': itemNames,
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('AI Tahmini Fiyat Raporu', style: AppTypography.headlineLg),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Tahmini Toplam: ~${total.toStringAsFixed(2)} TL',
                style: AppTypography.headlineMd.copyWith(color: Colors.teal, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    return ListTile(
                      title: Text(item['item_name'] ?? ''),
                      subtitle: Text('Kategori: ${item['category'] ?? 'Genel'}'),
                      trailing: Text(
                        '~${item['estimated_price']} TL',
                        style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
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
                        final pendingNames = pendingItems.map((e) => e.itemName).toList();
                        _calculateAIEstimatedPrices(pendingNames);
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

