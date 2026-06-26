import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';
import 'package:kap_app_front/shared/theme/app_shapes.dart';
import '../models/confirmed_password_input.dart';
import '../models/email_input.dart';
import '../models/password_input.dart';
import '../providers/register_controller.dart';

/// Screen representing the Material 3 Registration Form.
class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(registerControllerProvider);
    final controller = ref.read(registerControllerProvider.notifier);

    final isSubmitting = state.status == FormzSubmissionStatus.inProgress;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.auth_register_title),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BlobPainter(
                color: Theme.of(context).colorScheme.primary,
                opacity: 0.08,
                scale: 1.3,
                offset: const Offset(-60, -120),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: BlobPainter(
                color: Theme.of(context).colorScheme.secondary,
                opacity: 0.06,
                scale: 1.1,
                offset: const Offset(80, 140),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.auth_register_title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Display Name Input Field
                      TextFormField(
                        key: const Key('registerForm_displayNameInput_textField'),
                        decoration: InputDecoration(
                          labelText: l10n.auth_register_display_name_label,
                          prefixIcon: const Icon(Icons.person),
                          errorText: state.displayName.displayError != null
                              ? l10n.auth_display_name_empty
                              : null,
                        ),
                        onChanged: controller.displayNameChanged,
                        enabled: !isSubmitting,
                      ),
                      const SizedBox(height: 16),

                      // Email Input Field
                      TextFormField(
                        key: const Key('registerForm_emailInput_textField'),
                        decoration: InputDecoration(
                          labelText: l10n.auth_register_email_label,
                          prefixIcon: const Icon(Icons.email),
                          errorText: state.email.displayError != null
                              ? (state.email.error == EmailValidationError.empty
                                  ? l10n.auth_email_empty
                                  : l10n.auth_email_invalid)
                              : null,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: controller.emailChanged,
                        enabled: !isSubmitting,
                      ),
                      const SizedBox(height: 16),

                      // Password Input Field
                      TextFormField(
                        key: const Key('registerForm_passwordInput_textField'),
                        decoration: InputDecoration(
                          labelText: l10n.auth_register_password_label,
                          prefixIcon: const Icon(Icons.lock),
                          errorText: state.password.displayError != null
                              ? (state.password.error == PasswordValidationError.empty
                                  ? l10n.auth_password_empty
                                  : l10n.auth_password_too_short)
                              : null,
                        ),
                        obscureText: true,
                        onChanged: controller.passwordChanged,
                        enabled: !isSubmitting,
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Input Field
                      TextFormField(
                        key: const Key('registerForm_confirmPasswordInput_textField'),
                        decoration: InputDecoration(
                          labelText: l10n.auth_register_confirm_password_label,
                          prefixIcon: const Icon(Icons.lock_outline),
                          errorText: state.confirmPassword.displayError != null
                              ? (state.confirmPassword.error == ConfirmedPasswordValidationError.empty
                                  ? l10n.auth_password_empty
                                  : l10n.auth_password_mismatch)
                              : null,
                        ),
                        obscureText: true,
                        onChanged: controller.confirmPasswordChanged,
                        enabled: !isSubmitting,
                      ),
                      const SizedBox(height: 24),

                      // Submission error status message
                      if (state.errorMessage != null) ...[
                        Text(
                          state.errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Register submit button (with state-driven loading indicator)
                      ElevatedButton(
                        key: const Key('registerForm_continue_elevatedButton'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSubmitting ? null : controller.submit,
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.auth_register_button),
                      ),
                      const SizedBox(height: 16),

                      // Link back to Login Screen
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.auth_register_login_prompt),
                          TextButton(
                            onPressed: isSubmitting
                                ? null
                                : () => context.go('/login'),
                            child: Text(l10n.auth_register_login_link),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

