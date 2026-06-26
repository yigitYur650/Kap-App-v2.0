import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import '../../providers/auth_repository_provider.dart';
import '../models/confirmed_password_input.dart';
import '../models/display_name_input.dart';
import '../models/email_input.dart';
import '../models/password_input.dart';
import 'auth_provider.dart';
import 'register_state.dart';

/// Controller for orchestrating the registration form interactions and states.
class RegisterController extends Notifier<RegisterState> {
  @override
  RegisterState build() {
    return const RegisterState();
  }

  /// Handles display name text input updates.
  void displayNameChanged(String value) {
    state = state.copyWith(
      displayName: DisplayNameInput.dirty(value),
      status: FormzSubmissionStatus.initial,
    );
  }

  /// Handles email text input updates.
  void emailChanged(String value) {
    state = state.copyWith(
      email: EmailInput.dirty(value),
      status: FormzSubmissionStatus.initial,
    );
  }

  /// Handles password text input updates and re-evaluates the confirm password validation.
  void passwordChanged(String value) {
    final password = PasswordInput.dirty(value);
    final confirmPassword = ConfirmedPasswordInput.dirty(
      originalPassword: password.value,
      value: state.confirmPassword.value,
    );
    state = state.copyWith(
      password: password,
      confirmPassword: confirmPassword,
      status: FormzSubmissionStatus.initial,
    );
  }

  /// Handles confirm password text input updates.
  void confirmPasswordChanged(String value) {
    state = state.copyWith(
      confirmPassword: ConfirmedPasswordInput.dirty(
        originalPassword: state.password.value,
        value: value,
      ),
      status: FormzSubmissionStatus.initial,
    );
  }

  /// Submits the registration form data to create a new user profile.
  Future<void> submit() async {
    final displayName = DisplayNameInput.dirty(state.displayName.value);
    final email = EmailInput.dirty(state.email.value);
    final password = PasswordInput.dirty(state.password.value);
    final confirmPassword = ConfirmedPasswordInput.dirty(
      originalPassword: password.value,
      value: state.confirmPassword.value,
    );

    final isValid = Formz.validate([displayName, email, password, confirmPassword]);
    if (!isValid) {
      state = state.copyWith(
        displayName: displayName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        status: FormzSubmissionStatus.failure,
      );
      return;
    }

    state = state.copyWith(status: FormzSubmissionStatus.inProgress);

    final authRepository = ref.read(authRepositoryProvider);
    final authNotifier = ref.read(authProvider.notifier);

    final result = await authRepository.registerUser(
      email: email.value,
      password: password.value,
      displayName: displayName.value,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: FormzSubmissionStatus.failure,
          errorMessage: failure.message,
        );
      },
      (user) {
        state = state.copyWith(status: FormzSubmissionStatus.success);
        authNotifier.updateState(user);
      },
    );
  }
}

/// Provider to access and interact with the Auto-Disposable [RegisterController].
final registerControllerProvider = NotifierProvider.autoDispose<RegisterController, RegisterState>(() {
  return RegisterController();
});
