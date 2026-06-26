import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/models/request_model.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../groups/presentation/providers/group_members_provider.dart';
import '../providers/request_controller.dart';

/// A Material 3 bottom sheet for adding a new shopping request.
/// Includes support for private requests with a member picker excluding the current user.
class AddRequestBottomSheet extends ConsumerStatefulWidget {
  const AddRequestBottomSheet({super.key});

  @override
  ConsumerState<AddRequestBottomSheet> createState() => _AddRequestBottomSheetState();
}

class _AddRequestBottomSheetState extends ConsumerState<AddRequestBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  bool _isPrivate = false;
  String? _selectedMemberId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _itemNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final activeGroup = ref.read(activeGroupProvider);
    if (activeGroup == null) return;

    if (_isPrivate && _selectedMemberId == null) {
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.add_request_private_recipient_required),
          ),
        );
      }
      return;
    }

    final trimmedName = _itemNameController.text.trim();
    if (trimmedName.isEmpty) return;

    setState(() => _isSubmitting = true);

    await ref.read(requestControllerProvider.notifier).createRequest(
          itemName: trimmedName,
          isPrivate: _isPrivate,
          privateTo: _isPrivate ? _selectedMemberId : null,
        );

    final hasError = ref.read(requestControllerProvider).hasError;
    if (!hasError && mounted) {
      Navigator.of(context).pop();
    }
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeGroup = ref.watch(activeGroupProvider);
    final authUser = ref.watch(authProvider).value;

    ref.listen<AsyncValue<List<RequestModel>>>(
      requestControllerProvider,
      (previous, next) {
        if (next.hasError) {
          setState(() => _isSubmitting = false);
        }
      },
    );

    if (activeGroup == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(l10n.shopping_list_no_active_group),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.add_request_title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _itemNameController,
                autofocus: true,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  labelText: l10n.add_request_item_name_label,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.add_request_item_name_empty;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              SwitchListTile(
                title: Text(l10n.add_request_private_label),
                value: _isPrivate,
                onChanged: _isSubmitting
                    ? null
                    : (val) {
                        setState(() {
                          _isPrivate = val;
                          if (!val) {
                            _selectedMemberId = null;
                          }
                        });
                      },
              ),
              if (_isPrivate) ...[
                const SizedBox(height: 8.0),
                Text(
                  l10n.add_request_private_to_label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8.0),
                ref.watch(groupMembersProvider(activeGroup.id)).when(
                      data: (members) {
                        // Member Picker Exclusion Rule: filter out current user (auth.uid())
                        final otherMembers = members
                            .where((m) => m.user.id != authUser?.id)
                            .toList();

                        if (otherMembers.isEmpty) {
                          // Clean localized indicator fallback
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              l10n.shopping_list_no_items, // Use appropriate i18n
                            ),
                          );
                        }

                        // Set default selection if empty
                        if (_selectedMemberId == null && otherMembers.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _selectedMemberId == null) {
                              setState(() {
                                _selectedMemberId = otherMembers.first.user.id;
                              });
                            }
                          });
                        }

                        return Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 50,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: otherMembers.length,
                                itemBuilder: (context, index) {
                                  final member = otherMembers[index];
                                  final isSelected = _selectedMemberId == member.user.id;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      avatar: CircleAvatar(
                                        radius: 12,
                                        child: Text(
                                          member.user.displayName.isNotEmpty
                                              ? member.user.displayName[0].toUpperCase()
                                              : '?',
                                        ),
                                      ),
                                      label: Text(member.user.displayName),
                                      selected: isSelected,
                                      onSelected: _isSubmitting
                                          ? null
                                          : (selected) {
                                              if (selected) {
                                                setState(() {
                                                  _selectedMemberId = member.user.id;
                                                });
                                              }
                                            },
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (_selectedMemberId == null) ...[
                              const SizedBox(height: 8.0),
                              Text(
                                l10n.add_request_private_recipient_required,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, _) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          l10n.errorGeneric,
                        ),
                      ),
                    ),
              ],
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.add_request_cancel_button),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    onPressed: (_isSubmitting || (_isPrivate && _selectedMemberId == null)) ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.add_request_submit_button),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

