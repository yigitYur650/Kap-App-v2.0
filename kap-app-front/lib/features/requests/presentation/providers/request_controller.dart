import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/models/request_model.dart';
import '../../../../core/services/notification_service.dart';
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
  Future<Either<Failure, void>> createRequest({
    required String itemName,
    bool isPrivate = false,
    String? privateTo,
    String? quantity,
    String? unit,
  }) async {
    final activeGroup = ref.read(activeGroupProvider);
    if (activeGroup == null) {
      return Left(ServerFailure('No active group selected.'));
    }

    final repository = ref.read(requestRepositoryProvider);
    final result = await repository.createRequest(
      groupId: activeGroup.id,
      itemName: itemName,
      isPrivate: isPrivate,
      privateTo: privateTo,
      quantity: quantity,
      unit: unit,
    );

    result.fold(
      (failure) {},
      (newRequest) {
        final currentList = state.value ?? [];
        state = AsyncData([newRequest, ...currentList.where((r) => r.id != newRequest.id)]);

        try {
          ref.read(notificationServiceProvider).showInstantNotification(
            title: '🛒 Yeni İhtiyaç Ekledi!',
            body: 'Gruba yeni \'$itemName\' isteği eklendi.',
          );
        } catch (_) {}
      },
    );

    return result;
  }

  /// Updates the status of a shopping request ('pending', 'done') with instant optimistic UI update.
  Future<Either<Failure, void>> updateRequestStatus({
    required String requestId,
    required String status,
  }) async {
    final activeGroup = ref.read(activeGroupProvider);
    if (activeGroup == null) {
      return Left(ServerFailure('No active group selected.'));
    }

    final previousList = state.value ?? [];

    // 1. Optimistic UI update (0ms instant UI feedback)
    state = AsyncData(
      previousList
          .map((r) => r.id == requestId ? r.copyWith(status: status) : r)
          .toList(),
    );

    // 2. Network write
    final repository = ref.read(requestRepositoryProvider);
    final result = await repository.updateRequestStatus(
      requestId: requestId,
      status: status,
      groupId: activeGroup.id,
    );

    // 3. Rollback on failure
    result.fold(
      (failure) {
        state = AsyncData(previousList);
      },
      (_) {},
    );

    return result;
  }

  /// Deletes (soft-deletes) a shopping request with instant optimistic UI update.
  Future<Either<Failure, void>> deleteRequest({
    required String requestId,
  }) async {
    final activeGroup = ref.read(activeGroupProvider);
    if (activeGroup == null) {
      return Left(ServerFailure('No active group selected.'));
    }

    final previousList = state.value ?? [];

    // 1. Optimistic UI update (0ms instant removal)
    state = AsyncData(previousList.where((r) => r.id != requestId).toList());

    // 2. Network write
    final repository = ref.read(requestRepositoryProvider);
    final result = await repository.deleteRequest(
      requestId: requestId,
      groupId: activeGroup.id,
    );

    // 3. Rollback on failure
    result.fold(
      (failure) {
        state = AsyncData(previousList);
      },
      (_) {},
    );

    return result;
  }
}

/// Provider to access and watch the list of shopping requests for the active group.
final requestControllerProvider =
    AsyncNotifierProvider<RequestController, List<RequestModel>>(() {
  return RequestController();
});
