import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kap_app_front/features/auth/presentation/providers/auth_provider.dart';
import 'package:kap_app_front/features/groups/data/group_repository_provider.dart';
import 'package:kap_app_front/features/groups/presentation/providers/active_group_provider.dart';
import 'package:kap_app_front/features/groups/presentation/providers/user_groups_provider.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';
import 'package:kap_app_front/shared/theme/app_colors.dart';
import 'package:kap_app_front/shared/theme/app_typography.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:kap_app_front/features/updater/presentation/app_update_checker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    final localizations = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.group_members_copied),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, WidgetRef ref, String groupId, String groupName) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(localizations.settings_delete_group_title, style: const TextStyle(color: Colors.white)),
        content: Text(
          '${localizations.settings_delete_group_confirm} "$groupName"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(localizations.dialog_cancel, style: const TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final repo = ref.read(groupRepositoryProvider);
              final result = await repo.deleteGroup(groupId: groupId);
              if (context.mounted) {
                result.fold(
                  (failure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(failure.message), backgroundColor: AppColors.primary),
                    );
                  },
                  (_) {
                    ref.invalidate(userGroupsProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations.settings_delete_group_success),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  },
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(localizations.dialog_delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final activeGroup = ref.watch(activeGroupProvider);
    final groupsAsync = ref.watch(userGroupsProvider);
    final user = authState.value;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          localizations.settings_title,
          style: AppTypography.headlineLg,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            if (user != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(
                        user.displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: AppTypography.headlineMd,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.secondary.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Active Group Share Code Section
            if (activeGroup != null) ...[
              Text(
                localizations.settings_active_group_info,
                style: AppTypography.labelLg.copyWith(
                  color: AppColors.secondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeGroup.name,
                      style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.settings_join_code,
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.secondary.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activeGroup.joinCode ?? localizations.settings_no_code,
                              style: AppTypography.headlineMd.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        if (activeGroup.joinCode != null)
                          IconButton(
                            onPressed: () => _copyToClipboard(context, activeGroup.joinCode!),
                            icon: const Icon(Icons.copy, color: AppColors.primary),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Group Switcher List
            Text(
              localizations.settings_my_groups,
              style: AppTypography.labelLg.copyWith(
                color: AppColors.secondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return Text(
                    localizations.settings_no_groups_found,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.secondary.withOpacity(0.6),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final isActive = activeGroup?.id == group.id;

                    return Material(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(10),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive
                                ? AppColors.primary.withOpacity(0.5)
                                : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: ListTile(
                          onTap: () {
                            ref.read(activeGroupProvider.notifier).switchGroup(group);
                          },
                        leading: Icon(
                          Icons.home_outlined,
                          color: isActive ? AppColors.primary : Colors.grey,
                        ),
                        title: Text(
                          group.name,
                          style: AppTypography.bodyLg.copyWith(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Delete button (only for admins or group creators)
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: AppColors.primary.withOpacity(0.7),
                              ),
                              onPressed: () => _confirmDeleteGroup(
                                context, ref, group.id, group.name,
                              ),
                            ),
                            if (isActive)
                              const Icon(Icons.check_circle, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('${localizations.errorGeneric}: $err'),
            ),

            const SizedBox(height: 24),
            // App Version & Manual Update Check Card
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final versionName = snapshot.data?.version ?? '2.2.0';
                final buildNumber = snapshot.data?.buildNumber ?? '106';

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Uygulama Sürümü',
                                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'v$versionName (Build $buildNumber)',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.teal.withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'YÜKLÜ',
                              style: TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () => AppUpdateChecker.check(context, isManual: true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF333333)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
                          label: const Text(
                            'Güncellemeleri Denetle',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Admin Dashboard Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/admin');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2022),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
                label: const Text(
                  '🛡️ Admin Paneline Git',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(authProvider.notifier).signOut();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  localizations.auth_sign_out,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 80), // bottom nav padding spacer
          ],
        ),
      ),
    );
  }
}
