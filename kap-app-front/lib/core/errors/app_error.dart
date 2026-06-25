class AppError {
  final String message;
  final dynamic originalError; // Explanatory comment: dynamic is used here to allow any type of underlying original error (e.g. Exception, Error, or standard object) from external SDKs.
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppError: $message';
}
