import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kap_app_front/features/auth/presentation/providers/auth_provider.dart';
import 'package:kap_app_front/features/auth/presentation/screens/login_screen.dart';
import 'package:kap_app_front/features/auth/presentation/screens/register_screen.dart';
import 'package:kap_app_front/features/groups/presentation/screens/group_members_screen.dart';
import 'package:kap_app_front/features/requests/presentation/screens/shopping_list_screen.dart';

/// Provider that exposes the GoRouter configuration and rebuilds on auth state changes.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading) {
        return null;
      }

      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';

      if (!isLoggedIn) {
        if (!isLoggingIn && !isRegistering) {
          return '/login';
        }
      } else {
        if (isLoggingIn || isRegistering) {
          return '/';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const ShoppingListScreen(),
      ),
      GoRoute(
        path: '/members',
        builder: (context, state) => const GroupMembersScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
    ],
  );
});


