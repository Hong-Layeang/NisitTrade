import 'university_dto.dart';

class SellerDto {
  final int id;
  final String fullName;
  final String email;
  final String? profileImage;
  final String? provider;
  final String role;
  final int? universityId;
  final String? major;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UniversityDto? university;
  final bool isOnline;
  final DateTime? lastSeenAt;

  const SellerDto({
    required this.id,
    required this.fullName,
    required this.email,
    this.profileImage,
    this.provider,
    required this.role,
    this.universityId,
    this.major,
    required this.createdAt,
    required this.updatedAt,
    this.university,
    this.isOnline = false,
    this.lastSeenAt,
  });

  factory SellerDto.fromJson(Map<String, dynamic> json) {
    final universityJson = json['University'] ?? json['university'];

    return SellerDto(
      id: json['id'] as int? ?? 0,
      fullName: (json['full_name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      profileImage: json['profile_image'] as String?,
      provider: json['provider'] as String?,
      role: (json['role'] ?? 'user') as String,
      universityId: json['university_id'] as int?,
      major: json['major'] as String?,
      createdAt: (json['createdAt'] ?? json['created_at']) != null
          ? DateTime.parse((json['createdAt'] ?? json['created_at']) as String)
          : DateTime.now(),
      updatedAt: (json['updatedAt'] ?? json['updated_at']) != null
          ? DateTime.parse((json['updatedAt'] ?? json['updated_at']) as String)
          : DateTime.now(),
      university: universityJson is Map<String, dynamic>
          ? UniversityDto.fromJson(universityJson)
          : null,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeenAt: (json['last_seen_at'] ?? json['lastSeenAt']) is String
          ? DateTime.tryParse((json['last_seen_at'] ?? json['lastSeenAt']) as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'profile_image': profileImage,
      'provider': provider,
      if (university != null) 'University': university!.toJson(),
      'role': role,
      'university_id': universityId,
      'major': major,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_online': isOnline,
      'last_seen_at': lastSeenAt?.toIso8601String(),
    };
  }

  SellerDto copyWith({
    int? id,
    String? fullName,
    String? email,
    String? profileImage,
    String? provider,
    String? role,
    int? universityId,
    String? major,
    DateTime? createdAt,
    DateTime? updatedAt,
    UniversityDto? university,
    bool? isOnline,
    DateTime? lastSeenAt,
  }) {
    return SellerDto(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      provider: provider ?? this.provider,
      role: role ?? this.role,
      universityId: universityId ?? this.universityId,
      major: major ?? this.major,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      university: university ?? this.university,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}
