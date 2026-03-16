import 'package:equatable/equatable.dart';
import 'university_entity.dart';

/// Domain entity representing a user profile
class UserEntity extends Equatable {
  final int id;
  final String fullName;
  final String email;
  final String? profileImage;
  final String? coverImage;
  final String? bio;
  final String? major;
  final String? provider;
  final UserRole role;
  final int? universityId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UniversityEntity? university;
  final int followerCount;
  final int followingCount;
  final bool isFollowing;
  final String? emailDomain;

  const UserEntity({
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
  });

  /// Returns true if the user has a profile image
  bool get hasProfileImage => profileImage != null && profileImage!.isNotEmpty;

  /// Returns true if the user has a cover image
  bool get hasCoverImage => coverImage != null && coverImage!.isNotEmpty;

  /// Returns true if the user has a bio
  bool get hasBio => bio != null && bio!.isNotEmpty;

  /// Returns true if the user is an admin
  bool get isAdmin => role == UserRole.admin;

  /// Returns true if the user is a regular user
  bool get isRegularUser => role == UserRole.user;

  /// Returns display name for the user
  String get displayName => fullName;

  /// Creates a copy of this entity with the given fields replaced
  UserEntity copyWith({
    int? id,
    String? fullName,
    String? email,
    String? profileImage,
    String? coverImage,
    String? bio,
    String? major,
    String? provider,
    UserRole? role,
    int? universityId,
    DateTime? createdAt,
    DateTime? updatedAt,
    UniversityEntity? university,
    int? followerCount,
    int? followingCount,
    bool? isFollowing,
    String? emailDomain,
  }) {
    return UserEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      coverImage: coverImage ?? this.coverImage,
      bio: bio ?? this.bio,
      major: major ?? this.major,
      provider: provider ?? this.provider,
      role: role ?? this.role,
      universityId: universityId ?? this.universityId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      university: university ?? this.university,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
      emailDomain: emailDomain ?? this.emailDomain,
    );
  }

  @override
  List<Object?> get props => [
    id, fullName, email, profileImage, coverImage, bio, major,
    provider, role, universityId, createdAt, updatedAt, university,
    followerCount, followingCount, isFollowing, emailDomain
  ];
}

/// Enum representing user role
enum UserRole {
  user,
  admin;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  String toValue() {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.user:
        return 'user';
    }
  }
}
