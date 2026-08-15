import 'package:flutter/material.dart';
import 'package:kap_app_front/features/groups/presentation/providers/group_members_provider.dart';
import 'package:kap_app_front/shared/theme/app_colors.dart';
import 'package:kap_app_front/shared/theme/app_typography.dart';

class GroupMemberTile extends StatelessWidget {
  final GroupMemberWithProfile member;

  const GroupMemberTile({
    super.key,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              member.user.displayName.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            member.user.displayName,
            style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
