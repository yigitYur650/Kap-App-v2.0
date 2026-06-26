import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import '../../providers/auth_repository_provider.dart';
import '../models/email_input.dart';
import '../models/password_input.dart';
import 'auth_provider.dart';
import 'login_state.dart';

/// Controller for orchestrating the login form interactions and states.
class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() {
    return const LoginState();
  }

  /// Handles email text input updates.
  void emailChanged(String value) {
    final email = EmailInput.dirty(value);
    state = state.copyWith(
      email: email,
      status: FormzSubmissionStatus.initial,
    );
  }

  /// Handles password text input updates.
  void passwordChanged(String value) {
    final password = PasswordInput.dirty(value);
    state = state.copyWith(
      password: password,
      status: FormzSubmissionStatus.initial,
    );
  }

  /// Submits the form data to authenticate the user.
  Future<void> submit() async {
    final email = EmailInput.dirty(state.email.value);
    final password = PasswordInput.dirty(state.password.value);
    
    final isValid = Formz.validate([email, password]);
    if (!isValid) {
      state = state.copyWith(
        email: email,
        password: password,
        status: FormzSubmissionStatus.failure,
      );
      return;
    }

    state = state.copyWith(status: FormzSubmissionStatus.inProgress);
    
    final authRepository = ref.read(authRepositoryProvider);
    final authNotifier = ref.read(authProvider.notifier);

    final result = await authRepository.loginUser(
      email: email.value,
      password: password.value,
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

/// Provider to access and interact with the Auto-Disposable [LoginController].
final loginControllerProvider = NotifierProvider.autoDispose<LoginController, LoginState>(() {
  return LoginController();
});
