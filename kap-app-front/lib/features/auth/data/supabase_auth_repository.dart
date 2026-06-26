import 'dart:convert';
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/failure.dart';
import '../../../core/models/app_user.dart';
import '../../../core/repositories/auth_repository.dart';

/// An implementation of [AuthRepository] using Supabase.
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabaseClient;
  final http.Client _httpClient;

  SupabaseAuthRepository(this._supabaseClient, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  @override
  Future<Either<Failure, AppUser>> registerUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // 1. Invoke Supabase Auth sign-up
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      final user = response.user;
      if (user == null) {
        return const Left(UnknownFailure('User is null after signup'));
      }

      // 2. Fetch the unique sharing code from local Go backend using authenticated request
      const backendUrl = String.fromEnvironment(
        'BACKEND_URL',
        defaultValue: 'http://localhost:8080',
      );

      final jwtToken = _supabaseClient.auth.currentSession?.accessToken;
      if (jwtToken == null) {
        return const Left(UnknownFailure('Session token is missing after signup'));
      }

      final httpResponse = await _httpClient.post(
        Uri.parse('$backendUrl/api/v1/auth/unique-code'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      if (httpResponse.statusCode != 200) {
        try {
          final errorData = jsonDecode(httpResponse.body) as Map<String, dynamic>;
          final errorMessage = errorData['error'] as String?;
          if (errorMessage != null) {
            if (errorMessage == 'collision_limit_reached' || errorMessage.contains('collision')) {
              return const Left(CollisionFailure());
            }
            return Left(ServerFailure(errorMessage));
          }
        } catch (_) {}
        return Left(ServerFailure('Server error with status code: ${httpResponse.statusCode}'));
      }

      final responseData = jsonDecode(httpResponse.body) as Map<String, dynamic>;
      final uniqueCode = responseData['unique_code'] as String?;
      if (uniqueCode == null || uniqueCode.isEmpty) {
        return const Left(UnknownFailure('Unique code from backend is empty'));
      }

      // 3. Insert the user profile row into the public.users table
      await _supabaseClient.from('users').insert({
        'id': user.id,
        'display_name': displayName,
        'unique_code': uniqueCode,
        'email': email,
        'email_verified': false,
      });

      return Right(
        AppUser(
          id: user.id,
          displayName: displayName,
          uniqueCode: uniqueCode,
          email: email,
          emailVerified: false,
        ),
      );
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on SocketException catch (_) {
      return const Left(NetworkFailure());
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('socketexception') ||
          str.contains('network') ||
          str.contains('connection failed') ||
          str.contains('failed host lookup')) {
        return const Left(NetworkFailure());
      }
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Invoke Supabase Auth login
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        return const Left(UnknownFailure('User is null after login'));
      }

      // 2. Fetch user profile from public.users table
      final profile = await _supabaseClient
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        return const Left(UnknownFailure('User profile not found in database'));
      }

      return Right(AppUser.fromJson(profile));
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on SocketException catch (_) {
      return const Left(NetworkFailure());
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('socketexception') ||
          str.contains('network') ||
          str.contains('connection failed')) {
        return const Left(NetworkFailure());
      }
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Maps Supabase auth exceptions to domain-specific failures.
  Failure _mapAuthException(AuthException e) {
    final message = e.message.toLowerCase();
    
    // Check for invalid credentials
    if (message.contains('invalid credentials') ||
        message.contains('invalid login credentials') ||
        message.contains('invalid grant') ||
        (e.statusCode != null && e.statusCode == '400' && message.contains('invalid')) ||
        (e.statusCode != null && e.statusCode == '401' && message.contains('invalid')) ||
        (e.statusCode != null && e.statusCode == '400' && message.contains('password'))) {
      return const InvalidCredentialsFailure();
    }
    
    if (message.contains('already registered') ||
        message.contains('already exists') ||
        message.contains('already in use') ||
        (e.statusCode != null && e.statusCode == '400' && message.contains('exists')) ||
        (e.statusCode != null && e.statusCode == '422' && message.contains('exists'))) {
      return const EmailAlreadyInUseFailure();
    }
    if (message.contains('network') || message.contains('connection')) {
      return const NetworkFailure();
    }
    return UnknownFailure(e.message);
  }

  /// Maps PostgreSQL database exceptions to domain-specific failures.
  Failure _mapPostgrestException(PostgrestException e) {
    final code = e.code;
    final message = e.message.toLowerCase();
    final details = e.details?.toString().toLowerCase() ?? '';

    // Check for unique violation (PostgreSql status code 23505)
    if (code == '23505') {
      if (message.contains('email') || details.contains('email')) {
        return const EmailAlreadyInUseFailure();
      }
      return UnknownFailure('Database unique constraint violation: ${e.message}');
    }
    return UnknownFailure('Database error: ${e.message}');
  }
}
