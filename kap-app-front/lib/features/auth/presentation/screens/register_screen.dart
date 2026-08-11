import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:kap_app_front/features/auth/presentation/providers/register_controller.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';
import 'package:kap_app_front/shared/theme/app_colors.dart';
import 'package:kap_app_front/shared/theme/app_shapes.dart';
import 'package:kap_app_front/shared/theme/app_typography.dart';
import 'package:kap_app_front/shared/widgets/kap_app_brand_logo.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerControllerProvider);
    final controller = ref.read(registerControllerProvider.notifier);
    final localizations = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    ref.listen(registerControllerProvider, (previous, next) {
      if (next.status == FormzSubmissionStatus.failure && next.errorMessage != null) {
        if (next.errorMessage!.startsWith('2FA_REQUIRED:')) {
          final email = next.errorMessage!.replaceFirst('2FA_REQUIRED:', '');
          context.go('/verify-otp', extra: email);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -size.height * 0.1,
            left: -size.width * 0.1,
            width: size.width * 0.5,
            height: size.height * 0.5,
            child: CustomPaint(
              painter: BlobPainter(
                color: AppColors.primary,
                opacity: 0.1,
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            right: -size.width * 0.1,
            width: size.width * 0.5,
            height: size.height * 0.5,
            child: CustomPaint(
              painter: BlobPainter(
                color: AppColors.primary,
                opacity: 0.1,
              ),
            ),
          ),

          // Scrollable Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Modern App Title / Branding
                  const KapAppBrandLogo(),
                  const SizedBox(height: 32),

                  // Glassmorphic Card
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414).withOpacity(0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.auth_register_title,
                          style: AppTypography.headlineLg,
                        ),
                        const SizedBox(height: 24),

                        // Error Message
                        if (registerState.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    registerState.errorMessage!,
                                    style: AppTypography.bodyMd.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Display Name Input
                        TextField(
                          onChanged: controller.displayNameChanged,
                          style: AppTypography.bodyLg,
                          decoration: InputDecoration(
                            hintText: localizations.auth_register_display_name_label,
                            hintStyle: AppTypography.bodyLg.copyWith(
                              color: AppColors.secondary.withOpacity(0.4),
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: AppColors.secondary.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
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
                            errorText: registerState.displayName.displayError != null
                                ? localizations.auth_display_name_empty
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email Input
                        TextField(
                          keyboardType: TextInputType.emailAddress,
                          onChanged: controller.emailChanged,
                          style: AppTypography.bodyLg,
                          decoration: InputDecoration(
                            hintText: localizations.auth_register_email_label,
                            hintStyle: AppTypography.bodyLg.copyWith(
                              color: AppColors.secondary.withOpacity(0.4),
                            ),
                            prefixIcon: Icon(
                              Icons.mail_outline,
                              color: AppColors.secondary.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
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
                            errorText: registerState.email.displayError != null
                                ? localizations.auth_email_invalid
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Input
                        TextField(
                          obscureText: _obscurePassword,
                          onChanged: controller.passwordChanged,
                          style: AppTypography.bodyLg,
                          decoration: InputDecoration(
                            hintText: localizations.auth_register_password_label,
                            hintStyle: AppTypography.bodyLg.copyWith(
                              color: AppColors.secondary.withOpacity(0.4),
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: AppColors.secondary.withOpacity(0.5),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: AppColors.secondary.withOpacity(0.5),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
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
                            errorText: registerState.password.displayError != null
                                ? localizations.auth_password_too_short
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Input
                        TextField(
                          obscureText: _obscureConfirmPassword,
                          onChanged: controller.confirmPasswordChanged,
                          style: AppTypography.bodyLg,
                          decoration: InputDecoration(
                            hintText: localizations.auth_register_confirm_password_label,
                            hintStyle: AppTypography.bodyLg.copyWith(
                              color: AppColors.secondary.withOpacity(0.4),
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: AppColors.secondary.withOpacity(0.5),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: AppColors.secondary.withOpacity(0.5),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
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
                            errorText: registerState.confirmPassword.displayError != null
                                ? localizations.auth_password_mismatch
                                : null,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: registerState.status.isInProgress
                                ? null
                                : () => controller.submit(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primary.withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 8,
                              shadowColor: AppColors.primary.withOpacity(0.4),
                            ),
                            child: registerState.status.isInProgress
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    localizations.auth_register_button,
                                    style: AppTypography.headlineMd.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Link
                        Row(
                          children: [
                            Text(
                              '${localizations.auth_register_login_prompt} ',
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.secondary.withOpacity(0.4),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: Text(
                                localizations.auth_register_login_link,
                                style: AppTypography.bodyMd.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
