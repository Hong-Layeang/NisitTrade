import '../../domain/entities/seller_entity.dart';

class Seller {
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

  const Seller({
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
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'profile_image': profileImage,
      'provider': provider,
      'role': role,
      'university_id': universityId,
      'major': major,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Seller copyWith({
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
  }) {
    return Seller(
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
    );
  }

  /// Convert to domain entity
  SellerEntity toEntity() {
    return SellerEntity(
      id: id,
      fullName: fullName,
      profileImage: profileImage,
      major: major,
    );
  }

  /// Create from domain entity
  factory Seller.fromEntity(SellerEntity entity) {
    return Seller(
      id: entity.id,
      fullName: entity.fullName,
      email: '', // Not in entity
      profileImage: entity.profileImage,
      role: 'user', // Default
      major: entity.major,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
