class AppUser {
  final String id;
  final String displayName;
  final String uniqueCode;
  final String email;
  final bool emailVerified;

  const AppUser({
    required this.id,
    required this.displayName,
    required this.uniqueCode,
    required this.email,
    required this.emailVerified,
  });

  // Explanatory comment: dynamic is used here because JSON payload values can represent multiple different Dart types (e.g. String, bool, num, null).
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      uniqueCode: json['unique_code'] as String,
      email: json['email'] as String,
      emailVerified: json['email_verified'] as bool? ?? false,
    );
  }

  // Explanatory comment: dynamic is used here because JSON payload values can represent multiple different Dart types (e.g. String, bool, num, null).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'unique_code': uniqueCode,
      'email': email,
      'email_verified': emailVerified,
    };
  }
}
