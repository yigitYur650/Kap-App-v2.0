import 'package:flutter_test/flutter_test.dart';
import 'package:kap_app_front/features/auth/presentation/models/email_input.dart';
import 'package:kap_app_front/features/auth/presentation/models/password_input.dart';
import 'package:kap_app_front/features/auth/presentation/models/confirmed_password_input.dart';
import 'package:kap_app_front/features/auth/presentation/models/display_name_input.dart';

void main() {
  group('EmailInput', () {
    test('pure() should not be dirty and isPure should be true', () {
      const input = EmailInput.pure();
      expect(input.isPure, true);
    });

    test('dirty with empty string should return empty error', () {
      const input = EmailInput.dirty('');
      expect(input.error, EmailValidationError.empty);
      expect(input.isValid, false);
    });

    test('dirty with whitespace-only should return empty error', () {
      const input = EmailInput.dirty('   ');
      expect(input.error, EmailValidationError.empty);
      expect(input.isValid, false);
    });

    test('dirty with invalid format (no @) should return invalid error', () {
      const input = EmailInput.dirty('notanemail');
      expect(input.error, EmailValidationError.invalid);
      expect(input.isValid, false);
    });

    test('dirty with missing domain should return invalid error', () {
      const input = EmailInput.dirty('user@');
      expect(input.error, EmailValidationError.invalid);
      expect(input.isValid, false);
    });

    test('dirty with valid email should return no error', () {
      const input = EmailInput.dirty('test@example.com');
      expect(input.error, isNull);
      expect(input.isValid, true);
    });

    test('dirty with short TLD valid email should return no error', () {
      const input = EmailInput.dirty('a@b.co');
      expect(input.error, isNull);
      expect(input.isValid, true);
    });
  });

  group('PasswordInput', () {
    test('pure() should be pure', () {
      const input = PasswordInput.pure();
      expect(input.isPure, true);
    });

    test('dirty with empty string should return empty error', () {
      const input = PasswordInput.dirty('');
      expect(input.error, PasswordValidationError.empty);
      expect(input.isValid, false);
    });

    test('dirty with 5 characters should return tooShort error', () {
      const input = PasswordInput.dirty('12345');
      expect(input.error, PasswordValidationError.tooShort);
      expect(input.isValid, false);
    });

    test('dirty with exactly 6 characters should be valid (lower boundary)', () {
      const input = PasswordInput.dirty('123456');
      expect(input.error, isNull);
      expect(input.isValid, true);
    });

    test('dirty with long password should be valid', () {
      const input = PasswordInput.dirty('supersecurepassword123!');
      expect(input.error, isNull);
      expect(input.isValid, true);
    });
  });

  group('ConfirmedPasswordInput', () {
    test('pure() should be pure', () {
      const input = ConfirmedPasswordInput.pure();
      expect(input.isPure, true);
    });

    test('dirty with empty value should return empty error', () {
      const input = ConfirmedPasswordInput.dirty(
        originalPassword: 'abc123',
        value: '',
      );
      expect(input.error, ConfirmedPasswordValidationError.empty);
      expect(input.isValid, false);
    });

    test('dirty with mismatching value should return mismatch error', () {
      const input = ConfirmedPasswordInput.dirty(
        originalPassword: 'abc123',
        value: 'xyz789',
      );
      expect(input.error, ConfirmedPasswordValidationError.mismatch);
      expect(input.isValid, false);
    });

    test('dirty with matching value should return no error', () {
      const input = ConfirmedPasswordInput.dirty(
        originalPassword: 'abc123',
        value: 'abc123',
      );
      expect(input.error, isNull);
      expect(input.isValid, true);
    });

    test('dirty is case-sensitive: different casing should return mismatch error', () {
      const input = ConfirmedPasswordInput.dirty(
        originalPassword: 'Password',
        value: 'password',
      );
      expect(input.error, ConfirmedPasswordValidationError.mismatch);
      expect(input.isValid, false);
    });
  });

  group('DisplayNameInput', () {
    test('pure() should be pure', () {
      const input = DisplayNameInput.pure();
      expect(input.isPure, true);
    });

    test('dirty with empty string should return empty error', () {
      const input = DisplayNameInput.dirty('');
      expect(input.error, DisplayNameValidationError.empty);
      expect(input.isValid, false);
    });

    test('dirty with whitespace-only should return empty error (trim applied)', () {
      const input = DisplayNameInput.dirty('   ');
      expect(input.error, DisplayNameValidationError.empty);
      expect(input.isValid, false);
    });

    // NOTE: The validator only checks trim().isEmpty — no minimum character count enforced.
    // A single non-whitespace character is considered valid per current implementation.
    // This is intentional behavior documented here for future reference.
    test('dirty with single character should be valid (no minimum length enforced)', () {
      const input = DisplayNameInput.dirty('A');
      expect(input.error, isNull);
      expect(input.isValid, true);
    });

    test('dirty with a normal display name should be valid', () {
      const input = DisplayNameInput.dirty('Test User');
      expect(input.error, isNull);
      expect(input.isValid, true);
    });

    test('dirty with leading/trailing spaces but non-empty core should be valid', () {
      const input = DisplayNameInput.dirty('  Alice  ');
      expect(input.error, isNull); // trim() leaves 'Alice'
      expect(input.isValid, true);
    });
  });
}
