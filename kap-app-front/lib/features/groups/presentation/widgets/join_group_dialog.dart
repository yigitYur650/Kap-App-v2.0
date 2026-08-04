import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kap_app_front/features/groups/presentation/providers/user_groups_provider.dart';
import 'package:kap_app_front/features/groups/data/group_repository_provider.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';
import 'package:kap_app_front/shared/theme/app_colors.dart';
import 'package:kap_app_front/shared/theme/app_typography.dart';

class JoinGroupDialog extends ConsumerStatefulWidget {
  const JoinGroupDialog({super.key});

  @override
  ConsumerState<JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends ConsumerState<JoinGroupDialog> {
  final _joinCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    final code = _joinCodeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    final repo = ref.read(groupRepositoryProvider);
    final result = await repo.joinGroup(
      joinCode: code.toLowerCase(),
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
      (_) {
        ref.invalidate(userGroupsProvider);
        setState(() => _isLoading = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.group_join_success), backgroundColor: Colors.teal),
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
      title: Text(localizations.group_join_title, style: AppTypography.headlineMd),
      content: TextField(
        controller: _joinCodeController,
        style: AppTypography.bodyLg,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          hintText: localizations.group_join_code_hint,
          hintStyle: TextStyle(color: AppColors.secondary.withOpacity(0.4)),
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.dialog_cancel, style: const TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _joinGroup,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(localizations.dialog_join, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
