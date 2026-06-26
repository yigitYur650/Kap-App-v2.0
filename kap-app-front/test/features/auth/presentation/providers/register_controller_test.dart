import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formz/formz.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kap_app_front/core/errors/failure.dart';
import 'package:kap_app_front/core/models/app_user.dart';
import 'package:kap_app_front/core/repositories/auth_repository.dart';
import 'package:kap_app_front/features/auth/providers/auth_repository_provider.dart';
import 'package:kap_app_front/features/auth/presentation/providers/auth_provider.dart';
import 'package:kap_app_front/features/auth/presentation/providers/register_controller.dart';
import 'package:kap_app_front/features/auth/presentation/models/confirmed_password_input.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// Fake AuthNotifier that records updateState calls without touching Supabase.
class FakeAuthNotifier extends AuthNotifier {
  @override
  FutureOr<AppUser?> build() async => null;

  @override
  void updateState(AppUser? user) {
    state = AsyncValue.data(user);
  }

  @override
  Future<void> signOut() async {
    state = const AsyncValue.data(null);
  }
}

void main() {
  late MockAuthRepository mockAuthRepository;

  const tDisplayName = 'Test User';
  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tAppUser = AppUser(
    id: 'user-1',
    displayName: tDisplayName,
    uniqueCode: 'ABCD-EFGH',
    email: tEmail,
    emailVerified: false,
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        authProvider.overrideWith(() => FakeAuthNotifier()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Helper: fill all fields with valid data.
  void fillValidForm(ProviderContainer container) {
    final notifier = container.read(registerControllerProvider.notifier);
    notifier.displayNameChanged(tDisplayName);
    notifier.emailChanged(tEmail);
    notifier.passwordChanged(tPassword);
    notifier.confirmPasswordChanged(tPassword);
  }

  group('RegisterController', () {
    group('field changes', () {
      test('displayNameChanged updates displayName field and resets status', () {
        final container = createContainer();
        container.read(registerControllerProvider.notifier).displayNameChanged(tDisplayName);

        final state = container.read(registerControllerProvider);
        expect(state.displayName.value, tDisplayName);
        expect(state.status, FormzSubmissionStatus.initial);
      });

      test('emailChanged updates email field and resets status', () {
        final container = createContainer();
        container.read(registerControllerProvider.notifier).emailChanged(tEmail);

        final state = container.read(registerControllerProvider);
        expect(state.email.value, tEmail);
        expect(state.status, FormzSubmissionStatus.initial);
      });

      test('passwordChanged updates password and re-evaluates confirmPassword (mismatch case)', () {
        final container = createContainer();
        final notifier = container.read(registerControllerProvider.notifier);

        // Set confirm first, then change password to something different
        notifier.confirmPasswordChanged('abc123');
        notifier.passwordChanged('differentpass');

        final state = container.read(registerControllerProvider);
        // confirmPassword should now be re-evaluated: 'abc123' != 'differentpass'
        expect(
          state.confirmPassword.error,
          ConfirmedPasswordValidationError.mismatch,
        );
      });

      test('passwordChanged re-evaluates confirmPassword — becomes valid when they match', () {
        final container = createContainer();
        final notifier = container.read(registerControllerProvider.notifier);

        notifier.confirmPasswordChanged(tPassword);
        notifier.passwordChanged(tPassword);

        final state = container.read(registerControllerProvider);
        expect(state.confirmPassword.isValid, true);
      });
    });

    group('submit', () {
      test('should set failure and NOT call registerUser when all fields are empty', () async {
        final container = createContainer();
        await container.read(registerControllerProvider.notifier).submit();

        final state = container.read(registerControllerProvider);
        expect(state.status, FormzSubmissionStatus.failure);
        verifyNever(() => mockAuthRepository.registerUser(
              email: any(named: 'email'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            ));
      });

      test('should set failure and NOT call registerUser when passwords do not match', () async {
        final container = createContainer();
        final notifier = container.read(registerControllerProvider.notifier);

        notifier.displayNameChanged(tDisplayName);
        notifier.emailChanged(tEmail);
        notifier.passwordChanged(tPassword);
        notifier.confirmPasswordChanged('differentpassword');

        await notifier.submit();

        final state = container.read(registerControllerProvider);
        expect(state.status, FormzSubmissionStatus.failure);
        verifyNever(() => mockAuthRepository.registerUser(
              email: any(named: 'email'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            ));
      });

      test('should set failure and NOT call registerUser when email is invalid', () async {
        final container = createContainer();
        final notifier = container.read(registerControllerProvider.notifier);

        notifier.displayNameChanged(tDisplayName);
        notifier.emailChanged('invalid-email');
        notifier.passwordChanged(tPassword);
        notifier.confirmPasswordChanged(tPassword);

        await notifier.submit();

        final state = container.read(registerControllerProvider);
        expect(state.status, FormzSubmissionStatus.failure);
        verifyNever(() => mockAuthRepository.registerUser(
              email: any(named: 'email'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            ));
      });

      test('should set success status and call authNotifier.updateState on Right(AppUser)', () async {
        when(() => mockAuthRepository.registerUser(
              email: tEmail,
              password: tPassword,
              displayName: tDisplayName,
            )).thenAnswer((_) async => const Right(tAppUser));

        final container = createContainer();
        fillValidForm(container);
        await container.read(registerControllerProvider.notifier).submit();

        final state = container.read(registerControllerProvider);
        expect(state.status, FormzSubmissionStatus.success);

        verify(() => mockAuthRepository.registerUser(
              email: tEmail,
              password: tPassword,
              displayName: tDisplayName,
            )).called(1);

        final authState = container.read(authProvider);
        expect(authState.value, tAppUser);
      });

      test('should set failure status and errorMessage on Left(EmailAlreadyInUseFailure)', () async {
        when(() => mockAuthRepository.registerUser(
              email: tEmail,
              password: tPassword,
              displayName: tDisplayName,
            )).thenAnswer((_) async => const Left(EmailAlreadyInUseFailure()));

        final container = createContainer();
        fillValidForm(container);
        await container.read(registerControllerProvider.notifier).submit();

        final state = container.read(registerControllerProvider);
        expect(state.status, FormzSubmissionStatus.failure);
        expect(state.errorMessage, isNotNull);
        expect(state.errorMessage, contains('already in use'));
      });

      test('should set failure status and errorMessage on Left(NetworkFailure)', () async {
        when(() => mockAuthRepository.registerUser(
              email: tEmail,
              password: tPassword,
              displayName: tDisplayName,
            )).thenAnswer((_) async => const Left(NetworkFailure()));

        final container = createContainer();
        fillValidForm(container);
        await container.read(registerControllerProvider.notifier).submit();

        final state = container.read(registerControllerProvider);
        expect(state.status, FormzSubmissionStatus.failure);
        expect(state.errorMessage, isNotNull);
      });
    });
  });
}
