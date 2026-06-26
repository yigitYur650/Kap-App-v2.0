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
  });

  /// Updates status of a shopping request ('pending', 'done').
  Future<Either<Failure, void>> updateRequestStatus({
    required String requestId,
    required String status,
  });

  /// Deletes (soft-deletes) a shopping request.
  Future<Either<Failure, void>> deleteRequest({
    required String requestId,
  });
}
