import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/request_model.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../providers/request_repository_provider.dart';

/// Notifier that manages the active group's shopping list requests state using Realtime streams.
class RequestController extends AsyncNotifier<List<RequestModel>> {
  StreamSubscription<List<RequestModel>>? _subscription;

  @override
  FutureOr<List<RequestModel>> build() async {
    final activeGroup = ref.watch(activeGroupProvider);
    if (activeGroup == null) {
      return const [];
    }

    final repository = ref.watch(requestRepositoryProvider);
    final completer = Completer<List<RequestModel>>();

    _subscription?.cancel();
    _subscription = repository.getRequestsStream(groupId: activeGroup.id).listen(
      (requests) {
        state = AsyncData(requests);
        if (!completer.isCompleted) {
          completer.complete(requests);
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

  /// Creates a new shopping request.
  Future<void> createRequest({
    required String itemName,
    bool isPrivate = false,
    String? privateTo,
  }) async {
    final activeGroup = ref.read(activeGroupProvider);
    if (activeGroup == null) return;

    final repository = ref.read(requestRepositoryProvider);
    final result = await repository.createRequest(
      groupId: activeGroup.id,
      itemName: itemName,
      isPrivate: isPrivate,
      privateTo: privateTo,
    );

    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (_) {},
    );
  }

  /// Updates the status of a shopping request ('pending', 'done').
  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
  }) async {
    final repository = ref.read(requestRepositoryProvider);
    final result = await repository.updateRequestStatus(
      requestId: requestId,
      status: status,
    );

    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (_) {},
    );
  }

  /// Deletes (soft-deletes) a shopping request.
  Future<void> deleteRequest({
    required String requestId,
  }) async {
    final repository = ref.read(requestRepositoryProvider);
    final result = await repository.deleteRequest(
      requestId: requestId,
    );

    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (_) {},
    );
  }
}

/// Provider to access and watch the list of shopping requests for the active group.
final requestControllerProvider =
    AsyncNotifierProvider<RequestController, List<RequestModel>>(() {
  return RequestController();
});
