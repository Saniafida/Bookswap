import '../core/enums/user_role.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final int swapCount;
  final DateTime createdAt;
  final UserRole role;
  final bool isBanned;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    this.location,
    this.swapCount = 0,
    required this.createdAt,
    this.role = UserRole.user,
    this.isBanned = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      swapCount: json['swap_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      role: UserRole.fromString(json['role'] as String?),
      isBanned: json['is_banned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'location': location,
      'swap_count': swapCount,
      'role': role.name,
      'is_banned': isBanned,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? location,
    UserRole? role,
    bool? isBanned,
  }) {
    return UserModel(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      swapCount: swapCount,
      createdAt: createdAt,
      role: role ?? this.role,
      isBanned: isBanned ?? this.isBanned,
    );
  }

  /// Convenience: is this user an admin?
  bool get isAdmin => role.isAdmin;
}
