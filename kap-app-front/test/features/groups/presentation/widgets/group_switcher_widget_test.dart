import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kap_app_front/core/models/group_model.dart';
import 'package:kap_app_front/core/repositories/group_repository.dart';
import 'package:kap_app_front/features/groups/providers/group_repository_provider.dart';
import 'package:kap_app_front/features/groups/presentation/providers/active_group_provider.dart';
import 'package:kap_app_front/features/groups/presentation/widgets/group_switcher_widget.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

final tGroup = GroupModel(
  id: 'group-1',
  name: 'Family Kitchen',
  type: 'family',
  createdBy: 'user-1',
  createdAt: DateTime(2026, 6, 26),
);

class FakeActiveGroup extends ActiveGroup {
  final GroupModel? _group;
  FakeActiveGroup(this._group);
  @override
  GroupModel? build() => _group;
}

Widget buildGroupSwitcher({
  required MockGroupRepository mockGroupRepo,
  GroupModel? activeGroup,
}) {
  return ProviderScope(
    overrides: [
      groupRepositoryProvider.overrideWithValue(mockGroupRepo),
      activeGroupProvider.overrideWith(() => FakeActiveGroup(activeGroup)),
    ],
    child: const MaterialApp(
      home: Scaffold(body: GroupSwitcherWidget()),
    ),
  );
}

void main() {
  late MockGroupRepository mockGroupRepo;

  setUp(() {
    mockGroupRepo = MockGroupRepository();
    when(() => mockGroupRepo.getMyGroups())
        .thenAnswer((_) async => const Right([]));
  });

  group('GroupSwitcherWidget', () {
    testWidgets('shows fallback text when activeGroup is null', (tester) async {
      await tester.pumpWidget(
        buildGroupSwitcher(mockGroupRepo: mockGroupRepo, activeGroup: null),
      );
      await tester.pump();

      expect(find.text('No Group Selected'), findsOneWidget);
    });

    testWidgets('shows group name when activeGroup is set', (tester) async {
      await tester.pumpWidget(
        buildGroupSwitcher(mockGroupRepo: mockGroupRepo, activeGroup: tGroup),
      );
      await tester.pump();

      expect(find.text('Family Kitchen'), findsOneWidget);
    });

    testWidgets('shows group_outlined icon', (tester) async {
      await tester.pumpWidget(
        buildGroupSwitcher(mockGroupRepo: mockGroupRepo, activeGroup: tGroup),
      );
      await tester.pump();

      expect(find.byIcon(Icons.group_outlined), findsOneWidget);
    });

    testWidgets('shows dropdown arrow icon', (tester) async {
      await tester.pumpWidget(
        buildGroupSwitcher(mockGroupRepo: mockGroupRepo, activeGroup: tGroup),
      );
      await tester.pump();

      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('tapping widget opens a modal bottom sheet', (tester) async {
      // For the BottomSheet, userGroupsProvider is also needed.
      // We override groupRepositoryProvider so userGroupsProvider can resolve.
      await tester.pumpWidget(
        buildGroupSwitcher(mockGroupRepo: mockGroupRepo, activeGroup: tGroup),
      );
      await tester.pump();

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // A ModalBarrier appears when a BottomSheet is open.
      expect(find.byType(ModalBarrier), findsWidgets);
    });
  });
}
