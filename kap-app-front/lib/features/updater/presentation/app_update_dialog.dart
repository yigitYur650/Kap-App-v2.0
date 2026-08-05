import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/app_version_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';

class AppUpdateDialog extends StatefulWidget {
  final AppVersionModel version;

  const AppUpdateDialog({
    super.key,
    required this.version,
  });

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusText = '';

  Future<void> _startInAppDownloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _statusText = 'İndirme başlatılıyor...';
    });

    try {
      final url = Uri.parse(widget.version.apkUrl);
      final client = http.Client();
      final request = http.Request('GET', url);
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Sunucu yanıt vermedi (${response.statusCode})');
      }

      final contentLength = response.contentLength ?? 0;
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/kap_app_update.apk';
      final file = File(filePath);

      final sink = file.openWrite();
      int downloadedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        if (contentLength > 0 && mounted) {
          setState(() {
            _downloadProgress = downloadedBytes / contentLength;
            final percentage = (_downloadProgress * 100).toInt();
            _statusText = 'APK indiriliyor... %$percentage';
          });
        }
      }

      await sink.close();
      client.close();

      if (mounted) {
        setState(() {
          _downloadProgress = 1.0;
          _statusText = 'Yükleyici başlatılıyor...';
        });
      }

      // Trigger native Package Installer
      final result = await OpenFile.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        // Fallback to URL launcher if OpenFile fails
        await _fallbackLaunchUrl();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uygulama içi indirme başarısız oldu, tarayıcı açılıyor... ($e)'),
            backgroundColor: AppColors.primary,
          ),
        );
        await _fallbackLaunchUrl();
      }
    }
  }

  Future<void> _fallbackLaunchUrl() async {
    final url = Uri.parse(widget.version.apkUrl);
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.version.isMandatory && !_isDownloading,
      child: AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Yeni Güncelleme Mevcut! 🚀',
              style: AppTypography.headlineMd.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.version.versionName,
              style: AppTypography.labelLg.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isDownloading && widget.version.changelog != null && widget.version.changelog!.trim().isNotEmpty) ...[
              Text(
                'Yenilikler:',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.secondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2022),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Text(
                  widget.version.changelog!,
                  style: AppTypography.bodyLg.copyWith(color: AppColors.text),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_isDownloading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                backgroundColor: const Color(0xFF242424),
                color: AppColors.primary,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _statusText,
                  style: AppTypography.labelSm.copyWith(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.version.isMandatory && !_isDownloading)
              Text(
                '⚠️ Bu zorunlu bir güncellemedir. Devam edebilmek için lütfen yeni sürümü yükleyin.',
                style: AppTypography.labelSm.copyWith(color: AppColors.primary),
              ),
          ],
        ),
        actions: [
          if (!widget.version.isMandatory && !_isDownloading)
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text('Daha Sonra', style: TextStyle(color: Colors.white54, fontSize: 16)),
            ),
          if (!_isDownloading)
            ElevatedButton.icon(
              onPressed: _startInAppDownloadAndInstall,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              label: const Text('İndir ve Yükle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
