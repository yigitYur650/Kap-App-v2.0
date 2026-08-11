abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure([super.message = 'The email address is already in use by another account.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'A network error occurred. Please check your connection.']);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([super.message = 'Invalid email or password.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred.']);
}

class CollisionFailure extends Failure {
  const CollisionFailure([super.message = 'Unique code collision limit reached. Please try again.']);
}

class DuplicateItemFailure extends Failure {
  const DuplicateItemFailure([super.message = 'This item is already in your shopping list.']);
}

class TwoFactorRequiredFailure extends Failure {
  final String email;
  const TwoFactorRequiredFailure(this.email, [super.message = '2-Step Verification Required']);
}
