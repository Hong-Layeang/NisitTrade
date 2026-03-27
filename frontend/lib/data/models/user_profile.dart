import '../dtos/user_profile_dto.dart';
import 'university.dart';

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

  bool get hasProfileImage => profileImage != null && profileImage!.isNotEmpty;
  bool get hasCoverImage => coverImage != null && coverImage!.isNotEmpty;
  bool get hasBio => bio != null && bio!.isNotEmpty;
  bool get isAdmin => role == 'admin';
  bool get isRegularUser => role == 'user';
  String get displayName => fullName;

  factory UserProfile.fromDto(UserProfileDto dto) {
    return UserProfile(
      id: dto.id,
      fullName: dto.fullName,
      email: dto.email,
      profileImage: dto.profileImage,
      coverImage: dto.coverImage,
      bio: dto.bio,
      major: dto.major,
      provider: dto.provider,
      role: dto.role,
      universityId: dto.universityId,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      university: dto.university != null ? University.fromDto(dto.university!) : null,
      followerCount: dto.followerCount,
      followingCount: dto.followingCount,
      isFollowing: dto.isFollowing,
      emailDomain: dto.emailDomain,
      isBlockedByMe: dto.isBlockedByMe,
      hasBlockedMe: dto.hasBlockedMe,
      isOnline: dto.isOnline,
      lastSeenAt: dto.lastSeenAt,
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
    String? fullName,
    String? bio,
    String? major,
  }) {
    return UserProfile(
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
      isFollowing: isFollowing ?? this.isFollowing,
      emailDomain: emailDomain,
      isBlockedByMe: isBlockedByMe ?? this.isBlockedByMe,
      hasBlockedMe: hasBlockedMe ?? this.hasBlockedMe,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}