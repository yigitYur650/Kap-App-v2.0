class AppConstants {
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://kap-app-backend.onrender.com',
  );
}
