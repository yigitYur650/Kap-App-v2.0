import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/failure.dart';
import '../../../core/models/inventory_item.dart';
import '../../../core/models/stock_status.dart';
import '../../../core/repositories/inventory_repository.dart';

class SupabaseInventoryRepository implements InventoryRepository {
  final SupabaseClient _supabaseClient;

  SupabaseInventoryRepository(this._supabaseClient);

  @override
  Stream<List<InventoryItem>> getInventoryStream(String groupId) {
    return _supabaseClient
        .from('inventory')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .map((list) => list
            .map((json) => InventoryItem.fromJson(json))
            .where((item) => item.deletedAt == null)
            .toList());
  }

  @override
  Future<Either<Failure, InventoryItem>> addInventoryItem(
    String groupId,
    String itemName,
  ) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      return const Left(UnknownFailure('User is not authenticated'));
    }

    try {
      final normalizedItemName = itemName.toLowerCase().trim();

      final response = await _supabaseClient
          .from('inventory')
          .insert({
            'group_id': groupId,
            'item_name': normalizedItemName,
            'status': StockStatus.inStock.toDbString(),
          })
          .select()
          .single();

      return Right(InventoryItem.fromJson(response));
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, bool>> updateStockStatus(
    String itemId,
    StockStatus status,
  ) async {
    try {
      await _supabaseClient
          .from('inventory')
          .update({
            'status': status.toDbString(),
          })
          .eq('id', itemId);
      return const Right(true);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteInventoryItem(String itemId) async {
    try {
      await _supabaseClient
          .from('inventory')
          .update({
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', itemId);
      return const Right(true);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  Failure _mapException(Object e) {
    if (e is PostgrestException) {
      if (e.code == '23505') {
        return UnknownFailure('Database unique constraint violation: ${e.message}');
      }
      return UnknownFailure('Database error: ${e.message}');
    }
    if (e is SocketException) {
      return const NetworkFailure();
    }
    final str = e.toString().toLowerCase();
    if (str.contains('socketexception') ||
        str.contains('network') ||
        str.contains('connection failed')) {
      return const NetworkFailure();
    }
    return UnknownFailure(e.toString());
  }
}
