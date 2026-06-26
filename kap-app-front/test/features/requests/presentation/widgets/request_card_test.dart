import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kap_app_front/core/models/app_user.dart';
import 'package:kap_app_front/core/models/request_model.dart';
import 'package:kap_app_front/core/repositories/request_repository.dart';
import 'package:kap_app_front/features/auth/presentation/providers/auth_provider.dart';
import 'package:kap_app_front/features/groups/presentation/providers/group_members_provider.dart';
import 'package:kap_app_front/features/requests/presentation/providers/request_controller.dart';
import 'package:kap_app_front/features/requests/presentation/widgets/request_card.dart';
import 'package:kap_app_front/core/network/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockRequestRepository extends Mock implements RequestRepository {}

// ── Fake notifiers ────────────────────────────────────────────────────────────

class FakeAuthNotifier extends AuthNotifier {
  final AppUser? _user;
  FakeAuthNotifier(this._user);

  @override
  FutureOr<AppUser?> build() async => _user;
}

class FakeRequestController extends RequestController {
  final List<RequestModel> _requests;
  String? lastUpdatedRequestId;
  String? lastUpdatedStatus;
  String? lastDeletedRequestId;

  FakeRequestController(this._requests);

  @override
  FutureOr<List<RequestModel>> build() async => _requests;

  @override
  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
  }) async {
    lastUpdatedRequestId = requestId;
    lastUpdatedStatus = status;
  }

  @override
  Future<void> deleteRequest({required String requestId}) async {
    lastDeletedRequestId = requestId;
  }
}

// ── Test fixtures ─────────────────────────────────────────────────────────────

const tOwnerId = 'owner-user-id';
const tOtherUserId = 'other-user-id';
const tGroupId = 'group-1';

const tOwner = AppUser(
  id: tOwnerId,
  displayName: 'Owner',
  uniqueCode: 'AAAA-BBBB',
  email: 'owner@example.com',
  emailVerified: true,
);

RequestModel makeRequest({
  String status = 'pending',
  bool isPrivate = false,
  String requestedBy = tOwnerId,
}) {
  return RequestModel(
    id: 'req-1',
    groupId: tGroupId,
    requestedBy: requestedBy,
    itemName: 'milk',
    isPrivate: isPrivate,
    status: status,
    createdAt: DateTime(2026, 6, 26),
  );
}

// ── Widget builder ────────────────────────────────────────────────────────────

Widget buildCard({
  required RequestModel request,
  AppUser? authUser = tOwner,
  List<GroupMemberWithProfile> members = const [],
}) {
  final fakeRequestController = FakeRequestController([request]);
  final mockSupabase = MockSupabaseClient();
  final mockGoTrue = MockGoTrueClient();
  when(() => mockSupabase.auth).thenReturn(mockGoTrue);

  return ProviderScope(
    overrides: [
      supabaseClientProvider.overrideWithValue(mockSupabase),
      authProvider.overrideWith(() => FakeAuthNotifier(authUser)),
      requestControllerProvider.overrideWith(() => fakeRequestController),
      groupMembersProvider(tGroupId).overrideWith((_) async => members),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: RequestCard(
          request: request,
          requesterName: authUser?.displayName ?? 'Unknown',
        ),
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('RequestCard', () {
    testWidgets('shows unchecked checkbox when status is pending', (tester) async {
      await tester.pumpWidget(buildCard(request: makeRequest(status: 'pending')));
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);
    });

    testWidgets('shows checked checkbox when status is done', (tester) async {
      await tester.pumpWidget(buildCard(request: makeRequest(status: 'done')));
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
    });

    testWidgets('shows lineThrough decoration when status is done', (tester) async {
      await tester.pumpWidget(buildCard(request: makeRequest(status: 'done')));
      await tester.pumpAndSettle();

      final titleText = tester.widget<Text>(find.text('Milk'));
      expect(titleText.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('shows lock icon when request is private', (tester) async {
      await tester.pumpWidget(
        buildCard(request: makeRequest(isPrivate: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('does NOT show lock icon when request is not private', (tester) async {
      await tester.pumpWidget(
        buildCard(request: makeRequest(isPrivate: false)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });

    testWidgets('shows delete icon when auth user is the owner', (tester) async {
      await tester.pumpWidget(
        buildCard(request: makeRequest(requestedBy: tOwnerId), authUser: tOwner),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('does NOT show delete icon when auth user is NOT the owner', (tester) async {
      const otherUser = AppUser(
        id: tOtherUserId,
        displayName: 'Other',
        uniqueCode: 'XXXX-XXXX',
        email: 'other@example.com',
        emailVerified: true,
      );
      await tester.pumpWidget(
        buildCard(
          request: makeRequest(requestedBy: tOwnerId),
          authUser: otherUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets(
        'checkbox is disabled (onChanged null) when user is not owner or admin',
        (tester) async {
      const otherUser = AppUser(
        id: tOtherUserId,
        displayName: 'Other',
        uniqueCode: 'XXXX-XXXX',
        email: 'other@example.com',
        emailVerified: true,
      );
      await tester.pumpWidget(
        buildCard(
          request: makeRequest(requestedBy: tOwnerId),
          authUser: otherUser,
        ),
      );
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.onChanged, isNull);
    });

    testWidgets('tapping delete icon calls deleteRequest on controller', (tester) async {
      final fakeController = FakeRequestController([makeRequest()]);
      final mockSupabase = MockSupabaseClient();
      final mockGoTrue = MockGoTrueClient();
      when(() => mockSupabase.auth).thenReturn(mockGoTrue);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(mockSupabase),
            authProvider.overrideWith(() => FakeAuthNotifier(tOwner)),
            requestControllerProvider.overrideWith(() => fakeController),
            groupMembersProvider(tGroupId).overrideWith((_) async => []),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RequestCard(
                request: makeRequest(),
                requesterName: 'Owner',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(fakeController.lastDeletedRequestId, 'req-1');
    });

    testWidgets('tapping checkbox calls updateRequestStatus on controller', (tester) async {
      final fakeController = FakeRequestController([makeRequest(status: 'pending')]);
      final mockSupabase = MockSupabaseClient();
      final mockGoTrue = MockGoTrueClient();
      when(() => mockSupabase.auth).thenReturn(mockGoTrue);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(mockSupabase),
            authProvider.overrideWith(() => FakeAuthNotifier(tOwner)),
            requestControllerProvider.overrideWith(() => fakeController),
            groupMembersProvider(tGroupId).overrideWith((_) async => []),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RequestCard(
                request: makeRequest(status: 'pending'),
                requesterName: 'Owner',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(fakeController.lastUpdatedRequestId, 'req-1');
      expect(fakeController.lastUpdatedStatus, 'done');
    });
  });
}
