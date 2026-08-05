import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/models/app_version_model.dart';

class UpdaterRepository {
  final http.Client _httpClient;

  UpdaterRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Checks Go backend for the latest released app version.
  Future<AppVersionModel?> checkUpdate() async {
    try {
      const backendUrl = String.fromEnvironment(
        'GO_BACKEND_URL',
        defaultValue: String.fromEnvironment(
          'BACKEND_URL',
          defaultValue: 'http://localhost:8080',
        ),
      );

      final response = await _httpClient.get(
        Uri.parse('$backendUrl/api/v1/app/check-update'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final hasUpdate = data['has_update'] as bool? ?? false;
        final latestData = data['latest'] as Map<String, dynamic>?;

        if (hasUpdate && latestData != null) {
          return AppVersionModel.fromJson(latestData);
        }
      }
    } catch (_) {
      // Soft fallback on network error
    }
    return null;
  }
}
