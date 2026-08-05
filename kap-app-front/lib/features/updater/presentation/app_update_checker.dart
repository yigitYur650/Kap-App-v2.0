import 'package:flutter/foundation.dart';
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
  /// Set [isManual] = true for user-triggered check from Settings.
  static Future<void> check(BuildContext context, {bool isManual = false}) async {
    // Web browsers do not download/install APK updates
    if (kIsWeb && !isManual) return;
    if (isManual && context.mounted) {
      _alreadyShownVersionCode = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔍 Güncellemeler denetleniyor...'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF1F2022),
        ),
      );
    }

    final latestVersion = await _repository.checkUpdate();

    // Dynamic Installed Version Check & ABI Split Normalization (e.g. 2102 -> 102)
    int rawCode = 100;
    String versionName = '1.0.0';
    try {
      final info = await PackageInfo.fromPlatform();
      rawCode = int.tryParse(info.buildNumber) ?? 100;
      versionName = info.version;
    } catch (_) {}

    // Handle Gradle ABI split offsets (e.g., arm64 adds 2000 -> 2102 % 1000 = 102)
    final int currentCode = (rawCode >= 1000) ? (rawCode % 1000) : rawCode;

    if (latestVersion == null) {
      if (isManual && context.mounted) {
        _showUpToDateSnackBar(context, versionName, currentCode);
      }
      return;
    }

    // 1. Session Guard (Skip for automatic background check)
    if (!isManual && _alreadyShownVersionCode == latestVersion.versionCode) {
      return;
    }

    // 2. SharedPreferences Guard (Skip for automatic background check)
    final prefs = await SharedPreferences.getInstance();
    final dismissedVersionCode = prefs.getInt('dismissed_version_code') ?? 0;
    if (!isManual && !latestVersion.isMandatory && latestVersion.versionCode <= dismissedVersionCode) {
      return;
    }

    if (latestVersion.versionCode > currentCode) {
      _alreadyShownVersionCode = latestVersion.versionCode;
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: !latestVersion.isMandatory,
          builder: (context) => AppUpdateDialog(version: latestVersion),
        );
      }
    } else {
      if (isManual && context.mounted) {
        _showUpToDateSnackBar(context, versionName, currentCode);
      }
    }
  }

  static void _showUpToDateSnackBar(BuildContext context, String versionName, int currentCode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.teal,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '🎉 Uygulamanız en güncel sürümde! (v$versionName - Build $currentCode)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reset session guard (e.g. after manual check)
  static void resetSession() {
    _alreadyShownVersionCode = null;
  }
}
