import 'package:fpdart/fpdart.dart';
import '../errors/failure.dart';
import '../models/request_model.dart';

/// Repository handling shopping list requests operations.
abstract class RequestRepository {
  /// Fetches requests belonging to a specific group, filtering by RLS access in Database.
  Future<Either<Failure, List<RequestModel>>> getRequests({
    required String groupId,
  });

  /// Realtime stream that emits lists of shopping requests when data changes.
  Stream<List<RequestModel>> getRequestsStream({
    required String groupId,
  });

  /// Creates a new shopping request.
  Future<Either<Failure, RequestModel>> createRequest({
    required String groupId,
    required String itemName,
    bool isPrivate = false,
    String? privateTo,
    String? quantity,
    String? unit,
  });

  /// Updates status of a shopping request ('pending', 'done').
  /// Requires [groupId] to verify the request belongs to the current active group,
  /// providing defense-in-depth against cross-group mutations.
  Future<Either<Failure, void>> updateRequestStatus({
    required String requestId,
    required String status,
    required String groupId,
  });

  /// Deletes (soft-deletes) a shopping request.
  /// Requires [groupId] to verify the request belongs to the current active group,
  /// providing defense-in-depth against cross-group mutations.
  Future<Either<Failure, void>> deleteRequest({
    required String requestId,
    required String groupId,
  });
}
