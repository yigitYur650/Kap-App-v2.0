import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

import 'package:kap_app_front/core/models/app_user.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';
import 'package:kap_app_front/core/models/group_model.dart';
import 'package:kap_app_front/core/models/request_model.dart';
import 'package:kap_app_front/core/repositories/group_repository.dart';
import 'package:kap_app_front/core/repositories/request_repository.dart';
import 'package:kap_app_front/core/network/supabase_client.dart';
import 'package:kap_app_front/features/auth/presentation/providers/auth_provider.dart';
import 'package:kap_app_front/features/groups/presentation/providers/active_group_provider.dart';
import 'package:kap_app_front/features/groups/presentation/providers/group_members_provider.dart';
import 'package:kap_app_front/features/groups/providers/group_repository_provider.dart';
import 'package:kap_app_front/features/requests/providers/request_repository_provider.dart';
import 'package:kap_app_front/features/requests/presentation/providers/request_controller.dart';
import 'package:kap_app_front/features/requests/presentation/screens/shopping_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockRequestRepository extends Mock implements RequestRepository {}

// ── Fake notifiers ────────────────────────────────────────────────────────────

class FakeAuthNotifier extends AuthNotifier {
  final AppUser? _user;
  FakeAuthNotifier(this._user);

  @override
  FutureOr<AppUser?> build() async => _user;

  @override
  Future<void> signOut() async {
    state = const AsyncValue.data(null);
  }
}

class FakeActiveGroup extends ActiveGroup {
  final GroupModel? _group;
  FakeActiveGroup(this._group);

  @override
  GroupModel? build() => _group;
}

class FakeRequestController extends RequestController {
  final AsyncValue<List<RequestModel>> _initialState;
  FakeRequestController(this._initialState);

  @override
  FutureOr<List<RequestModel>> build() async {
    // Replicate the state set by the mock
    if (_initialState.hasError) {
      state = _initialState;
      throw _initialState.error!;
    }
    if (_initialState.isLoading) {
      return Completer<List<RequestModel>>().future;
    }
    return _initialState.value ?? [];
  }
}

// ── GoRouter setup for testing ────────────────────────────────────────────────

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const ShoppingListScreen(),
      ),
      GoRoute(
        path: '/members',
        builder: (context, state) => const Scaffold(body: Text('Members')),
      ),
    ],
  );
}

// ── Widget factory ────────────────────────────────────────────────────────────

Widget buildScreen({
  required MockSupabaseClient mockSupabase,
  required MockGroupRepository mockGroupRepo,
  required MockRequestRepository mockRequestRepo,
  GroupModel? activeGroup,
  AsyncValue<List<RequestModel>> requestsState = const AsyncValue.loading(),
  AppUser? authUser,
}) {
  final mockGoTrue = MockGoTrueClient();
  when(() => mockSupabase.auth).thenReturn(mockGoTrue);

  return ProviderScope(
    overrides: [
      supabaseClientProvider.overrideWithValue(mockSupabase),
      groupRepositoryProvider.overrideWithValue(mockGroupRepo),
      requestRepositoryProvider.overrideWithValue(mockRequestRepo),
      authProvider.overrideWith(() => FakeAuthNotifier(authUser)),
      activeGroupProvider.overrideWith(() => FakeActiveGroup(activeGroup)),
      requestControllerProvider.overrideWith(
        () => FakeRequestController(requestsState),
      ),
      if (activeGroup != null)
        groupMembersProvider(activeGroup.id).overrideWith((_) async => []),
    ],
    child: MaterialApp.router(
      routerConfig: _buildTestRouter(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

// ── Test fixtures ─────────────────────────────────────────────────────────────

final tGroup = GroupModel(
  id: 'group-1',
  name: 'Family Kitchen',
  type: 'family',
  createdBy: 'user-1',
  createdAt: DateTime(2026, 6, 26),
);

const tUser = AppUser(
  id: 'user-1',
  displayName: 'Test User',
  uniqueCode: 'ABCD-EFGH',
  email: 'test@example.com',
  emailVerified: true,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGroupRepository mockGroupRepo;
  late MockRequestRepository mockRequestRepo;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockGroupRepo = MockGroupRepository();
    mockRequestRepo = MockRequestRepository();
    when(() => mockGroupRepo.getMyGroups()).thenAnswer((_) async => const Right([]));
  });

  group('ShoppingListScreen', () {
    testWidgets('shows no-active-group message and GroupSwitcherWidget when activeGroup is null',
        (tester) async {
      await tester.pumpWidget(buildScreen(
        mockSupabase: mockSupabase,
        mockGroupRepo: mockGroupRepo,
        mockRequestRepo: mockRequestRepo,
        activeGroup: null,
        authUser: tUser,
      ));
      await tester.pumpAndSettle();

      // The screen should show the no-group empty state
      expect(find.byIcon(Icons.group_off_outlined), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator while requests are loading',
        (tester) async {
      await tester.pumpWidget(buildScreen(
        mockSupabase: mockSupabase,
        mockGroupRepo: mockGroupRepo,
        mockRequestRepo: mockRequestRepo,
        activeGroup: tGroup,
        requestsState: const AsyncValue.loading(),
        authUser: tUser,
      ));
      // Only pump once — don't settle, otherwise provider resolves
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state icon when requests list is empty', (tester) async {
      await tester.pumpWidget(buildScreen(
        mockSupabase: mockSupabase,
        mockGroupRepo: mockGroupRepo,
        mockRequestRepo: mockRequestRepo,
        activeGroup: tGroup,
        requestsState: const AsyncValue.data([]),
        authUser: tUser,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shopping_basket_outlined), findsOneWidget);
    });

    testWidgets('shows group name in AppBar when group is active', (tester) async {
      await tester.pumpWidget(buildScreen(
        mockSupabase: mockSupabase,
        mockGroupRepo: mockGroupRepo,
        mockRequestRepo: mockRequestRepo,
        activeGroup: tGroup,
        requestsState: const AsyncValue.data([]),
        authUser: tUser,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Family Kitchen'), findsWidgets);
    });

    testWidgets('shows FAB with add icon when group is active', (tester) async {
      await tester.pumpWidget(buildScreen(
        mockSupabase: mockSupabase,
        mockGroupRepo: mockGroupRepo,
        mockRequestRepo: mockRequestRepo,
        activeGroup: tGroup,
        requestsState: const AsyncValue.data([]),
        authUser: tUser,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
