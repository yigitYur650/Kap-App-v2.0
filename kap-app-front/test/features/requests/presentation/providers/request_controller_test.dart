import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kap_app_front/core/errors/failure.dart';
import 'package:kap_app_front/core/models/group_model.dart';
import 'package:kap_app_front/core/models/request_model.dart';
import 'package:kap_app_front/core/repositories/request_repository.dart';
import 'package:kap_app_front/features/groups/presentation/providers/active_group_provider.dart';
import 'package:kap_app_front/features/requests/providers/request_repository_provider.dart';
import 'package:kap_app_front/features/requests/presentation/providers/request_controller.dart';

class MockRequestRepository extends Mock implements RequestRepository {}

// ── Test fixtures ─────────────────────────────────────────────────────────────

final tGroup = GroupModel(
  id: 'group-1',
  name: 'Test Group',
  type: 'family',
  createdBy: 'user-1',
  createdAt: DateTime(2026, 6, 26),
);

RequestModel makeRequest({String id = 'req-1', String status = 'pending'}) {
  return RequestModel(
    id: id,
    groupId: 'group-1',
    requestedBy: 'user-1',
    itemName: 'milk',
    isPrivate: false,
    status: status,
    createdAt: DateTime(2026, 6, 26),
  );
}

// ── Fake ActiveGroup notifier ─────────────────────────────────────────────────

class FakeActiveGroup extends ActiveGroup {
  final GroupModel? _group;
  FakeActiveGroup(this._group);

  @override
  GroupModel? build() => _group;
}

// ── Container factory ─────────────────────────────────────────────────────────

