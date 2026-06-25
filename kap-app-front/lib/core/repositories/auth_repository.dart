import '../errors/app_error.dart';
import '../models/app_user.dart';

abstract class AuthRepository {
  /// Registers a user using their email, password, and display name.
  ///
  /// Returns a record containing the registered [AppUser] if successful,
  /// or an [AppError] if the registration fails.
  /// This method must catch all internal exceptions and return them as an [AppError] record.
  Future<({AppUser? data, AppError? error})> registerUser({
    required String email,
    required String password,
    required String displayName,
  });
}
