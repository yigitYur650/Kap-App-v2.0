import 'package:fpdart/fpdart.dart';
import '../errors/failure.dart';
import '../models/inventory_item.dart';
import '../models/stock_status.dart';

abstract class InventoryRepository {
  /// Fetches active inventory items for a specific group.
  Future<Either<Failure, List<InventoryItem>>> getInventory({
    required String groupId,
  });

  /// Realtime stream that emits lists of inventory items when data changes.
  Stream<List<InventoryItem>> getInventoryStream({
    required String groupId,
  });

  /// Adds a new inventory item to a group.
  Future<Either<Failure, InventoryItem>> addInventoryItem({
    required String groupId,
    required String itemName,
    StockStatus status = StockStatus.inStock,
  });

  /// Updates the stock status of an inventory item.
  Future<Either<Failure, void>> updateStockStatus({
    required String itemId,
    required StockStatus status,
  });

  /// Soft deletes an inventory item.
  Future<Either<Failure, void>> deleteInventoryItem({
    required String itemId,
  });
}
