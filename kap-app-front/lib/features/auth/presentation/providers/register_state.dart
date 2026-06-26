import 'package:formz/formz.dart';
import '../models/confirmed_password_input.dart';
import '../models/display_name_input.dart';
import '../models/email_input.dart';
import '../models/password_input.dart';

/// Immutable state class for the registration form and its inputs.
class RegisterState {
  final DisplayNameInput displayName;
  final EmailInput email;
  final PasswordInput password;
  final ConfirmedPasswordInput confirmPassword;
  final FormzSubmissionStatus status;
  final String? errorMessage;

  const RegisterState({
    this.displayName = const DisplayNameInput.pure(),
    this.email = const EmailInput.pure(),
    this.password = const PasswordInput.pure(),
    this.confirmPassword = const ConfirmedPasswordInput.pure(),
    this.status = FormzSubmissionStatus.initial,
    this.errorMessage,
  });

  RegisterState copyWith({
    DisplayNameInput? displayName,
    EmailInput? email,
    PasswordInput? password,
    ConfirmedPasswordInput? confirmPassword,
    FormzSubmissionStatus? status,
    String? errorMessage,
  }) {
    return RegisterState(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}
