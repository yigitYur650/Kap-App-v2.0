import 'package:formz/formz.dart';

/// Validation errors for [ConfirmedPasswordInput].
enum ConfirmedPasswordValidationError { empty, mismatch }

/// Formz input model for confirm password validation.
class ConfirmedPasswordInput extends FormzInput<String, ConfirmedPasswordValidationError> {
  final String originalPassword;

  const ConfirmedPasswordInput.pure({this.originalPassword = ''}) : super.pure('');
  const ConfirmedPasswordInput.dirty({required this.originalPassword, String value = ''}) : super.dirty(value);

  @override
  ConfirmedPasswordValidationError? validator(String value) {
    if (value.isEmpty) return ConfirmedPasswordValidationError.empty;
    if (value != originalPassword) return ConfirmedPasswordValidationError.mismatch;
    return null;
  }
}
