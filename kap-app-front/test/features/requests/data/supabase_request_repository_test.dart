import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kap_app_front/core/models/request_model.dart';
import 'package:kap_app_front/features/requests/data/supabase_request_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}

class FakePostgrestTransformBuilder<T> extends Fake implements PostgrestTransformBuilder<T> {
  final T? value;
  final Object? error;

  FakePostgrestTransformBuilder(this.value, {this.error});

  @override
  PostgrestTransformBuilder<PostgrestList> select([String columns = '*']) {
    final err = error;
    if (err != null) {
      return FakePostgrestTransformBuilder<PostgrestList>(null, error: err);
    }
    final val = value;
    if (val is List) {
      return FakePostgrestTransformBuilder<PostgrestList>(List<Map<String, dynamic>>.from(val));
    }
    if (val is Map) {
      return FakePostgrestTransformBuilder<PostgrestList>([Map<String, dynamic>.from(val)]);
    }
    return FakePostgrestTransformBuilder<PostgrestList>([]);
  }

  @override
  PostgrestTransformBuilder<PostgrestMap> single() {
    final err = error;
    if (err != null) {
      return FakePostgrestTransformBuilder<PostgrestMap>(null, error: err);
    }
    final val = value;
    if (val is List && val.isNotEmpty) {
      return FakePostgrestTransformBuilder<PostgrestMap>(val.first as PostgrestMap);
    }
    if (val is Map) {
      return FakePostgrestTransformBuilder<PostgrestMap>(val as PostgrestMap);
    }
    throw StateError('Cannot call single on value: $val');
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    final err = error;
    if (err != null) {
      if (onError != null) {
        return Future<T>.error(err).then(onValue, onError: onError);
      }
      return Future<T>.error(err).then(onValue);
    }
    return Future.value(value as T).then(onValue, onError: onError);
  }
}

class FakePostgrestFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final T? value;
  final Object? error;

  FakePostgrestFilterBuilder(this.value, {this.error});

  @override
  PostgrestTransformBuilder<PostgrestList> select([String columns = '*']) {
    final err = error;
    if (err != null) {
      return FakePostgrestTransformBuilder<PostgrestList>(null, error: err);
    }
    final val = value;
    if (val is List) {
      return FakePostgrestTransformBuilder<PostgrestList>(List<Map<String, dynamic>>.from(val));
    }
    if (val is Map) {
      return FakePostgrestTransformBuilder<PostgrestList>([Map<String, dynamic>.from(val)]);
    }
    return FakePostgrestTransformBuilder<PostgrestList>([]);
  }

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<T> isFilter(String column, bool? value) => this;

  @override
  PostgrestTransformBuilder<PostgrestMap> single() {
    final err = error;
    if (err != null) {
      return FakePostgrestTransformBuilder<PostgrestMap>(null, error: err);
    }
    final val = value;
    if (val is List && val.isNotEmpty) {
      return FakePostgrestTransformBuilder<PostgrestMap>(val.first as PostgrestMap);
    }
    if (val is Map) {
      return FakePostgrestTransformBuilder<PostgrestMap>(val as PostgrestMap);
    }
    throw StateError('Cannot call single on value: $val');
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    final err = error;
    if (err != null) {
      if (onError != null) {
        return Future<T>.error(err).then(onValue, onError: onError);
      }
      return Future<T>.error(err).then(onValue);
    }
    return Future.value(value as T).then(onValue, onError: onError);
  }
}

class FakeSupabaseStreamBuilder extends Fake implements SupabaseStreamBuilder {
  final Stream<List<Map<String, dynamic>>> _stream;

  FakeSupabaseStreamBuilder(this._stream);

  @override
  Stream<R> map<R>(R Function(List<Map<String, dynamic>> event) convert) {
    return _stream.map(convert);
  }

