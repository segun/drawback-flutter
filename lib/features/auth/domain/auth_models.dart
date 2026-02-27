class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.mode,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String mode;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      mode: json['mode'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class AuthResult {
  const AuthResult({required this.accessToken});

  final String accessToken;
}

class ResetPasswordResult {
  const ResetPasswordResult({
    required this.status,
    required this.message,
    this.email,
  });

  final String status;
  final String message;
  final String? email;

  factory ResetPasswordResult.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResult(
      status: json['status'] as String,
      message: json['message'] as String,
      email: json['email'] as String?,
    );
  }
}
