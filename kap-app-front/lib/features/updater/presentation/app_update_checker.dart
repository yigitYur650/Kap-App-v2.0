import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../data/updater_repository.dart';
import 'app_update_dialog.dart';

class AppUpdateChecker {
  static final UpdaterRepository _repository = UpdaterRepository();

  /// Checks for available updates and shows the update dialog if a newer version exists.
  static Future<void> check(BuildContext context) async {
    final latestVersion = await _repository.checkUpdate();
    if (latestVersion == null) return;

    try {
      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 100;

      if (latestVersion.versionCode > currentCode) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: !latestVersion.isMandatory,
            builder: (context) => AppUpdateDialog(version: latestVersion),
          );
        }
      }
    } catch (_) {
      // Fallback check
      if (latestVersion.versionCode > 100) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: !latestVersion.isMandatory,
            builder: (context) => AppUpdateDialog(version: latestVersion),
          );
        }
      }
    }
  }
}
