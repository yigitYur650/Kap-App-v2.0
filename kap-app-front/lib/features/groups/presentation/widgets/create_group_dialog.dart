import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kap_app_front/features/groups/presentation/providers/user_groups_provider.dart';
import 'package:kap_app_front/features/groups/data/group_repository_provider.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';
import 'package:kap_app_front/shared/theme/app_colors.dart';
import 'package:kap_app_front/shared/theme/app_typography.dart';

class CreateGroupDialog extends ConsumerStatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  ConsumerState<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<CreateGroupDialog> {
  final _groupNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) return;
    
    setState(() => _isLoading = true);
    final repo = ref.read(groupRepositoryProvider);
    final result = await repo.createGroup(
      name: name,
    );

    if (!mounted) return;
    final localizations = AppLocalizations.of(context)!;

    result.fold(
      (failure) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: AppColors.primary),
        );
      },
      (group) {
        ref.invalidate(userGroupsProvider);
        setState(() => _isLoading = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.group_create_success), backgroundColor: Colors.teal),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(localizations.group_create_title, style: AppTypography.headlineMd),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _groupNameController,
            style: AppTypography.bodyLg,
            decoration: InputDecoration(
              hintText: localizations.group_create_name_hint,
              hintStyle: TextStyle(color: AppColors.secondary.withValues(alpha: 0.4)),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.dialog_cancel, style: const TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createGroup,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(localizations.dialog_create, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
