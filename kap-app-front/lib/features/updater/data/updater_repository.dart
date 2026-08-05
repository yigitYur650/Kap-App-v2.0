import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/app_version_model.dart';

class UpdaterRepository {
  /// Checks Supabase directly for the latest released app version.
  Future<AppVersionModel?> checkUpdate() async {
    try {
      final res = await Supabase.instance.client
          .from('app_versions')
          .select('*')
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null) {
        return AppVersionModel.fromJson(res);
      }
    } catch (_) {
      // Soft fallback on network error
    }
    return null;
  }
}
