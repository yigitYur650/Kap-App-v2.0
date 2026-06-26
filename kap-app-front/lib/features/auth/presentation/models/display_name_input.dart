import 'package:formz/formz.dart';

/// Validation errors for [DisplayNameInput].
enum DisplayNameValidationError { empty }

/// Formz input model for display name validation.
class DisplayNameInput extends FormzInput<String, DisplayNameValidationError> {
  const DisplayNameInput.pure() : super.pure('');
  const DisplayNameInput.dirty([super.value = '']) : super.dirty();

  @override
  DisplayNameValidationError? validator(String value) {
    return value.trim().isEmpty ? DisplayNameValidationError.empty : null;
  }
}