ProviderContainer createContainer({
  required MockRequestRepository mockRepo,
  GroupModel? activeGroup,
}) {
  final container = ProviderContainer(
    overrides: [
      requestRepositoryProvider.overrideWithValue(mockRepo),
      activeGroupProvider.overrideWith(() => FakeActiveGroup(activeGroup)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockRequestRepository mockRepo;

  setUp(() {
    mockRepo = MockRequestRepository();
  });

  group('RequestController — build()', () {
    test('should return empty list when activeGroup is null and NOT subscribe', () async {
      // No stream setup — if subscribe is called, mock will throw.
      final container = createContainer(mockRepo: mockRepo, activeGroup: null);

      final state = await container.read(requestControllerProvider.future);
      expect(state, isEmpty);
      verifyNever(() => mockRepo.getRequestsStream(groupId: any(named: 'groupId')));
    });

    test('should subscribe to stream and emit first batch when activeGroup is set', () async {
      final streamController = StreamController<List<RequestModel>>();
      when(() => mockRepo.getRequestsStream(groupId: 'group-1'))
          .thenAnswer((_) => streamController.stream);

      final container = createContainer(mockRepo: mockRepo, activeGroup: tGroup);
      // Emit one batch before awaiting future
      streamController.add([makeRequest()]);
      final state = await container.read(requestControllerProvider.future);

      expect(state, hasLength(1));
      expect(state.first.id, 'req-1');

      await streamController.close();
    });

    test('should update state on subsequent stream events', () async {
      final streamController = StreamController<List<RequestModel>>();
      when(() => mockRepo.getRequestsStream(groupId: 'group-1'))
          .thenAnswer((_) => streamController.stream);

      final container = createContainer(mockRepo: mockRepo, activeGroup: tGroup);

      // First event
      streamController.add([makeRequest(id: 'req-1')]);
      await container.read(requestControllerProvider.future);

      // Second event
      streamController.add([makeRequest(id: 'req-1'), makeRequest(id: 'req-2')]);
      await Future.delayed(Duration.zero);

      final state = container.read(requestControllerProvider);
      expect(state.value, hasLength(2));

      await streamController.close();
    });

    test('should set AsyncError state when stream emits an error', () async {
      final streamController = StreamController<List<RequestModel>>();
      when(() => mockRepo.getRequestsStream(groupId: 'group-1'))
          .thenAnswer((_) => streamController.stream);

      final container = createContainer(mockRepo: mockRepo, activeGroup: tGroup);

      // First a valid event to resolve the future, then an error
      streamController.add([makeRequest()]);
      await container.read(requestControllerProvider.future);

      streamController.addError(Exception('stream broke'));
      await Future.delayed(Duration.zero);

      final state = container.read(requestControllerProvider);
      expect(state.hasError, true);

      await streamController.close();
    });
  });

  group('RequestController — createRequest()', () {
    test('should call repository.createRequest with correct arguments', () async {
      final streamController = StreamController<List<RequestModel>>();
      when(() => mockRepo.getRequestsStream(groupId: 'group-1'))
          .thenAnswer((_) => streamController.stream);
      when(() => mockRepo.createRequest(
            groupId: 'group-1',
            itemName: 'bread',
            isPrivate: false,
            privateTo: null,
          )).thenAnswer((_) async => Right(makeRequest(id: 'req-new')));

      final container = createContainer(mockRepo: mockRepo, activeGroup: tGroup);
      streamController.add([]);
      await container.read(requestControllerProvider.future);

      await container.read(requestControllerProvider.notifier).createRequest(itemName: 'bread');

      verify(() => mockRepo.createRequest(
            groupId: 'group-1',
            itemName: 'bread',
            isPrivate: false,
            privateTo: null,
          )).called(1);

      await streamController.close();
    });

    test(
        'should set state to AsyncError when repository.createRequest returns Left(Failure)', () async {
      final streamController = StreamController<List<RequestModel>>();
      when(() => mockRepo.getRequestsStream(groupId: 'group-1'))
          .thenAnswer((_) => streamController.stream);
      when(() => mockRepo.createRequest(
            groupId: any(named: 'groupId'),
            itemName: any(named: 'itemName'),
            isPrivate: any(named: 'isPrivate'),
            privateTo: any(named: 'privateTo'),
          )).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = createContainer(mockRepo: mockRepo, activeGroup: tGroup);
      streamController.add([]);
      await container.read(requestControllerProvider.future);

      await container
          .read(requestControllerProvider.notifier)
          .createRequest(itemName: 'bread');

      final controllerState = container.read(requestControllerProvider);
      expect(controllerState.hasError, true);
      expect(controllerState.error, isA<NetworkFailure>());

      await streamController.close();
    });

    test('should do nothing when activeGroup is null', () async {
      final container = createContainer(mockRepo: mockRepo, activeGroup: null);
      await container.read(requestControllerProvider.future);

      // Should complete without error and NOT call the repository
      await container
          .read(requestControllerProvider.notifier)
          .createRequest(itemName: 'bread');

      verifyNever(() => mockRepo.createRequest(
            groupId: any(named: 'groupId'),
            itemName: any(named: 'itemName'),
          ));
    });
  });

  group('RequestController — updateRequestStatus()', () {
    test('should call repository.updateRequestStatus with correct arguments', () async {
      final streamController = StreamController<List<RequestModel>>();
      when(() => mockRepo.getRequestsStream(groupId: 'group-1'))
          .thenAnswer((_) => streamController.stream);
      when(() => mockRepo.updateRequestStatus(
            requestId: 'req-1',
            status: 'done',
          )).thenAnswer((_) async => const Right(null));

      final container = createContainer(mockRepo: mockRepo, activeGroup: tGroup);
      streamController.add([makeRequest()]);
      await container.read(requestControllerProvider.future);

      await container.read(requestControllerProvider.notifier).updateRequestStatus(
            requestId: 'req-1',
            status: 'done',
          );

      verify(() => mockRepo.updateRequestStatus(
            requestId: 'req-1',
            status: 'done',
          )).called(1);

      await streamController.close();
    });
  });

  group('RequestController — deleteRequest()', () {
    test('should call repository.deleteRequest with correct requestId', () async {
      final streamController = StreamController<List<RequestModel>>();
      when(() => mockRepo.getRequestsStream(groupId: 'group-1'))
          .thenAnswer((_) => streamController.stream);
      when(() => mockRepo.deleteRequest(requestId: 'req-1'))
          .thenAnswer((_) async => const Right(null));

      final container = createContainer(mockRepo: mockRepo, activeGroup: tGroup);
      streamController.add([makeRequest()]);
      await container.read(requestControllerProvider.future);

      await container
          .read(requestControllerProvider.notifier)
          .deleteRequest(requestId: 'req-1');

      verify(() => mockRepo.deleteRequest(requestId: 'req-1')).called(1);

      await streamController.close();
    });
  });
}
