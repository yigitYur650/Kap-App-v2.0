import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/inventory_item_model.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository();
});

class InventoryRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _getCacheKey(String groupId) => 'kap_inventory_$groupId';

  /// Save inventory items to SharedPreferences for instant local fallback
  Future<void> _saveToLocalCache(String groupId, List<InventoryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(items.map((i) => i.toJson()).toList());
      await prefs.setString(_getCacheKey(groupId), encoded);
    } catch (_) {}
  }

  /// Read inventory items from SharedPreferences
  Future<List<InventoryItem>> getFromLocalCache(String groupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_getCacheKey(groupId));
      if (str != null && str.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(str);
        return decoded.map((map) => InventoryItem.fromJson(map as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Get inventory items for a group (remote + local fallback)
  Future<List<InventoryItem>> getInventoryItems(String groupId) async {
    List<InventoryItem> cached = await getFromLocalCache(groupId);

    try {
      final response = await _supabase
          .from('inventory')
          .select()
          .eq('group_id', groupId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      final remoteItems = (response as List)
          .map((json) => InventoryItem.fromJson(json as Map<String, dynamic>))
          .toList();

      await _saveToLocalCache(groupId, remoteItems);
      return remoteItems;
    } catch (e) {
      return cached;
    }
  }

  /// Add a new item to inventory
  Future<InventoryItem> addInventoryItem({
    required String groupId,
    required String itemName,
    required String status,
    required String category,
  }) async {
    final newItemMap = {
      'group_id': groupId,
      'item_name': itemName,
      'status': status,
      'category': category,
    };

    try {
      final response = await _supabase
          .from('inventory')
          .insert(newItemMap)
          .select()
          .single();

      final createdItem = InventoryItem.fromJson(response);
      
      // Update local cache
      final currentList = await getFromLocalCache(groupId);
      currentList.insert(0, createdItem);
      await _saveToLocalCache(groupId, currentList);

      return createdItem;
    } catch (e) {
      // Offline fallback item creation
      final fallbackItem = InventoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        groupId: groupId,
        itemName: itemName,
        status: status,
        category: category,
        createdAt: DateTime.now(),
      );

      final currentList = await getFromLocalCache(groupId);
      currentList.insert(0, fallbackItem);
      await _saveToLocalCache(groupId, currentList);

      return fallbackItem;
    }
  }

  /// Update item status ('var', 'azaldı', 'yok')
  Future<void> updateItemStatus(String groupId, String itemId, String newStatus) async {
    try {
      await _supabase.from('inventory').update({
        'status': newStatus,
        'last_updated_at': DateTime.now().toIso8601String(),
      }).eq('id', itemId);
    } catch (_) {}

    // Update local cache
    final currentList = await getFromLocalCache(groupId);
    final idx = currentList.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      currentList[idx] = currentList[idx].copyWith(
        status: newStatus,
        lastUpdatedAt: DateTime.now(),
      );
      await _saveToLocalCache(groupId, currentList);
    }
  }

  /// Delete item from inventory (soft delete)
  Future<void> deleteInventoryItem(String groupId, String itemId) async {
    try {
      await _supabase.from('inventory').update({
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', itemId);
    } catch (_) {}

    // Remove from local cache
    final currentList = await getFromLocalCache(groupId);
    currentList.removeWhere((i) => i.id == itemId);
    await _saveToLocalCache(groupId, currentList);
  }
}
