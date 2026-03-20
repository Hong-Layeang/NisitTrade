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
  final String? emailDomain;
  final bool isBlockedByMe;
  final bool hasBlockedMe;
  final bool isOnline;
  final DateTime? lastSeenAt;

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
    this.emailDomain,
    this.isBlockedByMe = false,
    this.hasBlockedMe = false,
    this.isOnline = false,
    this.lastSeenAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final universityJson = json['University'] ?? json['university'];

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
      university: universityJson is Map<String, dynamic>
          ? University.fromJson(universityJson)
          : null,
      followerCount: json['follower_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      isFollowing: json['is_following'] as bool? ?? false,
      emailDomain: json['email_domain'] as String?,
      isBlockedByMe: json['is_blocked_by_me'] as bool? ?? false,
      hasBlockedMe: json['has_blocked_me'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeenAt: (json['last_seen_at'] ?? json['lastSeenAt']) is String
          ? DateTime.tryParse((json['last_seen_at'] ?? json['lastSeenAt']) as String)
          : null,
    );
  }

  UserProfile copyWith({
    bool? isFollowing,
    int? followerCount,
    int? followingCount,
    String? coverImage,
    String? profileImage,
    bool? isBlockedByMe,
    bool? hasBlockedMe,
    bool? isOnline,
    DateTime? lastSeenAt,
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
      emailDomain: emailDomain,
      isBlockedByMe: isBlockedByMe ?? this.isBlockedByMe,
      hasBlockedMe: hasBlockedMe ?? this.hasBlockedMe,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
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
      emailDomain: emailDomain,
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
      emailDomain: entity.emailDomain,
      isBlockedByMe: false,
      hasBlockedMe: false,
      isOnline: false,
      lastSeenAt: null,
    );
  }
}
