import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kap_app_front/core/models/app_user.dart';
import 'package:kap_app_front/core/network/supabase_client.dart';
import 'package:kap_app_front/features/auth/presentation/providers/auth_provider.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockFilterBuilderList extends Mock
    implements PostgrestFilterBuilder<PostgrestList> {}

class MockSession extends Mock implements Session {}

class MockUser extends Mock implements User {}

// ── Fake Future-bearing builder ───────────────────────────────────────────────
// Exactly the same approach as supabase_auth_repository_test.dart uses.

class FakePostgrestFilterBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  final Future<T> _future;
  FakePostgrestFilterBuilder(this._future);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _tUserId = 'user-uuid-123';
const _tProfileRow = <String, dynamic>{
  'id': _tUserId,
  'display_name': 'Test User',
  'unique_code': 'ABCD-EFGH',
  'email': 'test@example.com',
  'email_verified': false,
};
const _tUser = AppUser(
  id: _tUserId,
  displayName: 'Test User',
  uniqueCode: 'ABCD-EFGH',
  email: 'test@example.com',
  emailVerified: false,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockGoTrue;
  late MockSupabaseQueryBuilder mockQB;
  late MockFilterBuilderList mockFBList;
  late MockSession mockSession;
  late MockUser mockUser;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockGoTrue = MockGoTrueClient();
    mockQB = MockSupabaseQueryBuilder();
    mockFBList = MockFilterBuilderList();
    mockSession = MockSession();
    mockUser = MockUser();

    when(() => mockClient.auth).thenReturn(mockGoTrue);
    when(() => mockSession.user).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn(_tUserId);

    // Wire from('users') → mockQB
    when(() => mockClient.from('users')).thenAnswer((_) => mockQB);
    // select() returns a MockFilterBuilderList (via thenAnswer to avoid Future issue)
    when(() => mockQB.select()).thenAnswer((_) => mockFBList);
    // eq() returns itself so the chain continues
    when(() => mockFBList.eq('id', _tUserId)).thenAnswer((_) => mockFBList);
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [supabaseClientProvider.overrideWithValue(mockClient)],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('AuthNotifier', () {
    group('build() — initial session hydration', () {
      test('should return null when there is no active session', () async {
        when(() => mockGoTrue.currentSession).thenReturn(null);

        final state = await makeContainer().read(authProvider.future);

        expect(state, isNull);
        verifyNever(() => mockClient.from(any()));
      });

      test('should return AppUser when session exists and profile is found', () async {
        when(() => mockGoTrue.currentSession).thenReturn(mockSession);
        when(() => mockFBList.maybeSingle()).thenAnswer(
          (_) => FakePostgrestFilterBuilder<Map<String, dynamic>?>(
            Future.value(_tProfileRow),
          ),
        );

        final state = await makeContainer().read(authProvider.future);

        expect(state, isNotNull);
        expect(state!.id, _tUserId);
        expect(state.displayName, 'Test User');
      });

      test(
          'should call signOut and return null on ghost session '
          '(session exists but profile lookup returns null)', () async {
        when(() => mockGoTrue.currentSession).thenReturn(mockSession);
        when(() => mockGoTrue.signOut()).thenAnswer((_) async {});
        when(() => mockFBList.maybeSingle()).thenAnswer(
          (_) => FakePostgrestFilterBuilder<Map<String, dynamic>?>(
            Future.value(null),
          ),
        );

        final state = await makeContainer().read(authProvider.future);

        verify(() => mockGoTrue.signOut()).called(1);
        expect(state, isNull);
      });

      test(
          'should call signOut and return null when profile lookup throws '
          '(catch(_) swallows the error — ghost session path executes)', () async {
        // NOTE: _fetchUserProfile in auth_provider.dart silently swallows all
        // exceptions via catch(_). When swallowed, userProfile == null, triggering signOut.
        // This test documents that error-silent behavior.
        when(() => mockGoTrue.currentSession).thenReturn(mockSession);
        when(() => mockGoTrue.signOut()).thenAnswer((_) async {});
        when(() => mockClient.from('users')).thenThrow(Exception('DB error'));

        final state = await makeContainer().read(authProvider.future);

        verify(() => mockGoTrue.signOut()).called(1);
        expect(state, isNull);
      });
    });

    group('signOut()', () {
      test('should call supabase.auth.signOut and set state to null', () async {
        when(() => mockGoTrue.currentSession).thenReturn(null);
        when(() => mockGoTrue.signOut()).thenAnswer((_) async {});

        final container = makeContainer();
        await container.read(authProvider.future);

        await container.read(authProvider.notifier).signOut();

        verify(() => mockGoTrue.signOut()).called(1);
        expect(container.read(authProvider).value, isNull);
      });
    });

    group('updateState()', () {
      test('should update state to the given AppUser', () async {
        when(() => mockGoTrue.currentSession).thenReturn(null);

        final container = makeContainer();
        await container.read(authProvider.future);

        container.read(authProvider.notifier).updateState(_tUser);

        expect(container.read(authProvider).value, _tUser);
      });

      test('should reset state to null after being set', () async {
        when(() => mockGoTrue.currentSession).thenReturn(null);

        final container = makeContainer();
        await container.read(authProvider.future);

        container.read(authProvider.notifier).updateState(_tUser);
        container.read(authProvider.notifier).updateState(null);

        expect(container.read(authProvider).value, isNull);
      });
    });
  });
}
