/// Representation of an authenticated user returned by Next.js /api/auth/login.
class UserModel {
  final String id;
  final String email;
  final Map<String, dynamic>? userMetadata;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.userMetadata,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      userMetadata: json['user_metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'user_metadata': userMetadata,
      'created_at': createdAt,
    };
  }
}

