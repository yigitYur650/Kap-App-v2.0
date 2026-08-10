import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/fitness_calculator.dart';

final healthProfileRepositoryProvider = Provider<HealthProfileRepository>((ref) {
  return HealthProfileRepository(Supabase.instance.client);
});

final healthProfileProvider = FutureProvider<HealthProfileData>((ref) async {
  final repo = ref.watch(healthProfileRepositoryProvider);
  return repo.getHealthProfile();
});

class HealthProfileRepository {
  final SupabaseClient _supabase;

  HealthProfileRepository(this._supabase);

  static const String _prefsKey = 'user_health_profile_data';

  Future<HealthProfileData> getHealthProfile() async {
    // 1. Check local SharedPreferences cache first
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJsonStr = prefs.getString(_prefsKey);
      if (localJsonStr != null && localJsonStr.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(localJsonStr);
        return HealthProfileData.fromJson(map);
      }
    } catch (_) {}

    // 2. Fallback to Supabase DB if logged in
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await _supabase
            .from('health_profiles')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        if (response != null) {
          final profile = HealthProfileData.fromJson(response);
          // Sync to local prefs
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefsKey, jsonEncode(profile.toJson()));
          return profile;
        }
      } catch (_) {}
    }

    return const HealthProfileData();
  }

  Future<void> saveHealthProfile(HealthProfileData profile) async {
    // 1. Save to local SharedPreferences immediately
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(profile.toJson()));
    } catch (_) {}

    // 2. Save to Supabase DB if logged in
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = {
          'user_id': user.id,
          ...profile.toJson(),
        };
        await _supabase.from('health_profiles').upsert(data);
      } catch (e) {
        // Table migration might be pending on Supabase instance
        // Catch gracefully so local state succeeds without throwing red bar
      }
    }
  }
}
