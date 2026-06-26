import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kap_app_front/core/errors/failure.dart';
import 'package:kap_app_front/features/auth/data/supabase_auth_repository.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}
class MockAuthResponse extends Mock implements AuthResponse {}
class MockUser extends Mock implements User {}
class MockHttpClient extends Mock implements http.Client {}
class MockSession extends Mock implements Session {}

// Fake PostgrestFilterBuilder to delegate Future behaviors correctly.
class FakePostgrestFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final Future<T> _future;
  FakePostgrestFilterBuilder(this._future);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }
}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockSupabaseQueryBuilder mockSupabaseQueryBuilder;
  late MockPostgrestFilterBuilder mockPostgrestFilterBuilder;
  late MockHttpClient mockHttpClient;
  late MockSession mockSession;
  late SupabaseAuthRepository repository;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockSupabaseQueryBuilder = MockSupabaseQueryBuilder();
    mockPostgrestFilterBuilder = MockPostgrestFilterBuilder();
    mockHttpClient = MockHttpClient();
    mockSession = MockSession();

    repository = SupabaseAuthRepository(
      mockSupabaseClient,
      httpClient: mockHttpClient,
    );

    // Default setups
    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(() => mockSupabaseClient.from(any())).thenAnswer((_) => mockSupabaseQueryBuilder);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tDisplayName = 'Test User';
  const tUserId = 'user-uuid-123';

  group('registerUser', () {
    test('should return Right(AppUser) when signUp and insert succeed', () async {
      // Arrange
      final mockAuthResponse = MockAuthResponse();
      final mockUser = MockUser();
      
      when(() => mockUser.id).thenReturn(tUserId);
      when(() => mockAuthResponse.user).thenReturn(mockUser);
      
      when(() => mockGoTrueClient.signUp(
        email: tEmail,
        password: tPassword,
        data: {'display_name': tDisplayName},
      )).thenAnswer((_) async => mockAuthResponse);

      when(() => mockSession.accessToken).thenReturn('test-jwt-token-abc');
      when(() => mockGoTrueClient.currentSession).thenReturn(mockSession);
      when(() => mockHttpClient.post(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(jsonEncode({'unique_code': 'KAP-ABC12345'}), 200));

      final fakeFilterBuilder = FakePostgrestFilterBuilder(Future.value([]));
      when(() => mockSupabaseQueryBuilder.insert(any())).thenAnswer((_) => fakeFilterBuilder);

      // Act
      final result = await repository.registerUser(
        email: tEmail,
        password: tPassword,
        displayName: tDisplayName,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return Left: $failure'),
        (user) {
          expect(user.id, tUserId);
          expect(user.displayName, tDisplayName);
          expect(user.email, tEmail);
          expect(user.emailVerified, false);
          expect(user.uniqueCode.startsWith('KAP-'), true);
        },
      );

      verify(() => mockGoTrueClient.signUp(
        email: tEmail,
        password: tPassword,
        data: {'display_name': tDisplayName},
      )).called(1);
      
      verify(() => mockSupabaseClient.from('users')).called(1);
      verify(() => mockSupabaseQueryBuilder.insert(any())).called(1);
    });

    test('should return Left(UnknownFailure) when signUp succeeds but user is null', () async {
      // Arrange
      final mockAuthResponse = MockAuthResponse();
      when(() => mockAuthResponse.user).thenReturn(null);
      
      when(() => mockGoTrueClient.signUp(
        email: tEmail,
        password: tPassword,
        data: {'display_name': tDisplayName},
      )).thenAnswer((_) async => mockAuthResponse);

      // Act
      final result = await repository.registerUser(
        email: tEmail,
        password: tPassword,
        displayName: tDisplayName,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(failure.message, contains('User is null'));
        },
        (_) => fail('Should not return Right'),
      );
    });

    test('should return Left(EmailAlreadyInUseFailure) when signUp throws AuthException already registered', () async {
      // Arrange
      when(() => mockGoTrueClient.signUp(
        email: tEmail,
        password: tPassword,
        data: {'display_name': tDisplayName},
      )).thenThrow(const AuthException('User already registered', statusCode: '400'));

      // Act
      final result = await repository.registerUser(
        email: tEmail,
        password: tPassword,
        displayName: tDisplayName,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<EmailAlreadyInUseFailure>()),
        (_) => fail('Should not return Right'),
      );
    });

    test('should return Left(EmailAlreadyInUseFailure) when database insert throws PostgrestException unique violation on email', () async {
      // Arrange
      final mockAuthResponse = MockAuthResponse();
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn(tUserId);
      when(() => mockAuthResponse.user).thenReturn(mockUser);
      
      when(() => mockGoTrueClient.signUp(
        email: tEmail,
        password: tPassword,
        data: {'display_name': tDisplayName},
      )).thenAnswer((_) async => mockAuthResponse);

      when(() => mockSession.accessToken).thenReturn('test-jwt-token-abc');
      when(() => mockGoTrueClient.currentSession).thenReturn(mockSession);
      when(() => mockHttpClient.post(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(jsonEncode({'unique_code': 'KAP-ABC12345'}), 200));

      when(() => mockSupabaseQueryBuilder.insert(any())).thenThrow(
        const PostgrestException(
          message: 'duplicate key value violates unique constraint "users_email_key"',
          code: '23505',
          details: 'Key (email)=(test@example.com) already exists.',
        ),
      );

      // Act
      final result = await repository.registerUser(
        email: tEmail,
        password: tPassword,
        displayName: tDisplayName,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<EmailAlreadyInUseFailure>()),
        (_) => fail('Should not return Right'),
      );
    });

    test('should return Left(NetworkFailure) when signUp throws SocketException', () async {
      // Arrange
      when(() => mockGoTrueClient.signUp(
        email: tEmail,
        password: tPassword,
        data: {'display_name': tDisplayName},
      )).thenThrow(const SocketException('Failed host lookup: api.supabase.co'));

      // Act
      final result = await repository.registerUser(
        email: tEmail,
        password: tPassword,
        displayName: tDisplayName,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should not return Right'),
      );
    });

    test('should return Left(NetworkFailure) when generic network exception occurs', () async {
      // Arrange
      when(() => mockGoTrueClient.signUp(
        email: tEmail,
        password: tPassword,
        data: {'display_name': tDisplayName},
      )).thenThrow(const AuthException('Network connection failed'));

      // Act
      final result = await repository.registerUser(
        email: tEmail,
        password: tPassword,
        displayName: tDisplayName,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should not return Right'),
      );
    });

    test('should return Left(UnknownFailure) when generic error occurs', () async {
      // Arrange
      when(() => mockGoTrueClient.signUp(
        email: tEmail,
        password: tPassword,
        data: {'display_name': tDisplayName},
      )).thenThrow(Exception('Some unexpected generic error'));

      // Act
      final result = await repository.registerUser(
        email: tEmail,
        password: tPassword,
        displayName: tDisplayName,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (_) => fail('Should not return Right'),
      );
    });

    test('should return Left(ServerFailure) when Go backend returns non-200 status code with non-JSON body', () async {
      // Arrange
      final mockAuthResponse = MockAuthResponse();
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn(tUserId);
      when(() => mockAuthResponse.user).thenReturn(mockUser);

      when(() => mockGoTrueClient.signUp(
        email: tEmail,
        password: tPassword,
        data: {'display_name': tDisplayName},
      )).thenAnswer((_) async => mockAuthResponse);

      when(() => mockSession.accessToken).thenReturn('test-jwt-token-abc');
      when(() => mockGoTrueClient.currentSession).thenReturn(mockSession);
      when(() => mockHttpClient.post(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Internal Server Error', 500));

      // Act
      final result = await repository.registerUser(
        email: tEmail,
        password: tPassword,
        displayName: tDisplayName,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('500'));
        },
        (_) => fail('Should not return Right'),
      );
    });

    test('should return Left(CollisionFailure) when Go backend returns collision_limit_reached error', () async {
      // Arrange
      final mockAuthResponse = MockAuthResponse();
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn(tUserId);
      when(() => mockAuthResponse.user).thenReturn(mockUser);

      when(() => mockGoTrueClient.signUp(
        email: tEmail,
        password: tPassword,
        data: {'display_name': tDisplayName},
      )).thenAnswer((_) async => mockAuthResponse);

      when(() => mockSession.accessToken).thenReturn('test-jwt-token-abc');
      when(() => mockGoTrueClient.currentSession).thenReturn(mockSession);
      when(() => mockHttpClient.post(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(jsonEncode({'error': 'collision_limit_reached'}), 500));

      // Act
      final result = await repository.registerUser(
        email: tEmail,
        password: tPassword,
        displayName: tDisplayName,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CollisionFailure>()),
        (_) => fail('Should not return Right'),
      );
    });

    test('should return Left(ServerFailure) when Go backend returns general error response', () async {
      // Arrange
      final mockAuthResponse = MockAuthResponse();
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn(tUserId);
      when(() => mockAuthResponse.user).thenReturn(mockUser);

      when(() => mockGoTrueClient.signUp(
        email: tEmail,
        password: tPassword,
        data: {'display_name': tDisplayName},
      )).thenAnswer((_) async => mockAuthResponse);

      when(() => mockSession.accessToken).thenReturn('test-jwt-token-abc');
      when(() => mockGoTrueClient.currentSession).thenReturn(mockSession);
      when(() => mockHttpClient.post(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(jsonEncode({'error': 'unauthorized request'}), 401));

      // Act
      final result = await repository.registerUser(
        email: tEmail,
        password: tPassword,
        displayName: tDisplayName,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('unauthorized request'));
        },
        (_) => fail('Should not return Right'),
      );
    });
  });

  group('loginUser', () {
    test('should return Right(AppUser) when signInWithPassword and profile fetch succeed', () async {
      // Arrange
      final mockAuthResponse = MockAuthResponse();
      final mockUser = MockUser();
      final profileData = {
        'id': tUserId,
        'display_name': tDisplayName,
        'unique_code': 'KAP-12345678',
        'email': tEmail,
        'email_verified': false,
      };

      when(() => mockUser.id).thenReturn(tUserId);
      when(() => mockAuthResponse.user).thenReturn(mockUser);

      when(() => mockGoTrueClient.signInWithPassword(
        email: tEmail,
        password: tPassword,
      )).thenAnswer((_) async => mockAuthResponse);

      when(() => mockSupabaseQueryBuilder.select(any())).thenAnswer((_) => mockPostgrestFilterBuilder);
      when(() => mockPostgrestFilterBuilder.eq(any(), any())).thenAnswer((_) => mockPostgrestFilterBuilder);
      
      final fakeFilterBuilder = FakePostgrestFilterBuilder(Future.value(profileData));
      when(() => mockPostgrestFilterBuilder.maybeSingle()).thenAnswer((_) => fakeFilterBuilder);

      // Act
      final result = await repository.loginUser(
        email: tEmail,
        password: tPassword,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return Left: $failure'),
        (user) {
          expect(user.id, tUserId);
          expect(user.displayName, tDisplayName);
          expect(user.email, tEmail);
          expect(user.uniqueCode, 'KAP-12345678');
          expect(user.emailVerified, false);
        },
      );

      verify(() => mockGoTrueClient.signInWithPassword(
        email: tEmail,
        password: tPassword,
      )).called(1);
      verify(() => mockSupabaseClient.from('users')).called(1);
    });

    test('should return Left(InvalidCredentialsFailure) when signInWithPassword throws AuthException invalid credentials', () async {
      // Arrange
      when(() => mockGoTrueClient.signInWithPassword(
        email: tEmail,
        password: tPassword,
      )).thenThrow(const AuthException('Invalid login credentials', statusCode: '400'));

      // Act
      final result = await repository.loginUser(
        email: tEmail,
        password: tPassword,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<InvalidCredentialsFailure>()),
        (_) => fail('Should not return Right'),
      );
    });

    test('should return Left(UnknownFailure) when user profile is not found in database', () async {
      // Arrange
      final mockAuthResponse = MockAuthResponse();
      final mockUser = MockUser();

      when(() => mockUser.id).thenReturn(tUserId);
      when(() => mockAuthResponse.user).thenReturn(mockUser);

      when(() => mockGoTrueClient.signInWithPassword(
        email: tEmail,
        password: tPassword,
      )).thenAnswer((_) async => mockAuthResponse);

      when(() => mockSupabaseQueryBuilder.select(any())).thenAnswer((_) => mockPostgrestFilterBuilder);
      when(() => mockPostgrestFilterBuilder.eq(any(), any())).thenAnswer((_) => mockPostgrestFilterBuilder);
      
      final fakeFilterBuilder = FakePostgrestFilterBuilder(Future.value(null));
      when(() => mockPostgrestFilterBuilder.maybeSingle()).thenAnswer((_) => fakeFilterBuilder);

      // Act
      final result = await repository.loginUser(
        email: tEmail,
        password: tPassword,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(failure.message, contains('profile not found'));
        },
        (_) => fail('Should not return Right'),
      );
    });

    test('should return Left(UnknownFailure) when database select throws PostgrestException', () async {
      // Arrange
      final mockAuthResponse = MockAuthResponse();
      final mockUser = MockUser();

      when(() => mockUser.id).thenReturn(tUserId);
      when(() => mockAuthResponse.user).thenReturn(mockUser);

      when(() => mockGoTrueClient.signInWithPassword(
        email: tEmail,
        password: tPassword,
      )).thenAnswer((_) async => mockAuthResponse);

      when(() => mockSupabaseQueryBuilder.select(any())).thenAnswer((_) => mockPostgrestFilterBuilder);
      when(() => mockPostgrestFilterBuilder.eq(any(), any())).thenAnswer((_) => mockPostgrestFilterBuilder);
      when(() => mockPostgrestFilterBuilder.maybeSingle()).thenThrow(
        const PostgrestException(message: 'Database connection lost', code: '500'),
      );

      // Act
      final result = await repository.loginUser(
        email: tEmail,
        password: tPassword,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (_) => fail('Should not return Right'),
      );
    });

    test('should return Left(NetworkFailure) when signInWithPassword throws SocketException', () async {
      // Arrange
      when(() => mockGoTrueClient.signInWithPassword(
        email: tEmail,
        password: tPassword,
      )).thenThrow(const SocketException('Connection timeout'));

      // Act
      final result = await repository.loginUser(
        email: tEmail,
        password: tPassword,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should not return Right'),
      );
    });
  });
}
