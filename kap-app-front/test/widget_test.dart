import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kap_app_front/core/network/supabase_client.dart';
import 'package:kap_app_front/core/providers/shared_preferences_provider.dart';
import 'package:kap_app_front/core/repositories/group_repository.dart';
import 'package:kap_app_front/features/groups/providers/group_repository_provider.dart';
import 'package:kap_app_front/main.dart';
import 'package:kap_app_front/features/auth/presentation/screens/login_screen.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  testWidgets('App boilerplate compiles and builds smoke test', (WidgetTester tester) async {
    final mockSupabase = MockSupabaseClient();
    final mockGoTrue = MockGoTrueClient();
    final mockSharedPreferences = MockSharedPreferences();
    final mockGroupRepository = MockGroupRepository();

    when(() => mockSupabase.auth).thenReturn(mockGoTrue);
    when(() => mockGoTrue.currentSession).thenReturn(null);
    when(() => mockSharedPreferences.getString('active_group_id')).thenReturn(null);
    when(() => mockGroupRepository.getMyGroups()).thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockSupabase),
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
          groupRepositoryProvider.overrideWithValue(mockGroupRepository),
        ],
        child: const KapApp(),
      ),
    );

    // Let router and state resolve
    await tester.pumpAndSettle();

    // Verify that the login screen is shown.
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

