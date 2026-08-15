import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kap_app_front/features/auth/presentation/providers/auth_provider.dart';
import 'package:kap_app_front/features/auth/presentation/screens/login_screen.dart';
import 'package:kap_app_front/features/auth/presentation/screens/register_screen.dart';
import 'package:kap_app_front/features/groups/presentation/screens/hub_screen.dart';
import 'package:kap_app_front/features/groups/presentation/screens/settings_screen.dart';
import 'package:kap_app_front/features/requests/presentation/screens/shopping_list_screen.dart';
import 'package:kap_app_front/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:kap_app_front/features/health/presentation/screens/health_profile_screen.dart';
import 'package:kap_app_front/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:kap_app_front/core/navigation/shell_screen.dart';

import 'package:kap_app_front/features/auth/presentation/screens/otp_verification_screen.dart';

import 'package:kap_app_front/features/subscription/presentation/screens/store_screen.dart';

import 'package:kap_app_front/features/admin/presentation/providers/admin_provider.dart';

/// Provider that exposes the GoRouter configuration and rebuilds on auth state changes.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final isAdmin = ref.watch(isSystemAdminProvider).value ?? false;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading) {
        return null;
      }

      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isVerifyingOTP = state.matchedLocation == '/verify-otp';
      final isAdminRoute = state.matchedLocation == '/admin';

      if (!isLoggedIn) {
        if (!isLoggingIn && !isRegistering && !isVerifyingOTP) {
          return '/login';
        }
      } else {
        if (isLoggingIn || isRegistering || isVerifyingOTP) {
          return '/';
        }
        if (isAdminRoute && !isAdmin) {
          return '/';
        }
      }

      return null;
    },
    routes: [
      // Authentication Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final email = (state.extra as String?) ?? (state.uri.queryParameters['email'] ?? '');
          return OTPVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/store',
        builder: (context, state) => const StoreScreen(),
      ),
      
      // Bottom Navigation Stateful Shell Route
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Hub Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HubScreen(),
              ),
            ],
          ),
          
          // Tab 1: Shopping List
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/list',
                builder: (context, state) => const ShoppingListScreen(),
              ),
            ],
          ),

          // Tab 2: Home Inventory ("Evde Ne Var?")
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (context, state) => const InventoryScreen(),
              ),
            ],
          ),

          // Tab 3: Health / Kişisel Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/health',
                builder: (context, state) => const HealthProfileScreen(),
              ),
            ],
          ),
          
          // Tab 4: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
