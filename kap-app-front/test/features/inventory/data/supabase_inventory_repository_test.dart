import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fpdart/fpdart.dart';

import 'package:kap_app_front/core/models/inventory_item.dart';
import 'package:kap_app_front/core/models/stock_status.dart';
import 'package:kap_app_front/features/inventory/data/supabase_inventory_repository.dart';

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
      return FakePostgrestTransformBuilder<PostgrestMap>(Map<String, dynamic>.from(val));
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

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final FakePostgrestFilterBuilder<dynamic> filterBuilder;

  FakeSupabaseQueryBuilder(this.filterBuilder);

  @override
  PostgrestFilterBuilder<dynamic> insert(Object values, {bool defaultToNull = false}) => filterBuilder;

  @override
  PostgrestFilterBuilder<dynamic> update(Object values, {bool defaultToNull = false}) => filterBuilder;
}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockUser mockUser;
  late SupabaseInventoryRepository repository;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockUser = MockUser();
    repository = SupabaseInventoryRepository(mockSupabaseClient);

    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
  });

  group('StockStatus mapping', () {
    test('converts strings from database correctly', () {
      expect(StockStatus.fromString('var'), equals(StockStatus.inStock));
      expect(StockStatus.fromString('azaldı'), equals(StockStatus.low));
      expect(StockStatus.fromString('yok'), equals(StockStatus.outOfStock));
      expect(StockStatus.fromString('unknown_status'), equals(StockStatus.inStock));
    });

    test('converts enum to database strings correctly', () {
      expect(StockStatus.inStock.toDbString(), equals('var'));
      expect(StockStatus.low.toDbString(), equals('azaldı'));
      expect(StockStatus.outOfStock.toDbString(), equals('yok'));
    });
  });

  group('InventoryItem serialization', () {
    final itemJson = {
      'id': 'item-id-123',
      'group_id': 'group-id-456',
      'item_name': 'Elma',
      'status': 'azaldı',
      'last_updated_by': 'user-id-789',
      'last_updated_at': '2026-07-01T12:00:00Z',
      'created_at': '2026-07-01T10:00:00Z',
      'deleted_at': null,
    };

    test('fromJson deserializes fields correctly', () {
      final item = InventoryItem.fromJson(itemJson);

      expect(item.id, equals('item-id-123'));
      expect(item.groupId, equals('group-id-456'));
      expect(item.itemName, equals('Elma'));
      expect(item.status, equals(StockStatus.low));
      expect(item.lastUpdatedBy, equals('user-id-789'));
      expect(item.lastUpdatedAt, equals(DateTime.parse('2026-07-01T12:00:00Z')));
      expect(item.createdAt, equals(DateTime.parse('2026-07-01T10:00:00Z')));
      expect(item.deletedAt, isNull);
    });

    test('toJson serializes fields correctly', () {
      final item = InventoryItem.fromJson(itemJson);
      final serialized = item.toJson();

      expect(serialized['id'], equals('item-id-123'));
      expect(serialized['group_id'], equals('group-id-456'));
      expect(serialized['item_name'], equals('Elma'));
      expect(serialized['status'], equals('azaldı'));
      expect(serialized['last_updated_by'], equals('user-id-789'));
    });
  });

  group('SupabaseInventoryRepository name normalization', () {
    test('normalizes itemName using toLowerCase() and trim() before insert', () async {
      final mockResponse = {
        'id': 'new-item-id',
        'group_id': 'group-id-123',
        'item_name': 'süt',
        'status': 'var',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      final fakeFilter = FakePostgrestFilterBuilder<dynamic>(mockResponse);
      final fakeQuery = FakeSupabaseQueryBuilder(fakeFilter);
      
      when(() => mockSupabaseClient.from('inventory')).thenAnswer((_) => fakeQuery);

      final result = await repository.addInventoryItem(
        'group-id-123',
        '  SüT  ',
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('should not return failure'),
        (item) {
          expect(item.itemName, equals('süt'));
        },
      );
    });
  });
}
