import 'package:equatable/equatable.dart';
import 'university_entity.dart';

/// Domain entity representing a seller/user
class SellerEntity extends Equatable {
  final int id;
  final String fullName;
  final String email;
  final String? profileImage;
  final String? major;
  final UniversityEntity? university;

  const SellerEntity({
    required this.id,
    required this.fullName,
    required this.email,
    this.profileImage,
    this.major,
    this.university,
  });

  /// Returns true if the seller has a profile image
  bool get hasProfileImage => profileImage != null && profileImage!.isNotEmpty;

  /// Returns display name for the seller
  String get displayName => fullName;

  @override
  List<Object?> get props => [id, fullName, email, profileImage, major, university];
}
