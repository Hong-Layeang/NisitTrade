import 'university_dto.dart';

class UserProfileDto {
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
  final UniversityDto? university;
  final int followerCount;
  final int followingCount;
  final double averageRating;
  final int ratingCount;
  final bool isFollowing;
  final String? emailDomain;
  final bool isBlockedByMe;
  final bool hasBlockedMe;
  final bool isOnline;
  final DateTime? lastSeenAt;

  const UserProfileDto({
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
    this.averageRating = 0,
    this.ratingCount = 0,
    this.isFollowing = false,
    this.emailDomain,
    this.isBlockedByMe = false,
    this.hasBlockedMe = false,
    this.isOnline = false,
    this.lastSeenAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isRegularUser => role == 'user';
  String get displayName => fullName;
  bool get hasProfileImage => profileImage != null && profileImage!.isNotEmpty;
  bool get hasCoverImage => coverImage != null && coverImage!.isNotEmpty;
  bool get hasBio => bio != null && bio!.isNotEmpty;

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    final universityJson = json['University'] ?? json['university'];

    return UserProfileDto(
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
          ? UniversityDto.fromJson(universityJson)
          : null,
      followerCount: json['follower_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
        averageRating: json['avg_rating'] is num
          ? (json['avg_rating'] as num).toDouble()
          : (json['avg_rating'] is String
            ? double.tryParse(json['avg_rating'] as String) ?? 0
            : 0),
        ratingCount: json['rating_count'] is num
          ? (json['rating_count'] as num).toInt()
          : (json['rating_count'] is String
            ? int.tryParse(json['rating_count'] as String) ?? 0
            : 0),
      isFollowing: json['is_following'] as bool? ?? false,
      emailDomain: json['email_domain'] as String?,
      isBlockedByMe: json['is_blocked_by_me'] as bool? ?? false,
      hasBlockedMe: json['has_blocked_me'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeenAt: (json['last_seen_at'] ?? json['lastSeenAt']) is String
          ? DateTime.tryParse(
              (json['last_seen_at'] ?? json['lastSeenAt']) as String)
          : null,
    );
  }

  UserProfileDto copyWith({
    bool? isFollowing,
    int? followerCount,
    int? followingCount,
    double? averageRating,
    int? ratingCount,
    String? coverImage,
    String? profileImage,
    bool? isBlockedByMe,
    bool? hasBlockedMe,
    bool? isOnline,
    DateTime? lastSeenAt,
    String? fullName,
    String? bio,
    String? major,
  }) {
    return UserProfileDto(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      profileImage: profileImage ?? this.profileImage,
      coverImage: coverImage ?? this.coverImage,
      bio: bio ?? this.bio,
      major: major ?? this.major,
      provider: provider,
      role: role,
      universityId: universityId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      university: university,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      isFollowing: isFollowing ?? this.isFollowing,
      emailDomain: emailDomain,
      isBlockedByMe: isBlockedByMe ?? this.isBlockedByMe,
      hasBlockedMe: hasBlockedMe ?? this.hasBlockedMe,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}
