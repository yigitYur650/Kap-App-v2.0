import 'package:formz/formz.dart';
import '../models/email_input.dart';
import '../models/password_input.dart';

/// Immutable state class for the login form and its inputs.
class LoginState {
  final EmailInput email;
  final PasswordInput password;
  final FormzSubmissionStatus status;
  final String? errorMessage;

  const LoginState({
    this.email = const EmailInput.pure(),
    this.password = const PasswordInput.pure(),
    this.status = FormzSubmissionStatus.initial,
    this.errorMessage,
  });

  LoginState copyWith({
    EmailInput? email,
    PasswordInput? password,
    FormzSubmissionStatus? status,
    String? errorMessage,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}
