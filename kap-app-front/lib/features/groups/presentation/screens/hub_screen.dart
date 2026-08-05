import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kap_app_front/features/groups/presentation/providers/active_group_provider.dart';
import 'package:kap_app_front/features/groups/presentation/providers/group_members_provider.dart';
import 'package:kap_app_front/features/groups/presentation/widgets/active_list_summary_card.dart';
import 'package:kap_app_front/features/groups/presentation/widgets/create_group_dialog.dart';
import 'package:kap_app_front/features/groups/presentation/widgets/group_member_tile.dart';
import 'package:kap_app_front/features/groups/presentation/widgets/join_group_dialog.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';
import 'package:kap_app_front/shared/theme/app_colors.dart';
import 'package:kap_app_front/shared/theme/app_shapes.dart';
import 'package:kap_app_front/shared/theme/app_typography.dart';
import 'package:kap_app_front/shared/widgets/kap_app_brand_logo.dart';

import 'package:kap_app_front/features/updater/presentation/app_update_checker.dart';

class HubScreen extends ConsumerWidget {
  const HubScreen({super.key});

  void _showCreateGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateGroupDialog(),
    );
  }

  void _showJoinGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const JoinGroupDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGroup = ref.watch(activeGroupProvider);
    final size = MediaQuery.of(context).size;
    final localizations = AppLocalizations.of(context)!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateChecker.check(context);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -size.height * 0.1,
            left: -size.width * 0.1,
            width: size.width * 0.4,
            height: size.height * 0.4,
            child: CustomPaint(
              painter: BlobPainter(
                color: AppColors.primary,
                opacity: 0.08,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with modern KapAppBrandLogo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const KapAppBrandLogo(fontSize: 22, showBadge: false),
                          const SizedBox(height: 4),
                          Text(
                            activeGroup?.name ?? localizations.group_none_selected,
                            style: AppTypography.headlineMd.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _showJoinGroupDialog(context),
                        icon: const Icon(Icons.group_add, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Shopping List Summary Card
                  if (activeGroup != null) ...[
                    const ActiveListSummaryCard(),
                    const SizedBox(height: 24),

                    // Members Section
                    Text(
                      localizations.hub_members_header,
                      style: AppTypography.labelLg.copyWith(
                        color: AppColors.secondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ref.watch(groupMembersProvider(activeGroup.id)).when(
                          data: (members) => ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: members.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              return GroupMemberTile(member: members[index]);
                            },
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Text('${localizations.errorGeneric}: $err'),
                        ),
                  ] else ...[
                    // Empty state when no active group
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60.0),
                        child: Column(
                          children: [
                            Icon(Icons.house_outlined, size: 64, color: AppColors.secondary.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(
                              localizations.hub_no_group_joined,
                              style: AppTypography.bodyLg.copyWith(color: AppColors.secondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Actions grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      InkWell(
                        onTap: () => _showCreateGroupDialog(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF141414),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_home, color: AppColors.primary),
                              const SizedBox(height: 8),
                              Text(
                                localizations.hub_create_group_button,
                                style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _showJoinGroupDialog(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF141414),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.group_add, color: AppColors.primary),
                              const SizedBox(height: 8),
                              Text(
                                localizations.hub_join_group_button,
                                style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80), // bottom nav spacer
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
