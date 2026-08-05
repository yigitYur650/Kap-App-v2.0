import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/app_version_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';

class AppUpdateDialog extends StatelessWidget {
  final AppVersionModel version;

  const AppUpdateDialog({
    super.key,
    required this.version,
  });

  Future<void> _downloadAndInstall(BuildContext context) async {
    final url = Uri.parse(version.apkUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İndirme bağlantısı açılamadı.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !version.isMandatory,
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
              version.versionName,
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
            if (version.changelog != null && version.changelog!.trim().isNotEmpty) ...[
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
                  version.changelog!,
                  style: AppTypography.bodyLg.copyWith(color: AppColors.text),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (version.isMandatory)
              Text(
                '⚠️ Bu zorunlu bir güncellemedir. Devam edebilmek için lütfen yeni sürümü yükleyin.',
                style: AppTypography.labelSm.copyWith(color: AppColors.primary),
              ),
          ],
        ),
        actions: [
          if (!version.isMandatory)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Daha Sonra', style: TextStyle(color: Colors.white54)),
            ),
          ElevatedButton.icon(
            onPressed: () => _downloadAndInstall(context),
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
