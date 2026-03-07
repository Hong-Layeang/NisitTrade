import 'university.dart';
import '../../domain/entities/user_entity.dart';

class UserProfile {
  final int id;
  final String fullName;
  final String email;
  final String? profileImage;
  final String? coverImage;
  final String? bio;
  final String? major;
  final String? provider;
  final String role;
  final int? universityId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final University? university;
  final int followerCount;
  final int followingCount;
  final bool isFollowing;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.profileImage,
    this.coverImage,
    this.bio,
    this.major,
    this.provider,
    required this.role,
    this.universityId,
    required this.createdAt,
    required this.updatedAt,
    this.university,
    this.followerCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int? ?? 0,
      fullName: (json['full_name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      profileImage: json['profile_image'] as String?,
      coverImage: json['cover_image'] as String?,
      bio: json['bio'] as String?,
      major: json['major'] as String?,
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
      followerCount: json['follower_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      isFollowing: json['is_following'] as bool? ?? false,
    );
  }

  UserProfile copyWith({
    bool? isFollowing,
    int? followerCount,
    int? followingCount,
    String? coverImage,
    String? profileImage,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName,
      email: email,
      profileImage: profileImage ?? this.profileImage,
      coverImage: coverImage ?? this.coverImage,
      bio: bio,
      major: major,
      provider: provider,
      role: role,
      universityId: universityId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      university: university,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  /// Convert to domain entity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      fullName: fullName,
      email: email,
      profileImage: profileImage,
      coverImage: coverImage,
      bio: bio,
      major: major,
      provider: provider,
      role: UserRole.fromString(role),
      universityId: universityId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      university: university?.toEntity(),
      followerCount: followerCount,
      followingCount: followingCount,
      isFollowing: isFollowing,
    );
  }

  /// Create from domain entity
  factory UserProfile.fromEntity(UserEntity entity) {
    return UserProfile(
      id: entity.id,
      fullName: entity.fullName,
      email: entity.email,
      profileImage: entity.profileImage,
      coverImage: entity.coverImage,
      bio: entity.bio,
      major: entity.major,
      provider: entity.provider,
      role: entity.role.toValue(),
      universityId: entity.universityId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      university: entity.university != null 
          ? University.fromEntity(entity.university!) 
          : null,
      followerCount: entity.followerCount,
      followingCount: entity.followingCount,
      isFollowing: entity.isFollowing,
    );
  }
}
