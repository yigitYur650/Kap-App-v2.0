import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/inventory_item.dart';
import '../../../../core/models/stock_status.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/repositories/inventory_repository.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../data/supabase_inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabaseInventoryRepository(supabaseClient);
});

class InventoryController extends AsyncNotifier<List<InventoryItem>> {
  StreamSubscription<List<InventoryItem>>? _subscription;

  @override
  FutureOr<List<InventoryItem>> build() async {
    final activeGroup = ref.watch(activeGroupProvider);
    if (activeGroup == null) {
      return const [];
    }

    final repository = ref.watch(inventoryRepositoryProvider);
    final completer = Completer<List<InventoryItem>>();

    _subscription?.cancel();
    _subscription = repository.getInventoryStream(groupId: activeGroup.id).listen(
      (items) {
        state = AsyncData(items);
        if (!completer.isCompleted) {
          completer.complete(items);
        }
      },
      onError: (err, stack) {
        state = AsyncError(err, stack);
        if (!completer.isCompleted) {
          completer.completeError(err, stack);
        }
      },
    );

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return completer.future;
  }

  /// Adds a new inventory item.
  Future<void> addInventoryItem({
    required String itemName,
    StockStatus status = StockStatus.inStock,
  }) async {
    final activeGroup = ref.read(activeGroupProvider);
    if (activeGroup == null) return;

    final repository = ref.read(inventoryRepositoryProvider);
    final result = await repository.addInventoryItem(
      groupId: activeGroup.id,
      itemName: itemName,
      status: status,
    );

    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (_) {},
    );
  }

  /// Updates the stock status of an inventory item.
  Future<void> updateStockStatus({
    required String itemId,
    required StockStatus status,
  }) async {
    final repository = ref.read(inventoryRepositoryProvider);
    final result = await repository.updateStockStatus(
      itemId: itemId,
      status: status,
    );

    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (_) {},
    );
  }

  /// Deletes (soft-deletes) an inventory item.
  Future<void> deleteInventoryItem({
    required String itemId,
  }) async {
    final repository = ref.read(inventoryRepositoryProvider);
    final result = await repository.deleteInventoryItem(
      itemId: itemId,
    );

    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (_) {},
    );
  }
}

final inventoryControllerProvider =
    AsyncNotifierProvider<InventoryController, List<InventoryItem>>(() {
  return InventoryController();
});