  @override
  StreamSubscription<List<Map<String, dynamic>>> listen(
    void Function(List<Map<String, dynamic>> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

class FakeSupabaseStreamFilterBuilder extends Fake implements SupabaseStreamFilterBuilder {
  final FakeSupabaseStreamBuilder _streamBuilder;

  FakeSupabaseStreamFilterBuilder(this._streamBuilder);

  @override
  SupabaseStreamBuilder eq(String column, Object value) => _streamBuilder;
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final FakePostgrestFilterBuilder<dynamic> filterBuilder;
  final FakeSupabaseStreamFilterBuilder? streamFilterBuilder;

  FakeSupabaseQueryBuilder(this.filterBuilder, {this.streamFilterBuilder});

  @override
  PostgrestFilterBuilder<dynamic> insert(Object values, {bool defaultToNull = false}) => filterBuilder;

  @override
  PostgrestFilterBuilder<dynamic> update(Object values, {bool defaultToNull = false}) => filterBuilder;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    return filterBuilder as FakePostgrestFilterBuilder<PostgrestList>;
  }

  @override
  SupabaseStreamFilterBuilder stream({required List<String> primaryKey, bool private = false}) {
    final sfb = streamFilterBuilder;
    if (sfb == null) {
      throw UnimplementedError('streamFilterBuilder is not configured in this test');
    }
    return sfb;
  }
}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockUser mockUser;
  late SupabaseRequestRepository repository;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockUser = MockUser();

    repository = SupabaseRequestRepository(mockSupabaseClient);

    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
  });

  const tGroupId = 'group-uuid-123';
  const tUserId = 'user-uuid-456';
  const tRequestId = 'request-uuid-789';
  const tItemName = '  Fresh Milk  ';
  const tNormalizedItemName = 'fresh milk';

  final tRequestData = {
    'id': tRequestId,
    'group_id': tGroupId,
    'requested_by': tUserId,
    'item_name': tNormalizedItemName,
    'is_private': false,
    'private_to': null,
    'status': 'pending',
    'created_at': '2026-06-26T01:30:00.000Z',
    'deleted_at': null,
  };

  group('getRequests', () {
    test('should return Right(List<RequestModel>) when query succeeds', () async {
      // Arrange
      when(() => mockSupabaseClient.from('requests')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([tRequestData]),
        ),
      );

      // Act
      final result = await repository.getRequests(groupId: tGroupId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return Left'),
        (list) {
          expect(list.length, 1);
          expect(list.first.id, tRequestId);
          expect(list.first.itemName, tNormalizedItemName);
        },
      );
    });
  });

  group('createRequest', () {
    test('should return Right(RequestModel) and normalize item name when insert succeeds', () async {
      // Arrange
      when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn(tUserId);

      when(() => mockSupabaseClient.from('requests')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          FakePostgrestFilterBuilder<Map<String, dynamic>>(tRequestData),
        ),
      );

      // Act
      final result = await repository.createRequest(
        groupId: tGroupId,
        itemName: tItemName,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return Left'),
        (request) {
          expect(request.id, tRequestId);
          expect(request.itemName, tNormalizedItemName); // lowercase and trimmed
        },
      );
    });
  });

  group('updateRequestStatus', () {
    test('should return Right(void) when status update succeeds', () async {
      // Arrange
      when(() => mockSupabaseClient.from('requests')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([]),
        ),
      );

      // Act
      final result = await repository.updateRequestStatus(
        requestId: tRequestId,
        status: 'done',
      );

      // Assert
      expect(result.isRight(), true);
    });
  });

  group('deleteRequest', () {
    test('should return Right(void) and update deleted_at when soft delete succeeds', () async {
      // Arrange
      when(() => mockSupabaseClient.from('requests')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([]),
        ),
      );

      // Act
      final result = await repository.deleteRequest(requestId: tRequestId);

      // Assert
      expect(result.isRight(), true);
    });
  });

  group('getRequestsStream', () {
    test('should emit mapped lists of RequestModel when database events occur', () async {
      // Arrange
      final controller = StreamController<List<Map<String, dynamic>>>();
      final fakeStreamBuilder = FakeSupabaseStreamBuilder(controller.stream);
      final fakeStreamFilterBuilder = FakeSupabaseStreamFilterBuilder(fakeStreamBuilder);

      when(() => mockSupabaseClient.from('requests')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([]),
          streamFilterBuilder: fakeStreamFilterBuilder,
        ),
      );

      // Act
      final stream = repository.getRequestsStream(groupId: tGroupId);

      // Assert
      expect(
        stream,
        emitsInOrder([
          [isA<RequestModel>().having((r) => r.id, 'id', tRequestId)],
        ]),
      );

      controller.add([tRequestData]);
      await controller.close();
    });
  });
}
