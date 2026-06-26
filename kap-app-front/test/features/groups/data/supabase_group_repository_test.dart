import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kap_app_front/core/errors/failure.dart';
import 'package:kap_app_front/features/groups/data/supabase_group_repository.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}

/// A Fake implementation of Supabase PostgrestTransformBuilder.
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
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    final err = error;
    if (err != null) {
      return FakePostgrestTransformBuilder<PostgrestMap?>(null, error: err);
    }
    final val = value;
    if (val is List && val.isNotEmpty) {
      return FakePostgrestTransformBuilder<PostgrestMap?>(val.first as PostgrestMap?);
    }
    if (val is Map) {
      return FakePostgrestTransformBuilder<PostgrestMap?>(val as PostgrestMap?);
    }
    return FakePostgrestTransformBuilder<PostgrestMap?>(null);
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

/// A Fake implementation of Supabase PostgrestFilterBuilder.
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
  PostgrestFilterBuilder<T> order(String column, {bool ascending = true, bool nullsFirst = false, String? referencedTable}) => this;

  @override
  PostgrestFilterBuilder<T> limit(int count, {String? referencedTable}) => this;

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
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    final err = error;
    if (err != null) {
      return FakePostgrestTransformBuilder<PostgrestMap?>(null, error: err);
    }
    final val = value;
    if (val is List && val.isNotEmpty) {
      return FakePostgrestTransformBuilder<PostgrestMap?>(val.first as PostgrestMap?);
    }
    if (val is Map) {
      return FakePostgrestTransformBuilder<PostgrestMap?>(val as PostgrestMap?);
    }
    return FakePostgrestTransformBuilder<PostgrestMap?>(null);
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

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final FakePostgrestFilterBuilder<dynamic> _filterBuilder;

  FakeSupabaseQueryBuilder(this._filterBuilder);

  @override
  PostgrestFilterBuilder<dynamic> insert(Object values, {bool defaultToNull = false}) => _filterBuilder;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    return _filterBuilder as FakePostgrestFilterBuilder<PostgrestList>;
  }

  @override
  PostgrestFilterBuilder<dynamic> delete({bool defaultToNull = false}) => _filterBuilder;
}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockUser mockUser;
  late SupabaseGroupRepository repository;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockUser = MockUser();

    repository = SupabaseGroupRepository(mockSupabaseClient);

    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
  });

  const tUserId = 'user-uuid-123';
  const tGroupId = 'group-uuid-456';
  const tGroupName = 'Test Group';
  const tGroupType = 'family';
  const tUniqueCode = 'KAP-12345678';
  const tOwnerId = 'owner-uuid-999';

  final tGroupData = {
    'id': tGroupId,
    'name': tGroupName,
    'type': tGroupType,
    'created_by': tUserId,
    'created_at': '2026-06-26T01:30:00.000Z',
  };

  group('createGroup', () {
    test('should return Right(GroupModel) when inserts succeed', () async {
      // Arrange
      when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn(tUserId);

      when(() => mockSupabaseClient.from('groups')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          FakePostgrestFilterBuilder<Map<String, dynamic>>(tGroupData),
        ),
      );
      when(() => mockSupabaseClient.from('group_members')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([]),
        ),
      );

      // Act
      final result = await repository.createGroup(name: tGroupName, type: tGroupType);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return Left'),
        (group) {
          expect(group.id, tGroupId);
          expect(group.name, tGroupName);
          expect(group.type, tGroupType);
          expect(group.createdBy, tUserId);
        },
      );
    });

    test('should delete group (rollback) and return Left(Failure) when members insert fails', () async {
      // Arrange
      when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn(tUserId);

      when(() => mockSupabaseClient.from('groups')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          FakePostgrestFilterBuilder<Map<String, dynamic>>(tGroupData),
        ),
      );
      when(() => mockSupabaseClient.from('group_members')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
            null,
            error: const PostgrestException(message: 'Failed to insert member', code: '400'),
          ),
        ),
      );

      // Act
      final result = await repository.createGroup(name: tGroupName, type: tGroupType);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(failure.message, contains('Failed to insert member'));
        },
        (_) => fail('Should not return Right'),
      );
    });
  });

  group('joinGroup', () {
    test('should return Right(void) when user lookup, group lookup, and member insert succeed', () async {
      // Arrange
      when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn(tUserId);

      when(() => mockSupabaseClient.from('public_user_lookup')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
            [
              {'id': tOwnerId}
            ],
          ),
        ),
      );
      when(() => mockSupabaseClient.from('groups')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
            [
              {'id': tGroupId}
            ],
          ),
        ),
      );
      when(() => mockSupabaseClient.from('group_members')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([]),
        ),
      );

      // Act
      final result = await repository.joinGroup(uniqueCode: tUniqueCode);

      // Assert
      expect(result.isRight(), true);
    });

    test('should return Left(Failure) when unique code lookup returns null', () async {
      // Arrange
      when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn(tUserId);

      when(() => mockSupabaseClient.from('public_user_lookup')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([]),
        ),
      );

      // Act
      final result = await repository.joinGroup(uniqueCode: tUniqueCode);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(failure.message, contains('User with unique code not found'));
        },
        (_) => fail('Should not return Right'),
      );
    });

    test('should return Left(Failure) when family group lookup returns null', () async {
      // Arrange
      when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn(tUserId);

      when(() => mockSupabaseClient.from('public_user_lookup')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
            [
              {'id': tOwnerId}
            ],
          ),
        ),
      );
      when(() => mockSupabaseClient.from('groups')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([]),
        ),
      );

      // Act
      final result = await repository.joinGroup(uniqueCode: tUniqueCode);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(failure.message, contains('No active family group found'));
        },
        (_) => fail('Should not return Right'),
      );
    });
  });

  group('getMyGroups', () {
    test('should return Right(List<GroupModel>) when query succeeds', () async {
      // Arrange
      when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn(tUserId);
      when(() => mockSupabaseClient.from('groups')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
            [tGroupData],
          ),
        ),
      );

      // Act
      final result = await repository.getMyGroups();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return Left'),
        (list) {
          expect(list.length, 1);
          expect(list.first.id, tGroupId);
        },
      );
    });

    test('should return Left(UnknownFailure) when user is not authenticated', () async {
      // Arrange
      when(() => mockGoTrueClient.currentUser).thenReturn(null);

      // Act
      final result = await repository.getMyGroups();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(failure.message, contains('User is not authenticated'));
        },
        (_) => fail('Should not return Right'),
      );
    });
  });
}
