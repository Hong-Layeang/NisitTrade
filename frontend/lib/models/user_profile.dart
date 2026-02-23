import 'university.dart';

class UserProfile {
  final int id;
  final String fullName;
  final String email;
  final String? profileImage;
  final String? provider;
  final String role;
  final int? universityId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final University? university;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.profileImage,
    this.provider,
    required this.role,
    this.universityId,
    required this.createdAt,
    required this.updatedAt,
    this.university,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int? ?? 0,
      fullName: (json['full_name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      profileImage: json['profile_image'] as String?,
      provider: json['provider'] as String?,
      role: (json['role'] ?? 'user') as String,
      universityId: json['university_id'] as int?,
      createdAt: (json['createdAt'] ?? json['created_at']) != null
          ? DateTime.parse((json['createdAt'] ?? json['created_at']) as String)
          : DateTime.now(),
      updatedAt: (json['updatedAt'] ?? json['updated_at']) != null
          ? DateTime.parse((json['updatedAt'] ?? json['updated_at']) as String)
          : DateTime.now(),
      university: json['University'] != null
          ? University.fromJson(json['University'] as Map<String, dynamic>)
          : null,
    );
  }
}
