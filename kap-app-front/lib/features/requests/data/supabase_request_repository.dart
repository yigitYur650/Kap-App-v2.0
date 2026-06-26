import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/failure.dart';
import '../../../core/models/request_model.dart';
import '../../../core/repositories/request_repository.dart';

/// Implementation of [RequestRepository] using Supabase client.
///
/// **Realtime Performance Optimization Tradeoffs (HATA-12):**
/// - Supabase Realtime Stream builder (`from('requests').stream(...)`) only supports basic
///   column equality filters (e.g. `.eq()`) and does not natively support null check filters
///   like `.isFilter('deleted_at', null)` directly on the streaming socket edge.
/// - Therefore, filtering out soft-deleted requests must be performed client-side in-memory
///   using `.where((r) => r.deletedAt == null)`.
/// - Tradeoff: This approach fetches all records (including soft-deleted ones) over the websocket,
///   which increases network payload size. However, it guarantees immediate UI sync without complex
///   database function subscriptions.
class SupabaseRequestRepository implements RequestRepository {
  final SupabaseClient _supabaseClient;

  SupabaseRequestRepository(this._supabaseClient);

  @override
  Future<Either<Failure, List<RequestModel>>> getRequests({
    required String groupId,
  }) async {
    try {
      final response = await _supabaseClient
          .from('requests')
          .select()
          .eq('group_id', groupId)
          .isFilter('deleted_at', null);

      final list = (response as List)
          .map((json) => RequestModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(list);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Stream<List<RequestModel>> getRequestsStream({required String groupId}) {
    return _supabaseClient
        .from('requests')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .map((list) => list
            .map((json) => RequestModel.fromJson(json))
            .where((r) => r.deletedAt == null)
            .toList());
  }

  @override
  Future<Either<Failure, RequestModel>> createRequest({
    required String groupId,
    required String itemName,
    bool isPrivate = false,
    String? privateTo,
  }) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      return const Left(UnknownFailure('User is not authenticated'));
    }

    try {
      // Functional performance index matching: item name is trimmed and lowercase
      final normalizedItemName = itemName.toLowerCase().trim();

      final response = await _supabaseClient
          .from('requests')
          .insert({
            'group_id': groupId,
            'requested_by': currentUser.id,
            'item_name': normalizedItemName,
            'is_private': isPrivate,
            'private_to': isPrivate ? privateTo : null,
            'status': 'pending',
          })
          .select()
          .single();

      return Right(RequestModel.fromJson(response));
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateRequestStatus({
    required String requestId,
    required String status,
  }) async {
    try {
      await _supabaseClient
          .from('requests')
          .update({
            'status': status,
          })
          .eq('id', requestId);
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRequest({
    required String requestId,
  }) async {
    try {
      // Soft delete: update deleted_at instead of executing physical deletion
      await _supabaseClient
          .from('requests')
          .update({
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', requestId);
      return const Right(null);
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
