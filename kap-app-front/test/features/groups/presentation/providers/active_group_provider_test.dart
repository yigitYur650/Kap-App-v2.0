import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fpdart/fpdart.dart';

import 'package:kap_app_front/core/models/group_model.dart';
import 'package:kap_app_front/core/providers/shared_preferences_provider.dart';
import 'package:kap_app_front/core/repositories/group_repository.dart';
import 'package:kap_app_front/features/groups/providers/group_repository_provider.dart';
import 'package:kap_app_front/features/groups/presentation/providers/active_group_provider.dart';
import 'package:kap_app_front/features/groups/presentation/providers/user_groups_provider.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockSharedPreferences mockSharedPreferences;
  late MockGroupRepository mockGroupRepository;

  final tGroup1 = GroupModel(
    id: 'group-1',
    name: 'Group One',
    type: 'family',
    createdBy: 'user-1',
    createdAt: DateTime.parse('2026-06-26T01:30:00Z'),
  );

  final tGroup2 = GroupModel(
    id: 'group-2',
    name: 'Group Two',
    type: 'community',
    createdBy: 'user-1',
    createdAt: DateTime.parse('2026-06-26T01:35:00Z'),
  );

  final tGroupsList = [tGroup1, tGroup2];

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    mockGroupRepository = MockGroupRepository();
  });

  ProviderContainer createContainer({
    List<dynamic> overrides = const [],
  }) {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        groupRepositoryProvider.overrideWithValue(mockGroupRepository),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ActiveGroup Provider', () {
    test('initialization defaults to the first group when local storage is empty', () async {
      // Arrange
      when(() => mockGroupRepository.getMyGroups())
          .thenAnswer((_) async => Right(tGroupsList));
      when(() => mockSharedPreferences.getString('active_group_id')).thenReturn(null);

      final container = createContainer();

      expect(container.read(activeGroupProvider), null);

      // Wait until userGroupsProvider resolves
      await container.read(userGroupsProvider.future);

      expect(container.read(activeGroupProvider), tGroup1);
    });

    test('initialization restores correct group when local storage has a valid cached ID', () async {
      // Arrange
      when(() => mockGroupRepository.getMyGroups())
          .thenAnswer((_) async => Right(tGroupsList));
      when(() => mockSharedPreferences.getString('active_group_id')).thenReturn('group-2');

      final container = createContainer();

      expect(container.read(activeGroupProvider), null);

      await container.read(userGroupsProvider.future);

      expect(container.read(activeGroupProvider), tGroup2);
    });

    test('invalid cache eviction: clears invalid ID from preferences and defaults to first group', () async {
      // Arrange
      when(() => mockGroupRepository.getMyGroups())
          .thenAnswer((_) async => Right(tGroupsList));
      when(() => mockSharedPreferences.getString('active_group_id')).thenReturn('non-existent-group-id');
      when(() => mockSharedPreferences.remove('active_group_id')).thenAnswer((_) async => true);

      final container = createContainer();

      expect(container.read(activeGroupProvider), null);

      await container.read(userGroupsProvider.future);

      // Falls back to first group
      expect(container.read(activeGroupProvider), tGroup1);

      // Wait a microtask since eviction is scheduled in Future.microtask
      await Future.delayed(Duration.zero);
      verify(() => mockSharedPreferences.remove('active_group_id')).called(1);
    });

    test('switchGroup updates state immediately and schedules storage write', () async {
      // Arrange
      when(() => mockGroupRepository.getMyGroups())
          .thenAnswer((_) async => Right(tGroupsList));
      when(() => mockSharedPreferences.getString('active_group_id')).thenReturn(null);
      when(() => mockSharedPreferences.setString('active_group_id', 'group-2'))
          .thenAnswer((_) async => true);

      final container = createContainer();

      await container.read(userGroupsProvider.future);
      expect(container.read(activeGroupProvider), tGroup1);

      // Act
      container.read(activeGroupProvider.notifier).switchGroup(tGroup2);

      // Assert
      expect(container.read(activeGroupProvider), tGroup2);
      verify(() => mockSharedPreferences.setString('active_group_id', 'group-2')).called(1);
    });
  });
}
