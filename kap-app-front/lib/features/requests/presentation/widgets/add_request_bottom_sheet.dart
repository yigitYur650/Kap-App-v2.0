import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kap_app_front/features/groups/presentation/providers/active_group_provider.dart';
import 'package:kap_app_front/features/groups/presentation/providers/group_members_provider.dart';
import 'package:kap_app_front/features/requests/presentation/providers/request_controller.dart';
import 'package:kap_app_front/shared/utils/category_helper.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';
import 'package:kap_app_front/shared/theme/app_colors.dart';
import 'package:kap_app_front/shared/theme/app_typography.dart';

class AddRequestBottomSheet extends ConsumerStatefulWidget {
  const AddRequestBottomSheet({super.key});

  @override
  ConsumerState<AddRequestBottomSheet> createState() => _AddRequestBottomSheetState();
}

class _AddRequestBottomSheetState extends ConsumerState<AddRequestBottomSheet> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  String? _selectedUnit;
  bool _isPrivate = false;
  String? _selectedMemberId;
  bool _isSubmitting = false;

  static const List<String> _unitOptions = [
    'pcs', 'kg', 'g', 'L', 'mL', 'tsp', 'tbsp', 'cup',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final itemName = _nameController.text.trim();
    if (itemName.isEmpty) return;

    if (_isPrivate && _selectedMemberId == null) {
      final localizations = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.add_request_private_recipient_required),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ref.read(requestControllerProvider.notifier).createRequest(
          itemName: itemName,
          isPrivate: _isPrivate,
          privateTo: _selectedMemberId,
          quantity: _quantityController.text.trim().isNotEmpty
              ? _quantityController.text.trim()
              : null,
          unit: _selectedUnit,
        );

    if (mounted) {
      result.fold(
        (failure) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.primary,
            ),
          );
        },
        (_) {
          Navigator.of(context).pop();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final localizations = AppLocalizations.of(context)!;

    if (activeGroup == null) {
      return const SizedBox.shrink();
    }

    final membersAsync = ref.watch(groupMembersProvider(activeGroup.id));

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomPadding + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(
            color: Color(0xFF242424),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF555555),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            localizations.add_request_title,
            style: AppTypography.headlineLg,
          ),
          const SizedBox(height: 20),

          // Name Input
          TextField(
            controller: _nameController,
            style: AppTypography.bodyLg,
            autofocus: true,
            decoration: InputDecoration(
              hintText: localizations.add_request_item_name_hint,
              hintStyle: TextStyle(
                color: AppColors.secondary.withOpacity(0.4),
              ),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF2A2A2A),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          if (_nameController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.label_outlined, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('Otomatik Kategori: ', style: AppTypography.labelSm.copyWith(color: AppColors.textMuted)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    CategoryHelper.detectCategory(_nameController.text),
                    style: AppTypography.labelSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Quantity & Unit Row
          Row(
            children: [
              // Quantity Input
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantityController,
                  style: AppTypography.bodyLg,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: localizations.add_request_quantity_label,
                    hintText: localizations.add_request_quantity_hint,
                    hintStyle: TextStyle(
                      color: AppColors.secondary.withOpacity(0.4),
                    ),
                    labelStyle: TextStyle(
                      color: AppColors.secondary.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF2A2A2A),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Unit Dropdown
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF2A2A2A),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedUnit,
                      isExpanded: true,
                      hint: Text(
                        localizations.add_request_unit_label,
                        style: TextStyle(
                          color: AppColors.secondary.withOpacity(0.4),
                          fontSize: 14,
                        ),
                      ),
                      dropdownColor: const Color(0xFF141414),
                      style: AppTypography.bodyLg,
                      items: _unitOptions.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedUnit = val;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Private Toggle Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: AppColors.secondary.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    localizations.request_card_private_label,
                    style: AppTypography.bodyLg,
                  ),
                ],
              ),
              Switch(
                value: _isPrivate,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() {
                    _isPrivate = val;
                    if (!val) {
                      _selectedMemberId = null;
                    }
                  });
                },
              ),
            ],
          ),

          // Member Picker dropdown if private is active
          if (_isPrivate) ...[
            const SizedBox(height: 16),
            membersAsync.when(
              data: (members) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF2A2A2A),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMemberId,
                      hint: Text(
                        localizations.add_request_private_to_label,
                        style: TextStyle(
                          color: AppColors.secondary.withOpacity(0.4),
                        ),
                      ),
                      dropdownColor: const Color(0xFF141414),
                      style: AppTypography.bodyLg,
                      isExpanded: true,
                      items: members.map((m) {
                        return DropdownMenuItem<String>(
                          value: m.user.id,
                          child: Text(m.user.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedMemberId = val;
                        });
                      },
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Text('${localizations.errorGeneric}: $err'),
            ),
          ],
          const SizedBox(height: 24),

          // Submit / Add Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      localizations.add_request_submit_button,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          // Bottom safe area padding to prevent overlap with navigation bar
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16.0,
          ),
        ],
      ),
    );
  }
}
