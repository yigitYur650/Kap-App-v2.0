class AppUser {
  final String id;
  final String displayName;
  final String uniqueCode;
  final String email;
  final bool emailVerified;
  final bool is2FAEnabled;

  const AppUser({
    required this.id,
    required this.displayName,
    required this.uniqueCode,
    required this.email,
    required this.emailVerified,
    this.is2FAEnabled = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      uniqueCode: json['unique_code'] as String,
      email: json['email'] as String,
      emailVerified: json['email_verified'] as bool? ?? false,
      is2FAEnabled: json['is_2fa_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'unique_code': uniqueCode,
      'email': email,
      'email_verified': emailVerified,
      'is_2fa_enabled': is2FAEnabled,
    };
  }

  AppUser copyWith({
    String? id,
    String? displayName,
    String? uniqueCode,
    String? email,
    bool? emailVerified,
    bool? is2FAEnabled,
  }) {
    return AppUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      uniqueCode: uniqueCode ?? this.uniqueCode,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      is2FAEnabled: is2FAEnabled ?? this.is2FAEnabled,
    );
  }
}
