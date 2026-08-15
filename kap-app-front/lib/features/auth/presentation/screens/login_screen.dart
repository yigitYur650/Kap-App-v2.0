import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:kap_app_front/features/auth/presentation/providers/login_controller.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';
import 'package:kap_app_front/shared/theme/app_colors.dart';
import 'package:kap_app_front/shared/theme/app_shapes.dart';
import 'package:kap_app_front/shared/theme/app_typography.dart';
import 'package:kap_app_front/shared/widgets/kap_app_brand_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);
    final localizations = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    ref.listen(loginControllerProvider, (previous, next) {
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
                      color: const Color(0xFF141414).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.auth_login_title,
                          style: AppTypography.headlineLg,
                        ),
                        const SizedBox(height: 24),

                        // Error Message
                        if (loginState.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
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
                                    loginState.errorMessage!,
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

                        // Email Input
                        TextField(
                          keyboardType: TextInputType.emailAddress,
                          onChanged: controller.emailChanged,
                          style: AppTypography.bodyLg,
                          decoration: InputDecoration(
                            hintText: localizations.auth_login_email_label,
                            hintStyle: AppTypography.bodyLg.copyWith(
                              color: AppColors.secondary.withValues(alpha: 0.4),
                            ),
                            prefixIcon: Icon(
                              Icons.mail_outline,
                              color: AppColors.secondary.withValues(alpha: 0.5),
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
                            errorText: loginState.email.displayError != null
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
                            hintText: localizations.auth_login_password_label,
                            hintStyle: AppTypography.bodyLg.copyWith(
                              color: AppColors.secondary.withValues(alpha: 0.4),
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: AppColors.secondary.withValues(alpha: 0.5),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: AppColors.secondary.withValues(alpha: 0.5),
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
                            errorText: loginState.password.displayError != null
                                ? localizations.auth_password_too_short
                                : null,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: loginState.status.isInProgress
                                ? null
                                : () => controller.submit(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 8,
                              shadowColor: AppColors.primary.withValues(alpha: 0.4),
                            ),
                            child: loginState.status.isInProgress
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    localizations.auth_login_button,
                                    style: AppTypography.headlineMd.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Helper Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Beni hatırla',
                              style: AppTypography.labelLg.copyWith(
                                color: AppColors.secondary.withValues(alpha: 0.6),
                              ),
                            ),
                            Text(
                              localizations.auth_login_forgot_password,
                              style: AppTypography.labelLg.copyWith(
                                color: AppColors.secondary.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Register Link
                        Row(
                          children: [
                            Text(
                              '${localizations.auth_login_register_prompt} ',
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.secondary.withValues(alpha: 0.4),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/register'),
                              child: Text(
                                localizations.auth_login_register_link,
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
