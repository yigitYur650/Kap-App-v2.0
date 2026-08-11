import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kap_app_front/features/auth/presentation/providers/auth_provider.dart';

/// Riverpod provider to check if current logged-in user is a system admin
final isSystemAdminProvider = FutureProvider<bool>((ref) async {
  final appUser = ref.watch(authProvider).value;
  if (appUser == null) return false;

  final client = Supabase.instance.client;
  final currentUser = client.auth.currentUser;

  if (currentUser == null || currentUser.id != appUser.id) return false;

  try {
    final res = await client
        .from('system_admins')
        .select('user_id')
        .eq('user_id', appUser.id)
        .maybeSingle();

    return res != null;
  } catch (_) {
    return false;
  }
});
