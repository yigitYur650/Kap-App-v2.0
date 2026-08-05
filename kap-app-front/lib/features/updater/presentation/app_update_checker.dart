import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/updater_repository.dart';
import 'app_update_dialog.dart';

class AppUpdateChecker {
  static final UpdaterRepository _repository = UpdaterRepository();

  /// Prevents opening duplicate update dialogs in the same app session.
  static int? _alreadyShownVersionCode;

  /// Checks for available updates and shows the update dialog if a newer version exists.
  static Future<void> check(BuildContext context) async {
    final latestVersion = await _repository.checkUpdate();
    if (latestVersion == null) return;

    // 1. Session Guard: Don't show again if already shown during this app run
    if (_alreadyShownVersionCode == latestVersion.versionCode) {
      return;
    }

    // 2. SharedPreferences Guard: Don't show if user clicked "Daha Sonra" for this version
    final prefs = await SharedPreferences.getInstance();
    final dismissedVersionCode = prefs.getInt('dismissed_version_code') ?? 0;
    if (!latestVersion.isMandatory && latestVersion.versionCode <= dismissedVersionCode) {
      return;
    }

    // 3. Dynamic Installed Version Check
    int currentCode = 100;
    try {
      final info = await PackageInfo.fromPlatform();
      currentCode = int.tryParse(info.buildNumber) ?? 100;
    } catch (_) {}

    if (latestVersion.versionCode > currentCode) {
      _alreadyShownVersionCode = latestVersion.versionCode;
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: !latestVersion.isMandatory,
          builder: (context) => AppUpdateDialog(version: latestVersion),
        );
      }
    }
  }

  /// Reset session guard (e.g. after manual check)
  static void resetSession() {
    _alreadyShownVersionCode = null;
  }
}
