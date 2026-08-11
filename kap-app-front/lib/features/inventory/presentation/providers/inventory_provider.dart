import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kap_app_front/features/groups/presentation/providers/active_group_provider.dart';
import 'package:kap_app_front/features/inventory/data/inventory_repository.dart';
import 'package:kap_app_front/features/inventory/domain/models/inventory_item_model.dart';

class InventoryState {
  final bool isLoading;
  final List<InventoryItem> items;
  final String statusFilter; // 'Tümü', 'var', 'azaldı', 'yok'
  final String categoryFilter; // 'Tümü', 'Süt & Kahvaltılık', etc.
  final String searchQuery;

  const InventoryState({
    this.isLoading = false,
    this.items = const [],
    this.statusFilter = 'Tümü',
    this.categoryFilter = 'Tümü',
    this.searchQuery = '',
  });

  InventoryState copyWith({
    bool? isLoading,
    List<InventoryItem>? items,
    String? statusFilter,
    String? categoryFilter,
    String? searchQuery,
  }) {
    return InventoryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      statusFilter: statusFilter ?? this.statusFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<InventoryItem> get filteredItems {
    return items.where((item) {
      // Search filter
      if (searchQuery.isNotEmpty &&
          !item.itemName.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      // Status filter
      if (statusFilter != 'Tümü' && item.status != statusFilter) {
        return false;
      }
      // Category filter
      if (categoryFilter != 'Tümü' && item.category != categoryFilter) {
        return false;
      }
      return true;
    }).toList();
  }
}

final inventoryNotifierProvider =
    NotifierProvider<InventoryNotifier, InventoryState>(InventoryNotifier.new);

class InventoryNotifier extends Notifier<InventoryState> {
  late InventoryRepository _repository;
  String? _groupId;

  @override
  InventoryState build() {
    _repository = ref.watch(inventoryRepositoryProvider);
    final activeGroup = ref.watch(activeGroupProvider);
    _groupId = activeGroup?.id;

    if (_groupId != null && _groupId!.isNotEmpty) {
      scheduleMicrotask(() => loadInventory());
    }

    return const InventoryState();
  }

  Future<void> loadInventory() async {
    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) return;
    state = state.copyWith(isLoading: true);

    final localItems = await _repository.getFromLocalCache(groupId);
    if (localItems.isNotEmpty) {
      state = state.copyWith(items: localItems, isLoading: false);
    }

    final freshItems = await _repository.getInventoryItems(groupId);
    state = state.copyWith(items: freshItems, isLoading: false);
  }

  void setStatusFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
  }

  void setCategoryFilter(String filter) {
    state = state.copyWith(categoryFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> addItem({
    required String itemName,
    required String status,
    required String category,
  }) async {
    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) return;

    final newItem = await _repository.addInventoryItem(
      groupId: groupId,
      itemName: itemName,
      status: status,
      category: category,
    );

    final updated = [newItem, ...state.items];
    state = state.copyWith(items: updated);
  }

  Future<void> updateStatus(String itemId, String newStatus) async {
    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) return;

    final updatedList = state.items.map((InventoryItem item) {
      if (item.id == itemId) {
        return item.copyWith(status: newStatus, lastUpdatedAt: DateTime.now());
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedList);
    await _repository.updateItemStatus(groupId, itemId, newStatus);
  }

  Future<void> removeItem(String itemId) async {
    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) return;

    final updatedList = state.items.where((InventoryItem i) => i.id != itemId).toList();
    state = state.copyWith(items: updatedList);
    await _repository.deleteInventoryItem(groupId, itemId);
  }
}
