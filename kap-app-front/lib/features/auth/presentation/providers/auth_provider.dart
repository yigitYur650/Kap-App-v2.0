import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/network/supabase_client.dart';

/// Notifier that manages and projects the current user authentication session state.
class AuthNotifier extends AsyncNotifier<AppUser?> {
  @override
  FutureOr<AppUser?> build() async {
    final supabaseClient = ref.watch(supabaseClientProvider);

    // 1. Check current Supabase Auth session
    final session = supabaseClient.auth.currentSession;
    if (session != null) {
      // 2. Hydration pull user metadata from public.users
      final userProfile = await _fetchUserProfile(supabaseClient, session.user.id);
      if (userProfile == null) {
        // Safe sign-out / cleanup to prevent deadlocks (Ghost Session Hotfix)
        await supabaseClient.auth.signOut();
        return null;
      }
      return userProfile;
    }
    return null;
  }

  /// Hydrates the user profile from the public.users database table.
  Future<AppUser?> _fetchUserProfile(SupabaseClient client, String userId) async {
    try {
      final data = await client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        return AppUser.fromJson(data);
      }
    } catch (_) {
      // Fallback to null on lookup failures
    }
    return null;
  }

  /// Updates the authentication state with the specified user profile.
  void updateState(AppUser? user) {
    state = AsyncValue.data(user);
  }

  /// Sets the authentication state to an error.
  void setError(Object error, StackTrace stackTrace) {
    state = AsyncValue.error(error, stackTrace);
  }

  /// Sets the authentication state to loading.
  void setLoading() {
    state = const AsyncValue.loading();
  }

  /// Signs out the current user session and resets the state.
  Future<void> signOut() async {
    final supabaseClient = ref.read(supabaseClientProvider);
    await supabaseClient.auth.signOut();
    updateState(null);
  }
}

/// Provider to access and watch the current user authentication state.
final authProvider = AsyncNotifierProvider<AuthNotifier, AppUser?>(() {
  return AuthNotifier();
});
