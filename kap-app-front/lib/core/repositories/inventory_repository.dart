import 'package:fpdart/fpdart.dart';
import '../errors/failure.dart';
import '../models/inventory_item.dart';
import '../models/stock_status.dart';

abstract class InventoryRepository {
  /// Emits realtime updates of the inventory items for a group.
  Stream<List<InventoryItem>> getInventoryStream(String groupId);

  /// Adds a new inventory item to the group.
  Future<Either<Failure, InventoryItem>> addInventoryItem(String groupId, String itemName);

  /// Updates the stock status of an item.
  Future<Either<Failure, bool>> updateStockStatus(String itemId, StockStatus status);

  /// Soft deletes an inventory item.
  Future<Either<Failure, bool>> deleteInventoryItem(String itemId);
}
