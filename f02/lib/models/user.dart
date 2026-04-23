/// Khớp schema `User` từ backend (snake_case JSON).
class AdminUser {
  const AdminUser({
    required this.id,
    this.email,
    this.username,
    this.fullName,
    this.isActive = false,
    this.isSuperuser = false,
  });

  final int id;
  final String? email;
  final String? username;
  final String? fullName;
  final bool isActive;
  final bool isSuperuser;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as int,
      email: json['email'] as String?,
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      isSuperuser: json['is_superuser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'email': email,
        'username': username,
        'full_name': fullName,
        'is_active': isActive,
        'is_superuser': isSuperuser,
      };

  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty)
          ? fullName!.trim()
          : (username ?? email ?? 'User #$id');
}

class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  final String accessToken;
  final String tokenType;
  final AdminUser user;

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: AdminUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
