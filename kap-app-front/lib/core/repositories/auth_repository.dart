import 'package:fpdart/fpdart.dart';
import '../errors/failure.dart';
import '../models/app_user.dart';

abstract class AuthRepository {
  /// Registers a user using their email, password, and display name.
  ///
  /// Returns [Either] containing a [Failure] on the left if the registration fails,
  /// or the registered [AppUser] on the right if successful.
  Future<Either<Failure, AppUser>> registerUser({
    required String email,
    required String password,
    required String displayName,
  });

  /// Logins a user using their email and password.
  ///
  /// Returns [Either] containing a [Failure] on the left if the login fails,
  /// or the authenticated [AppUser] on the right if successful.
  Future<Either<Failure, AppUser>> loginUser({
    required String email,
    required String password,
  });
}
