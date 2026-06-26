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
import 'package:kap_app_front/features/auth/presentation/providers/login_controller.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// Fake AuthNotifier that records updateState calls without touching Supabase.
class FakeAuthNotifier extends AuthNotifier {
  AppUser? lastUpdatedUser;

  @override
  FutureOr<AppUser?> build() async => null;

  @override
  void updateState(AppUser? user) {
    lastUpdatedUser = user;
    state = AsyncValue.data(user);
  }

  @override
  Future<void> signOut() async {
    state = const AsyncValue.data(null);
  }
}

void main() {
  late MockAuthRepository mockAuthRepository;

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tAppUser = AppUser(
    id: 'user-1',
    displayName: 'Test User',
    uniqueCode: 'ABCD-EFGH',
    email: tEmail,
    emailVerified: false,
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  ProviderContainer createContainer() {
    final fakeAuthNotifier = FakeAuthNotifier();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        authProvider.overrideWith(() => fakeAuthNotifier),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('LoginController', () {
    group('emailChanged', () {
      test('updates email field and resets status to initial', () {
        final container = createContainer();
        container.read(loginControllerProvider.notifier).emailChanged(tEmail);

        final state = container.read(loginControllerProvider);
        expect(state.email.value, tEmail);
        expect(state.status, FormzSubmissionStatus.initial);
      });
    });

    group('passwordChanged', () {
      test('updates password field and resets status to initial', () {
        final container = createContainer();
        container.read(loginControllerProvider.notifier).passwordChanged(tPassword);

        final state = container.read(loginControllerProvider);
        expect(state.password.value, tPassword);
        expect(state.status, FormzSubmissionStatus.initial);
      });
    });

    group('submit', () {
      test('should set failure status and NOT call loginUser when email is empty', () async {
        final container = createContainer();

        container.read(loginControllerProvider.notifier).passwordChanged(tPassword);
        await container.read(loginControllerProvider.notifier).submit();

        final state = container.read(loginControllerProvider);
        expect(state.status, FormzSubmissionStatus.failure);
        verifyNever(() => mockAuthRepository.loginUser(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ));
      });

      test('should set failure status and NOT call loginUser when password is too short', () async {
        final container = createContainer();

        container.read(loginControllerProvider.notifier).emailChanged(tEmail);
        container.read(loginControllerProvider.notifier).passwordChanged('12345');
        await container.read(loginControllerProvider.notifier).submit();

        final state = container.read(loginControllerProvider);
        expect(state.status, FormzSubmissionStatus.failure);
        verifyNever(() => mockAuthRepository.loginUser(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ));
      });

      test('should set failure status and NOT call loginUser when email is invalid', () async {
        final container = createContainer();

        container.read(loginControllerProvider.notifier).emailChanged('notvalid');
        container.read(loginControllerProvider.notifier).passwordChanged(tPassword);
        await container.read(loginControllerProvider.notifier).submit();

        final state = container.read(loginControllerProvider);
        expect(state.status, FormzSubmissionStatus.failure);
        verifyNever(() => mockAuthRepository.loginUser(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ));
      });

      test('should set success status and call authNotifier.updateState on Right(AppUser)', () async {
        when(() => mockAuthRepository.loginUser(
              email: tEmail,
              password: tPassword,
            )).thenAnswer((_) async => const Right(tAppUser));

        final container = createContainer();
        container.read(loginControllerProvider.notifier).emailChanged(tEmail);
        container.read(loginControllerProvider.notifier).passwordChanged(tPassword);
        await container.read(loginControllerProvider.notifier).submit();

        final state = container.read(loginControllerProvider);
        expect(state.status, FormzSubmissionStatus.success);

        verify(() => mockAuthRepository.loginUser(
              email: tEmail,
              password: tPassword,
            )).called(1);

        // Verify authProvider state was updated
        final authState = container.read(authProvider);
        expect(authState.value, tAppUser);
      });

      test('should set failure status and errorMessage on Left(InvalidCredentialsFailure)', () async {
        when(() => mockAuthRepository.loginUser(
              email: tEmail,
              password: tPassword,
            )).thenAnswer((_) async => const Left(InvalidCredentialsFailure()));

        final container = createContainer();
        container.read(loginControllerProvider.notifier).emailChanged(tEmail);
        container.read(loginControllerProvider.notifier).passwordChanged(tPassword);
        await container.read(loginControllerProvider.notifier).submit();

        final state = container.read(loginControllerProvider);
        expect(state.status, FormzSubmissionStatus.failure);
        expect(state.errorMessage, isNotNull);
        expect(state.errorMessage, contains('Invalid'));
      });

      test('should set failure status and errorMessage on Left(NetworkFailure)', () async {
        when(() => mockAuthRepository.loginUser(
              email: tEmail,
              password: tPassword,
            )).thenAnswer((_) async => const Left(NetworkFailure()));

        final container = createContainer();
        container.read(loginControllerProvider.notifier).emailChanged(tEmail);
        container.read(loginControllerProvider.notifier).passwordChanged(tPassword);
        await container.read(loginControllerProvider.notifier).submit();

        final state = container.read(loginControllerProvider);
        expect(state.status, FormzSubmissionStatus.failure);
        expect(state.errorMessage, isNotNull);
      });

      test('should clear errorMessage and reset status to initial on emailChanged after a failure', () async {
        when(() => mockAuthRepository.loginUser(
              email: tEmail,
              password: tPassword,
            )).thenAnswer((_) async => const Left(InvalidCredentialsFailure()));

        final container = createContainer();
        container.read(loginControllerProvider.notifier).emailChanged(tEmail);
        container.read(loginControllerProvider.notifier).passwordChanged(tPassword);
        await container.read(loginControllerProvider.notifier).submit();

        // Now change the email — status should reset
        container.read(loginControllerProvider.notifier).emailChanged('new@example.com');

        final state = container.read(loginControllerProvider);
        expect(state.status, FormzSubmissionStatus.initial);
      });
    });
  });
}
