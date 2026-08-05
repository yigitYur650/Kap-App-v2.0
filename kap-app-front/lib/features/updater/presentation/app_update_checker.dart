import 'package:flutter/material.dart';
import '../data/updater_repository.dart';
import 'app_update_dialog.dart';

class AppUpdateChecker {
  static final UpdaterRepository _repository = UpdaterRepository();

  /// Current compiled app version code (e.g. 100 for v2.0.0).
  static const int currentVersionCode = 100;

  /// Checks for available updates and shows the update dialog if a newer version exists.
  static Future<void> check(BuildContext context) async {
    final latestVersion = await _repository.checkUpdate();
    if (latestVersion == null) return;

    if (latestVersion.versionCode > currentVersionCode) {
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
