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

  Future<HealthProfileData> getHealthProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return const HealthProfileData();

    try {
      final response = await _supabase
          .from('health_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        return HealthProfileData.fromJson(response);
      }
    } catch (_) {}

    return const HealthProfileData();
  }

  Future<void> saveHealthProfile(HealthProfileData profile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final data = {
      'user_id': user.id,
      ...profile.toJson(),
    };

    await _supabase.from('health_profiles').upsert(data);
  }
}
