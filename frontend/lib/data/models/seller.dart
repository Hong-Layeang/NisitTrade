import '../dtos/seller_dto.dart';
import 'university.dart';

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
  final University? university;
  final bool isOnline;
  final DateTime? lastSeenAt;

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
    this.university,
    this.isOnline = false,
    this.lastSeenAt,
  });

  factory Seller.fromDto(SellerDto dto) {
    return Seller(
      id: dto.id,
      fullName: dto.fullName,
      email: dto.email,
      profileImage: dto.profileImage,
      provider: dto.provider,
      role: dto.role,
      universityId: dto.universityId,
      major: dto.major,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      university: dto.university != null ? University.fromDto(dto.university!) : null,
      isOnline: dto.isOnline,
      lastSeenAt: dto.lastSeenAt,
    );
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
    University? university,
    bool? isOnline,
    DateTime? lastSeenAt,
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
      university: university ?? this.university,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}